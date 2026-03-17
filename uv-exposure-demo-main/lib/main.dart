import 'package:flutter/material.dart';
import 'app/app.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  // Required when calling platform channels before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Hive local storage
  await StorageService.init();

  // Initialise the notification channel so it is ready before the first
  // UV reading arrives from BLE.
  await NotificationService().initialize();

  runApp(const UVApp());
}
