import 'dart:io';
import 'dart:math' as math;
import 'dart:ui'; // For ImageFilter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vive_app/core/ui/background_gradient.dart';
import 'package:vive_app/core/ui/bouncy_button.dart';
import 'package:vive_app/core/ui/glass_card.dart';
import 'package:vive_app/features/mission/providers/mission_provider.dart';

// Reuse DamageEntry
class DamageEntry {
  final Key key;
  final Offset position;
  final String text;
  final Color color;
  final double fontSize;

  DamageEntry({
    required this.key,
    required this.position,
    required this.text,
    this.color = Colors.white,
    this.fontSize = 24,
  });
}

class MissionScreen extends ConsumerStatefulWidget {
  const MissionScreen({super.key});

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

enum _TargetType { none, image, text }

class _MissionScreenState extends ConsumerState<MissionScreen>
    with TickerProviderStateMixin {
  _TargetType _targetType = _TargetType.none;
  XFile? _targetImage;
  String? _targetText;

  late AnimationController _shakeController;
  final TextEditingController _textController = TextEditingController();

  // Visual Effects State
  final List<DamageEntry> _damageNumbers = [];
  final List<Path> _crackPaths = [];
  final math.Random _random = math.Random();
  bool _isDestroyed = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // --- Selection Logic (from ShredderMissionScreen) ---

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    XFile? image;

    try {
      image = await picker.pickImage(
        source: source, // Use the passed source
        maxWidth: 300,
        imageQuality: 30,
        requestFullMetadata: false,
      );
    } catch (e) {
      debugPrint('Gallery/Image Picker failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지를 불러올 수 없습니다.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!mounted) return;

    if (image != null) {
      setState(() {
        _targetImage = image;
        _targetType = _TargetType.image;
      });
    }
  }

  void _submitText() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _targetText = _textController.text;
        _targetType = _TargetType.text;
      });
    }
  }

  // --- Visual Logic (Cracks & Damage) ---

  void _generateCrack() {
    if (_crackPaths.length >= 15) {
      _crackPaths.removeAt(0); // Limit cracks
    }

    final path = Path();
    final bool isHorizontal = _random.nextBool();
    const double w = 320;
    const double h = 480;

    if (isHorizontal) {
      double startY = _random.nextDouble() * h;
      double endY = _random.nextDouble() * h;
      path.moveTo(0, startY);
      path.lineTo(w * 0.3, startY + (_random.nextDouble() - 0.5) * 50);
      path.lineTo(w * 0.6, endY + (_random.nextDouble() - 0.5) * 50);
      path.lineTo(w, endY);
    } else {
      double startX = _random.nextDouble() * w;
      double endX = _random.nextDouble() * w;
      path.moveTo(startX, 0);
      path.lineTo(startX + (_random.nextDouble() - 0.5) * 50, h * 0.3);
      path.lineTo(endX + (_random.nextDouble() - 0.5) * 50, h * 0.6);
      path.lineTo(endX, h);
    }

    _crackPaths.add(path);
  }

  void _addDamageEffect(Offset? position, bool isCritical) {
    _shakeController.forward(from: 0).then((_) {
      if (mounted) _shakeController.reset();
    });

    setState(() {
      _generateCrack();

      if (_damageNumbers.length >= 5) {
        _damageNumbers.removeAt(0);
      }

      final newEntry = DamageEntry(
        key: UniqueKey(),
        position: position ?? const Offset(160, 240), // Default center if null
        text: isCritical ? "CRITICAL!" : "Hit!",
        color: isCritical ? Colors.yellowAccent : Colors.white,
        fontSize: isCritical ? 40 : 28,
      );
      _damageNumbers.add(newEntry);

      // Cleanup textual effect
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _damageNumbers.removeWhere((e) => e.key == newEntry.key);
          });
        }
      });
    });
  }

  // --- Mission Logic Integration ---

  void _onTap(TapDownDetails details) {
    final missionState = ref.read(missionProvider);
    if (missionState.type == MissionType.tap && !missionState.isCompleted) {
      ref.read(missionProvider.notifier).tap();
      HapticFeedback.mediumImpact();
      _addDamageEffect(details.localPosition, _random.nextDouble() < 0.2);
    }
  }

  // Listen to provider state changes for Shake & Completion
  void _listenToMissionState(MissionState? previous, MissionState next) {
    if (previous == null) return;

    // Detect progress change (for Shake mode mainly, or general updates)
    if (next.progress > previous.progress) {
      // Ideally we want position for shake too, but we use center
      if (next.type == MissionType.shake) {
        HapticFeedback.lightImpact();
        // Add effect at random position or center
        _addDamageEffect(
          Offset(
            100 + _random.nextDouble() * 120,
            150 + _random.nextDouble() * 180,
          ),
          false,
        );
      }
    }

    // Completion
    if (next.isCompleted && !previous.isCompleted) {
      _completeMission();
    }
  }

  Future<void> _completeMission() async {
    setState(() {
      _isDestroyed = true;
      _damageNumbers.clear();
    });

    HapticFeedback.heavyImpact();

    // Wait for animation then exit
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(missionProvider, _listenToMissionState);
    final missionState = ref.watch(missionProvider);

    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Mission',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: _targetType == _TargetType.none
              ? _buildInputSelection()
              : Stack(
                  children: [
                    _buildMissionZone(missionState),
                    _buildDebugOverlay(missionState),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInputSelection() {
    // Reusing the exact UI from before for consistency
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '무엇을 파괴하시겠습니까?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '사진을 찍거나 텍스트를 입력하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionButton(
                icon: Icons.photo_library,
                label: '갤러리에서 선택',
                color: Colors.redAccent,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(width: 24),
              _buildOptionButton(
                icon: Icons.edit_note_rounded,
                label: '텍스트 입력',
                color: Colors.orangeAccent,
                onTap: () => _showTextInputDialog(context),
              ),
            ],
          ),
        ],
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onTap: onTap,
      child: GlassCard(
        width: 140,
        height: 140,
        backgroundColor: color.withAlpha(51), // 0.2 * 255
        border: Border.all(color: color.withAlpha(128)), // 0.5 * 255
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionZone(MissionState state) {
    return Column(
      children: [
        // Progress Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Destruction Progress",
                style: TextStyle(
                  color: Colors.white.withAlpha(179), // 0.7 * 255
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.white10,
                  color: Colors.redAccent,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: Center(
            child: GestureDetector(
              onTapDown: _onTap, // For Tap Mode
              child: SizedBox(
                width: 320,
                height: 480,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // --- Animated Container ---
                    AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, child) {
                        final offset =
                            _shakeController.value *
                            8 *
                            (0.5 - _shakeController.value).sign;
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.redAccent.withAlpha(
                              (128 + (state.progress * 127)).toInt(),
                            ), // 0.5 to 1.0 -> 128 to 255
                            width: 2 + (state.progress * 2),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Content (Image or Text)
                            _targetType == _TargetType.image
                                ? ImageFileOrAsset(file: _targetImage!)
                                : Center(
                                    child: Text(
                                      _targetText ?? '',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),

                            // Blur & Red Tint based on progress
                            BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: state.progress * 3, // Gets blurrier
                                sigmaY: state.progress * 3,
                              ),
                              child: Container(
                                color: Colors.red.withAlpha(
                                  ((state.progress * 0.4).clamp(0.0, 0.8) * 255)
                                      .toInt(),
                                ),
                              ),
                            ),

                            // Cracks layer
                            CustomPaint(
                              painter: CrackPainter(_crackPaths),
                              size: Size.infinite,
                            ),

                            // --- SHREDDING LINE ---
                            // White line that moves down based on progress
                            if (!_isDestroyed)
                              Positioned(
                                left: 0,
                                right: 0,
                                top:
                                    (state.progress * 480) - 2, // 480 is height
                                child:
                                    Container(
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white.withAlpha(
                                                  204,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        )
                                        .animate(
                                          onPlay: (c) =>
                                              c.repeat(reverse: true),
                                        )
                                        .fade(
                                          begin: 0.8,
                                          end: 1.0,
                                          duration: 200.ms,
                                        ),
                              ),

                            // Overlay Instruction (Adaptive)
                            if (!_isDestroyed && state.progress < 1.0)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(153), // 0.6
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                            state.type == MissionType.shake
                                                ? Icons.vibration
                                                : Icons.touch_app,
                                            color: Colors.white,
                                            size: 32,
                                          )
                                          .animate(
                                            onPlay: (c) =>
                                                c.repeat(reverse: true),
                                          )
                                          .scale(
                                            begin: const Offset(1, 1),
                                            end: const Offset(1.2, 1.2),
                                          ),
                                      const SizedBox(height: 8),
                                      Text(
                                        state.type == MissionType.shake
                                            ? "폰을 미친듯이 흔드세요!"
                                            : "연타해서 파괴하세요",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // --- Effects Layer ---
                    // Damage Numbers
                    for (final entry in _damageNumbers)
                      Positioned(
                        left: entry.position.dx - 40,
                        top: entry.position.dy - 60,
                        child:
                            Text(
                                  entry.text,
                                  style: TextStyle(
                                    color: entry.color,
                                    fontSize: entry.fontSize,
                                    fontWeight: FontWeight.w900,
                                    shadows: const [
                                      BoxShadow(
                                        color: Colors.black,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                )
                                .animate(key: entry.key)
                                .moveY(begin: 0, end: -80)
                                .fadeOut(),
                      ),

                    // Destruction Success
                    if (_isDestroyed)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '💥',
                              style: TextStyle(fontSize: 80),
                            ).animate().scale(curve: Curves.elasticOut),
                            const Text(
                              'DESTROYED!',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.redAccent,
                                fontStyle: FontStyle.italic,
                              ),
                            ).animate().fadeIn().shimmer(),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugOverlay(MissionState state) {
    // Only show in debug mode or if explicitly requested (logging requirement implies this is needed)
    return Positioned(
      top: 100, // Below App Bar
      left: 16,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(4),
          color: Colors.black54,
          child: Text(
            "Mode: ${state.type.name.toUpperCase()}\nProgress: ${(state.progress * 100).toStringAsFixed(1)}%",
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 10,
              fontFamily: 'Courier',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text('텍스트 입력', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _textController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '예: 스트레스, 빚, 걱정',
            hintStyle: TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _submitText();
            },
            child: const Text('확인', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// Helpers
class ImageFileOrAsset extends StatelessWidget {
  final XFile file;
  const ImageFileOrAsset({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(file.path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(Icons.broken_image, color: Colors.white)),
    );
  }
}

class CrackPainter extends CustomPainter {
  final List<Path> cracks;
  CrackPainter(this.cracks);

  @override
  void paint(Canvas canvas, Size size) {
    if (cracks.isEmpty) return;
    final paint = Paint()
      ..color = Colors.white
          .withAlpha(217) // 0.85
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

    for (final path in cracks) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CrackPainter oldDelegate) =>
      oldDelegate.cracks.length != cracks.length;
}
