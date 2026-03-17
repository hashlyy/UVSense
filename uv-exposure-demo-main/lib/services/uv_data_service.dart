import 'dart:async';
import 'storage_service.dart';

/// UV data service — Medically accurate MED-based UV energy dose model.
///
/// Receives real UV index values pushed by the BLE service (originating from
/// the GUVA-S12SD sensor on the ESP32) and accumulates a daily energy dose
/// in J/m² based on the Minimal Erythema Dose (MED) framework.
///
/// Data flow:
///   BLEService.onData callback → [updateFromBLE] → streams → UI
///
/// Conversion standard (dermatology):
///   1 UV Index = 25 mW/m²   →   irradiance (mW/m²) = uvIndex × 25
///
/// Energy dose per BLE reading (ESP32 sends every 5 seconds):
///   energyDose (J/m²) = irradiance (mW/m²) × 5 (s) / 1000
///                      = uvIndex × 25 × 5 / 1000
///                      = uvIndex × 0.125
///
/// Default MED threshold for Fitzpatrick Skin Type III (J/m²).
///   300 J/m²  — the daily safe UV energy dose for Fitzpatrick Skin Type III.

class UVPoint {
  DateTime time;
  double uv;
  UVPoint(this.time, this.uv);
}

class UVDataService {
  // Singleton
  static final UVDataService _instance = UVDataService._internal();

  factory UVDataService() => _instance;

  UVDataService._internal();

  // ─── MED Model Constants ───────────────────────────────────────────────────

  /// Irradiance conversion factor: 1 UV Index = 25 mW/m²  (WHO / CIE standard)
  static const double _irradiancePerUVI = 25.0; // mW/m²

  /// Integration window — ESP32 sends a reading every 5 seconds.
  static const double _integrationSeconds = 5.0; // s

  /// Default MED threshold for Fitzpatrick Skin Type III (J/m²).
  /// Can be overridden externally to match questionnaire skin-type result.
  double medThreshold = 300.0;

  // ─── State ────────────────────────────────────────────────────────────────

  double _currentUV = 0.0;

  /// Accumulated UV energy dose for today, in J/m².
  double _cumulativeDose = 0.0;

  final List<UVPoint> _points = [];

  // ─── Streams ───────────────────────────────────────────────────────────────

  final _uvController = StreamController<double>.broadcast();
  final _cumulativeController = StreamController<double>.broadcast();
  final _pointsController = StreamController<List<UVPoint>>.broadcast();

  /// Stream of the latest instantaneous UV index readings.
  Stream<double> get uvStream => _uvController.stream;

  /// Stream of the accumulated energy dose (J/m²).
  Stream<double> get cumulativeStream => _cumulativeController.stream;

  /// Stream of the UV graph points in a sliding window.
  Stream<List<UVPoint>> get pointsStream => _pointsController.stream;

  /// Latest UV index reading (synchronous getter for initial UI state).
  double get currentUV => _currentUV;

  /// Total accumulated energy dose today in J/m² (synchronous getter).
  double get cumulativeDose => _cumulativeDose;

  // ─── BLE data entry point ─────────────────────────────────────────────────

  /// Called by [BLEService] whenever a new UV value arrives from the ESP32.
  ///
  /// [rawData] is the UTF-8 string sent over BLE (e.g. "7.3" or "5").
  /// Invalid / non-numeric strings are silently ignored.
  ///
  /// For every valid reading the method:
  ///   1. Updates [currentUV] and pushes to [uvStream].
  ///   2. Converts UV index → irradiance (mW/m²) using 1 UVI = 25 mW/m².
  ///   3. Computes the energy dose for the 5-second window (J/m²).
  ///   4. Adds the dose to [_cumulativeDose] and pushes to [cumulativeStream].
  void updateFromBLE(String rawData) {
    final double? parsed = double.tryParse(rawData.trim());
    if (parsed == null || parsed < 0) return; // guard against malformed data
    if (parsed > 12) return; // ignore invalid spikes

    _currentUV = parsed.clamp(0.0, 11.0);

    // Update real-time graph points
    final now = DateTime.now();
    _points.add(UVPoint(now, _currentUV));
    final cutoff = now.subtract(const Duration(minutes: 5));
    _points.removeWhere((p) => p.time.isBefore(cutoff));
    if (_points.length > 100) {
      _points.removeRange(0, _points.length - 100);
    }
    _pointsController.add(_points);

    // ── MED energy dose calculation ─────────────────────────────────────────
    // irradiance (mW/m²) = uvIndex × 25
    // energyDose (J/m²)  = irradiance × seconds / 1000
    //                     = uvIndex × 25 × 5 / 1000
    final double energyDose =
        (_currentUV * _irradiancePerUVI * _integrationSeconds) / 1000.0;

    _cumulativeDose += energyDose;

    // Save to local Hive storage background layer
    StorageService().addExposureData(
      uvIndex: _currentUV,
      energyDose: energyDose,
    );

    _uvController.add(_currentUV);
    _cumulativeController.add(_cumulativeDose);
  }

  // ─── Exposure Progress ─────────────────────────────────────────────────────

  /// Returns the fraction of the MED threshold reached, clamped to [0, 1].
  ///
  /// Use this for the progress bar:  exposurePercent = cumulativeDose / medThreshold
  double get exposurePercent =>
      (_cumulativeDose / medThreshold).clamp(0.0, 1.0);

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  /// Reset the daily cumulative dose (call at the start of each new day or
  /// after the user completes their daily check-in).
  void reset() {
    _cumulativeDose = 0.0;
    _cumulativeController.add(_cumulativeDose);
  }

  void dispose() {
    _uvController.close();
    _cumulativeController.close();
    _pointsController.close();
  }
}
