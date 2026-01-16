import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/i18n.dart';
import '../../../core/providers/wishlist_provider.dart';
import '../providers/wishlist_provider.dart';
import 'add_wishlist_dialog.dart';
import '../../../core/ui/bouncy_button.dart';
import 'package:vive_app/core/theme/app_theme.dart';
import 'package:vive_app/core/theme/theme_provider.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistStreamProvider);
    final i18n = I18n.of(context);
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final themeMode = ref.watch(themeNotifierProvider);
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          i18n.wishlistTitle,
          style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold),
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
      // Background color handled by Theme
      body: wishlistAsync.when(
        data: (wishlist) {
          final activeWishlist = wishlist
              .where(
                (item) =>
                    !item.isAchieved && item.id != null && item.id!.isNotEmpty,
              )
              .toList();

          // Log filtering results
          if (activeWishlist.length <
              wishlist.where((i) => !i.isAchieved).length) {
            debugPrint(
              'Filtered out ${wishlist.where((i) => !i.isAchieved).length - activeWishlist.length} items with null IDs',
            );
          }

          final achievedCount = wishlist
              .where((item) => item.isAchieved)
              .length;

          // Widget for the Achievement Banner
          Widget buildBanner() {
            return GestureDetector(
              onTap: () => context.push('/achieved-goals'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                  boxShadow: isPureFinance
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "총 $achievedCount개의 목표 달성 완료",
                          style: TextStyle(color: colors.textSub, fontSize: 14),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: colors.accent,
                      size: 18,
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
                        ? (item.savedAmount / item.totalGoal).clamp(0.0, 1.0)
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
                              border: Border.all(color: colors.border),
                              boxShadow: isPureFinance
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: colors.textMain,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Price Badge (No Image Case)
                                      isPureFinance
                                          ? Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                i18n.formatCurrency(item.price),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: colors.textMain,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              i18n.formatCurrency(item.price),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: colors.textMain,
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
                                        backgroundColor: colors.border,
                                        color: const Color(0xFF003366),
                                        minHeight: 8,
                                        borderRadius: BorderRadius.circular(4),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text:
                                                  '${(progress * 100).toInt()}%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF333D4B),
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' ${i18n.achieved}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colors.textSub,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '남은 금액: ${i18n.formatCurrency(item.totalGoal - item.savedAmount)}',
                                        style: TextStyle(
                                          color: colors.textMain,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
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
                            child: Card(
                              elevation: 0,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: colors.border),
                              ),
                              color: Theme.of(context).cardColor,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Hero(
                                      tag: 'wishlist_img_${item.id}',
                                      child: Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.cover,
                                        color: Colors.black.withAlpha(128),
                                        colorBlendMode: BlendMode.darken,
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
                                              child: Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      item.title,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            isPureFinance
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: BackdropFilter(
                                                      filter: ImageFilter.blur(
                                                        sigmaX: 5,
                                                        sigmaY: 5,
                                                      ),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 4,
                                                            ),
                                                        color: Colors.white
                                                            .withOpacity(0.4),
                                                        child: Text(
                                                          i18n.formatCurrency(
                                                            item.price,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                colors.textMain,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : Text(
                                                    i18n.formatCurrency(
                                                      item.price,
                                                    ),
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: colors.textMain,
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
                                              backgroundColor: Colors.grey[800],
                                              color: isPureFinance
                                                  ? colors.accent
                                                  : const Color(0xFF003366),
                                              minHeight: 8,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${(progress * 100).toInt()}% ${i18n.achieved}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white60,
                                              ),
                                            ),
                                            Text(
                                              '남은 금액: ${i18n.formatCurrency(item.totalGoal - item.savedAmount)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                    final card = BouncyButton(
                      onTap: () =>
                          context.push('/wishlist/detail', extra: item),
                      child: cardcontent,
                    );

                    if (item.id == null) {
                      return card;
                    }

                    return Dismissible(
                      // Ensure key is never null or duplicate
                      key: ValueKey(item.id ?? DateTime.now().toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        if (item.id == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('오류: ID가 없는 항목입니다.')),
                          );
                          return false;
                        }

                        final confirmed = await _showDeleteConfirmation(
                          context,
                        );
                        if (confirmed != true) return false;

                        try {
                          // Call delete with STRICT synchronization
                          await ref
                              .read(wishlistProvider.notifier)
                              .deleteWishlist(item.id!);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('목표가 삭제되었습니다.')),
                            );
                          }
                          return true; // Triggers UI removal
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('삭제 실패: ${e.toString()}'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                          return false; // Snaps back
                        }
                      },
                      onDismissed: (_) {
                        // handled in confirmDismiss and state update
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete, color: Colors.white),
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
                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ), // Bottom padding for FAB
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
      floatingActionButton: BouncyButton(
        onTap: () => _showAddDialog(context, ref),
        child: FloatingActionButton(
          heroTag: 'wishlist_add_fab',
          onPressed: () => _showAddDialog(context, ref),
          backgroundColor: isPureFinance ? colors.accent : colors.accent,
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
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
            style: TextButton.styleFrom(foregroundColor: colors.danger),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
