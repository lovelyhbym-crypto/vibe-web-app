import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vive_app/core/providers/locale_provider.dart';
import '../../../core/utils/i18n.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = I18n.of(context);
    // localeProvider is watched in main.dart to trigger app rebuild

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.settingsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              i18n.languageSetting,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: _LanguageToggle(
              isKorean: i18n.isKorean,
              onChanged: (isKorean) {
                final locale = isKorean
                    ? const Locale('ko')
                    : const Locale('en');
                ref.read(localeProvider.notifier).setLocale(locale);
              },
            ),
          ),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final bool isKorean;
  final ValueChanged<bool> onChanged;

  const _LanguageToggle({required this.isKorean, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: isKorean ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 80,
              height: 36,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFF00),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(true),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      '한국어',
                      style: TextStyle(
                        color: isKorean ? Colors.black : Colors.white60,
                        fontWeight: isKorean
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(false),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'English',
                      style: TextStyle(
                        color: !isKorean ? Colors.black : Colors.white60,
                        fontWeight: !isKorean
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
