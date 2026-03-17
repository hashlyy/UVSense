import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../app/routes.dart';
import '../models/skin_type_model.dart';
import '../services/ml_service.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  // Store selected index for each question. Key: SectionIndex-QuestionIndex
  final Map<String, int> _answers = {};

  final List<Map<String, dynamic>> _sections = [
    {
      "title": "1. Genetic / Baseline Pigmentation",
      "questions": [
        {
          "q": "What is your natural eye colour?",
          "options": [
            "Light blue, light gray, or light green (0)",
            "Blue, gray, or green (1)",
            "Hazel or light brown (2)",
            "Dark brown (3)",
            "Brownish black (4)"
          ]
        },
        {
          "q": "What is your natural hair colour?",
          "options": [
            "Red or light blonde (0)",
            "Blonde (1)",
            "Dark blonde or light brown (2)",
            "Dark brown (3)",
            "Black (4)"
          ]
        },
        {
          "q": "What is your natural skin colour (unexposed areas)?",
          "options": [
            "Reddish white (0)",
            "Very pale (1)",
            "Pale with beige tint (2)",
            "Light brown (3)",
            "Dark brown (4)"
          ]
        },
        {
          "q": "Do you have freckles on unexposed areas?",
          "options": [
            "Many (0)",
            "Several (1)",
            "Few (2)",
            "Very few (3)",
            "None (4)"
          ]
        },
      ]
    },
    {
      "title": "2. Reaction to Sun Exposure",
      "questions": [
        {
          "q": "What happens when you stay in the sun for too long?",
          "options": [
            "Painful redness, blistering, peeling (0)",
            "Blistering followed by peeling (1)",
            "Burns sometimes followed by peeling (2)",
            "Rarely burns (3)",
            "Never burns (4)"
          ]
        },
        {
          "q": "To what degree do you turn brown?",
          "options": [
            "Hardly or not at all (0)",
            "Light color tan (1)",
            "Reasonable tan (2)",
            "Tan very easily (3)",
            "Turn dark brown quickly (4)"
          ]
        },
        {
          "q": "Do you turn brown within several hours after sun exposure?",
          "options": [
            "Never (0)",
            "Seldom (1)",
            "Sometimes (2)",
            "Often (3)",
            "Always (4)"
          ]
        },
        {
          "q": "How does your face react to the sun?",
          "options": [
            "Very sensitive (0)",
            "Sensitive (1)",
            "Normal (2)",
            "Very resistant (3)",
            "Never had a problem (4)"
          ]
        },
      ]
    },
    {
      "title": "3. Pigmentation Behaviour (India-Specific)",
      "questions": [
        {
          "q": "When you get a pimple or cut, does it leave a dark mark?",
          "options": [
            "Never (0)",
            "Rarely (1)",
            "Sometimes (2)",
            "Often (3)",
            "Always (4)"
          ]
        },
        {
          "q": "Do you have patches of uneven pigmentation (melasma)?",
          "options": [
            "No (0)",
            "Mild (visible close up) (1)",
            "Moderate (visible at conversation distance) (2)",
            "Severe (3)",
            "Very Severe (4)"
          ]
        },
      ]
    },
    {
      "title": "4. Sun Exposure / Tanning Habits",
      "questions": [
        {
          "q": "When did you last expose your body to strong sun?",
          "options": [
            "More than 3 months ago (0)",
            "2-3 months ago (1)",
            "1-2 months ago (2)",
            "Less than 1 month ago (3)",
            "Less than 2 weeks ago (4)"
          ]
        },
        {
          "q": "Does your skin have a history of sun exposure?",
          "options": [
            "Never (0)",
            "Hardly ever (1)",
            "Sometimes (2)",
            "Often (3)",
            "Always (4)"
          ]
        },
      ]
    },
  ];

  int _calculateSubtotal(int sectionIndex) {
    int subtotal = 0;
    List<Map<String, dynamic>> questions = _sections[sectionIndex]['questions'];
    for (int i = 0; i < questions.length; i++) {
      String key = "$sectionIndex-$i";
      subtotal += _answers[key] ?? 0;
    }
    return subtotal;
  }

  void _calculateAndFinish() async {
    int genetic = _calculateSubtotal(0);
    int reaction = _calculateSubtotal(1);
    int pigmentation = _calculateSubtotal(2);
    int habits = _calculateSubtotal(3);

    int totalScore = genetic + reaction + pigmentation + habits;
    SkinType skinType = SkinTypeModel.getSkinTypeFromScore(totalScore);
    
    // Initialize ML Service with the score
    final mlService = AdaptiveThresholdService();
    await mlService.initialize(totalScore);
    
    // Get the calculated threshold
    double threshold = mlService.dailySafeExposureLimit;

    if (!mounted) return;

    // Show result dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Skin Type Calculated"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Score: $totalScore"),
            const SizedBox(height: 8),
            Text("Your Skin Type: ${skinType.name}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
            const SizedBox(height: 8),
            Text("Daily UV Budget: ${threshold.toInt()}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text("This helps us personalize your sun protection advice.", style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pushReplacementNamed(
                context, 
                AppRoutes.dashboard, 
                arguments: threshold.toInt()
              );
            },
            child: const Text("Continue to Dashboard"),
          )
        ],
      ),
    );
  }

  bool get _isComplete {
    int totalQuestions = 0;
    for (var s in _sections) {
      totalQuestions += (s['questions'] as List).length;
    }
    return _answers.length == totalQuestions;
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
              "To give you accurate advice, we need to know your skin type.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _sections.length,
              itemBuilder: (context, sectionIndex) {
                var section = _sections[sectionIndex];
                List<Map<String, dynamic>> questions = section['questions'];
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.grey[200],
                      child: Text(
                        section['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    ...questions.asMap().entries.map((entry) {
                       int qIndex = entry.key;
                       Map<String, dynamic> question = entry.value;
                       String key = "$sectionIndex-$qIndex";
                       
                       return Card(
                         margin: const EdgeInsets.all(8),
                         elevation: 0,
                         shape: RoundedRectangleBorder(
                           side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                           borderRadius: BorderRadius.circular(8)
                         ),
                         child: Padding(
                           padding: const EdgeInsets.all(12.0),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(question['q'], style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                               const SizedBox(height: 8),
                               ...List.generate(question['options'].length, (optIndex) {
                                 String optText = question['options'][optIndex];
                                 return RadioListTile<int>(
                                   title: Text(optText, style: const TextStyle(fontSize: 13)),
                                   value: optIndex,
                                   groupValue: _answers[key],
                                   onChanged: (val) {
                                     setState(() {
                                       _answers[key] = val!;
                                     });
                                   },
                                   contentPadding: EdgeInsets.zero,
                                   dense: true,
                                   visualDensity: VisualDensity.compact,
                                   activeColor: Colors.teal,
                                 );
                               })
                             ],
                           ),
                         ),
                       );
                    }),
                  ],
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
          // We can visually disable it if not complete, or show a snackbar on click
        ),
      ),
    );
  }
}
