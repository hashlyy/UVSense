import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

/// UV Risk Level classification using WHO UV index scale.
///
/// Used both by [NotificationService] (to decide alert strength) and by
/// [DashboardScreen] (to drive dynamic card colours).
enum UVRiskLevel {
  safe,     // UV < 3
  moderate, // 3 ≤ UV < 6
  high,     // 6 ≤ UV < 8
  veryHigh, // 8 ≤ UV < 11
  extreme,  // UV ≥ 11
}

/// Maps a numeric UV index to a [UVRiskLevel].
UVRiskLevel classifyUV(double uvIndex) {
  if (uvIndex < 3)  return UVRiskLevel.safe;
  if (uvIndex < 6)  return UVRiskLevel.moderate;
  if (uvIndex < 8)  return UVRiskLevel.high;
  if (uvIndex < 11) return UVRiskLevel.veryHigh;
  return UVRiskLevel.extreme;
}

// ─── Notification channel constants ─────────────────────────────────────────

const String _channelId   = 'uv_alert_channel';
const String _channelName = 'UV Safety Alerts';
const String _channelDesc = 'Real-time UV exposure warnings from the wearable sensor';

// ─── Service ─────────────────────────────────────────────────────────────────

/// Handles local push notifications and vibration alerts for UV safety events.
///
/// Architecture note: this service contains **no UI code** and no BLE code.
/// It is called from [DashboardScreen] after a UV reading has been classified.
///
/// Initialisation:
///   Call [initialize] once in [main] before [runApp].
///
/// Usage:
///   [showUVWarning] — shows an OS-level push notification.
///   [triggerBuzzAlert] — vibrates the device for ~1 second.
class NotificationService {
  // Singleton
  static final NotificationService _instance =
      NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  // ─── Core plugin instance ─────────────────────────────────────────────────

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // Running notification ID counter (wraps at int max)
  int _notificationId = 0;

  // ─── Initialisation ────────────────────────────────────────────────────────

  /// Must be called once at app start (in [main], before [runApp]).
  Future<void> initialize() async {
    if (_initialised) return;

    // Android: use app icon as the notification icon.
    // The drawable name '@mipmap/ic_launcher' is always present in Flutter
    // Android projects.
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS / macOS: request permission at first notification.
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Ensure the Android notification channel exists before any notification
    // is posted.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: false, // vibration handles the alert signal
          ),
        );

    _initialised = true;
  }

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Show a UV safety push notification with [message] as the body text.
  ///
  /// The notification appears in the OS notification tray and, on Android,
  /// also as a heads-up banner.
  ///
  /// Example:
  /// ```dart
  /// notificationService.showUVWarning(
  ///   'High UV Exposure Warning. Seek shade or apply sunscreen.'
  /// );
  /// ```
  Future<void> showUVWarning(String message) async {
    if (!_initialised) await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      // Icon shown in the status bar
      icon: '@mipmap/ic_launcher',
      // No sound — vibration is handled separately via [triggerBuzzAlert]
      playSound: false,
      enableVibration: false,
      // Heads-up style banner
      fullScreenIntent: false,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Cycle through notification IDs so each alert replaces the previous
    // one from the same session, preventing tray clutter.
    _notificationId = (_notificationId + 1) % 100;

    await _plugin.show(
      _notificationId,
      'UV Sense — Safety Alert 🌞',
      message,
      details,
    );
  }

  /// Vibrate the device for approximately 1 second as a tactile UV alert.
  ///
  /// Gracefully degrades on devices without vibration hardware by checking
  /// capability first.
  Future<void> triggerBuzzAlert() async {
    final bool hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) return;

    // Single 1000 ms burst (1 second)
    Vibration.vibrate(duration: 1000);
  }

  /// Convenience helper: show notification + vibrate in one call.
  /// Use this from [DashboardScreen] when a high-UV reading arrives.
  Future<void> alertHighUV(String message) async {
    await Future.wait([
      showUVWarning(message),
      triggerBuzzAlert(),
    ]);
  }
}
