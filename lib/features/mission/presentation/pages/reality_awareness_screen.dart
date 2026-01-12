import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/ui/glass_card.dart';
import '../../../../core/ui/bouncy_button.dart';
import '../../../../core/ui/background_gradient.dart';

class RealityAwarenessScreen extends StatefulWidget {
  const RealityAwarenessScreen({super.key});

  @override
  State<RealityAwarenessScreen> createState() => _RealityAwarenessScreenState();
}

class _RealityAwarenessScreenState extends State<RealityAwarenessScreen> {
  // 15 Master-Selected Missions
  final List<String> _missions = [
    '찬물 한 컵 원샷하기',
    '팔굽혀펴기 15회 하기',
    '플랭크 자세로 30~60초 유지하기',
    '온 힘을 다해 1분간 벽 밀기',
    '얼음 조각 손바닥에 올리고 30초 버티기',
    '한 발로 서서 1분간 균형 잡기',
    '주변(책상 등) 깨끗이 청소하기',
    '가장 아끼는 물건 정성껏 닦아주기',
    '손 씻고 로션 바르며 감각 집중하기',
    '고마운 사람에게 안부 문자 보내기',
    '5-4-3-2-1 오감 찾기: 주변에서 보이는 것 5개, 들리는 것 4개, 만져지는 것 3개, 냄새 2개, 맛 1개를 차례대로 마음속으로 찾아보며 현재 감각에 집중하세요.',
    '1년 뒤 이 물건을 가진 나를 시각화하기',
    '사고 싶은 물건 이름 30번 반복하기',
    '이 물건의 장점 1개와 단점 3개 적기',
    '좋아하는 음악 1곡 끝까지 감상하기',
  ];

  late String _currentMission;
  Timer? _timer;
  int _timeLeft = 180; // 3 minutes

  @override
  void initState() {
    super.initState();
    // Random Selection
    _currentMission = _missions[Random().nextInt(_missions.length)];
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _completeMission() {
    _timer?.cancel();
    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  String get _formattedTime {
    final minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              if (context.canPop()) context.pop();
            },
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                const Icon(
                  Icons.spa_rounded,
                  size: 80,
                  color: Colors.cyanAccent,
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                const SizedBox(height: 32),

                // Mission Text
                Text(
                  _currentMission,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),
                const Text(
                  '지금 바로 위 행동을 수행하며\n충동을 흘려보내세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const SizedBox(height: 48),

                // Timer
                Text(
                      _formattedTime,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.redAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withAlpha(50),
                    ),

                const SizedBox(height: 64),

                // Complete Button
                BouncyButton(
                  onTap: _completeMission,
                  child: GlassCard(
                    width: double.infinity,
                    height: 60,
                    backgroundColor: Colors.cyanAccent.withAlpha(51),
                    border: Border.all(color: Colors.cyanAccent.withAlpha(128)),
                    child: Center(
                      child: const Text(
                        '미션 완료',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
