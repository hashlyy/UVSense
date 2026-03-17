import 'package:flutter/material.dart';
import '../services/xai_service.dart';
import '../widgets/primary_button.dart';
import '../app/routes.dart';

class ExplanationScreen extends StatelessWidget {
  final double cumulativeExposure;
  final double currentUV;
  final double threshold; // New threshold
  final double previousThreshold;
  final String feedback;

  const ExplanationScreen({
    super.key,
    required this.cumulativeExposure,
    required this.currentUV,
    required this.threshold,
    required this.previousThreshold,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    // Generate explanation from real BLE-derived session data.
    final xaiService = XAIService();
    final String explanation = xaiService.generateExplanation(
      cumulativeExposure: cumulativeExposure,
      threshold: threshold,
      currentUV: currentUV,
    );

    double diff = threshold - previousThreshold;
    String sign = diff >= 0 ? "+" : "";

    return Scaffold(
      appBar: AppBar(title: const Text("Analysis")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.insights, size: 80, color: Colors.indigo),
            const SizedBox(height: 24),
            Text(
              "Daily Summary",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                explanation,
                style: const TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.justify,
              ),
            ),
            
            const SizedBox(height: 10),
            Text(
              "This system learns from your feedback over time.",
              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            
            Text(
              "Adaptive Adjustment",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Previous limit:", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text("${previousThreshold.toStringAsFixed(0)} J/m²", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("New limit:", style: TextStyle(fontSize: 16, color: Colors.black87)),
                      Text("${threshold.toStringAsFixed(0)} J/m²", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Change:", style: TextStyle(fontSize: 16, color: Colors.black87)),
                      Text(
                        "${diff > 0 ? 'Increased' : diff < 0 ? 'Reduced' : 'Maintained'} by ${diff.abs().toStringAsFixed(0)} J/m²",
                        style: TextStyle(
                          color: diff > 0 ? Colors.green : (diff < 0 ? Colors.orange : Colors.grey),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Reason for adjustment",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint("High UV exposure detected"),
                  _buildBulletPoint(
                      feedback == 'None'
                          ? "User feedback indicated no skin discomfort"
                          : "User feedback indicated ${feedback.toLowerCase()} skin redness"),
                  _buildBulletPoint(
                      diff > 0
                          ? "System increased safe exposure threshold"
                          : diff < 0
                              ? "System reduced safe exposure threshold"
                              : "System maintained safe exposure threshold"),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: "Back to Home",
              onPressed: () {
                // Return to dashboard with new threshold
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  AppRoutes.dashboard, 
                  (route) => false,
                  arguments: threshold.toInt() // integer strictly for backward compat if needed, though we use service mostly
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4))),
        ],
      ),
    );
  }
}
