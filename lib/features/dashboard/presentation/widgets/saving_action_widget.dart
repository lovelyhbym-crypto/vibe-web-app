import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/i18n.dart';

class SavingActionWidget extends StatelessWidget {
  const SavingActionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    const limeColor = Color(0xFFD4FF00);
    final i18n = I18n.of(context);

    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: () => context.push('/saving'),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: limeColor.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: limeColor.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: limeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  size: 32,
                  color: limeColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Resist Now", // Could be i18n.resistButtonLabel if appropriate
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
