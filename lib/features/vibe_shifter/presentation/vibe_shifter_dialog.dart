import 'dart:math';
import 'dart:ui'; // [Added] For ImageFilter

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'protocol_dialog.dart';
import 'shredder_mission_screen.dart';
import 'asmr_mission_screen.dart';
import '../../mission/presentation/pages/reality_awareness_screen.dart';

class VibeShifterDialog extends StatefulWidget {
  const VibeShifterDialog({super.key});

  @override
  State<VibeShifterDialog> createState() => _VibeShifterDialogState();
}

class _VibeShifterDialogState extends State<VibeShifterDialog> {
  bool _isLoading = true;
  late _ProtocolType _selectedProtocol;

  @override
  void initState() {
    super.initState();
    _selectRandomProtocol();

    // Simulate analyzing delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _selectRandomProtocol() {
    final random = Random();
    final chance = random.nextDouble();

    if (chance < 0.20) {
      _selectedProtocol = _ProtocolType.neuralStabilization; // [20%] 마음 진정 사운드
    } else if (chance < 0.60) {
      _selectedProtocol = _ProtocolType.cognitiveCorrection; // [40%] 정신 번뜩 딴짓
    } else {
      _selectedProtocol = _ProtocolType.temptationDestroyer; // [40%] 유혹 즉시 파쇄
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _LoadingDialog();
    }

    switch (_selectedProtocol) {
      case _ProtocolType.neuralStabilization:
        return ProtocolDialog(
          themeColor: const Color(0xFFD050FF), // Neon Purple
          title: "[마음 진정 사운드]",
          subTitle: "CODE: NEURAL_STABLIZATION",
          description: "지금 버튼을 눌러\n3분간 마음을 가라앉히세요.",
          centerWidget: const _WaveformAnimation(),
          onAccept: () {
            context.pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AsmrMissionScreen(),
              ),
            );
          },
        );

      case _ProtocolType.cognitiveCorrection:
        return ProtocolDialog(
          themeColor: const Color(0xFF00FFD1), // Neon Cyan
          title: "[정신 번뜩 딴짓]",
          subTitle: "CODE: COGNITIVE_RESET",
          description: "지금 버튼을 눌러\n3분간 다른 것에 집중하세요.",
          centerWidget: const _GlitchIcon(
            Icons.bolt_rounded,
            Color(0xFF00FFD1),
          ),
          bottomWidget: const _CountdownProgressBar(color: Color(0xFF00FFD1)),
          onAccept: () {
            context.pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RealityAwarenessScreen(),
              ),
            );
          },
        );

      case _ProtocolType.temptationDestroyer:
        return ProtocolDialog(
          themeColor: const Color(0xFFFF3B30), // Neon Red
          title: "[유혹 즉시 파쇄]",
          subTitle: "CODE: TEMPTATION_DESTROY",
          description: "지금 버튼을 눌러\n지름신을 가루로 만드세요.",
          centerWidget: const _CrosshairAnimation(),
          isPulse: true,
          onAccept: () {
            context.pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ShredderMissionScreen(),
              ),
            );
          },
        );
    }
  }
}

enum _ProtocolType {
  neuralStabilization,
  cognitiveCorrection,
  temptationDestroyer,
}

// --- Loading Dialog ---
class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero, // [UX] Full screen dimming effect
      child: GestureDetector(
        onTap: () => Navigator.of(
          context,
        ).pop(), // [UX Fix] Force dismissal on background tap
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 
            0.7,
          ), // [UX] Dim background to obscure data
          child: Center(
            child: GestureDetector(
              onTap: () {}, // [UX] Prevent dismissal when tapping content
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with Scan Effect
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        size: 80,
                        color: Colors.white38,
                      ),
                      ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0xFFD4FF00), // Neon Lime
                                  Colors.transparent,
                                ],
                                stops: [0.0, 0.5, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcIn,
                            child: const Icon(
                              Icons.analytics_outlined,
                              size: 80,
                              color: Colors.white,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .moveY(begin: -40, end: 40, duration: 1.5.seconds),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Enhanced Text with Background Band
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child:
                          Container(
                                width: double
                                    .infinity, // [Layout] Full width to support centering
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20, // [Layout] Side padding
                                  vertical:
                                      2, // [Layout] Minimal height to fit text
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 
                                    0.5, // [Visual] Ghost layer opacity
                                  ),
                                  border: Border.symmetric(
                                    horizontal: BorderSide(
                                      color: const Color(
                                        0xFFD4FF00,
                                      ).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'PROTOCOL ANALYZING...',
                                  maxLines: 1, // [Layout] Force single line
                                  overflow: TextOverflow
                                      .visible, // [Layout] No ellipsis for this effect
                                  style: TextStyle(
                                    fontSize:
                                        16, // [Layout] Adjusted for fitting
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFD4FF00),
                                    fontFamily: 'Courier',
                                    letterSpacing: 3.0,
                                    shadows: [
                                      BoxShadow(
                                        color: Color(0xFFD4FF00),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .shimmer(
                                duration: 2.seconds,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Specific Animations ---

class _WaveformAnimation extends StatelessWidget {
  const _WaveformAnimation();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Container(
              width: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD050FF),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD050FF).withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleY(
              begin: 0.2,
              end: 1.0,
              duration: Duration(milliseconds: 600 + (index * 200)),
              curve: Curves.easeInOutQuad,
            );
      }),
    );
  }
}

class _GlitchIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _GlitchIcon(this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Icon(icon, size: 80, color: color.withValues(alpha: 0.5))
            .animate(onPlay: (c) => c.repeat())
            .move(
              begin: const Offset(-2, 0),
              end: const Offset(2, 0),
              duration: 100.ms,
            )
            .shake(hz: 8),
        Icon(icon, size: 80, color: color)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 50.ms)
            .then()
            .fadeOut(duration: 150.ms),
      ],
    );
  }
}

class _CountdownProgressBar extends StatelessWidget {
  final Color color;

  const _CountdownProgressBar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: 1.0,
        child:
            Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: color, blurRadius: 5)],
              ),
            ).animate().custom(
              duration: 3.seconds, // Just a visual demo of shrinking
              builder: (_, value, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1.0 - value, // Shrink
                  child: child,
                );
              },
            ),
      ),
    );
  }
}

class _CrosshairAnimation extends StatelessWidget {
  const _CrosshairAnimation();

  @override
  Widget build(BuildContext context) {
    return Stack(
          alignment: Alignment.center,
          children: [
            // Rotating Outer Ring
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF3B30), width: 2),
              ),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3.seconds),

            // Inner Cross
            const Icon(Icons.add, size: 40, color: Color(0xFFFF3B30)),

            // Targeting Dots
            ...List.generate(4, (index) {
              return Transform.rotate(
                angle: index * (pi / 2),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 4,
                    height: 10,
                    color: const Color(0xFFFF3B30),
                    margin: const EdgeInsets.only(top: 25),
                  ),
                ),
              );
            }),
          ],
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.1, 1.1),
          duration: 500.ms,
        );
  }
}
