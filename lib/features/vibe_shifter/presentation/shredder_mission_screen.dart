import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../mission/providers/mission_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/ui/glass_card.dart';
import '../../../core/ui/bouncy_button.dart';
import '../../../core/ui/background_gradient.dart';

// Robust Damage Entry Class
class DamageEntry {
  final Key key; // UniqueKey is critical
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

class ShredderMissionScreen extends ConsumerStatefulWidget {
  const ShredderMissionScreen({super.key});

  @override
  ConsumerState<ShredderMissionScreen> createState() =>
      _ShredderMissionScreenState();
}

enum _TargetType { none, image, text }

class _ShredderMissionScreenState extends ConsumerState<ShredderMissionScreen>
    with TickerProviderStateMixin {
  _TargetType _targetType = _TargetType.none;
  XFile? _targetImage;
  String? _targetText;

  int _hp = 10;
  final int _maxHp = 10;
  bool _isDestroyed = false;
  bool _isNavigating = false;

  late AnimationController _shakeController;
  // Note: Float controller removed for ultra-stability (reducing animation overhead)

  final TextEditingController _textController = TextEditingController();

  final List<DamageEntry> _damageNumbers = [];
  final List<Path> _crackPaths = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      // ULTRA-LIGHT MODE OPTIMIZATION
      // maxWidth: 300 (Very small, optimized for thumbail/preview usage)
      // imageQuality: 30 (High compression)
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        imageQuality: 30,
        requestFullMetadata: false,
      );

      if (!mounted) return;

      if (image != null) {
        setState(() {
          _targetImage = image;
          _targetType = _TargetType.image;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지를 불러오지 못했습니다.'),
          backgroundColor: Colors.redAccent,
        ),
      );
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

  void _generateCrack() {
    // Optimization: Limit to 10 cracks to prevent memory/GPU overload
    if (_crackPaths.length >= 10) {
      _crackPaths.removeAt(0);
    }

    final path = Path();
    final bool isHorizontal = _random.nextBool();

    // Fixed size container reference (320x480)
    const double w = 320;
    const double h = 480;

    if (isHorizontal) {
      // Left to Right crack
      double startY = _random.nextDouble() * h;
      double endY = _random.nextDouble() * h;
      path.moveTo(0, startY);

      // Simple 3-step zigzag
      path.lineTo(w * 0.3, startY + (_random.nextDouble() - 0.5) * 50);
      path.lineTo(w * 0.6, endY + (_random.nextDouble() - 0.5) * 50);
      path.lineTo(w, endY);
    } else {
      // Top to Bottom crack
      double startX = _random.nextDouble() * w;
      double endX = _random.nextDouble() * w;
      path.moveTo(startX, 0);

      // Simple 3-step zigzag
      path.lineTo(startX + (_random.nextDouble() - 0.5) * 50, h * 0.3);
      path.lineTo(endX + (_random.nextDouble() - 0.5) * 50, h * 0.6);
      path.lineTo(endX, h);
    }

    _crackPaths.add(path);
  }

  void _onTapTarget(TapDownDetails details) {
    if (_hp <= 0) return;

    HapticFeedback.mediumImpact();

    _shakeController.forward(from: 0).then((_) {
      if (mounted) _shakeController.reset();
    });

    if (mounted) {
      setState(() {
        _hp--;

        // 1. Add Optimized Edge-to-Edge Crack
        _generateCrack();

        // 2. Add Floating Damage Text with UniqueKey
        // Optimization: Limit to 5 active texts
        if (_damageNumbers.length >= 5) {
          _damageNumbers.removeAt(0);
        }

        final isCritical = _random.nextDouble() < 0.2;
        final newEntry = DamageEntry(
          key: UniqueKey(), // CRITICAL for preventing red screen
          position: details.localPosition,
          text: isCritical ? "CRITICAL!" : "-1",
          color: isCritical ? Colors.yellowAccent : Colors.white,
          fontSize: isCritical ? 48 : 36,
        );
        _damageNumbers.add(newEntry);

        // 3. Cleanup logic (still needed for natural fade out)
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _damageNumbers.removeWhere((e) => e.key == newEntry.key);
            });
          }
        });
      });
    }

    if (_hp <= 0) {
      _destroy();
    }
  }

  Future<void> _destroy() async {
    if (_isDestroyed || _isNavigating || !mounted) return;

    setState(() {
      _isDestroyed = true;
      _isNavigating = true; // Block future taps
      _damageNumbers.clear();
    });

    HapticFeedback.heavyImpact();

    await Future.delayed(const Duration(milliseconds: 2000));

    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            '이미지 분쇄기 (Lite)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(child: Center(child: _buildBody(context))),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final missionState = ref.watch(missionProvider);

    if (missionState.type == MissionType.realityCheck) {
      return _buildRealityCheckUI(missionState);
    }

    return _targetType == _TargetType.none
        ? _buildInputSelection()
        : _buildDestructionZone();
  }

  Widget _buildRealityCheckUI(MissionState state) {
    // Format Seconds to MM:SS
    final minutes = (state.timeLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (state.timeLeft % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Icon
          const Icon(
            Icons.bolt_rounded,
            size: 80,
            color: Colors.yellowAccent,
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: 32),

          // 2. Mission Text
          Text(
            state.currentRealityMission ?? '현실 자각 미션 로딩 중...',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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

          // 3. Timer
          Text(
                '$minutes:$seconds',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: Colors.redAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: Colors.white.withAlpha(50)),

          const SizedBox(height: 64),

          // 4. Complete Button
          BouncyButton(
            onTap: state.isTimerRunning ? _completeRealityMission : () {},
            child: GlassCard(
              width: double.infinity,
              height: 60,
              backgroundColor: state.isTimerRunning
                  ? Colors.redAccent.withAlpha(200)
                  : Colors.grey.withAlpha(100),
              child: Center(
                child: Text(
                  '미션 완료',
                  style: TextStyle(
                    color: state.isTimerRunning ? Colors.white : Colors.white38,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _completeRealityMission() {
    // 1. Stop Timer
    ref.read(missionProvider.notifier).stopTimer();

    // 2. Show Success Feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('미션 성공! 충동을 이겨내셨습니다.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // 3. Safe Pop
    if (mounted && context.canPop()) {
      context.pop();
    }
  }

  Widget _buildInputSelection() {
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
            '사진을 찍거나 텍스트(영수증 금액 등)를 입력하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOptionButton(
                icon:
                    Icons.photo_library, // Changed from local_library or camera
                label: '갤러리에서 선택', // Changed from '사진 촬영'
                color: Colors.redAccent,
                onTap: _pickImage,
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
        backgroundColor: color.withAlpha(51),
        border: Border.all(color: color.withAlpha(128)),
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
            hintText: '예: 치킨 25,000원',
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

  Widget _buildDestructionZone() {
    final damagePercent = (_maxHp - _hp) / _maxHp;

    return Center(
      child: GestureDetector(
        onTapDown: _onTapTarget,
        child: SizedBox(
          width: 320,
          height: 480,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Base Container (Simple, No BoxShadow)
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final double offset =
                      _shakeController.value *
                      8 *
                      (0.5 - _shakeController.value).sign;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(128),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent, width: 2),
                    // NO BoxShadow for performance
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Content
                      _targetType == _TargetType.image
                          ? Image.file(
                              File(_targetImage!.path),
                              fit: BoxFit.cover,
                            )
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

                      // Simple Color Overlay
                      Container(
                        color: Colors.red.withAlpha(
                          ((damagePercent * 0.7).clamp(0.0, 0.9) * 255).toInt(),
                        ),
                      ),

                      // LIGHTWEIGHT CRACKS (No Blur, Just Lines)
                      CustomPaint(
                        painter: CrackPainter(_crackPaths),
                        size: Size.infinite,
                      ),
                    ],
                  ),
                ),
              ).animate(target: _isDestroyed ? 1 : 0).fadeOut(duration: 150.ms),

              // 2. Floating Damage Numbers (Simple Stack)
              for (final entry in _damageNumbers)
                Positioned(
                  left:
                      entry.position.dx -
                      40, // Centering adjustment for bigger text
                  top: entry.position.dy - 60,
                  child:
                      Text(
                            entry.text,
                            style: TextStyle(
                              color: entry.color,
                              fontSize: entry.fontSize,
                              // Bold for Normal, W900 for Critical
                              fontWeight: entry.text == "CRITICAL!"
                                  ? FontWeight.w900
                                  : FontWeight.bold,
                              // Simple shadow
                              shadows: const [
                                BoxShadow(color: Colors.black, blurRadius: 1),
                              ],
                            ),
                          )
                          .animate(key: entry.key)
                          // Increased moveY from -40 to -100 for bigger jump
                          .moveY(begin: 0, end: -100, duration: 400.ms)
                          .fadeOut(delay: 200.ms, duration: 200.ms),
                ),

              // HP Indicator
              Positioned(
                top: -40,
                child: Text(
                  'HP: $_hp',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Prompt Text
              if (!_isDestroyed)
                Positioned(
                  bottom: -40,
                  child: Text(
                    '터치해서 파괴하세요!',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 16,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(),
                ),

              // Destruction Text
              if (_isDestroyed)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      const Text('💥', style: TextStyle(fontSize: 80))
                          .animate()
                          .scale(duration: 400.ms, curve: Curves.elasticOut),
                      const Text(
                        'DESTROYED!',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.redAccent,
                          fontStyle: FontStyle.italic,
                        ),
                      ).animate().fadeIn(duration: 200.ms),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Simple Painter without Blur
// Simple Painter with Neon Effect restored
class CrackPainter extends CustomPainter {
  final List<Path> cracks;

  CrackPainter(this.cracks);

  @override
  void paint(Canvas canvas, Size size) {
    if (cracks.isEmpty) return;

    final paint = Paint()
      ..color = Colors.white.withAlpha(230)
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          4.5 // Even thicker
      ..strokeCap = StrokeCap.round
      // Restore Neon Blur for dramatic effect
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    for (final path in cracks) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CrackPainter oldDelegate) {
    return oldDelegate.cracks.length != cracks.length;
  }
}
