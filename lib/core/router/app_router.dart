// Material import removed
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/booting_screen.dart';
import '../../features/wishlist/presentation/wishlist_screen.dart';
import '../../features/saving/presentation/saving_record_screen.dart';
import '../../features/home/presentation/main_navigation_screen.dart';

import '../../features/settings/presentation/settings_screen.dart';
import '../../features/wishlist/presentation/achieved_timeline_screen.dart';
import '../../features/wishlist/presentation/wishlist_detail_screen.dart';
import '../../features/wishlist/domain/wishlist_model.dart';
import '../../features/wishlist/presentation/pages/glory_report_screen.dart';
import '../../features/mission/presentation/pages/reality_awareness_screen.dart';
import '../../features/wishlist/presentation/failed_dreams_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/booting',
    redirect: (context, state) {
      final authNotifier = ref.read(authProvider.notifier);
      final isLoggedIn =
          authState.asData?.value != null || authNotifier.isGuest;
      final isLoggingIn = state.uri.path == '/login';
      final isBooting = state.uri.path == '/booting';

      // 부팅 화면은 항상 허용
      if (isBooting) {
        return null;
      }

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/booting',
        builder: (context, state) => const BootingScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          return const MainNavigationScreen();
        },
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/saving',
        builder: (context, state) => SavingRecordScreen(
          initialData: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/achieved-goals',
        builder: (context, state) => const AchievedTimelineScreen(),
      ),
      GoRoute(
        path: '/wishlist/detail',
        builder: (context, state) {
          final item = state.extra as WishlistModel;
          return WishlistDetailScreen(item: item);
        },
      ),
      GoRoute(
        path: '/reality-awareness',
        builder: (context, state) => const RealityAwarenessScreen(),
      ),
      GoRoute(
        path: '/wishlist/glory-report',
        builder: (context, state) => const GloryReportScreen(),
      ),
      GoRoute(
        path: '/failed-dreams',
        builder: (context, state) => const FailedDreamsScreen(),
      ),
    ],
  );
}
