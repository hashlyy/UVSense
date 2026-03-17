import 'package:flutter/material.dart';

class UVProgressIndicator extends StatelessWidget {
  final double current;
  final double total;
  final String label;

  const UVProgressIndicator({
    super.key,
    required this.current,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    double progress = (current / total).clamp(0.0, 1.0);
    Color progressColor = progress > 1 ? Colors.red : (progress > 0.8 ? Colors.orange : Colors.teal);

    return Column(
      children: [
        SizedBox(
          height: 150,
          width: 150,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 12,
                backgroundColor: Colors.grey[200],
                color: progressColor,
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Text(label, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
