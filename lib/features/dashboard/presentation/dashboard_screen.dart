import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nerve/features/wishlist/providers/wishlist_provider.dart';
import 'package:nerve/core/utils/i18n.dart';

import 'package:nerve/core/theme/app_theme.dart';

import 'package:nerve/features/dashboard/providers/dashboard_provider.dart';
import 'package:nerve/features/dashboard/providers/savings_period_provider.dart';
import 'package:nerve/features/wishlist/domain/wishlist_model.dart';
import 'package:nerve/features/dashboard/providers/total_saved_provider.dart';
import 'package:nerve/features/dashboard/providers/achievement_provider.dart';
import 'package:nerve/features/home/providers/navigation_provider.dart';
import 'package:nerve/features/vibe_shifter/presentation/vibe_shifter_dialog.dart';

import 'package:nerve/core/theme/theme_provider.dart';
import 'package:nerve/features/auth/providers/user_profile_provider.dart';

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
    final wishlistState = ref.watch(wishlistProvider);
    final activeGoals =
        wishlistState.valueOrNull?.where((w) => !w.isAchieved).toList() ?? [];

    // [New] Get current theme colors
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          i18n.dashboardTitle,
          style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: colors.textMain),
            onPressed: () => context.push('/settings'),
          ),
        ],
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textMain),
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
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                ],

                // Middle: Weekly Trend
                if (data.totalSaved > 0)
                  _WeeklyTrendChart(
                    weeklyData: data.weeklyTrend,
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Bottom: Category Pie
                if (data.totalSaved > 0)
                  _CategoryPieChart(
                    categoryData: data.categoryBreakdown,
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1, end: 0),

                const SizedBox(height: 48),

                // [Ghost Data] The Ghost of Failed Dreams
                Consumer(
                  builder: (context, ref, _) {
                    final userProfile = ref
                        .watch(userProfileNotifierProvider)
                        .valueOrNull;
                    final failedCount = userProfile?.failedCount ?? 0;

                    if (failedCount == 0) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24, left: 16),
                      child: GestureDetector(
                        onTap: () {
                          // [Sound] Play Low Pitch Sound
                          // await rumble.playLowPitch();
                          HapticFeedback.heavyImpact();
                          context.push('/failed-dreams');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 4,
                              color: colors.textSub.withValues(alpha: 0.25),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '포기한 꿈: $failedCount개',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: colors.textSub.withValues(alpha: 0.25),
                                fontSize: 11,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton:
          FloatingActionButton(
                heroTag: 'dashboard_sos_fab',
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible:
                        true, // [SOS UX Fix] Enable tap-to-dismiss
                    barrierLabel: '', // [SOS UX Fix] Explicit barrier label
                    builder: (context) => const VibeShifterDialog(),
                  );
                },
                backgroundColor: colors.danger,
                elevation: 0,
                shape: const CircleBorder(),
                child: const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 800.ms,
                curve: Curves.easeInOut,
              ),
    );
  }

  void _showMilestoneBanner(
    BuildContext context,
    MilestoneEvent event,
    WidgetRef ref,
  ) {
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final isPureFinance = colors is PureFinanceColors;

    // 1. 기존 배너를 즉시 제거하여 공백/중복 현상 해결
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    Color neonColor;
    if (event.milestone >= 80) {
      neonColor = const Color(0xFF00FF00); // 네온 초록
    } else if (event.milestone >= 50) {
      neonColor = const Color(0xFFD4FF00); // 네온 노랑
    } else {
      neonColor = colors.accent;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: isPureFinance
                ? colors.surface
                : (event.milestone >= 50 ? neonColor : const Color(0xFF1E1E1E)),
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isPureFinance ? colors.border : neonColor,
                width: 2,
              ),
            ),
            content: Row(
              mainAxisSize: MainAxisSize.min, // 레이아웃 에러 방지
              children: [
                Text(
                  event.milestone >= 50 ? '🏆' : '🎉',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 16),
                Flexible(
                  fit: FlexFit.loose,
                  child: Text(
                    event.message,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      // [시인성 핵심] 토스에선 진회색, 사이버펑크 밝은 배경에선 검정색 글씨
                      color: isPureFinance
                          ? colors.textMain
                          : (event.milestone >= 50
                                ? Colors.black
                                : Colors.white),
                    ),
                  ),
                ),
              ],
            ),
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
    var selectedPeriod = ref.watch(savingsPeriodProvider);
    // Safety check for Hot Reload/enum changes:
    if (!SavingsPeriod.values.contains(selectedPeriod)) {
      selectedPeriod = SavingsPeriod.values.first;
    }

    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final isPureFinance = colors is PureFinanceColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: CupertinoSlidingSegmentedControl<SavingsPeriod>(
        backgroundColor: Colors.transparent,
        thumbColor: colors.accent,
        groupValue: selectedPeriod,
        children: {
          for (var period in SavingsPeriod.values)
            period: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                period.label,
                style: TextStyle(
                  color: selectedPeriod == period
                      ? (isPureFinance ? Colors.white : colors.background)
                      : colors.textSub,
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
    var period = ref.watch(savingsPeriodProvider);
    if (!SavingsPeriod.values.contains(period)) {
      period = SavingsPeriod.values.first;
    }
    final navIndex = ref.watch(
      navigationIndexProvider,
    ); // Watch nav index locally

    // Theme logic
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final themeMode = ref.watch(themeNotifierProvider);
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;

    String labelText;
    switch (period) {
      case SavingsPeriod.today:
        labelText = '오늘 절약 금액';
        break;
      case SavingsPeriod.yearly:
        labelText = '올해 절약 금액';
        break;
      case SavingsPeriod.monthly:
        labelText = '이번 달 절약 금액';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: isPureFinance
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            labelText,
            style: TextStyle(color: colors.textSub, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            key: ValueKey('${totalSaved}_$navIndex'),
            tween: Tween<double>(begin: 0, end: totalSaved),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutExpo,
            builder: (context, value, child) {
              return Text(
                i18n.formatCurrency(value),
                style: TextStyle(
                  color: colors.textMain,
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
              color: isPureFinance ? colors.textMain : colors.accent,
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
    _pageController =
        PageController(); // [Sync] Full width to match summary card
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
        // [Fix] Use SizedBox with explicit height instead of Expanded
        SizedBox(
          height: 280, // Flexible height that adapts to IntrinsicHeight content
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
                    ? Theme.of(
                        context,
                      ).extension<VibeThemeExtension>()!.colors.accent
                    : Theme.of(
                        context,
                      ).extension<VibeThemeExtension>()!.colors.border,
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

  @override
  Widget build(BuildContext context) {
    final title = topWishlist.title;
    final total = topWishlist.totalGoal;
    final saved = topWishlist.savedAmount;
    final penalty = topWishlist.penaltyAmount ?? 0.0;
    final progress = total > 0 ? ((saved - penalty) / total) : 0.0;

    // Theme logic
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final isPureFinance = colors is PureFinanceColors;

    final imageUrl = topWishlist.imageUrl;
    final remaining = (total - saved).clamp(0, total).toInt();

    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 16,
        ), // [Fix] Added padding for breathing room
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24), // [Sync] Match summary card
          border: Border.all(
            color: isPureFinance
                ? colors.border
                : colors.accent.withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: isPureFinance
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ]
              : [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.05),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Scanline Texture Overlay (Only for Cyberpunk/Vibe mode)
            if (!isPureFinance)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.05),
                        ],
                        stops: const [0.5, 0.5],
                        tileMode: TileMode.repeated,
                        transform: const GradientRotation(0.1),
                      ),
                      backgroundBlendMode: BlendMode.overlay,
                    ),
                  ),
                ),
              ),

            TweenAnimationBuilder<double>(
              key: ValueKey('${progress}_$navIndex'),
              tween: Tween<double>(begin: 0.0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1 & 2. Upper Quadrant: Image & Title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Frame
                        Container(
                          width: 85, // [Sync] Scaled up for larger card
                          height: 85, // [Sync] Scaled up for larger card
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPureFinance
                                  ? colors.border
                                  : colors.accent.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) => Icon(
                                    Icons.image_not_supported,
                                    color: colors.textSub,
                                  ),
                                )
                              : Container(
                                  color: colors.border.withValues(alpha: 0.3),
                                  child: Icon(
                                    Icons.flag,
                                    color: colors.textSub,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12), // [Fix] Consistent spacing
                        // Title & Percentage
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and Percentage Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: colors.textMain,
                                        letterSpacing: -0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Percentage Display (Top Right)
                                  Container(
                                    padding: const EdgeInsets.only(
                                      left: 4.0,
                                      right: 0.0,
                                    ),
                                    child: Text(
                                      '${(animatedProgress * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w300,
                                        color: animatedProgress < 0
                                            ? colors.danger
                                            : (isPureFinance
                                                  ? colors.accent
                                                  : colors.accent),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12), // [Fix] Consistent rhythm
                    // Status Message (Above Gauge)
                    if (!isPureFinance)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.accent,
                                shape: BoxShape.circle,
                              ),
                            ), // [Fix] Removed infinite animation to prevent freeze
                            const SizedBox(width: 6),
                            Text(
                              '실시간 저축 분석중...',
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.accent.withValues(alpha: 0.7),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (isPureFinance)
                      const SizedBox(height: 10) // [Redesign] 16 -> 10
                    else
                      const SizedBox(height: 10),

                    // 3. Middle Quadrant: Wide Laser Gauge + Ruler
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          children: [
                            Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                // Background Bar
                                Container(
                                  height: 12,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isPureFinance
                                        ? colors.border.withValues(alpha: 0.3)
                                        : Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                // Active Laser Bar
                                Builder(
                                  builder: (context) {
                                    final safeProgress = animatedProgress.clamp(
                                      0.0,
                                      1.0,
                                    );
                                    // [Fix] Use constraints.maxWidth for accurate gauge width
                                    final barWidth =
                                        constraints.maxWidth * safeProgress;

                                    return Stack(
                                      alignment: Alignment.centerRight,
                                      children: [
                                        // Neon Glow (Blur)
                                        if (!isPureFinance &&
                                            safeProgress > 0.05)
                                          Container(
                                            height: 12,
                                            width: barWidth,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colors.accent
                                                      .withValues(alpha: 0.6),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        // Main Bar (Laser)
                                        Container(
                                          height: 12,
                                          width: barWidth,
                                          decoration: BoxDecoration(
                                            gradient: isPureFinance
                                                ? null
                                                : LinearGradient(
                                                    colors: [
                                                      colors.accent.withValues(
                                                        alpha: 0.7,
                                                      ),
                                                      colors.accent,
                                                    ],
                                                  ),
                                            color: isPureFinance
                                                ? colors.accent
                                                : null,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Ruler Notches
                            if (!isPureFinance)
                              SizedBox(
                                height: 8,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(21, (index) {
                                    final isMajor =
                                        index % 2 == 0; // 0, 10, 20...
                                    return Container(
                                      width: 1,
                                      height: isMajor ? 6 : 3,
                                      color: Colors.white.withValues(
                                        alpha: isMajor ? 0.3 : 0.1,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16), // [Fix] Consistent rhythm
                    // 4. Bottom Quadrant: Data Reality
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // [Sync] Sharp alignment
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Current / Target Amount (Left side - 60% width)
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '현재 금액 / 목표 금액',
                                style: TextStyle(
                                  color:
                                      (isPureFinance
                                              ? const Color(0xFF8B95A1)
                                              : Colors
                                                    .white70) // [Readability] Increased opacity
                                          .withValues(alpha: 0.75),
                                  fontSize: 7,
                                  fontWeight: FontWeight
                                      .w500, // [Readability] Improved weight
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${NumberFormat.decimalPattern('ko_KR').format(saved)} / ${NumberFormat.decimalPattern('ko_KR').format(total)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isPureFinance
                                      ? colors.textMain
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Courier',
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Remaining Amount (Right Side - 40% width)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '남은 금액',
                                style: TextStyle(
                                  color:
                                      (isPureFinance
                                              ? const Color(0xFF8B95A1)
                                              : Colors
                                                    .white70) // [Readability] Increased opacity
                                          .withValues(alpha: 0.75),
                                  fontSize: 7,
                                  fontWeight: FontWeight
                                      .w500, // [Readability] Improved weight
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              TweenAnimationBuilder<double>(
                                key: ValueKey(
                                  'remaining_${remaining}_$navIndex',
                                ),
                                tween: Tween<double>(
                                  begin: 0,
                                  end: remaining.toDouble(),
                                ),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutExpo,
                                builder: (context, value, child) {
                                  return Text(
                                    NumberFormat.decimalPattern(
                                      'ko_KR',
                                    ).format(value.toInt()),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isPureFinance
                                          ? colors.textMain
                                          : Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTrendChart extends StatelessWidget {
  final List<double> weeklyData;

  const _WeeklyTrendChart({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    // Simple check for pure finance (light mode usually)
    final isPureFinance = Theme.of(context).brightness == Brightness.light;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: isPureFinance
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
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
                                color: colors.textSub,
                              ),
                            );
                          case 3:
                            return Text(
                              '3d ago',
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textSub,
                              ),
                            );
                          case 6:
                            return Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.textSub,
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
                    color: isPureFinance ? colors.accent : colors.accent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: isPureFinance
                          ? colors.accent.withValues(alpha: 0.05)
                          : colors.accent.withValues(alpha: 0.05),
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
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final isPureFinance = Theme.of(context).brightness == Brightness.light;

    // [Filter Logic] Remove 'Defense' categories to focus on 'Temptations'
    final filteredData = Map.fromEntries(
      categoryData.entries.where((e) {
        final key = e.key;
        final normalizedKey = key.replaceAll(
          ' ',
          '',
        ); // Allow fuzzy space matching

        // Exclude defense/asset protection related keys
        if (normalizedKey.contains('유혹방어') ||
            normalizedKey.contains('자산지킴') ||
            key == 'system_optimization') {
          return false;
        }
        return true;
      }),
    );

    if (filteredData.isEmpty) return const SizedBox.shrink();

    final sections = filteredData.entries.map((e) {
      final index = filteredData.keys.toList().indexOf(e.key);
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
        title: '', // Titles disabled
        radius: 40,
        showTitle: false, // [Refactor] Hide overlapping titles
      );
    }).toList();

    return Container(
      height: 400, // Increased height for legend
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: isPureFinance
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Temptations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textMain,
            ),
          ),
          const SizedBox(height: 20),
          // Chart Area
          SizedBox(
            height: 200,
            child: PieChart(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 4,
                startDegreeOffset: 270,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend List Area
          Expanded(
            child: ListView.separated(
              itemCount: filteredData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final key = filteredData.keys.elementAt(index);
                final value = filteredData[key]!;
                final color = [
                  Colors.blueAccent,
                  Colors.redAccent,
                  Colors.orangeAccent,
                  Colors.purpleAccent,
                  Colors.greenAccent,
                ][index % 5];

                return Row(
                  children: [
                    // Neon Indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category Name
                    Expanded(
                      child: Text(
                        i18n.categoryName(key),
                        style: TextStyle(
                          color: colors.textMain,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Amount
                    Text(
                      i18n.formatCurrency(value),
                      style: TextStyle(
                        color: colors.textSub,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
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
    final theme = Theme.of(context);
    final vibeTheme = theme.extension<VibeThemeExtension>();
    final colors = vibeTheme?.colors;
    final isPureFinance = colors is PureFinanceColors;

    return Stack(
      alignment: Alignment.center,
      children: [
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: colors?.surface ?? theme.colorScheme.surface,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors?.textMain ?? Colors.white,
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
                        ? (isPureFinance
                              ? (colors.accent)
                              : const Color(0xFFFFD700))
                        : (isPureFinance
                              ? (colors.border)
                              : theme.primaryColor),
                    foregroundColor: isSuccess
                        ? Colors.white
                        : colors?.textMain,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isSuccess ? '승리 기록하러 가기' : '확인',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
