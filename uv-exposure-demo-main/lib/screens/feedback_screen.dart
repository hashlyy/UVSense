import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../services/ml_service.dart';
import '../services/xai_service.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import '../app/routes.dart';

class FeedbackScreen extends StatefulWidget {
  final double cumulativeExposure;
  final double currentThreshold;
  final double currentUV;

  const FeedbackScreen({
    super.key,
    required this.cumulativeExposure,
    required this.currentThreshold,
    required this.currentUV,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _selectedFeedback = -1;

  final List<String> _options = [
    "No discomfort",
    "Normal",
    "Sunburn"
  ];

  final List<String> _descriptions = [
    "(No redness or pain)",
    "(Expected daily condition)",
    "(Visible redness or pain)"
  ];

  bool _isUpdating = false;

  final AdaptiveThresholdService _mlService = AdaptiveThresholdService();
  final BLEService _bleService = BLEService();
  final XAIService _xaiService = XAIService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Check-in")),

      body: Column(
        children: [

          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "Did you experience any skin discomfort today?",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _options.length,

              itemBuilder: (context, index) {

                bool isSelected = _selectedFeedback == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFeedback = index;
                    });
                  },

                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8),

                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.teal.withValues(alpha: 0.1)
                          : Colors.white,

                      border: Border.all(
                          color: isSelected
                              ? Colors.teal
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1),

                      borderRadius:
                          BorderRadius.circular(12),
                    ),

                    child: ListTile(
                      title: Text(
                        _options[index],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold),
                      ),

                      subtitle: Text(
                          _descriptions[index]),

                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.teal)
                          : const Icon(
                              Icons.circle_outlined,
                              color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),

            child: PrimaryButton(
              text: _isUpdating
                  ? "Updating..."
                  : "Submit & Analyze",

              onPressed:
                  (_selectedFeedback != -1 &&
                          !_isUpdating)
                      ? () async {

                          setState(() {
                            _isUpdating = true;
                          });

                          // Capture navigator BEFORE any await gap
                          final navigator = Navigator.of(context);

                          final String feedbackLabel =
                              _options[_selectedFeedback];

                          final double previousThreshold =
                              widget.currentThreshold;

                          // STEP 1: ML threshold update (synchronous,
                          // returns new value and persists to SharedPrefs)
                          final double newThreshold =
                              _mlService.updateThreshold(
                            widget.cumulativeExposure,
                            feedbackLabel,
                          );

                          // Save to Hive storage service
                          StorageService().addFeedbackData(feedback: feedbackLabel);
                          StorageService().updateAdaptiveThreshold(newThreshold);

                          // STEP 2: Send updated threshold to ESP32 via BLE
                          try {
                            await _bleService.sendThreshold(newThreshold);
                          } catch (e) {
                            debugPrint(
                                'BLE threshold send failed: $e');
                          }

                          // STEP 3: Build XAI explanation with real data
                          final String explanation =
                              _xaiService.generateExplanation(
                            cumulativeExposure:
                                widget.cumulativeExposure,
                            threshold: newThreshold,
                            currentUV: widget.currentUV,
                          );

                          if (!mounted) return;

                          // STEP 4: Navigate to XAI explanation screen
                          navigator.pushNamed(
                            AppRoutes.explanation,
                            arguments: {
                              'cumulative':
                                  widget.cumulativeExposure,
                              'currentUV': widget.currentUV,
                              'threshold': newThreshold,
                              'previousThreshold': previousThreshold,
                              'feedback': feedbackLabel,
                              'explanation': explanation,
                            },
                          );
                        }
                      : () {},
            ),
          ),
        ],
      ),
    );
  }
}