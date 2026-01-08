import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/i18n.dart';
import '../../saving/providers/saving_provider.dart';
import '../../saving/domain/saving_model.dart';
import '../providers/wishlist_provider.dart';
import '../domain/wishlist_model.dart';

class AchievedTimelineScreen extends ConsumerWidget {
  const AchievedTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistProvider);
    final savingsAsync = ref.watch(savingProvider);
    final i18n = I18n.of(context);

    // Color definitions
    const limeColor = Color(0xFFD4FF00);
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: wishlistAsync.when(
        data: (wishlist) {
          final achievedGoals = wishlist
              .where((item) => item.isAchieved)
              .toList();

          // Sort by achieved date descending
          achievedGoals.sort(
            (a, b) => (b.achievedAt ?? DateTime.now()).compareTo(
              a.achievedAt ?? DateTime.now(),
            ),
          );

          return savingsAsync.when(
            data: (savings) {
              if (achievedGoals.isEmpty) {
                return const Center(child: Text('No history yet.'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 32,
                ),
                itemCount: achievedGoals.length,
                itemBuilder: (context, index) {
                  final goal = achievedGoals[index];
                  final isLast = index == achievedGoals.length - 1;

                  // Calculate stats for this goal
                  final stats = _calculateStats(goal, savings);

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timeline Column
                        Column(
                          children: [
                            // Dot
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: limeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Line
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: limeColor.withOpacity(0.3),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        // Content Column
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 48.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Date Header
                                Text(
                                  DateFormat(
                                    'yyyy.MM.dd',
                                  ).format(goal.achievedAt ?? DateTime.now()),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Goal Card (Minimal)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              goal.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.check_circle,
                                            color: limeColor,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Stats Chips
                                      if (stats.isNotEmpty) ...[
                                        const Text(
                                          'Resisted Temptations:',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: stats.entries.map((e) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.05,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: Colors.white10,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _getCategoryIcon(
                                                      e.key,
                                                      i18n,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${i18n.categoryName(e.key)} x${e.value}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ] else
                                        const Text(
                                          'Pure dedication (no specific records)',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontStyle: FontStyle.italic,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Error loading savings')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Map<String, int> _calculateStats(
    WishlistModel goal,
    List<SavingModel> savings,
  ) {
    final start = goal.createdAt;
    final end = goal.achievedAt ?? DateTime.now();

    // Filter savings within the goal period
    final relevantSavings = savings.where((s) {
      return s.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
          s.createdAt.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    final stats = <String, int>{};
    for (final s in relevantSavings) {
      stats.update(s.category, (value) => value + 1, ifAbsent: () => 1);
    }
    return stats;
  }

  String _getCategoryIcon(String categoryId, I18n i18n) {
    // Basic mapping, could be enhanced with actual category metadata
    switch (categoryId) {
      case 'coffee':
        return '☕';
      case 'alcohol':
        return '🍺';
      case 'taxi':
        return '🚕';
      case 'food':
        return '🍔';
      default:
        return '✨';
    }
  }
}
