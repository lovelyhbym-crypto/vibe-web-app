import 'package:flutter/services.dart'; // HapticFeedback
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [Fix] Global check date
import 'package:nerve/features/wishlist/domain/wishlist_model.dart';

import 'package:nerve/core/utils/i18n.dart';
import 'package:nerve/core/services/sound_service.dart';

import 'package:nerve/features/wishlist/providers/wishlist_provider.dart';
import 'package:nerve/features/wishlist/presentation/add_wishlist_dialog.dart';
import 'package:nerve/core/ui/bouncy_button.dart';
import 'package:nerve/core/theme/app_theme.dart';
import 'package:nerve/core/theme/theme_provider.dart';
import 'package:nerve/features/dashboard/providers/reward_state_provider.dart';
import 'package:nerve/features/wishlist/presentation/widgets/quest_status_card.dart';
import 'package:nerve/features/wishlist/presentation/widgets/wishlist_card.dart';
import 'package:nerve/features/home/providers/navigation_provider.dart';
import 'package:nerve/features/saving/providers/saving_provider.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen>
    with WidgetsBindingObserver {
  late ConfettiController _confettiController;
  final GlobalKey _buttonKey = GlobalKey(); // For Overlay Positioning
  int _animationTriggerId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // [System Stabilization] Record access once on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishlistProvider.notifier).checkAccess();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetAnimation();
    }
  }

  void _resetAnimation() {
    if (mounted) {
      setState(() {
        _animationTriggerId++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // [Animation Engine] Trigger gauge animation when switching to this tab
    ref.listen(navigationIndexProvider, (previous, next) {
      if (next == 1) {
        // Index 1 is Wishlist Tab
        _resetAnimation();
      }
    });

    // RewardState 감시하여 폭죽 트리거가 켜지면 실행
    ref.listen(rewardStateProvider, (previous, next) {
      if (next.isTriggered) {
        // [Massive Boom] 화면 전환 애니메이션 후 터지도록 지연 시간 추가
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _confettiController.play();
            // 재생 시작 후 상태 소비
            ref.read(rewardStateProvider.notifier).consumeConfetti();
          }
        });
      }
    });

    // Check for deferred shatter effect (Passive check for navigation arrival)
    final rewardState = ref.watch(rewardStateProvider);
    if (rewardState.isShatterTriggered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Delay to allow screen transition to complete visually
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && ref.read(rewardStateProvider).isShatterTriggered) {
            SoundService().playShatter();
            HapticFeedback.heavyImpact();
            // Consume the trigger so it doesn't play again
            ref.read(rewardStateProvider.notifier).consumeShatter();
          }
        });
      });
    }

    final wishlistAsync = ref.watch(wishlistProvider);
    final savingsAsync = ref.watch(savingProvider);
    final i18n = I18n.of(context);
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final themeMode = ref.watch(themeNotifierProvider);
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(
              i18n.wishlistTitle,
              style: TextStyle(
                color: colors.textMain,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: colors.background,
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: colors.textMain),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
          body: wishlistAsync.when(
            data: (wishlist) {
              final activeWishlist = wishlist
                  .where(
                    (item) =>
                        !item.isAchieved &&
                        item.id != null &&
                        item.id!.isNotEmpty,
                  )
                  .toList();

              final achievedCount = wishlist
                  .where((item) => item.isAchieved)
                  .length;

              Widget buildBanner() {
                return BouncyButton(
                  onTap: () => context.push('/achieved-goals'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.border.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "나의 성공 기록",
                                style: TextStyle(
                                  color: colors.textMain,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    "총 $achievedCount개 목표 달성",
                                    style: TextStyle(
                                      color: colors.textSub,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: isPureFinance ? colors.textSub : colors.accent,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // [Survival Check] Banner Widget
              Widget buildSurvivalCheckBanner() {
                final now = DateTime.now();
                final isAfter8PM = now.hour >= 20;

                // 이미 오늘 체크했는지 확인하려면 리스트의 첫 번째 아이템(혹은 대표)을 확인해야 함.
                if (activeWishlist.isEmpty) return const SizedBox.shrink();
                final targetItem = activeWishlist.first;

                // [Fix] Use FutureBuilder to check global survival check date
                return FutureBuilder<bool>(
                  future: () async {
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final lastCheckStr = prefs.getString(
                        'last_survival_check_date',
                      );
                      if (lastCheckStr != null) {
                        final lastCheck = DateTime.parse(lastCheckStr);
                        final today = DateTime(now.year, now.month, now.day);
                        final lastCheckDay = DateTime(
                          lastCheck.year,
                          lastCheck.month,
                          lastCheck.day,
                        );
                        return today.isAtSameMomentAs(lastCheckDay);
                      }
                      return false;
                    } catch (e) {
                      debugPrint('Error reading survival check date: $e');
                      return false;
                    }
                  }(),
                  builder: (context, snapshot) {
                    final isCheckedToday = snapshot.data ?? false;

                    if (isCheckedToday) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFFD4FF00,
                            ).withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFD4FF00,
                              ).withValues(alpha: 0.1),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFFD4FF00),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.0,
                                ),
                                children: [
                                  TextSpan(
                                    text: "[ZERO] ",
                                    style: TextStyle(color: Color(0xFFD4FF00)),
                                  ),
                                  TextSpan(
                                    text: "동기화 완료",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        BouncyButton(
                          onTap: isAfter8PM
                              ? () async {
                                  // Trigger Logic
                                  await ref
                                      .read(wishlistProvider.notifier)
                                      .performSurvivalCheck(targetItem.id!);

                                  if (mounted) {
                                    _confettiController.play();

                                    // [Fix] Trigger flash animation
                                    _resetAnimation();

                                    // [Show Overlay]
                                    _showBonusOverlay();

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            '오늘의 무지출 데이터가 엔진에 기록되었습니다. 자산 효율이 상승합니다.',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          duration: const Duration(seconds: 3),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: colors.accent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              : () {},
                          child: Container(
                            key: _buttonKey, // Attach Key
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isAfter8PM
                                  ? Colors.black
                                  : Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isAfter8PM
                                    ? colors.accent
                                    : colors.textSub.withValues(alpha: 0.2),
                                width: isAfter8PM ? 2 : 1,
                              ),
                              boxShadow: isAfter8PM
                                  ? [
                                      BoxShadow(
                                        color: colors.accent.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isAfter8PM
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.verified_user_outlined,
                                      color: isAfter8PM
                                          ? colors.accent
                                          : colors.textSub,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      isAfter8PM ? "무지출 데이터 확정" : "생존 보고 대기 중",
                                      style: TextStyle(
                                        color: isAfter8PM
                                            ? colors.accent
                                            : colors.textSub,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isAfter8PM) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    "20시 이후에 무지출 인증이 가능합니다 (현재: ${now.hour}시)",
                                    style: TextStyle(
                                      color: colors.textSub,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (isAfter8PM)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Text(
                              "> 오늘 지출이 없는 경우 버튼을 눌러 무지출을 인증하세요.",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              }

              return CustomScrollView(
                slivers: [
                  if (activeWishlist.isEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        child: Column(
                          children: [
                            buildBanner(),
                            const SizedBox(height: 16),
                            buildSurvivalCheckBanner(),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 100),
                          const Icon(
                            Icons.favorite_border,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            i18n.wishlistEmpty,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = activeWishlist[index];
                        return WishlistCard(
                          item: item,
                          animationTriggerId: _animationTriggerId,
                        );
                      }, childCount: activeWishlist.length),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        child: buildBanner(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: buildSurvivalCheckBanner(),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),

                    // [Quest] 깨진 아이템이 있다면 목표 탭 최하단에 노출
                    // [Quest] Priority Engine: 가장 긴급한 퀘스트 하나만 노출
                    SliverToBoxAdapter(
                      child: wishlistAsync.maybeWhen(
                        data: (list) {
                          final activeItems = list
                              .where((item) => !item.isAchieved)
                              .toList();

                          if (activeItems.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          // 우선순위 정렬 (Enum 순서: broken, highBlur, lowBlur, none)
                          activeItems.sort(
                            (a, b) =>
                                a.priority.index.compareTo(b.priority.index),
                          );

                          final urgentItem = activeItems.first;

                          // P3(None)은 노출하지 않음
                          if (urgentItem.priority != WishlistPriority.none) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 24, // 좀 더 여유 있게
                              ),
                              child: QuestStatusCard(item: urgentItem),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          floatingActionButton: wishlistAsync.when(
            data: (wishlist) {
              final activeWishlist = wishlist.where((item) => !item.isAchieved);
              // 단일 목표 제한: 활성 목표가 없을 때만 FAB 노출
              if (activeWishlist.isNotEmpty) return const SizedBox.shrink();

              return BouncyButton(
                onTap: () => _showAddDialog(context, ref),
                child: Container(
                  decoration: isPureFinance
                      ? null
                      : BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.accent.withValues(alpha: 0.5),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                  child: FloatingActionButton(
                    heroTag: 'wishlist_add_fab',
                    onPressed: () => _showAddDialog(context, ref),
                    backgroundColor: isPureFinance
                        ? colors.accent
                        : const Color(0xFFD4FF00),
                    elevation: 0,
                    shape: const CircleBorder(),
                    child: Icon(
                      Icons.add,
                      color: isPureFinance ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        // Massive Confetti Layer
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
              Colors.red,
              Colors.yellow,
              Colors.cyan,
              Color(0xFFD4FF00),
            ],
            emissionFrequency: 0.1,
            numberOfParticles: 100,
            gravity: 0.05,
            maxBlastForce: 40,
            minBlastForce: 20,
            particleDrag: 0.05,
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddWishlistDialog(),
    );
  }

  void _showBonusOverlay() {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy - 60, // Above the button
        width: size.width,
        child: Material(
          color: Colors.transparent,
          child: _BonusOverlayWidget(
            onAnimationComplete: () {
              entry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(entry);
  }
}

class _BonusOverlayWidget extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const _BonusOverlayWidget({required this.onAnimationComplete});

  @override
  State<_BonusOverlayWidget> createState() => _BonusOverlayWidgetState();
}

class _BonusOverlayWidgetState extends State<_BonusOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_controller);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: const Offset(0, -1.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward().then((_) {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Center(
          child: Text(
            "+1% UP!",
            style: TextStyle(
              color: Colors.lightGreenAccent, // Neon Green
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.green.withValues(alpha: 0.8),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
