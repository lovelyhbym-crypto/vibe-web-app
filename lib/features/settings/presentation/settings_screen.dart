import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vive_app/core/providers/locale_provider.dart';
import '../../../core/utils/i18n.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../../saving/providers/saving_provider.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../wishlist/presentation/providers/glory_report_provider.dart';
import 'providers/pin_notifier.dart';
import 'widgets/pin_auth_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = I18n.of(context);
    // localeProvider is watched in main.dart to trigger app rebuild
    final pinState = ref.watch(pinProvider);

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
      body: Column(
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
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              ref.read(authProvider.notifier).signOut();
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Danger Zone',
                style: TextStyle(
                  color: Colors.redAccent.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
              color: Colors.redAccent.withOpacity(0.05),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                '데이터 전체 초기화',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '모든 절약 기록과 위시리스트가 영구 삭제됩니다.',
                style: TextStyle(
                  color: Colors.red.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              onTap: () {
                pinState.when(
                  data: (storedPin) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => PinAuthDialog(
                        isRegistration: storedPin == null,
                        onSuccess: () async {
                          try {
                            // 1. 서버 및 로컬 데이터 삭제 실행
                            await ref
                                .read(savingProvider.notifier)
                                .deleteAllSavings();
                            await ref
                                .read(wishlistProvider.notifier)
                                .deleteAllWishlists();

                            // 2. AI 리포트 상태 초기화
                            ref
                                .read(gloryReportProvider.notifier)
                                .resetReport();

                            // 3. 완료 알림 및 대시보드 이동
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("모든 데이터가 성공적으로 초기화되었습니다."),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                              context.go('/');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('초기화 실패: $e')),
                              );
                            }
                            debugPrint("초기화 실패: $e");
                          }
                        },
                      ),
                    );
                  },
                  loading: () {},
                  error: (e, _) => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('오류 발생: $e'))),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
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
