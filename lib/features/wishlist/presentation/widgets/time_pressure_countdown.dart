import 'dart:async';
import 'package:flutter/material.dart';

class TimePressureCountdown extends StatefulWidget {
  final DateTime targetDate;
  final Color? textColor;
  final double fontSize;

  const TimePressureCountdown({
    super.key,
    required this.targetDate,
    this.textColor,
    this.fontSize = 12,
  });

  @override
  State<TimePressureCountdown> createState() => _TimePressureCountdownState();
}

class _TimePressureCountdownState extends State<TimePressureCountdown> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    final diff = widget.targetDate.difference(now);

    if (mounted) {
      setState(() {
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return Text(
        "Time Over",
        style: TextStyle(
          color: widget.textColor ?? Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: widget.fontSize,
        ),
      );
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Text(
      'D-$days일 $hours시간 $minutes분 $seconds초',
      style: TextStyle(
        color: widget.textColor ?? Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: widget.fontSize,
        fontFeatures: const [FontFeature.tabularFigures()], // 고정 너비 숫자
      ),
    );
  }
}
