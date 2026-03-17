/// Explainable AI (XAI) service — human-readable decision explanations.
///
/// Generates plain-English summaries that explain:
///   • Whether today's exposure crossed the personalised threshold.
///   • What UV intensity level was responsible.
///   • Actionable advice for the user.
///
/// All values originate from real BLE/sensor data — no simulated inputs.
class XAIService {
  // Singleton
  static final XAIService _instance = XAIService._internal();

  factory XAIService() => _instance;

  XAIService._internal();

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Generate a human-readable explanation for the current UV session.
  ///
  /// Parameters match the live data pipeline (spec §3):
  ///   [cumulativeExposure] — total UV exposure accumulated today (BLE-derived).
  ///   [threshold]          — current personalised daily safe limit (ML output).
  ///   [currentUV]          — latest instantaneous UV index from the sensor.
  ///
  /// Returns a formatted multi-line explanation string ready to display in the UI.
  String generateExplanation({
    required double cumulativeExposure,
    required double threshold,
    required double currentUV,
  }) {
    final buf = StringBuffer();

    // ── 1. Threshold status ─────────────────────────────────────────────────
    final bool exceeded = cumulativeExposure >= threshold;

    if (exceeded) {
      buf.writeln(
          'Today\'s UV exposure exceeded your personalised safe limit.');
      buf.writeln();
      buf.writeln(
          'Your cumulative exposure reached '
          '${cumulativeExposure.toStringAsFixed(1)} '
          'while your current safe threshold is '
          '${threshold.toStringAsFixed(1)}.');
    } else {
      buf.writeln(
          'Your UV exposure is within your personalised safe limit today.');
      buf.writeln();
      buf.writeln(
          'Cumulative exposure: ${cumulativeExposure.toStringAsFixed(1)}  '
          '/ safe limit: ${threshold.toStringAsFixed(1)}.');
    }

    buf.writeln();

    // ── 2. Intensity attribution (feature-level) ────────────────────────────
    // UV index scale (WHO standard):
    //   0-2   Low      3-5   Moderate    6-7  High
    //   8-10  Very High   11+  Extreme
    if (currentUV >= 8.0) {
      buf.writeln(
          'Most exposure occurred during extreme UV conditions (UV index: '
          '${currentUV.toStringAsFixed(1)}). '
          'Consider avoiding direct sunlight between 10 am and 4 pm.');
    } else if (currentUV >= 6.0) {
      buf.writeln(
          'Most exposure occurred during high UV conditions (UV index: '
          '${currentUV.toStringAsFixed(1)}). '
          'Consider reducing sun exposure during midday hours.');
    } else if (currentUV >= 3.0) {
      buf.writeln(
          'UV intensity was moderate today (UV index: '
          '${currentUV.toStringAsFixed(1)}). '
          'Exposure accumulated steadily over time.');
    } else {
      buf.writeln(
          'UV levels were low today (UV index: '
          '${currentUV.toStringAsFixed(1)}). '
          'Continued exposure over long durations contributed to the total.');
    }

    // ── 3. Closing advice ───────────────────────────────────────────────────
    if (exceeded) {
      buf.writeln();
      buf.writeln(
          'Tip: Apply SPF 30+ sunscreen, wear UV-protective clothing, '
          'and stay in the shade when outdoors.');
    }

    return buf.toString().trimRight();
  }

  // ─── Convenience helpers ───────────────────────────────────────────────────

  /// One-line summary shown on the dashboard warning banner when threshold
  /// is reached.  Keeps the full [generateExplanation] for the detail screen.
  String shortWarning({
    required double cumulativeExposure,
    required double threshold,
    required double currentUV,
  }) {
    return 'Your UV exposure today exceeded your safe limit.\n'
        'Current exposure: ${cumulativeExposure.toStringAsFixed(1)}   '
        'Safe threshold: ${threshold.toStringAsFixed(1)}\n'
        '${_intensityLabel(currentUV)} UV conditions detected recently.';
  }

  String _intensityLabel(double uv) {
    if (uv >= 11) return 'Extreme';
    if (uv >= 8) return 'Very High';
    if (uv >= 6) return 'High';
    if (uv >= 3) return 'Moderate';
    return 'Low';
  }
}
