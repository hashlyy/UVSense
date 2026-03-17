import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/primary_button.dart';
import '../app/routes.dart';
import '../services/uv_data_service.dart';
import '../services/ml_service.dart';
import '../services/storage_service.dart';

class FitzpatrickQuestionnaireScreen extends StatefulWidget {
  const FitzpatrickQuestionnaireScreen({super.key});

  @override
  State<FitzpatrickQuestionnaireScreen> createState() => _FitzpatrickQuestionnaireScreenState();
}

class _FitzpatrickQuestionnaireScreenState extends State<FitzpatrickQuestionnaireScreen> {
  final Map<int, int> _answers = {};

  final List<Map<String, dynamic>> _questions = [
    {
      "q": "What best describes your natural skin color (in areas not exposed to the sun)?",
      "options": [
        "Very fair / pale",
        "Fair",
        "Medium / beige",
        "Light brown",
        "Dark brown"
      ]
    },
    {
      "q": "What best describes your eye color?",
      "options": [
        "Light blue or gray",
        "Green",
        "Blue",
        "Brown",
        "Dark brown"
      ]
    },
    {
      "q": "What is your natural hair color?",
      "options": [
        "Red",
        "Blonde",
        "Light brown / chestnut",
        "Dark brown",
        "Black"
      ]
    },
    {
      "q": "Do you have freckles on unexposed areas of your skin?",
      "options": [
        "Many freckles",
        "Several freckles",
        "Few freckles",
        "Rare freckles",
        "None"
      ]
    },
    {
      "q": "What usually happens when you stay in the sun without protection?",
      "options": [
        "Always burns with redness or blistering",
        "Burns easily",
        "Sometimes burns",
        "Rarely burns",
        "Never burns"
      ]
    },
    {
      "q": "How well do you tan after sun exposure?",
      "options": [
        "Never tan",
        "Light tan",
        "Moderate tan",
        "Tan easily",
        "Turn dark brown quickly"
      ]
    }
  ];

  bool get _isComplete => _answers.length == _questions.length;

  double _getMedForScore(int score) {
    if (score <= 7) return 200.0; // Type I
    if (score <= 16) return 250.0; // Type II
    if (score <= 25) return 300.0; // Type III
    if (score <= 30) return 450.0; // Type IV
    if (score <= 35) return 600.0; // Type V
    return 1000.0; // Type VI
  }

  String _getSkinTypeLabel(int score) {
    if (score <= 7) return "Type I";
    if (score <= 16) return "Type II";
    if (score <= 25) return "Type III";
    if (score <= 30) return "Type IV";
    if (score <= 35) return "Type V";
    return "Type VI";
  }

  void _calculateAndFinish() async {
    // 1. Sum the scores from all questions
    int totalScore = _answers.values.fold(0, (sum, val) => sum + val);
    
    // 2 & 3. Determine Fitzpatrick skin type and map to MED
    double medLimit = _getMedForScore(totalScore);
    String skinType = _getSkinTypeLabel(totalScore);

    // 4. Store the MED value locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('med_threshold', medLimit);
    
    // Pre-populate the ML service limits in prefs to align with the new baseline
    await prefs.setDouble('daily_safe_exposure_limit', medLimit);

    // 5. Use this MED value as the initial safe UV exposure limit used by the MED-based exposure model.
    UVDataService().medThreshold = medLimit;

    // Initialize the ML service so it picks up the newly persisted limit
    final mlService = AdaptiveThresholdService();
    await mlService.initialize(totalScore);

    // Save to Hive storage service
    StorageService().saveUserData(
      skinType: skinType,
      medThreshold: medLimit,
      adaptiveThreshold: medLimit,
    );

    if (!mounted) return;

    // Result dialog 
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Skin Profile Complete"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Score: $totalScore"),
            const SizedBox(height: 8),
            Text("Your Skin Type: $skinType", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
            const SizedBox(height: 8),
            Text("MED Threshold: ${medLimit.toInt()} J/m²", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text("Your daily UV safe limit has been adjusted.", style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // 6. Navigate the user to the Dashboard screen
              Navigator.pushReplacementNamed(
                context, 
                AppRoutes.dashboard, 
                arguments: medLimit.toInt()
              );
            },
            child: const Text("Continue to Dashboard"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Skin Profile")),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Please answer the following questions to determine your Fitzpatrick Skin Type and safe UV limit.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _questions.length,
              itemBuilder: (context, qIndex) {
                var question = _questions[qIndex];
                List<String> options = question['options'];
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Question ${qIndex + 1}:", 
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question['q'], 
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)
                        ),
                        const SizedBox(height: 12),
                        ...options.asMap().entries.map((entry) {
                          int optIndex = entry.key;
                          String optText = entry.value;
                          return RadioListTile<int>(
                            title: Text("$optIndex – $optText", style: const TextStyle(fontSize: 14)),
                            value: optIndex,
                            groupValue: _answers[qIndex],
                            onChanged: (val) {
                              setState(() {
                                _answers[qIndex] = val!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            activeColor: Colors.teal,
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0,-2))]
        ),
        child: PrimaryButton(
          text: "Calculate Skin Type",
          onPressed: _isComplete ? _calculateAndFinish : null,
        ),
      ),
    );
  }
}
