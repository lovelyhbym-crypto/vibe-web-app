import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nerve/features/saving/presentation/saving_record_screen.dart';
import 'package:nerve/features/wishlist/presentation/wishlist_screen.dart';
import 'package:nerve/features/dashboard/presentation/dashboard_screen.dart';
import 'package:nerve/features/home/providers/navigation_provider.dart';
import 'package:nerve/core/theme/app_theme.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;

    final screens = [
      const SavingRecordScreen(),
      const WishlistScreen(),
      const DashboardScreen(),
    ];

    void onItemTapped(int index) {
      ref.read(navigationIndexProvider.notifier).setIndex(index);
    }

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: colors.surface,
          selectedItemColor: colors.accent,
          unselectedItemColor: colors.textSub,
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: '기록'),
            BottomNavigationBarItem(icon: Icon(Icons.flag), label: '목표'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '통계'),
          ],
        ),
      ),
    );
  }
}
