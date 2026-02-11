import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/i18n.dart';
import '../../saving/providers/saving_provider.dart';
import '../../saving/domain/saving_model.dart';
import '../providers/wishlist_provider.dart';
import '../domain/wishlist_model.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/glass_card.dart';
import 'package:nerve/core/theme/app_theme.dart';
import 'package:nerve/core/theme/theme_provider.dart';

class AchievedTimelineScreen extends ConsumerStatefulWidget {
  const AchievedTimelineScreen({super.key});

  @override
  ConsumerState<AchievedTimelineScreen> createState() =>
      _AchievedTimelineScreenState();
}

class _AchievedTimelineScreenState
    extends ConsumerState<AchievedTimelineScreen> {
  bool _isEditing = false;
  final Set<String> _selectedIds = {};

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<String> allIds) {
    setState(() {
      if (_selectedIds.length == allIds.length) {
        _selectedIds.clear(); // Deselect all if already all selected
      } else {
        _selectedIds.addAll(allIds);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    if (count == 0) return;

    final i18n = I18n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24),
        ),
        title: Text(
          i18n.isKorean ? '기록 삭제' : 'Delete Items',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          i18n.isKorean
              ? "선택한 $count개의 기록을 삭제하시겠습니까?\n(삭제된 기록은 복구할 수 없습니다.)"
              : "Delete $count selected items?\n(This action cannot be undone.)",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              i18n.isKorean ? '취소' : 'Cancel',
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              i18n.isKorean ? '삭제' : 'Delete',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(wishlistProvider.notifier)
            .deleteWishlists(_selectedIds.toList());

        if (mounted) {
          setState(() {
            _selectedIds.clear();
            _isEditing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🗑️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    i18n.isKorean
                        ? '$count개의 기록이 삭제되었습니다.'
                        : '$count items deleted.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1A1A1A),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white24, width: 1),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistAsync = ref.watch(wishlistProvider);
    final savingsAsync = ref.watch(savingProvider);
    final i18n = I18n.of(context);
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final themeMode = ref.watch(themeNotifierProvider);
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;

    const limeColor = Color(0xFFD4FF00);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SUCCESS_ARCHIVE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _toggleEditMode,
            child: Text(
              _isEditing
                  ? (i18n.isKorean ? '완료' : 'Done')
                  : (i18n.isKorean ? '편집' : 'Edit'),
              style: TextStyle(
                color: isPureFinance ? colors.textMain : Colors.yellow,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // TODO: Implement Glory Report feature properly
          // IconButton(
          //   icon: const Icon(Icons.analytics_outlined),
          //   onPressed: () => context.push('/wishlist/glory-report'),
          //   tooltip: 'Glory Report',
          // ),
          const SizedBox(width: 8),
        ],
      ),
      body: wishlistAsync.when(
        data: (wishlist) {
          final achievedGoals = wishlist
              .where((item) => item.isAchieved && item.id != null)
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

              return Stack(
                children: [
                  // Ghost Grid Background (behind everything)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _GridPainter()),
                    ),
                  ),
                  // Main content
                  ListView.builder(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 32,
                      bottom: _isEditing
                          ? 100
                          : 32, // More padding for bottom bar
                    ),
                    itemCount: achievedGoals.length,
                    itemBuilder: (context, index) {
                      final goal = achievedGoals[index];
                      // We filtered null IDs above, so id is safe
                      final id = goal.id!;
                      final isLast = index == achievedGoals.length - 1;
                      final isSelected = _selectedIds.contains(id);

                      // Calculate stats for this goal
                      final stats = _calculateStats(goal, savings);

                      return GestureDetector(
                        onTap: () {
                          if (_isEditing) {
                            _toggleSelection(id);
                          } else {
                            context.push('/wishlist/detail', extra: goal);
                          }
                        },
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Checkbox Area (Animated)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                width: _isEditing ? 40 : 0,
                                margin: EdgeInsets.only(
                                  right: _isEditing ? 8 : 0,
                                ),
                                alignment: Alignment.topCenter,
                                child: _isEditing
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 24),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? (isPureFinance
                                                        ? colors.accent
                                                        : limeColor)
                                                  : (isPureFinance
                                                        ? colors.border
                                                        : Colors.white30),
                                              width: 2,
                                            ),
                                            color: isSelected
                                                ? (isPureFinance
                                                      ? colors.accent
                                                      : limeColor)
                                                : Colors.transparent,
                                          ),
                                          child: isSelected
                                              ? Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: isPureFinance
                                                      ? Colors.white
                                                      : Colors.black,
                                                )
                                              : null,
                                        ),
                                      )
                                    : null,
                              ),

                              // Timeline Column
                              Column(
                                children: [
                                  // Dot with Neon Glow
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: limeColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: limeColor.withValues(
                                            alpha: 0.6,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Line with Neon Effect
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        color: limeColor.withValues(alpha: 0.2),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Date Header
                                      Text(
                                        DateFormat('yyyy.MM.dd').format(
                                          goal.achievedAt ?? DateTime.now(),
                                        ),
                                        style: TextStyle(
                                          color: limeColor.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Goal Card (Hi-Tech Data Module)
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: limeColor.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                          boxShadow: isPureFinance
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                          alpha: 0.05,
                                                        ),
                                                    blurRadius: 4,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        goal.title,
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                // Right Side: Record ID, Check Icon & Amount
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    // Record ID & Check Icon (Row)
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        // Record ID Code
                                                        Text(
                                                          'RECORD_0x${goal.id?.substring(0, 3).toUpperCase() ?? "000"}',
                                                          style: TextStyle(
                                                            color: limeColor
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                ),
                                                            fontSize: 10,
                                                            fontFamily:
                                                                'Courier',
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        if (isPureFinance)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  2,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: colors
                                                                      .accent,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                            child: const Icon(
                                                              Icons.check,
                                                              color:
                                                                  Colors.white,
                                                              size: 14,
                                                            ),
                                                          )
                                                        else
                                                          const Icon(
                                                            Icons.check_circle,
                                                            color: limeColor,
                                                            size: 20,
                                                          ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    // Goal Amount (Right aligned below)
                                                    Text(
                                                      '${NumberFormat.decimalPattern('ko_KR').format(goal.totalGoal)}원',
                                                      style: TextStyle(
                                                        color: limeColor
                                                            .withValues(
                                                              alpha: 0.6,
                                                            ),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily: 'Courier',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            // Stats Chips
                                            if (stats.isNotEmpty) ...[
                                              Text(
                                                'Resisted Temptations:',
                                                style: TextStyle(
                                                  color: isPureFinance
                                                      ? colors.textSub
                                                      : Colors.white60,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: stats.entries.map((
                                                  e,
                                                ) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isPureFinance
                                                          ? colors.background
                                                          : Colors.white
                                                                .withAlpha(13),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: Border.all(
                                                        color: isPureFinance
                                                            ? colors.border
                                                            : Colors.white10,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          _getCategoryIcon(
                                                            e.key,
                                                            i18n,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${i18n.categoryName(e.key)} x${e.value}',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
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
                        ),
                      );
                    },
                  ),

                  // Bottom Action Bar
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    bottom: _isEditing ? 0 : -100,
                    left: 0,
                    right: 0,
                    child: GlassCard(
                      width: double.infinity,
                      height: 80,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => _selectAll(
                                achievedGoals.map((e) => e.id!).toList(),
                              ),
                              child: Text(
                                i18n.isKorean
                                    ? (_selectedIds.length ==
                                              achievedGoals.length
                                          ? '선택 해제'
                                          : '전체 선택')
                                    : (_selectedIds.length ==
                                              achievedGoals.length
                                          ? 'Deselect All'
                                          : 'Select All'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _selectedIds.isEmpty
                                  ? null
                                  : _deleteSelected,
                              child: Text(
                                i18n.isKorean
                                    ? '삭제 (${_selectedIds.length})'
                                    : 'Delete (${_selectedIds.length})',
                                style: TextStyle(
                                  color: _selectedIds.isEmpty
                                      ? Colors.white30
                                      : Colors.redAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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

// Ghost Grid Painter
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.01)
      ..strokeWidth = 0.5;

    const double spacing = 24.0;

    // Vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
