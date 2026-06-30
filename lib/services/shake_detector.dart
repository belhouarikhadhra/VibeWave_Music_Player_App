import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';

class ShakeDetector {
  static const double _shakeThreshold = 15.0;
  static const int _minTimeBetweenShakes = 1000; // ms

  StreamSubscription? _subscription;
  int _lastShakeTime = 0;
  final VoidCallback onShake;

  ShakeDetector({required this.onShake});

  void start() {
    _subscription = accelerometerEventStream().listen((event) {
      final double force =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z) - 9.8;

      if (force > _shakeThreshold) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastShakeTime > _minTimeBetweenShakes) {
          _lastShakeTime = now;
          onShake();
        }
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
