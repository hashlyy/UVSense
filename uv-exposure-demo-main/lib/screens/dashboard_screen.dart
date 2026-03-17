import 'package:flutter/material.dart';
import '../services/uv_data_service.dart';
import '../services/ml_service.dart';
import '../services/xai_service.dart';
import '../services/notification_service.dart';
import '../app/routes.dart';
import '../services/ble_service.dart';
import '../widgets/uv_exposure_graph.dart';

class DashboardScreen extends StatefulWidget {
  final int initialThreshold;

  const DashboardScreen({super.key, required this.initialThreshold});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  final UVDataService _uvService = UVDataService();
  final AdaptiveThresholdService _mlService = AdaptiveThresholdService();
  final BLEService _bleService = BLEService();
  final XAIService _xaiService = XAIService();
  final NotificationService _notifService = NotificationService();

  // ── BLE connection status ──────────────────────────────────────────────────
  // Non-"0.0" means at least one reading has been received.
  String _bleUV = "0.0";

  // ── ML threshold ───────────────────────────────────────────────────────────
  late double _currentThreshold;

  // ── Instant UV alert state (independent from cumulative threshold) ─────────
  UVRiskLevel _currentRiskLevel = UVRiskLevel.safe;

  // Throttle: track when the last alert notification was fired.
  // Alerts can fire at most once every 30 seconds when UV stays high.
  DateTime? _lastAlertTime;
  static const Duration _alertCooldown = Duration(seconds: 30);

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _currentThreshold = _mlService.dailySafeExposureLimit;

    // Start BLE scanning — every reading is piped through UVDataService and
    // also checked for instant UV safety alerts.
    _bleService.startScan((data) {
      // 1. Feed real sensor value into the accumulation service (streams → UI)
      _uvService.updateFromBLE(data);

      // 2. Parse and classify the UV level for instant alert logic
      final double? uv = double.tryParse(data.trim());
      if (uv != null && uv >= 0) {
        _handleUVAlert(uv);
      }

      // 3. Keep the raw string for connection-status display only
      setState(() {
        _bleUV = data;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ─── UV Alert Logic ─────────────────────────────────────────────────────────

  /// Called on every BLE reading.  Classifies the UV index, updates the
  /// visual risk level, and fires notifications + vibration if the reading
  /// is ≥ 8 and the 30-second cooldown has elapsed.
  ///
  /// This system runs in **parallel** with the cumulative threshold warning —
  /// one is an instant physical-safety check, the other is a personalised
  /// daily-budget check.
  void _handleUVAlert(double uvIndex) {
    final UVRiskLevel level = classifyUV(uvIndex);

    // Update the visual risk indicator regardless of cooldown
    if (level != _currentRiskLevel) {
      setState(() {
        _currentRiskLevel = level;
      });
    }

    // Only notify/vibrate for High or above, and only if BLE is the source
    // (guard: _bleUV != "0.0" confirms the ESP32 is connected)
    if (level == UVRiskLevel.safe || level == UVRiskLevel.moderate) return;

    // Cooldown check — prevent alert spam
    final now = DateTime.now();
    if (_lastAlertTime != null &&
        now.difference(_lastAlertTime!) < _alertCooldown) {
      return; // within cooldown window, skip
    }

    _lastAlertTime = now;

    // Pick the appropriate message based on risk level
    final String message = _alertMessageFor(level, uvIndex);

    // Fire notification + vibration (fire-and-forget: async but not awaited
    // to avoid blocking the BLE callback)
    _notifService.alertHighUV(message);
  }

  /// Returns the notification body text for a given [level].
  String _alertMessageFor(UVRiskLevel level, double uvIndex) {
    final String uvStr = uvIndex.toStringAsFixed(1);
    switch (level) {
      case UVRiskLevel.extreme:
        return 'Extreme UV radiation detected (UV $uvStr). '
            'Seek shade immediately and cover exposed skin.';
      case UVRiskLevel.veryHigh:
        return 'Very High UV detected (UV $uvStr). '
            'Limit outdoor exposure. Apply SPF 30+ sunscreen.';
      case UVRiskLevel.high:
        return 'High UV Exposure Warning (UV $uvStr). '
            'Seek shade or apply sunscreen.';
      default:
        return 'Elevated UV levels detected (UV $uvStr). Stay protected.';
    }
  }

  // ─── Dynamic UI helpers ────────────────────────────────────────────────────

  /// Card accent colour for the "Current UV" info card — reflects live risk.
  ///
  /// UV <  6  → orange  (safe/moderate)
  /// UV ≥  6  → deepOrange  (high)
  /// UV ≥  8  → red  (very high / extreme)
  Color _uvCardColor(double uvIndex) {
    if (uvIndex >= 8) return Colors.red;
    if (uvIndex >= 6) return Colors.deepOrange;
    return Colors.orange;
  }

  /// Background colour for the inline UV risk banner.
  Color _riskBannerColor(UVRiskLevel level) {
    switch (level) {
      case UVRiskLevel.extreme:
        return Colors.red.shade900;
      case UVRiskLevel.veryHigh:
        return Colors.red.shade600;
      case UVRiskLevel.high:
        return Colors.deepOrange.shade400;
      default:
        return Colors.orange.shade300;
    }
  }

  /// Human-readable label for the risk banner.
  String _riskLabel(UVRiskLevel level) {
    switch (level) {
      case UVRiskLevel.safe:     return 'Safe';
      case UVRiskLevel.moderate: return 'Moderate Risk';
      case UVRiskLevel.high:     return 'High Risk';
      case UVRiskLevel.veryHigh: return 'Very High Risk';
      case UVRiskLevel.extreme:  return 'Extreme Risk';
    }
  }

  /// Whether to show the UV risk banner at all.
  bool get _showUVBanner =>
      _bleUV != '0.0' &&
      (_currentRiskLevel == UVRiskLevel.high ||
          _currentRiskLevel == UVRiskLevel.veryHigh ||
          _currentRiskLevel == UVRiskLevel.extreme);

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/logo/uv_sense_logo.png',
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.wb_sunny_rounded, color: Colors.orange),
            ),
            const SizedBox(width: 10),
            const Text(
              "UV Sense",
              style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      body: StreamBuilder<double>(
        stream: _uvService.uvStream,
        builder: (context, uvSnapshot) {

          return StreamBuilder<double>(
            stream: _uvService.cumulativeStream,
            builder: (context, cumulativeSnapshot) {

              // ── Live data values ─────────────────────────────────────────
              final double currentUV =
                  uvSnapshot.data ?? _uvService.currentUV;

              final double currentCumulative =
                  cumulativeSnapshot.data ?? 0.0;

              // ── Cumulative threshold warning (MED-based daily dose limit) ──
              // Uses the ML-personalised threshold as the primary
              // safety boundary to drive the feedback → adapt loop.
              final double medLimit = _currentThreshold;
              final bool cumulativeWarning =
                  currentCumulative >= medLimit;

              final double progress =
                  (currentCumulative / medLimit).clamp(0.0, 1.0);

              // ── Dynamic UV card colour ───────────────────────────────────
              final Color uvCardColor = _bleUV == '0.0'
                  ? Colors.orange
                  : _uvCardColor(currentUV);

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [

                    // ── 1. Instant UV risk banner (high/very-high/extreme) ──
                    if (_showUVBanner) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _riskBannerColor(_currentRiskLevel),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.wb_sunny_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_riskLabel(_currentRiskLevel)}'
                                ' — ${_alertMessageFor(_currentRiskLevel, currentUV)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── 2. Cumulative threshold warning (ML personalised) ───
                    if (cumulativeWarning) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _xaiService.shortWarning(
                                  cumulativeExposure: currentCumulative,
                                  threshold: medLimit,
                                  currentUV: currentUV,
                                ),
                                style: const TextStyle(
                                    color: Colors.red, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── 3. Exposure progress bar ───────────────────────────
                    Column(
                      children: [

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Exposure",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                            Text(
                              "${(progress * 100).toInt()}%",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation(
                            cumulativeWarning ? Colors.red : Colors.orange,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),

                      ],
                    ),

                    const SizedBox(height: 30),

                    // ── 4. Info cards ──────────────────────────────────────
                    Row(
                      children: [

                        // "Current UV" card — colour changes by risk level
                        Expanded(
                          child: _buildInfoCard(
                            title: "Current UV",
                            value: _bleUV == "0.0"
                                ? "--"
                                : currentUV.toStringAsFixed(1),
                            subtitle: _bleUV == '0.0'
                                ? "Waiting"
                                : _riskLabel(_currentRiskLevel),
                            color: uvCardColor,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: _buildInfoCard(
                            title: "Limit",
                            value: _currentThreshold.toStringAsFixed(0),
                            subtitle: "MED Threshold (J/m²)",
                            color: Colors.teal,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: _buildInfoCard(
                            title: "Used",
                            value: currentCumulative.toStringAsFixed(1),
                            subtitle: "J/m² Dose",
                            color: Colors.blueGrey,
                          ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── 5. UV Exposure Graph ───────────────────────────────
                    const UVExposureGraph(),

                    const Spacer(),

                    // ── 5. Status footer ───────────────────────────────────
                    Text(
                      "Monitoring Active... (Updates every 5s)",
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _bleUV != "0.0"
                          ? "Connected to UV Monitor"
                          : "Searching for UV Monitor...",
                      style: TextStyle(
                        color: _bleUV != "0.0"
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── 6. Feedback button ─────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        child: const Text("Give Feedback / End Day"),

                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.feedback,
                            arguments: {
                              'cumulative': currentCumulative,
                              'threshold': _currentThreshold,
                              'currentUV': currentUV,
                            },
                          );
                          if (mounted) {
                            setState(() {
                              _currentThreshold = _mlService.dailySafeExposureLimit;
                            });
                          }
                        },

                      ),
                    ),

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ─── Info card widget ──────────────────────────────────────────────────────

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],

        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),

      child: Column(
        children: [

          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
            textAlign: TextAlign.center,
          ),

        ],
      ),
    );
  }
}