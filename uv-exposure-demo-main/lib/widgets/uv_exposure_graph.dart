import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/uv_data_service.dart';

class UVExposureGraph extends StatelessWidget {
  const UVExposureGraph({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UVPoint>>(
      stream: UVDataService().pointsStream,
      builder: (context, snapshot) {
        final points = snapshot.data ?? [];

        if (points.isEmpty) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: const Text(
              "No UV data recorded yet.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        final now = DateTime.now();
        List<FlSpot> spots = points.map((p) {
          final secondsAgo = now.difference(p.time).inSeconds;
          return FlSpot(-secondsAgo.toDouble(), p.uv);
        }).toList();

        // X-axis: -300 to 0 (last 5 minutes = 300 seconds)
        const double minX = -300.0;
        const double maxX = 0.0;
        const double minY = 0.0;
        const double maxY = 12.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "UV Index (Last 5 Mins)",
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 3,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 60, // Every 60 seconds
                          getTitlesWidget: (value, meta) {
                            if (value == minX || value == maxX) {
                              return const SizedBox.shrink(); // Prevent cut off
                            }
                            final int secondsAgo = (-value).toInt();
                            final int minsAgo = secondsAgo ~/ 60;
                            final int secs = secondsAgo % 60;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '-$minsAgo:${secs.toString().padLeft(2, "0")}',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: minX,
                    maxX: maxX,
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.orange,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.orange.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
