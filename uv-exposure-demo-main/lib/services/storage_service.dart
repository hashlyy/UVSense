import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String userBoxName = 'userBox';
  static const String exposureBoxName = 'exposureBox';
  static const String feedbackBoxName = 'feedbackBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(userBoxName);
    await Hive.openBox(exposureBoxName);
    await Hive.openBox(feedbackBoxName);
  }

  // ─── User Data ─────────────────────────────────────────────────────────────

  void saveUserData({
    String? skinType,
    double? medThreshold,
    double? adaptiveThreshold,
  }) {
    final box = Hive.box(userBoxName);
    if (skinType != null) box.put('skinType', skinType);
    if (medThreshold != null) box.put('medThreshold', medThreshold);
    if (adaptiveThreshold != null) box.put('adaptiveThreshold', adaptiveThreshold);
  }

  void updateAdaptiveThreshold(double newThreshold) {
    Hive.box(userBoxName).put('adaptiveThreshold', newThreshold);
  }

  double? getAdaptiveThreshold() {
    return Hive.box(userBoxName).get('adaptiveThreshold');
  }

  // ─── Exposure Data ─────────────────────────────────────────────────────────

  void addExposureData({required double uvIndex, required double energyDose}) {
    final box = Hive.box(exposureBoxName);
    final data = {
      'timestamp': DateTime.now().toIso8601String(),
      'uvIndex': uvIndex,
      'energyDose': energyDose,
    };
    box.add(data);
  }

  List<Map<String, dynamic>> getAllExposureData() {
    final box = Hive.box(exposureBoxName);
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  List<Map<String, dynamic>> getTodayExposure() {
    final now = DateTime.now();
    final allEvents = getAllExposureData();
    return allEvents.where((data) {
      final timestamp = data['timestamp'] as String?;
      if (timestamp == null) return false;
      final date = DateTime.tryParse(timestamp);
      if (date == null) return false;
      return date.year == now.year &&
             date.month == now.month &&
             date.day == now.day;
    }).toList();
  }

  // ─── Feedback Data ─────────────────────────────────────────────────────────

  void addFeedbackData({required String feedback}) {
    final box = Hive.box(feedbackBoxName);
    final data = {
      'date': DateTime.now().toIso8601String(),
      'feedback': feedback,
    };
    box.add(data);
  }
}
