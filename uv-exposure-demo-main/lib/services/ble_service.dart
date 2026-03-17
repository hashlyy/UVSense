import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEService {

  BluetoothDevice? connectedDevice;

  final serviceUUID =
    Guid("12345678-1234-1234-1234-123456789abc");

  final uvCharacteristicUUID =
      Guid("0000abcd-0000-1000-8000-00805f9b34fb");

  final thresholdCharacteristicUUID =
      Guid("0000ef01-0000-1000-8000-00805f9b34fb");

  BluetoothCharacteristic? uvCharacteristic;
  BluetoothCharacteristic? thresholdCharacteristic;

  bool _isConnecting = false;

  /// Scan and connect to ESP32
  Future<void> startScan(Function(String) onData) async {
    if (_isConnecting) return;
    _isConnecting = true;

    print("Starting BLE scan...");

    // 1. Setup listener FIRST before blocking the thread with await!
    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        
        // Grab name from either advertisement data or platform name
        String deviceName = r.advertisementData.advName.isNotEmpty 
            ? r.advertisementData.advName 
            : r.device.platformName;
            
        // print("Found device: $deviceName");

        // Detect ESP32 by name instantly as the broadcasts come in
        // Support both exact caps or all caps if user changed it.
        if (deviceName.toUpperCase().contains("UV_MONITOR")) {
          
          print("UV Monitor detected instantly!");
  
          await FlutterBluePlus.stopScan();

          connectedDevice = r.device;

          try {
            await connectedDevice!.connect(timeout: const Duration(seconds: 5));
          } catch (_) {
            _isConnecting = false;
            return;
          }

          // Monitor for accidental drops and auto-reconnect
          connectedDevice!.connectionState.listen((state) {
            if (state == BluetoothConnectionState.disconnected) {
              print("Device disconnected. Auto-reconnecting...");
              _isConnecting = false;
              startScan(onData);
            }
          });

          await _discoverServices(onData);

          break;
        }
      }
    });

    // 2. Fire the scan now that the net is listening
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (_) {}
    
    // Once scan completes unconditionally (timeout reached without connecting), we can reset state.
    // However, if we didn't connect, we might want to scan again.
    if (connectedDevice == null || connectedDevice!.isDisconnected) {
      _isConnecting = false;
      // startScan(onData); // Automatically rescanning forever could drain battery, but useful for a demo.
    }
  }

  /// Discover BLE services
  Future<void> _discoverServices(Function(String) onData) async {
    if (connectedDevice == null) return;

    List<BluetoothService> services =
        await connectedDevice!.discoverServices();

    for (BluetoothService service in services) {
      if (service.uuid == serviceUUID) {
        for (BluetoothCharacteristic c in service.characteristics) {
          if (c.uuid == uvCharacteristicUUID) {
            uvCharacteristic = c;
            await c.setNotifyValue(true);
            c.lastValueStream.listen((value) {
              if (value.isNotEmpty) {
                String uv = String.fromCharCodes(value);
                onData(uv);
              }
            });
          }

          if (c.uuid == thresholdCharacteristicUUID) {
            thresholdCharacteristic = c;
          }
        }
      }
    }
  }

  /// Send adaptive threshold to ESP32
  Future<void> sendThreshold(double threshold) async {
    if (thresholdCharacteristic == null) return;

    List<int> data = threshold.toString().codeUnits;
    await thresholdCharacteristic!.write(data);
  }

  /// Optional cleanup
  Future<void> disconnect() async {
    await connectedDevice?.disconnect();
    _isConnecting = false;
  }
}