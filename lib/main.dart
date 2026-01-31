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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiKey = EnvConfig.geminiApiKey;

  debugPrint('DEBUG: GEMINI_API_KEY length: ${apiKey.length}');
  if (apiKey.isEmpty) debugPrint('DEBUG: GEMINI_API_KEY is EMPTY');

  // await Firebase.initializeApp(); // Temporarily disabled until properly configured for Web

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

  // Notifications not supported on web currently or requires specific setup
  // if (!kIsWeb) {
  //   final notificationService = NotificationService();
  //   await notificationService.initialize();
  //   await notificationService.requestPermissions();
  //   await notificationService.scheduleDailyTenPM(
  //     'Ready to save closer to your goal? Log your resistance now!',
  //   );
  // }

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
        // Custom I18n delegate
        I18nDelegate(),
        // Standard delegates
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 2. 테마 엔진 연결!
      // 이제 themeMode가 바뀔 때마다 AppTheme이 새로운 디자인을 배달합니다.
      theme: AppTheme.getTheme(themeMode),

      routerConfig: router,
    );
  }
}
