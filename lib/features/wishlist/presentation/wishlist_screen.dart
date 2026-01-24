import 'dart:ui';
import 'package:flutter/services.dart'; // HapticFeedback
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:vive_app/features/wishlist/domain/wishlist_model.dart';

import 'package:vive_app/core/utils/i18n.dart';
import 'package:vive_app/core/services/sound_service.dart';

import 'package:vive_app/features/wishlist/providers/wishlist_provider.dart';
import 'package:vive_app/features/wishlist/presentation/add_wishlist_dialog.dart';
import 'package:vive_app/core/ui/bouncy_button.dart';
import 'package:vive_app/core/theme/app_theme.dart';
import 'package:vive_app/core/theme/theme_provider.dart';
import 'package:vive_app/features/dashboard/providers/reward_state_provider.dart';
import 'package:vive_app/core/ui/vibe_image_effect.dart';
import 'package:vive_app/features/home/providers/navigation_provider.dart';
import 'package:vive_app/features/wishlist/presentation/widgets/quest_status_card.dart';
import 'package:vive_app/features/wishlist/presentation/widgets/wishlist_card.dart';

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
  // Test Variables
  int _testFogDays = 0; // Restored Step-by-Step Fog
  bool _isNightMode = false; // 8시 이후 상황 시뮬레이션
  bool _simulateNoAccess = false; // 미접속 상황 시뮬레이션

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
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
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && ref.read(rewardStateProvider).isShatterTriggered) {
            SoundService().playShatter();
            HapticFeedback.heavyImpact();
            // Consume the trigger so it doesn't play again
            ref.read(rewardStateProvider.notifier).consumeShatter();
          }
        });
      });
    }

    // 탭 전환 감시 (Index 1: 목표 탭)
    ref.listen(navigationIndexProvider, (previous, next) {
      if (next == 1 && previous != 1) {
        _resetAnimation();
      }
    });

    final wishlistAsync = ref.watch(wishlistProvider);
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
              // [Restored] Cloud Button for Step-by-Step Test
              Row(
                children: [
                  if (_testFogDays > 0)
                    Text(
                      '$_testFogDays일',
                      style: TextStyle(
                        color: colors.textMain,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      _testFogDays > 0 ? Icons.cloud : Icons.cloud_queue,
                    ),
                    color: _testFogDays > 0
                        ? Colors.blue.withOpacity(
                            (0.2 * _testFogDays + 0.2).clamp(0.0, 1.0),
                          )
                        : colors.textSub,
                    onPressed: () {
                      setState(() {
                        _testFogDays++;
                        if (_testFogDays > 5) {
                          _testFogDays = 0;
                        }
                      });

                      // [Test logic] Fog Days 변경 시 생존 체크 리셋 & 실제 Blur 처리 (데이터 주입)
                      final wishlist = wishlistAsync.valueOrNull ?? [];
                      final activeItems = wishlist
                          .where((item) => !item.isAchieved && item.id != null)
                          .toList();

                      if (activeItems.isNotEmpty) {
                        final targetId = activeItems.first.id!;

                        // 1. 생존 체크 리셋 (반복 테스트 지원)
                        ref
                            .read(wishlistProvider.notifier)
                            .resetSurvivalCheck(targetId);

                        // 2. 실제 모델 데이터에 Blur Level 주입 (2.0 * days)
                        // Day 1: 2.0 (Low Blur)
                        // Day 2: 4.0
                        // Day 3: 6.0 (High Blur)
                        // ...
                        final newBlurLevel = (_testFogDays * 2.0).clamp(
                          0.0,
                          10.0,
                        );
                        ref
                            .read(wishlistProvider.notifier)
                            .setBlurLevel(targetId, newBlurLevel);
                      }
                    },
                  ),
                ],
              ),
              // Test Menu Button
              PopupMenuButton<String>(
                icon: const Icon(Icons.science),
                onSelected: (value) {
                  setState(() {
                    if (value == 'night_mode') {
                      _isNightMode = !_isNightMode;
                    } else if (value == 'simulate_no_access') {
                      _simulateNoAccess = !_simulateNoAccess;
                    }
                  });
                  // [Test Enhancement] 모드 변경 시 생존 체크 리셋 (재테스트 가능하도록)
                  // 활성화된 첫 번째 아이템의 체크 기록을 초기화
                  final wishlist = wishlistAsync.valueOrNull ?? [];
                  final activeItems = wishlist
                      .where((item) => !item.isAchieved && item.id != null)
                      .toList();
                  if (activeItems.isNotEmpty) {
                    ref
                        .read(wishlistProvider.notifier)
                        .resetSurvivalCheck(activeItems.first.id!);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'night_mode',
                    child: Row(
                      children: [
                        Icon(
                          _isNightMode
                              ? Icons.nightlight_round
                              : Icons.wb_sunny,
                          color: colors.textMain,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isNightMode ? '8시 이후 모드 (ON)' : '8시 이전 모드',
                          style: TextStyle(color: colors.textMain),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'simulate_no_access',
                    child: Row(
                      children: [
                        Icon(
                          _simulateNoAccess
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: colors.textMain,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _simulateNoAccess ? '미접속 시뮬레이션 (ON)' : '정상 모드',
                          style: TextStyle(color: colors.textMain),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                return GestureDetector(
                  onTap: () => context.push('/achieved-goals'),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "나의 성공 기록",
                              style: TextStyle(
                                color: colors.textMain,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "총 $achievedCount개의 목표 달성 완료",
                              style: TextStyle(
                                color: colors.textSub,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: isPureFinance ? colors.textSub : colors.accent,
                          size: 16,
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
                // 여기서는 리스트 전체 중 하나라도 오늘 체크된 게 있으면 '체크 완료'로 간주하거나,
                // 개별 아이템마다 버튼을 두는 게 아니라 '오늘 하루'에 대한 선언이므로
                // 대표 아이템(혹은 첫번째)에 기록한다고 가정?
                // 아니면 performSurvivalCheck를 Global하게?
                // Provider의 performSurvivalCheck는 ID를 받으므로, 활성화된 첫 번째 아이템에 적용하거나
                // 가장 최근에 수정한 아이템? -> 일단 '활성 목표 중 첫 번째'에 적용.
                if (activeWishlist.isEmpty) return const SizedBox.shrink();
                final targetItem = activeWishlist.first;

                bool isCheckedToday = false;
                if (targetItem.lastSurvivalCheckAt != null) {
                  final today = DateTime(now.year, now.month, now.day);
                  final lastCheck = DateTime(
                    targetItem.lastSurvivalCheckAt!.year,
                    targetItem.lastSurvivalCheckAt!.month,
                    targetItem.lastSurvivalCheckAt!.day,
                  );
                  if (today.isAtSameMomentAs(lastCheck)) {
                    isCheckedToday = true;
                  }
                }

                if (isCheckedToday) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          "오늘 생존 완료",
                          style: TextStyle(
                            color: colors.textMain,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GestureDetector(
                  onTap: (isAfter8PM || _isNightMode || _testFogDays > 0)
                      ? () async {
                          // Trigger Logic
                          await ref
                              .read(wishlistProvider.notifier)
                              .performSurvivalCheck(targetItem.id!);

                          // [Test Mode Enhancement]
                          // 테스트 모드(_testFogDays > 0)라면, 버튼 클릭 시 시각적으로 1단계 블러 해제
                          if (mounted && _testFogDays > 0) {
                            setState(() {
                              _testFogDays = (_testFogDays - 1).clamp(0, 10);
                            });
                          }

                          if (mounted) {
                            _confettiController.play();

                            // [Haptic Feedback]
                            HapticFeedback.lightImpact();

                            // [Show Overlay]
                            _showBonusOverlay();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  '🎉 생존 성공! 성공 확률 1% 상승 + 안개 제거 완료!',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: colors.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          }
                        }
                      : null,
                  child: Container(
                    key: _buttonKey, // Attach Key
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: (isAfter8PM || _isNightMode || _testFogDays > 0)
                          ? colors.accent.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isAfter8PM || _isNightMode || _testFogDays > 0)
                            ? colors.accent
                            : colors.textSub.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              color:
                                  (isAfter8PM ||
                                      _isNightMode ||
                                      _testFogDays > 0)
                                  ? colors.accent
                                  : colors.textSub,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              (isAfter8PM || _isNightMode || _testFogDays > 0)
                                  ? "오늘 지출 0원"
                                  : "8시 이후에 생존 보고가 가능합니다",
                              style: TextStyle(
                                color:
                                    (isAfter8PM ||
                                        _isNightMode ||
                                        _testFogDays > 0)
                                    ? colors.textMain
                                    : colors.textSub,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        if (!(isAfter8PM ||
                            _isNightMode ||
                            _testFogDays > 0)) ...[
                          const SizedBox(height: 4),
                          Text(
                            "현재 시각: ${now.hour}시 (20시부터 활성화)",
                            style: TextStyle(
                              color: colors.textSub,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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

                          if (activeItems.isEmpty)
                            return const SizedBox.shrink();

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
                              color: colors.accent.withOpacity(0.5),
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
                Shadow(color: Colors.green.withOpacity(0.8), blurRadius: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
