import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'package:nerve/core/providers/locale_provider.dart';
import 'core/utils/i18n.dart';
import 'core/config/env_config.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 알림 서비스 엔진 초기화 및 테스트 스케줄링
  try {
    debugPrint('🚀 [MAIN] 앱 초기화 시작...');
    final notify = NotificationService();

    debugPrint('🚀 [MAIN] CHECKPOINT: init 시작');
    await notify.init();
    debugPrint('🚀 [MAIN] CHECKPOINT: init 끝');

    // 2-1. [DEBUG] 즉시 알림 테스트 (앱 실행 직후 바로 확인용)
    debugPrint('🚀 [MAIN] CHECKPOINT: showImmediateRoast 시작');
    await notify.showImmediateRoast(
      id: 99,
      title: "🚨 NERVE 엔진 가동",
      body: "충동 제어 시스템이 활성화되었습니다. 당신의 통장을 지켜보고 있습니다.",
    );
    debugPrint('🚀 [MAIN] CHECKPOINT: showImmediateRoast 끝');

    // 2-2. [DEBUG] 10초 뒤 예약 알림 테스트 (스케줄 엔진 동작 여부 확인용)
    debugPrint('🚀 [MAIN] CHECKPOINT: scheduleOneshotRoast 시작');
    await notify.scheduleOneshotRoast(
      id: 88,
      seconds: 10,
      title: "⏱️ 예약 엔진 확인 (10초)",
      body: "스케줄러가 정상 작동하고 있습니다.",
    );
    debugPrint('🚀 [MAIN] CHECKPOINT: scheduleOneshotRoast 끝');

    // 2-3. [DEBUG] 고정 독설 알림 예약 (테스트: 1분마다 반복)
    debugPrint('🚀 [MAIN] CHECKPOINT: scheduleMinuteRoast(1) 시작');
    await notify.scheduleMinuteRoast(
      id: 1,
      title: "☕ 카페인 중독인가요?",
      body: "방금 생각한 그 커피값, 위시리스트 목표가 1일 뒤로 밀려났습니다.",
    );
    debugPrint('🚀 [MAIN] CHECKPOINT: scheduleMinuteRoast(1) 끝');

    debugPrint('🚀 [MAIN] CHECKPOINT: scheduleMinuteRoast(2) 시작');
    await notify.scheduleMinuteRoast(
      id: 2,
      title: "🛵 배달 앱 접속 차단 권고",
      body: "오늘만 먹고 싶다구요? 그 '오늘만'이 당신을 하층민으로 만듭니다.",
    );
    debugPrint('🚀 [MAIN] CHECKPOINT: scheduleMinuteRoast(2) 끝');
  } catch (e) {
    debugPrint('🔔 [NOTIFICATION ERROR] 메인 스케줄링 실패: $e');
  }

  final apiKey = EnvConfig.geminiApiKey;
  debugPrint('DEBUG: GEMINI_API_KEY length: ${apiKey.length}');

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://zgdwhauakiimczloynct.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpnZHdoYXVha2lpbWN6bG95bmN0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MDUxNDksImV4cCI6MjA4MzI4MTE0OX0.OsLKZpDNNb1qZrAR0fe0HHbRfQEiKiF0tg-ckghkEI8',
    ),
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final localeAsync = ref.watch(localeProvider);
    final locale = localeAsync.asData?.value ?? const Locale('ko');
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      title: 'Nerve App',
      locale: locale,
      supportedLocales: const [Locale('ko'), Locale('en')],
      localizationsDelegates: const [
        I18nDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.getTheme(themeMode),
      routerConfig: router,
    );
  }
}
