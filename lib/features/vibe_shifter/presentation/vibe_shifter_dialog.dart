import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/glass_card.dart';
import '../../../core/ui/bouncy_button.dart';
import 'shredder_mission_screen.dart';

class VibeShifterDialog extends StatefulWidget {
  const VibeShifterDialog({super.key});

  @override
  State<VibeShifterDialog> createState() => _VibeShifterDialogState();
}

class _VibeShifterDialogState extends State<VibeShifterDialog> {
  bool _isLoading = true;
  late _VibeMission _selectedMission;

  @override
  void initState() {
    super.initState();
    _selectRandomMission();
    // Simulate analyzing delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _selectRandomMission() {
    final random = Random();
    final chance = random.nextDouble(); // 0.0 to 1.0

    if (chance < 0.5) {
      // 50%
      _selectedMission = _VibeMission(
        title: '[이미지 분쇄]',
        description: '눈앞의 유혹을 가루로 만들어버리세요.',
        color: Colors.redAccent,
        icon: Icons.recycling_rounded,
      );
    } else if (chance < 0.7) {
      // 20% (0.5 to 0.7)
      _selectedMission = _VibeMission(
        title: '[힐링 타임]',
        description: '지갑 닫고, 눈 감고, 귀를 열어봐요',
        color: Colors.purpleAccent,
        icon: Icons.headphones_rounded,
      );
    } else {
      // 30% (0.7 to 1.0)
      final actions = ['딱 3분만 딴짓을 해봅시다.'];
      _selectedMission = _VibeMission(
        title: '[현실 자각]',
        description: actions[0],
        color: Colors.cyanAccent,
        icon: Icons.bolt_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GlassCard(
        backgroundColor: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isLoading ? Colors.white24 : _selectedMission.color,
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading) _buildLoadingState() else _buildMissionReveal(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.analytics_outlined, size: 64, color: Colors.white70)
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1.seconds, color: Colors.redAccent),
        const SizedBox(height: 24),
        const Text(
              '최적의 솔루션을 찾는 중...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Courier', // Tech/Hacking vibe
                letterSpacing: 2,
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 500.ms)
            .then()
            .fadeOut(duration: 500.ms),
      ],
    );
  }

  Widget _buildMissionReveal() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_selectedMission.icon, size: 80, color: _selectedMission.color)
            .animate()
            .scale(duration: 400.ms, curve: Curves.elasticOut)
            .then()
            .shake(duration: 400.ms),
        const SizedBox(height: 24),
        Text(
          _selectedMission.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              BoxShadow(
                color: _selectedMission.color.withOpacity(0.8),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).moveY(begin: 10, end: 0),
        const SizedBox(height: 16),
        Text(
          _selectedMission.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.4,
          ),
        ).animate().fadeIn(delay: 200.ms).moveY(begin: 10, end: 0),
        const SizedBox(height: 40),
        BouncyButton(
          onTap: () {
            context.pop();
            // Phase 2: Navigate to separate screen for Shredder Mission
            if (_selectedMission.title == '[이미지 분쇄]') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ShredderMissionScreen(),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: _selectedMission.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _selectedMission.color.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: _selectedMission.color.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              "돈 굳히러 가기 Let's Go",
              style: TextStyle(
                color: _selectedMission.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms).scale(),
      ],
    );
  }
}

class _VibeMission {
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  _VibeMission({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });
}
