import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shake/shake.dart'; // [NEW]

part 'mission_provider.g.dart';

enum MissionType { tap, shake, realityCheck }

class MissionState {
  final MissionType type;
  final double progress;
  final bool isCompleted;
  final String? currentRealityMission;
  final int timeLeft;
  final bool isTimerRunning;

  MissionState({
    required this.type,
    this.progress = 0.0,
    this.isCompleted = false,
    this.currentRealityMission,
    this.timeLeft = 180,
    this.isTimerRunning = false,
  });

  MissionState copyWith({
    MissionType? type,
    double? progress,
    bool? isCompleted,
    String? currentRealityMission,
    int? timeLeft,
    bool? isTimerRunning,
  }) {
    return MissionState(
      type: type ?? this.type,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      currentRealityMission:
          currentRealityMission ?? this.currentRealityMission,
      timeLeft: timeLeft ?? this.timeLeft,
      isTimerRunning: isTimerRunning ?? this.isTimerRunning,
    );
  }
}

@riverpod
class Mission extends _$Mission {
  StreamSubscription? _accelerometerSubscription;
  ShakeDetector? _shakeDetector; // [NEW] Shake Detector
  final _damageStreamController =
      StreamController<void>.broadcast(); // [NEW] Event Stream

  Timer? _debugTimer;
  Timer? _realityTimer;

  Stream<void> get damageStream => _damageStreamController.stream;

  static const List<String> realityMissions = [
    '찬물 마시기',
    '방 청소하기',
    '플랭크 1분 하기',
    '벽 밀기 1분',
    '얼음 1분간 쥐고 있기',
    '팔굽혀펴기 10회',
    '스쿼트 20회',
    '명상 3분',
    '창문 열고 환기하기',
    '스트레칭 하기',
    '눈 감고 1분 있기',
    '물 한 컵 천천히 마시기',
    '제자리 뛰기 30초',
    '거울 보고 웃기',
    '심호흡 10번 하기',
    '5-4-3-2-1 그라운딩',
  ];

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
      _shakeDetector?.stopListening(); // [NEW] Stop listening
      _debugTimer?.cancel();
      _realityTimer?.cancel();
      _damageStreamController.close(); // [NEW] Close stream
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

    // 1. [NEW] Shake Package (Works on Simulator Cmd+Shift+Z)
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (_) {
        debugPrint('Shake Detect (Package)!');
        _triggerDamage(0.1); // Big damage on explicit shake
      },
      minimumShakeCount: 1,
      shakeSlopTimeMS: 500,
      shakeCountResetTime: 3000,
      shakeThresholdGravity: 2.7,
    );

    // 2. Sensors Plus (Fine-grained control, works on Web/Real Device)
    // Switch to UserAccelerometer for better shake detection without gravity
    _accelerometerSubscription = userAccelerometerEventStream().listen((event) {
      // REQUIRED: Sensor Active Log
      // debugPrint('Sensor Active: ${event.x}, ${event.y}, ${event.z}');

      if (state.isCompleted) return;

      // Simple shake detection logic
      // Calculate magnitude of acceleration
      final double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Lower threshold for simulator/testing
      if (acceleration > 5.0) {
        // Debounce or reduce frequency could be added here
        _triggerDamage(0.02); // Small damage on continuous shake
      }
    });
  }

  void tap() {
    if (state.type == MissionType.tap && !state.isCompleted) {
      _triggerDamage(0.1);
    }
  }

  // Unified Trigger Method
  void _triggerDamage(double amount) {
    incrementProgress(amount);
    _damageStreamController.add(null); // Notify UI to show effects
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

  void startRealityMission() {
    // 1. Select Random Mission
    final random = Random();
    final mission = realityMissions[random.nextInt(realityMissions.length)];

    // 2. Reset State & Timer
    _realityTimer?.cancel();
    state = state.copyWith(
      type: MissionType.realityCheck,
      currentRealityMission: mission,
      timeLeft: 180,
      isTimerRunning: true,
      progress: 0.0,
      isCompleted: false,
    );

    // 3. Start Timer (3 minutes = 180 seconds)
    _realityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        stopTimer();
        // Option: Auto-complete or fail? For now just stop.
        // state = state.copyWith(isCompleted: true);
      }
    });
  }

  void stopTimer() {
    _realityTimer?.cancel();
    _realityTimer = null;
    state = state.copyWith(isTimerRunning: false);
  }
}
