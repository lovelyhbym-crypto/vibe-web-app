import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/ui/glass_card.dart';
import '../../../core/ui/bouncy_button.dart';
import '../../../core/ui/background_gradient.dart';

class ShredderMissionScreen extends StatefulWidget {
  const ShredderMissionScreen({super.key});

  @override
  State<ShredderMissionScreen> createState() => _ShredderMissionScreenState();
}

enum _TargetType { none, image, text }

class _ShredderMissionScreenState extends State<ShredderMissionScreen>
    with SingleTickerProviderStateMixin {
  _TargetType _targetType = _TargetType.none;
  XFile? _targetImage;
  String? _targetText;

  int _hp = 10;
  final int _maxHp = 10;
  bool _isDestroyed = false;

  late AnimationController _shakeController;
  final TextEditingController _textController = TextEditingController();

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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      // Critical OOM Optimization:
      // - maxWidth: 600 (reduced from 800)
      // - imageQuality: 50
      // - requestFullMetadata: false
      final image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        imageQuality: 50,
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

  void _onTapTarget() {
    if (_hp <= 0) return;

    HapticFeedback.mediumImpact();

    // Trigger shake without rebuilding whole widget tree
    _shakeController.forward(from: 0).then((_) {
      if (mounted) _shakeController.reset();
    });

    // Only rebuild for HP change
    if (mounted) {
      setState(() {
        _hp--;
      });
    }

    if (_hp <= 0) {
      _destroy();
    }
  }

  Future<void> _destroy() async {
    // Only set destruction state once
    if (_isDestroyed || !mounted) return;

    setState(() {
      _isDestroyed = true;
    });

    // Heavy impact for destruction
    HapticFeedback.heavyImpact();

    // Wait for animation then close
    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) {
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
            '이미지 분쇄기',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: Center(
            child: _targetType == _TargetType.none
                ? _buildInputSelection()
                : _buildDestructionZone(),
          ),
        ),
      ),
    );
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
                icon: Icons.camera_alt_rounded,
                label: '사진 촬영',
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
        backgroundColor: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.5)),
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
    // Damage calculation: 0.0 (full hp) -> 1.0 (dead)
    final damagePercent = (_maxHp - _hp) / _maxHp;

    return GestureDetector(
      onTap: _onTapTarget,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Target Content with AnimationController optimized shake
          AnimatedBuilder(
                animation: _shakeController,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  child: _targetType == _TargetType.image
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(_targetImage!.path),
                            fit: BoxFit.cover,
                          ),
                        )
                      : GlassCard(
                          height: 300,
                          child: Center(
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
                        ),
                ),
                builder: (context, child) {
                  final double offset =
                      _shakeController.value *
                      10 *
                      (0.5 - _shakeController.value).sign;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
              )
              .animate(target: _isDestroyed ? 1 : 0)
              .fadeOut(duration: 200.ms), // Disappear on destroy
          // Damage Overlay (Optimized: No Opacity widget, just color alpha)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(
                      (damagePercent * 0.8).clamp(0.0, 1.0),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),

          // HP Indicator
          Positioned(
                top: 20,
                child: Text(
                  'HP: $_hp',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    shadows: [BoxShadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              )
              .animate(key: UniqueKey())
              .scale(duration: 100.ms, curve: Curves.easeOutBack),

          // Prompt Text
          if (!_isDestroyed)
            Positioned(
              bottom: 40,
              child:
                  Text(
                        '터치해서 파괴하세요!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn()
                      .moveY(begin: 5, end: 0),
            ),

          // Destruction Effect
          if (_isDestroyed)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '💥',
                    style: TextStyle(fontSize: 80),
                  ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                  const Text(
                    'DESTROYED!',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.redAccent,
                      fontStyle: FontStyle.italic,
                    ),
                  ).animate().fadeIn(duration: 200.ms).shake(),
                  const SizedBox(height: 16),
                  const Text(
                    '충동이 분쇄되었습니다.',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
