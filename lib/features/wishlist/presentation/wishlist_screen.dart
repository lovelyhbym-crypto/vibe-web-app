import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

import 'package:vive_app/core/utils/i18n.dart';
import 'package:vive_app/core/providers/wishlist_provider.dart';
import 'package:vive_app/features/wishlist/providers/wishlist_provider.dart';
import 'package:vive_app/features/wishlist/presentation/add_wishlist_dialog.dart';
import 'package:vive_app/core/ui/bouncy_button.dart';
import 'package:vive_app/core/theme/app_theme.dart';
import 'package:vive_app/core/theme/theme_provider.dart';
import 'package:vive_app/features/dashboard/providers/reward_state_provider.dart';
import 'package:vive_app/core/ui/vibe_image_effect.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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

    final wishlistAsync = ref.watch(wishlistStreamProvider);
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
            elevation: 0,
            iconTheme: IconThemeData(color: colors.textMain),
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

              return CustomScrollView(
                slivers: [
                  if (activeWishlist.isEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        child: buildBanner(),
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
                        final progress = item.totalGoal > 0
                            ? (item.savedAmount / item.totalGoal).clamp(
                                0.0,
                                1.0,
                              )
                            : 0.0;

                        final cardcontent = item.imageUrl == null
                            ? Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isPureFinance
                                                    ? const Color(0xFF191F28)
                                                    : colors.textMain,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            i18n.formatCurrency(item.price),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: colors.textMain,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: Icon(
                                              item.isRepresentative
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: item.isRepresentative
                                                  ? const Color(0xFFFFC107)
                                                  : colors.textSub,
                                              size: 22,
                                            ),
                                            onPressed: () => ref
                                                .read(wishlistProvider.notifier)
                                                .setRepresentative(item.id!),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      TweenAnimationBuilder<double>(
                                        key: ValueKey(progress),
                                        tween: Tween<double>(
                                          begin: 0.0,
                                          end: progress,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 1500,
                                        ),
                                        curve: Curves.easeOutExpo,
                                        builder: (context, value, child) {
                                          return LinearProgressIndicator(
                                            value: value,
                                            backgroundColor: colors.border,
                                            color: isPureFinance
                                                ? colors.textMain
                                                : const Color(0xFFD4FF00),
                                            minHeight: 3.0,
                                            borderRadius: BorderRadius.circular(
                                              2.0,
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${(progress * 100).toInt()}% ${i18n.achieved}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isPureFinance
                                                  ? Colors.grey[500]
                                                  : colors.textSub,
                                            ),
                                          ),
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: '남은 금액: ',
                                                  style: TextStyle(
                                                    color: isPureFinance
                                                        ? const Color(
                                                            0xFF8B95A1,
                                                          )
                                                        : Colors.white60,
                                                    fontSize: 12,
                                                    fontWeight: isPureFinance
                                                        ? FontWeight.normal
                                                        : FontWeight.w400,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: i18n.formatCurrency(
                                                    item.totalGoal -
                                                        item.savedAmount,
                                                  ),
                                                  style: TextStyle(
                                                    color: isPureFinance
                                                        ? colors.textMain
                                                        : const Color(
                                                            0xFFD4FF00,
                                                          ),
                                                    fontSize: isPureFinance
                                                        ? 13
                                                        : 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                      child: SizedBox(
                                        height: 160,
                                        width: double.infinity,
                                        child: Hero(
                                          tag: 'wishlist_img_${item.id}',
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final w = constraints.maxWidth;
                                              final h = constraints.maxHeight;
                                              return Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: ColorFiltered(
                                                      colorFilter:
                                                          const ColorFilter.matrix(
                                                            [
                                                              0.2,
                                                              0.5,
                                                              0.1,
                                                              0,
                                                              -30,
                                                              0.2,
                                                              0.5,
                                                              0.1,
                                                              0,
                                                              -30,
                                                              0.2,
                                                              0.5,
                                                              0.1,
                                                              0,
                                                              -30,
                                                              0,
                                                              0,
                                                              0,
                                                              1,
                                                              0,
                                                            ],
                                                          ),
                                                      child: Image.network(
                                                        item.imageUrl!,
                                                        width: w,
                                                        height: h,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  ClipRect(
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      widthFactor: progress,
                                                      child: Image.network(
                                                        item.imageUrl!,
                                                        width: w,
                                                        height: h,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: isPureFinance
                                                        ? const Color(
                                                            0xFF191F28,
                                                          )
                                                        : Colors.white,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                i18n.formatCurrency(item.price),
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: colors.textMain,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                icon: Icon(
                                                  item.isRepresentative
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: item.isRepresentative
                                                      ? const Color(0xFFFFC107)
                                                      : isPureFinance
                                                      ? Colors.grey[400]
                                                      : Colors.white70,
                                                  size: 22,
                                                ),
                                                onPressed: () => ref
                                                    .read(
                                                      wishlistProvider.notifier,
                                                    )
                                                    .setRepresentative(
                                                      item.id!,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          TweenAnimationBuilder<double>(
                                            key: ValueKey(progress),
                                            tween: Tween<double>(
                                              begin: 0.0,
                                              end: progress,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 1500,
                                            ),
                                            curve: Curves.easeOutExpo,
                                            builder: (context, value, child) {
                                              return LinearProgressIndicator(
                                                value: value,
                                                backgroundColor: isPureFinance
                                                    ? colors.border
                                                    : Colors.grey[800],
                                                color: isPureFinance
                                                    ? colors.textMain
                                                    : const Color(0xFFD4FF00),
                                                minHeight: 3.0,
                                                borderRadius:
                                                    BorderRadius.circular(2.0),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${(progress * 100).toInt()}% ${i18n.achieved}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isPureFinance
                                                      ? Colors.grey[500]
                                                      : Colors.white60,
                                                ),
                                              ),
                                              RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: '남은 금액: ',
                                                      style: TextStyle(
                                                        color: isPureFinance
                                                            ? const Color(
                                                                0xFF8B95A1,
                                                              )
                                                            : Colors.white60,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            isPureFinance
                                                            ? FontWeight.normal
                                                            : FontWeight.w400,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: i18n.formatCurrency(
                                                        item.totalGoal -
                                                            item.savedAmount,
                                                      ),
                                                      style: TextStyle(
                                                        color: isPureFinance
                                                            ? colors.textMain
                                                            : const Color(
                                                                0xFFD4FF00,
                                                              ),
                                                        fontSize: isPureFinance
                                                            ? 13
                                                            : 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );

                        final card = BouncyButton(
                          onTap: () =>
                              context.push('/wishlist/detail', extra: item),
                          child: cardcontent,
                        );

                        if (item.id == null) return card;

                        return Dismissible(
                          key: ValueKey(item.id ?? DateTime.now().toString()),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            if (item.id == null) return false;
                            final confirmed = await _showDeleteConfirmation(
                              context,
                            );
                            if (confirmed != true) return false;
                            try {
                              await ref
                                  .read(wishlistProvider.notifier)
                                  .deleteWishlist(item.id!);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('목표가 삭제되었습니다.')),
                                );
                              }
                              return true;
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('삭제 실패: ${e.toString()}'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                              return false;
                            }
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: card,
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
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
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

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('정말 삭제할까요?', style: TextStyle(color: colors.textMain)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소', style: TextStyle(color: colors.textSub)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
