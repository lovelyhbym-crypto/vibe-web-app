import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../saving/presentation/saving_record_screen.dart';
import '../../wishlist/presentation/wishlist_screen.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../providers/navigation_provider.dart';

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    final screens = [
      const SavingRecordScreen(),
      const WishlistScreen(),
      const DashboardScreen(),
    ];

    void onItemTapped(int index) {
      ref.read(navigationIndexProvider.notifier).state = index;
    }

    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: screens),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF1E1E1E),
          selectedItemColor: const Color(0xFFD4FF00), // Lime
          unselectedItemColor: Colors.white38,
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
