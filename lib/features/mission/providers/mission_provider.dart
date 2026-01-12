import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sensors_plus/sensors_plus.dart';

part 'mission_provider.g.dart';

enum MissionType { tap, shake }

class MissionState {
  final MissionType type;
  final double progress;
  final bool isCompleted;

  MissionState({
    required this.type,
    this.progress = 0.0,
    this.isCompleted = false,
  });

  MissionState copyWith({
    MissionType? type,
    double? progress,
    bool? isCompleted,
  }) {
    return MissionState(
      type: type ?? this.type,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

@riverpod
class Mission extends _$Mission {
  StreamSubscription? _accelerometerSubscription;
  Timer? _debugTimer;

  @override
  MissionState build() {
    // FORCE SHAKE MODE FOR TESTING - Always active sensor
    const type = MissionType.shake;

    // Unconditionally initialize listener
    _initShakeListener();
    _startDebugLogging();

    // Cleanup subscription when the provider is disposed
    ref.onDispose(() {
      _accelerometerSubscription?.cancel();
      _debugTimer?.cancel();
    });

    return MissionState(type: type);
  }

  void _startDebugLogging() {
    _debugTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      debugPrint('[MISSION] Type: ${state.type}, Progress: ${state.progress}');
    });
  }

  void _initShakeListener() {
    debugPrint('Initializing Shake Listener...'); // DEBUG LOG

    // Switch to UserAccelerometer for better shake detection without gravity
    _accelerometerSubscription = userAccelerometerEventStream().listen((event) {
      // REQUIRED: Sensor Active Log
      debugPrint('Sensor Active: ${event.x}, ${event.y}, ${event.z}');

      if (state.isCompleted) return;

      // Simple shake detection logic
      // Calculate magnitude of acceleration
      double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // print('Shake detected: $acceleration'); // DEBUG LOG

      // Lower threshold for simulator/testing
      if (acceleration > 5.0) {
        incrementProgress(0.05); // Increase progress by 5% on shake
      }
    });
  }

  void tap() {
    if (state.type == MissionType.tap && !state.isCompleted) {
      incrementProgress(0.1); // Increase progress by 10% on tap
    }
  }

  void incrementProgress(double amount) {
    if (state.isCompleted) return;

    final newProgress = (state.progress + amount).clamp(0.0, 1.0);
    final isCompleted = newProgress >= 1.0;

    // Force state update to trigger UI rebuild
    final updatedState = state.copyWith(
      progress: newProgress,
      isCompleted: isCompleted,
    );
    state = updatedState;

    debugPrint(
      'Current Progress: ${updatedState.progress}',
    ); // DEBUG LOG to track UI updates
  }
}
