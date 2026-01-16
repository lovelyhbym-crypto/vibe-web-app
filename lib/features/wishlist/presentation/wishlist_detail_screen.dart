import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/background_gradient.dart';
import '../../../core/ui/glass_card.dart';
import '../../../core/utils/i18n.dart';
import '../../wishlist/domain/wishlist_model.dart';
import '../providers/wishlist_provider.dart';
import 'package:vive_app/core/theme/theme_provider.dart';
import 'package:vive_app/core/theme/app_theme.dart';

class WishlistDetailScreen extends ConsumerStatefulWidget {
  final WishlistModel item;

  const WishlistDetailScreen({super.key, required this.item});

  @override
  ConsumerState<WishlistDetailScreen> createState() =>
      _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends ConsumerState<WishlistDetailScreen> {
  late TextEditingController _commentController;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.item.comment);
    _commentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _commentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final original = widget.item.comment ?? '';
    final current = _commentController.text;
    setState(() {
      _hasChanges = original != current;
    });
  }

  Future<void> _saveComment() async {
    if (!_hasChanges || widget.item.id == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      FocusScope.of(context).unfocus(); // Close keyboard

      await ref
          .read(wishlistProvider.notifier)
          .updateComment(widget.item.id!, _commentController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  '나의 다짐이 저장되었습니다!',
                  style: TextStyle(
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
              side: const BorderSide(color: Colors.greenAccent, width: 2),
            ),
          ),
        );
        setState(() {
          _hasChanges = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final item = widget.item;
    final progress = item.totalGoal > 0
        ? (item.savedAmount / item.totalGoal).clamp(0.0, 1.0)
        : 0.0;
    final remaining = item.totalGoal - item.savedAmount;

    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final themeMode = ref.watch(themeNotifierProvider);
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;

    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: isPureFinance ? colors.background : Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: item.imageUrl != null ? 300 : 60,
              pinned: true,
              backgroundColor: isPureFinance
                  ? colors.background
                  : Colors.transparent,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isPureFinance ? Colors.black : Colors.black87,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isSaving ? null : _saveComment,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Icon(
                            Icons.check,
                            color: isPureFinance
                                ? Colors.black
                                : Colors.black87,
                            size: 28,
                          ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: item.imageUrl != null
                    ? TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: progress),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutExpo,
                        builder: (context, value, child) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              // (A) 베이스: 흑백 이미지
                              ColorFiltered(
                                colorFilter: const ColorFilter.matrix([
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                                child: Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // (B) 오버레이: ShaderMask를 통한 컬러 복원
                              ShaderMask(
                                shaderCallback: (rect) {
                                  return LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    stops: [value, value],
                                    colors: const [
                                      Colors.white,
                                      Colors.transparent,
                                    ],
                                  ).createShader(rect);
                                },
                                blendMode: BlendMode.dstIn,
                                child: Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          );
                        },
                      )
                    : null,
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isPureFinance ? colors.textMain : Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Price Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '총 가격',
                              style: TextStyle(
                                color: isPureFinance
                                    ? colors.textSub
                                    : Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              i18n.formatCurrency(item.totalGoal),
                              style: TextStyle(
                                color: isPureFinance
                                    ? colors.textMain
                                    : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '남은 금액',
                              style: TextStyle(
                                color: isPureFinance
                                    ? colors.textSub
                                    : Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              i18n.formatCurrency(remaining),
                              style: TextStyle(
                                color: isPureFinance
                                    ? colors.textMain
                                    : const Color(
                                        0xFFCCFF00,
                                      ), // Pure: Black, Cyber: Lime
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Progress Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toInt()}% 달성',
                              style: TextStyle(
                                color: isPureFinance
                                    ? colors.textMain
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isPureFinance
                              ? colors.border
                              : Colors.grey[800],
                          color: isPureFinance
                              ? colors.accent
                              : const Color(
                                  0xFFCCFF00,
                                ), // Pure: Blue, Cyber: Lime
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Comment Section (Editable)
                    Text(
                      '나의 다짐',
                      style: TextStyle(
                        color: isPureFinance ? colors.textMain : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _commentController,
                            maxLines: 4,
                            minLines: 1,
                            style: TextStyle(
                              color: isPureFinance
                                  ? colors.textMain
                                  : Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            readOnly: item.isAchieved || progress >= 1.0,
                            decoration: InputDecoration(
                              hintText: (item.isAchieved || progress >= 1.0)
                                  ? "달성 완료된 다짐입니다"
                                  : "미래의 나에게 보내는 응원 메시지",
                              hintStyle: TextStyle(
                                color: isPureFinance
                                    ? colors.textSub
                                    : Colors.white30,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              fillColor: isPureFinance
                                  ? colors.surface
                                  : Colors.transparent,
                              filled: isPureFinance,
                            ),
                            cursorColor: isPureFinance
                                ? colors.textSub
                                : const Color(
                                    0xFFCCFF00,
                                  ), // Pure: Grey, Cyber: Lime
                          ),
                          if (_hasChanges)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '저장하려면 상단 체크 버튼을 눌러주세요',
                                style: TextStyle(
                                  color: isPureFinance
                                      ? colors.textSub
                                      : const Color(0xFFCCFF00).withAlpha(
                                          179,
                                        ), // Pure: Grey, Cyber: Lime
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
