import 'dart:async';
import 'dart:math';
import '../models/uv_model.dart';

/// Service to simulate incoming UV data from a sensor.
class DummyDataService {
  // Singleton pattern
  static final DummyDataService _instance = DummyDataService._internal();
  factory DummyDataService() => _instance;
  DummyDataService._internal();

  final _controller = StreamController<UVModel>.broadcast();
  Stream<UVModel> get uvStream => _controller.stream;

  Timer? _timer;
  double _currentCumulative = 0.0;
  final Random _random = Random();

  /// Starts generating dummy UV data.
  void startSimulation() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Simulate UV index between 0 and 12
      // Using a random walk or sine wave could be smoother, but random is fine for now
      double currentUV = _random.nextDouble() * 10; 
      
      // Accumulate exposure (simplified integration)
      // In real life: dose = intensity * time
      _currentCumulative += currentUV * 0.1; // Add small amount for demo speed

      final data = UVModel(
        uvIndex: currentUV,
        cumulativeExposure: _currentCumulative,
        timestamp: DateTime.now(),
      );

      _controller.add(data);
    });
  }

  void stopSimulation() {
    _timer?.cancel();
  }
  
  void reset() {
    _currentCumulative = 0.0;
  }
}
