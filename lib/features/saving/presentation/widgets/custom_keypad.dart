import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vive_app/core/services/sound_service.dart';
import 'package:vive_app/core/services/haptic_service.dart';

class CustomKeypad extends StatelessWidget {
  final Function(String) onKeyTap;

  const CustomKeypad({super.key, required this.onKeyTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.white.withOpacity(0.05),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 40), // Safe zone
            child: Column(
              children: [
                // Handle Bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Rows
                Expanded(child: _buildRow(['1', '2', '3'])),
                Expanded(child: _buildRow(['4', '5', '6'])),
                Expanded(child: _buildRow(['7', '8', '9'])),
                Expanded(child: _buildRow(['00', '0', 'back'])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: _KeypadButton(value: key, onTap: () => onKeyTap(key)),
          ),
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatefulWidget {
  final String value;
  final VoidCallback onTap;

  const _KeypadButton({required this.value, required this.onTap});

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  double _scale = 1.0;
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    _triggerFeedback();
    setState(() {
      _scale = 0.95; // 0.9 -> 0.95 (PRD standard)
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
      _isPressed = false;
    });
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() {
      _scale = 1.0;
      _isPressed = false;
    });
  }

  void _triggerFeedback() {
    SoundService().playChip();
    HapticService.light();
  }

  @override
  Widget build(BuildContext context) {
    final isBack = widget.value == 'back';
    final neonLime = const Color(0xFFCCFF00);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: isBack
          ? () {
              _triggerFeedback();
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack, // 쫀득한 탄성 커브 적용
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: _isPressed ? neonLime.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: neonLime.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: isBack
              ? Icon(
                  Icons.backspace_outlined,
                  color: _isPressed ? neonLime : Colors.white,
                  size: 24,
                )
              : Text(
                  widget.value,
                  style: TextStyle(
                    color: _isPressed ? neonLime : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900, // 더 무거운 폰트 적용
                    fontFamily: 'Courier',
                  ),
                ),
        ),
      ),
    );
  }
}
