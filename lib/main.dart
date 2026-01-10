import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'package:vive_app/core/services/notification_service.dart';
import 'package:vive_app/core/providers/locale_provider.dart';
import 'core/utils/i18n.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  final notificationService = NotificationService();
  await notificationService.initialize();
  // Request permissions logic is now partly inside initialize (FCM)
  // But we keep this for consistency if local notifications need separate prompt logic?
  // Actually NotificationService.initialize() now requests FCM permission.
  // The existing .requestPermissions() was for local notifications purely.
  // We can keep calling it or merge. The prompt says "call NotificationService().initialize()".
  // Let's keep existing calls to retain behavior unless conflicts.
  await notificationService.requestPermissions();
  // Schedule a default reminder if none exists, this is a simple default.
  // In a real app we might base this on dynamic data immediately.
  await notificationService.scheduleDailyTenPM(
    'Ready to save closer to your goal? Log your resistance now!',
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

    return MaterialApp.router(
      title: 'Vive App',
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
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFCCFF00), // Neon Green
        scaffoldBackgroundColor: const Color(0xFF121212), // Deep Black
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFCCFF00),
          secondary: Color(0xFFCCFF00),
          surface: Color(0xFF1E1E1E),
          onSurface: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCCFF00),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      routerConfig: router,
    );
  }
}
