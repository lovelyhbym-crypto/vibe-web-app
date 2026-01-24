import 'package:flutter/material.dart';

class FloatingInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType keyboardType;
  final int maxLines;
  final TextStyle? style;
  final Color? accentColor;

  const FloatingInputField({
    super.key,
    required this.controller,
    required this.label,
    this.readOnly = false,
    this.onTap,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.style,
    this.accentColor,
  });

  @override
  State<FloatingInputField> createState() => _FloatingInputFieldState();
}

class _FloatingInputFieldState extends State<FloatingInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Neon Lime default if not provided
    final accent = widget.accentColor ?? const Color(0xFFD4FF00);
    final darkGrey = Colors.grey[800]!;

    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          _focusNode.requestFocus();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _isFocused ? accent : darkGrey,
              width: _isFocused ? 2.0 : 1.0,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            Text(
              widget.label,
              style: TextStyle(
                color: _isFocused ? accent : Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Input
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              readOnly: widget.readOnly,
              onTap: widget.onTap,
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              style:
                  widget.style ??
                  const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: accent,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
