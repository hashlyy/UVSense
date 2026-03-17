import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';

/// Online adaptive threshold learning service.
///
/// Maintains [dailySafeExposureLimit] — the personalised UV exposure budget
/// (MED threshold) for the user. Persists using Hive storage.
///
/// Update rules (MED-based):
///   "No discomfort" → MED = MED * 1.05
///   "Normal"        → no change
///   "Sunburn"       → MED = MED * 0.85
///
/// Constraints: MED threshold is clamped to [150, 500].
class AdaptiveThresholdService {
  // Singleton
  static final AdaptiveThresholdService _instance =
      AdaptiveThresholdService._internal();

  factory AdaptiveThresholdService() => _instance;

  AdaptiveThresholdService._internal();

  // ─── State ────────────────────────────────────────────────────────────────

  /// Current personalised daily safe UV exposure limit (MED threshold).
  double dailySafeExposureLimit = 300.0; // Default Skin Type III

  // Clamp bounds
  static const double _minThreshold = 150.0;
  static const double _maxThreshold = 500.0;

  // ─── Initialisation ────────────────────────────────────────────────────────

  /// Load a previously persisted threshold, or set default.
  Future<void> initialize(int skinTypeScore) async {
    final box = Hive.box(StorageService.userBoxName);
    
    if (box.containsKey('medThreshold')) {
      dailySafeExposureLimit = box.get('medThreshold');
    } else {
      // First-run seed based on Fitzpatrick skin-type score
      if (skinTypeScore <= 10) {
        dailySafeExposureLimit = 150.0;
      } else if (skinTypeScore <= 20) {
        dailySafeExposureLimit = 300.0;
      } else {
        dailySafeExposureLimit = 500.0;
      }
      _persist();
    }
  }

  // ─── Core ML update ────────────────────────────────────────────────────────

  /// Apply one incremental update step and return the **new** threshold.
  double updateThreshold(double cumulativeExposure, String feedback) {
    switch (feedback) {
      case 'No discomfort':
        dailySafeExposureLimit *= 1.05;
        break;
      case 'Normal':
        // no change
        break;
      case 'Sunburn':
        dailySafeExposureLimit *= 0.85;
        break;
      default:
        // no change
        break;
    }

    dailySafeExposureLimit = dailySafeExposureLimit.clamp(_minThreshold, _maxThreshold);

    _persist();

    return dailySafeExposureLimit;
  }

  // ─── Persistence ───────────────────────────────────────────────────────────

  void _persist() {
    StorageService().saveUserData(medThreshold: dailySafeExposureLimit);
  }

  Future<void> reset() async {
    dailySafeExposureLimit = 300.0;
    _persist();
  }
}
