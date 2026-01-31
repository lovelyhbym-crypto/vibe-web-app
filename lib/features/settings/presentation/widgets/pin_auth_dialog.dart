import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pin_notifier.dart';
import '../../../../core/services/haptic_service.dart';

class PinAuthDialog extends ConsumerStatefulWidget {
  final bool isRegistration;
  final VoidCallback onSuccess;

  const PinAuthDialog({
    super.key,
    required this.isRegistration,
    required this.onSuccess,
  });

  @override
  ConsumerState<PinAuthDialog> createState() => _PinAuthDialogState();
}

class _PinAuthDialogState extends ConsumerState<PinAuthDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        widget.isRegistration ? "초기 비밀번호 설정" : "데이터 초기화 인증",
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.isRegistration
                ? "데이터 삭제 시 사용할 숫자 4자리를 입력하세요."
                : "비밀번호 4자리를 입력하면 모든 데이터가 삭제됩니다.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _pinController,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 20,
            ),
            decoration: InputDecoration(
              counterText: "",
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.red.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
              errorText: _errorMessage,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("취소", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            final input = _pinController.text;
            if (input.length != 4) return;

            if (widget.isRegistration) {
              await ref.read(pinProvider.notifier).registerPin(input);
              HapticService.success();
              if (context.mounted) Navigator.pop(context);
              widget.onSuccess();
            } else {
              final isValid = await ref
                  .read(pinProvider.notifier)
                  .verifyPin(input);
              if (isValid) {
                HapticService.success();
                if (context.mounted) Navigator.pop(context);
                widget.onSuccess();
              } else {
                HapticService.error();
                setState(() => _errorMessage = "비밀번호가 일치하지 않습니다.");
              }
            }
          },
          child: Text(widget.isRegistration ? "등록" : "인증 및 삭제"),
        ),
      ],
    );
  }
}
