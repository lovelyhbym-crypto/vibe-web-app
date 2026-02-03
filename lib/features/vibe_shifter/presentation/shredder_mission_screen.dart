import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math' as math;
import 'dart:ui' as ui; // [Added] For BackdropFilter
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/ui/bouncy_button.dart';

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
  bool _showVictoryPanel = false;
  bool _isGlitching = false;

  late AnimationController _shakeController;
  late AnimationController _panelController;
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<Offset> _panelSlideAnim;
  late AudioPlayer _audioPlayer;

  final TextEditingController _textController = TextEditingController();
  final List<DamageEntry> _damageNumbers = [];
  final List<Path> _crackPaths = [];
  final math.Random _random = math.Random();

  // [System Sync Refinement]
  String _glitchText = "system sync...";
  Timer? _glitchTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _panelSlideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic),
        );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // [System Sync Refinement] Glitch Timer
    _glitchTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_isGlitching && mounted) {
        if (_random.nextDouble() < 0.3) {
          // 30% chance to glitch a character
          final chars = "system sync...".split('');
          final index = _random.nextInt(chars.length);
          final glitchChars = ['#', '@', '?', '!', '0', '1', '\$', '%', '&'];
          chars[index] = glitchChars[_random.nextInt(glitchChars.length)];
          setState(() {
            _glitchText = chars.join();
          });

          // Revert quickly
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) setState(() => _glitchText = "system sync...");
          });
        }
      }
    });

    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _panelController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    _glitchTimer?.cancel();
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _triggerGlitch(VoidCallback onComplete) async {
    setState(() => _isGlitching = true);
    HapticService.heavy();
    _scanController.repeat(); // Loop for the flowing effect
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
      _scanController.stop();
      setState(() => _isGlitching = false);
      onComplete();
    }
  }

  Future<void> _pickImage() async {
    _triggerGlitch(() async {
      try {
        final picker = ImagePicker();
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
    });
  }

  void _submitText() {
    _triggerGlitch(() {
      if (_textController.text.isNotEmpty) {
        setState(() {
          _targetText = _textController.text;
          _targetType = _TargetType.text;
        });
      }
    });
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
      final double startY = _random.nextDouble() * h;
      final double endY = _random.nextDouble() * h;
      path.moveTo(0, startY);

      // Simple 3-step zigzag
      path.lineTo(w * 0.3, startY + (_random.nextDouble() - 0.5) * 50);
      path.lineTo(w * 0.6, endY + (_random.nextDouble() - 0.5) * 50);
      path.lineTo(w, endY);
    } else {
      // Top to Bottom crack
      final double startX = _random.nextDouble() * w;
      final double endX = _random.nextDouble() * w;
      path.moveTo(startX, 0);

      // Simple 3-step zigzag
      path.lineTo(startX + (_random.nextDouble() - 0.5) * 50, h * 0.3);
      path.lineTo(endX + (_random.nextDouble() - 0.5) * 50, h * 0.6);
      path.lineTo(endX, h);
    }

    _crackPaths.add(path);
  }

  void _onTapTarget(TapDownDetails details) {
    if (_hp <= 0 || _isNavigating) return;
    _triggerVisualDamage(details.localPosition);
  }

  void _triggerVisualDamage([Offset? position]) {
    if (_hp <= 0 || _isNavigating) return;

    // Safety: Try-Catch to prevent app crash on animation error
    try {
      // 1. Audio Impact
      _audioPlayer.play(
        AssetSource('audio/chip.mp3'),
        mode: PlayerMode.lowLatency,
      );

      // 2. Physical Vibration (Mechanical Shredding Feel)
      HapticService.light();

      _shakeController.forward(from: 0).then((_) {
        if (mounted) _shakeController.reset();
      });

      if (mounted) {
        setState(() {
          _hp--;
          // DEBUG LOG
          print('Damage Triggered: HP $_hp / $_maxHp');

          // 1. Add Optimized Edge-to-Edge Crack
          _generateCrack();

          // 2. Add Floating Damage Text with UniqueKey
          // Optimization: Limit to 5 active texts
          if (_damageNumbers.length >= 5) {
            _damageNumbers.removeAt(0);
          }

          final isCritical = _random.nextDouble() < 0.2;

          // Use provided position or random position if triggered by shake
          final damagePos =
              position ??
              Offset(
                160 + (_random.nextDouble() - 0.5) * 100,
                240 + (_random.nextDouble() - 0.5) * 100,
              );

          final newEntry = DamageEntry(
            key: UniqueKey(), // CRITICAL for preventing red screen
            position: damagePos,
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
    } catch (e) {
      print("Animation Error Safe Catch: $e");
    }
  }

  Future<void> _destroy() async {
    if (_isDestroyed || _isNavigating || !mounted) return;

    setState(() {
      _isDestroyed = true;
      _isNavigating = true; // Block future taps
      _damageNumbers.clear();
    });

    // Final Destruction Sound & Vibration
    _audioPlayer.play(AssetSource('audio/shatter.mp3'));
    HapticService.heavy();

    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _showVictoryPanel = true;
      });
      _panelController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 칠흑 같은 블랙 배경
      appBar: AppBar(
        title: const Text(
          '유혹 파괴 프로토콜 (Temptation Destroyer)',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(child: Center(child: _buildBody(context))),
    );
  }

  Widget _buildInputSelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '파괴할 대상을 선택하세요',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Column(
                children: [
                  _buildOptionButton(
                    icon: Icons.image_search_rounded,
                    label: '시각적 유혹 파쇄',
                    subLabel: "사고 싶은 그 물건의 '영정사진'을 등록하세요.",
                    glowColor: const Color(0xFFD4FF00), // 네온 라임
                    onTap: _pickImage,
                  ),
                  const SizedBox(height: 24),
                  _buildOptionButton(
                    icon: Icons.terminal_rounded,
                    label: '관념적 유혹 파쇄',
                    subLabel: "머릿속을 맴도는 지름신의 이름을 적으세요.",
                    glowColor: Colors.redAccent, // 경고 레드
                    onTap: () => _showTextInputDialog(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return BouncyButton(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: glowColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.15),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: glowColor, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.54),
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        _targetType == _TargetType.none
            ? _buildInputSelection()
            : _buildDestructionZone(),
        if (_isGlitching)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: _buildScanProtocolOverlay(),
              ),
            ),
          ).animate().fadeIn(duration: 100.ms),
        if (_showVictoryPanel) Positioned.fill(child: _buildVictoryPanel()),
      ],
    );
  }

  Widget _buildVictoryPanel() {
    return SlideTransition(
      position: _panelSlideAnim,
      child: FadeTransition(
        opacity: _panelController,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.87),
            border: const Border(
              top: BorderSide(
                color: Color(0xFFD4FF00), // 네온 라임
                width: 1.0,
              ),
            ),
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.2),
                BlendMode.darken,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '유혹 파쇄 성공',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '파괴된 유혹은 곧 지켜낸 자산입니다.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.54),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Main Button with Pulse Animation
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4FF00).withValues(
                                  alpha: 0.1 + (_pulseController.value * 0.2),
                                ),
                                blurRadius: 10 + (_pulseController.value * 10),
                                spreadRadius: 1 + (_pulseController.value * 2),
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: BouncyButton(
                        onTap: () {
                          // [Victory Logging Protocol] Navigate with 0-Won Preset
                          context.push(
                            '/saving',
                            extra: {
                              'initialAmount': '0',
                              'initialMemo': _targetText?.isNotEmpty == true
                                  ? _targetText
                                  : '유혹방어',
                              'initialCategoryId': 'system_optimization',
                              'isTrophyMode': true,
                            },
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4FF00),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '[전리품 기록: 무지출 인증]',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sub Button 1: Ghost Button
                    BouncyButton(
                      onTap: () {
                        setState(() {
                          _showVictoryPanel = false;
                          _hp = _maxHp;
                          _isDestroyed = false;
                          _isNavigating = false;
                          _crackPaths.clear();
                          _targetType = _TargetType.none;
                        });
                        _panelController.reset();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '[추가 파쇄]',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sub Button 2: Text Button
                    TextButton(
                      onPressed: () {
                        if (context.canPop()) context.pop();
                      },
                      child: const Text(
                        '[대시보드 복귀]',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Unused _buildRealityCheckUI removed

  // ... (Keeping intervening methods)

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
            onPressed: () {
              if (context.canPop()) Navigator.pop(context);
            },
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (context.canPop()) {
                Navigator.pop(context);
                _submitText();
              }
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
        behavior: HitTestBehavior
            .opaque, // Ensure touches are caught even on empty spaces
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
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Content
                      _targetType == _TargetType.image
                          ? (kIsWeb
                                ? Image.network(
                                    _targetImage!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_targetImage!.path),
                                    fit: BoxFit.cover,
                                  ))
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
                      IgnorePointer(
                        child: Container(
                          color: Colors.red.withAlpha(
                            ((damagePercent * 0.7).clamp(0.0, 0.9) * 255)
                                .toInt(),
                          ),
                        ),
                      ),

                      // LIGHTWEIGHT CRACKS (No Blur, Just Lines)
                      IgnorePointer(
                        child: CustomPaint(
                          painter: CrackPainter(_crackPaths),
                          size: Size.infinite,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(target: _isDestroyed ? 1 : 0).fadeOut(duration: 150.ms),

              // 2. Floating Damage Numbers (Wrapped in IgnorePointer)
              for (final entry in _damageNumbers)
                Positioned(
                  left: entry.position.dx - 40,
                  top: entry.position.dy - 60,
                  child: IgnorePointer(
                    child:
                        Text(
                              entry.text,
                              style: TextStyle(
                                color: entry.color,
                                fontSize: entry.fontSize,
                                fontWeight: entry.text == "CRITICAL!"
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                                shadows: const [
                                  BoxShadow(color: Colors.black, blurRadius: 1),
                                ],
                              ),
                            )
                            .animate(key: entry.key)
                            .moveY(begin: 0, end: -100, duration: 400.ms)
                            .fadeOut(delay: 200.ms, duration: 200.ms),
                  ),
                ),

              // HP Indicator (Wrapped in IgnorePointer just in case)
              Positioned(
                top: -40,
                child: IgnorePointer(
                  child: Text(
                    'HP: $_hp',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Prompt Text
              if (!_isDestroyed)
                Positioned(
                  bottom: -40,
                  child: IgnorePointer(
                    child: Text(
                      '터치해서 파괴하세요!',
                      style: TextStyle(
                        color: Colors.white.withAlpha(204),
                        fontSize: 16,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(),
                  ),
                ),

              // Destruction Text
              if (_isDestroyed)
                Center(
                  child: IgnorePointer(
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
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanProtocolOverlay() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        // [System Sync Refinement]
        // Alignment: Moved to (0, -0.2) to be above the buttons/center

        return Align(
          alignment: const Alignment(0, -0.2),
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: double.infinity,
                height: 80, // Slightly taller for glow
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.8,
                  ), // [Visual Tuning] Increased Opacity to 0.8
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 15,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Moving Neon Scan Line (Intensified Glow)
                    Positioned(
                      left:
                          -100 +
                          (_scanController.value *
                              (MediaQuery.of(context).size.width + 200)),
                      child: Container(
                        width: 6, // Thicker
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4FF00),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4FF00),
                              blurRadius: 25, // Stronger blur
                              spreadRadius: 4, // Stronger spread
                            ),
                            const BoxShadow(
                              color: Colors.white,
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Text with ShaderMask Highlight (Neon Lime Glow)
                    // This layer handles the "Passing" effect
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.0), // Transparent
                            Colors
                                .white, // Visible (This allows the child Neon Lime to show)
                            Colors.white.withValues(alpha: 0.0), // Transparent
                          ],
                          stops: [
                            (_scanController.value - 0.1).clamp(0.0, 1.0),
                            _scanController.value,
                            (_scanController.value + 0.1).clamp(0.0, 1.0),
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode
                          .dstIn, // Show child only where shader is opaque
                      child: Text(
                        _glitchText,
                        style: const TextStyle(
                          color: Color(
                            0xFFD4FF00,
                          ), // [Visual Tuning] Active Neon Lime
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          fontFamily: 'Courier',
                          shadows: [
                            BoxShadow(
                              color: Color(0xFFD4FF00),
                              blurRadius: 30, // Stronger Glow
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Base White Text (Visible when mask is not there)
                    Opacity(
                      opacity: 1.0, // [Visual Tuning] Solid White
                      child: Text(
                        _glitchText,
                        style: const TextStyle(
                          color: Colors.white, // [Visual Tuning] Base White
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
