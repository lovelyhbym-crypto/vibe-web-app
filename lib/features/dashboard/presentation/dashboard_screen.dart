import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../wishlist/providers/wishlist_provider.dart';
import '../../../core/utils/i18n.dart';

import '../../../core/ui/background_gradient.dart';

import '../providers/dashboard_provider.dart';
import '../providers/savings_period_provider.dart';
import '../../wishlist/domain/wishlist_model.dart';
import '../providers/total_saved_provider.dart';
import '../providers/achievement_provider.dart';
import '../../../core/ui/glass_card.dart';
import '../../home/providers/navigation_provider.dart';
import '../../vibe_shifter/presentation/vibe_shifter_dialog.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final totalSaved = ref.watch(totalSavedProvider);
    final navIndex = ref.watch(navigationIndexProvider); // Watch nav index

    // Listen for achievement events
    ref.listen<AsyncValue<MilestoneEvent?>>(achievementNotifierProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (event) {
          if (event != null) {
            if (event.milestone == 100) {
              // 100% Milestone: Rhythmic Vibration + Dialog
              HapticFeedback.vibrate();
              Future.delayed(
                const Duration(milliseconds: 200),
                () => HapticFeedback.vibrate(),
              );
              Future.delayed(
                const Duration(milliseconds: 400),
                () => HapticFeedback.vibrate(),
              );
              _showMilestoneDialog(context, event, ref);
            } else {
              // Other Milestones: Short Vibration + Banner
              HapticFeedback.lightImpact();
              _showMilestoneBanner(context, event, ref);
            }
          }
        },
      );
    });

    final i18n = I18n.of(context);
    final wishlistAsync = ref.watch(wishlistProvider);
    final activeGoals =
        wishlistAsync.asData?.value.where((w) => !w.isAchieved).toList() ?? [];

    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            i18n.dashboardTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/settings'),
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: dashboardAsync.when(
          data: (data) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardProvider);
              ref.invalidate(wishlistProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PeriodSelector(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),

                  // Top: Total Saved Card
                  _SummaryCard(totalSaved: totalSaved)
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                  const SizedBox(height: 24),

                  // [NEW] Goal Progress Slider
                  if (activeGoals.isNotEmpty) ...[
                    _GoalCarousel(
                          wishlist: activeGoals,
                          averageDailySavings: data.averageDailySavings,
                          navIndex: navIndex, // Pass navIndex
                        )
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideX(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                  ],

                  // Middle: Weekly Trend
                  if (data.totalSaved > 0)
                    _WeeklyTrendChart(weeklyData: data.weeklyTrend)
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideX(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // Bottom: Category Pie
                  if (data.totalSaved > 0)
                    _CategoryPieChart(categoryData: data.categoryBreakdown)
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withAlpha(128),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child:
              FloatingActionButton(
                    heroTag: 'dashboard_sos_fab',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const VibeShifterDialog(),
                      );
                    },
                    backgroundColor: Colors.redAccent.withAlpha(204),
                    shape: const CircleBorder(),
                    child: const Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        shadows: [
                          BoxShadow(color: Colors.pinkAccent, blurRadius: 8),
                          BoxShadow(color: Colors.red, blurRadius: 12),
                        ],
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 800.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .shimmer(
                    duration: 1200.ms,
                    color: Colors.white54,
                    delay: 2000.ms,
                  ),
        ),
      ),
    );
  }

  void _showMilestoneBanner(
    BuildContext context,
    MilestoneEvent event,
    WidgetRef ref,
  ) {
    Color neonColor;
    String icon;
    if (event.milestone >= 80) {
      neonColor = Colors.redAccent;
      icon = '🔥';
    } else if (event.milestone >= 50) {
      neonColor = Colors.cyanAccent;
      icon = '🏆';
    } else {
      neonColor = Colors.purpleAccent;
      icon = '🎉';
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                      duration: 600.ms,
                    ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    event.message,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: neonColor, width: 2),
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            duration: const Duration(seconds: 2, milliseconds: 500),
          ),
        )
        .closed
        .then((_) {
          ref.read(achievementNotifierProvider.notifier).completeCurrentEvent();
        });
  }

  void _showMilestoneDialog(
    BuildContext context,
    MilestoneEvent event,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MilestoneDialog(event: event),
    ).then((_) {
      ref.read(achievementNotifierProvider.notifier).completeCurrentEvent();
    });
  }
}

class _PeriodSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(savingsPeriodProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoSlidingSegmentedControl<SavingsPeriod>(
        backgroundColor: Colors.transparent,
        thumbColor: Colors.white24,
        groupValue: selectedPeriod,
        children: {
          for (var period in SavingsPeriod.values)
            period: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                period.label,
                style: TextStyle(
                  color: selectedPeriod == period
                      ? const Color(0xFFD4FF00)
                      : Colors.white60,
                  fontWeight: selectedPeriod == period
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
        },
        onValueChanged: (value) {
          if (value != null) {
            ref.read(savingsPeriodProvider.notifier).state = value;
          }
        },
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  final double totalSaved;

  const _SummaryCard({required this.totalSaved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = I18n.of(context);
    final period = ref.watch(savingsPeriodProvider);
    final navIndex = ref.watch(
      navigationIndexProvider,
    ); // Watch nav index locally

    String labelText;
    switch (period) {
      case SavingsPeriod.total:
        labelText = i18n.totalSaved;
        break;
      case SavingsPeriod.yearly:
        labelText = '올해 절약 금액';
        break;
      case SavingsPeriod.monthly:
        labelText = '이번 달 절약 금액';
        break;
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            labelText,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            // key: Added navIndex to force rebuild when tab changes
            key: ValueKey('${totalSaved}_$navIndex'),
            tween: Tween<double>(begin: 0, end: totalSaved),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutExpo,
            builder: (context, value, child) {
              return Text(
                i18n.formatCurrency(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            i18n.keepResisting,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCarousel extends ConsumerStatefulWidget {
  final List<WishlistModel> wishlist;
  final double averageDailySavings;
  final int navIndex;

  const _GoalCarousel({
    required this.wishlist,
    required this.averageDailySavings,
    required this.navIndex,
  });

  @override
  ConsumerState<_GoalCarousel> createState() => _GoalCarouselState();
}

class _GoalCarouselState extends ConsumerState<_GoalCarousel> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wishlist.isEmpty) return const SizedBox.shrink();

    final itemCount = widget.wishlist.length;

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: itemCount,
            onPageChanged: (index) {},
            itemBuilder: (context, index) {
              final item = widget.wishlist[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, childWidget) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.1)).clamp(0.9, 1.0);
                  }
                  return Transform.scale(
                    scale: Curves.easeOut.transform(value),
                    child: childWidget,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: _WishlistProgressCard(
                    topWishlist: item,
                    averageDailySavings: widget.averageDailySavings,
                    navIndex: widget.navIndex, // Pass navIndex
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _PageIndicator(controller: _pageController, count: itemCount),
      ],
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final PageController controller;
  final int count;

  const _PageIndicator({required this.controller, required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final page = controller.hasClients ? (controller.page ?? 0) : 0.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            final selected = (page - index).abs() < 0.5;

            return AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: selected ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).primaryColor
                    : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}

class _WishlistProgressCard extends StatelessWidget {
  final dynamic topWishlist;
  final double averageDailySavings;
  final int navIndex;

  const _WishlistProgressCard({
    required this.topWishlist,
    required this.averageDailySavings,
    required this.navIndex,
  });

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return Colors.greenAccent;
    if (progress >= 0.7) return const Color(0xFFCCFF00); // Lime/Yellow
    if (progress >= 0.4) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final title = topWishlist.title;
    final total = topWishlist.totalGoal;
    final saved = topWishlist.savedAmount;
    final progress = (saved / total).clamp(0.0, 1.0);
    final remaining = total - saved;

    DateTime? prediction;
    if (remaining > 0 && averageDailySavings > 0) {
      final daysToFinish = (remaining / averageDailySavings).ceil();
      prediction = DateTime.now().add(Duration(days: daysToFinish));
    }

    final progressColor = _getProgressColor(progress);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.flag, color: Colors.grey[400]),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: progressColor,
                  fontSize: 24,
                ),
              ),
              Text(
                '₩${saved.toStringAsFixed(0)} / ₩${total.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            // key: Added navIndex to force rebuild
            key: ValueKey('${progress}_$navIndex'),
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutExpo,
            builder: (context, value, child) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[800],
                color: progressColor,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
              );
            },
          ),
          if (prediction != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: progressColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: progressColor),
                  const SizedBox(height: 8),
                  Text(
                    ' Estimated completion: ${prediction.year}.${prediction.month}.${prediction.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: progressColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyTrendChart extends StatelessWidget {
  final List<double> weeklyData;

  const _WeeklyTrendChart({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      height: 250,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return Text(
                              '6d ago',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            );
                          case 3:
                            return Text(
                              '3d ago',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            );
                          case 6:
                            return Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: weeklyData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> categoryData;

  const _CategoryPieChart({required this.categoryData});

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) return const SizedBox.shrink();

    final i18n = I18n.of(context);
    final sections = categoryData.entries.map((e) {
      final index = categoryData.keys.toList().indexOf(e.key);
      final color = [
        Colors.blueAccent,
        Colors.redAccent,
        Colors.orangeAccent,
        Colors.purpleAccent,
        Colors.greenAccent,
      ][index % 5];

      return PieChartSectionData(
        color: color,
        value: e.value,
        title: '${i18n.categoryName(e.key)}\n${e.value.toInt()}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return GlassCard(
      height: 300,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Temptations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneDialog extends StatefulWidget {
  final MilestoneEvent event;

  const _MilestoneDialog({required this.event});

  @override
  State<_MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<_MilestoneDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.event.milestone == 100;

    return Stack(
      alignment: Alignment.center,
      children: [
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSuccess
                      ? '🎆'
                      : (widget.event.milestone == 80 ? '🔥' : '🏆'),
                  style: const TextStyle(fontSize: 48),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                      widget.event.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .moveY(begin: 20, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (isSuccess) {
                      // TODO: Navigate to Victory/Success recording screen or update status
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess
                        ? const Color(0xFFFFD700)
                        : Theme.of(context).primaryColor, // Gold for success
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: Text(isSuccess ? '승리 기록하러 가기' : '확인'),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }
}
