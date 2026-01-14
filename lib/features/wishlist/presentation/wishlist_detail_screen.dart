import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/background_gradient.dart';
import '../../../core/ui/glass_card.dart';
import '../../../core/utils/i18n.dart';
import '../../wishlist/domain/wishlist_model.dart';
import '../providers/wishlist_provider.dart';

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
    // Use the passed item for static data, but we could also watch the provider if we needed live updates
    final item = widget.item;
    final progress = item.totalGoal > 0
        ? (item.savedAmount / item.totalGoal).clamp(0.0, 1.0)
        : 0.0;
    final remaining = item.totalGoal - item.savedAmount;

    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // Header Image
            SliverAppBar(
              expandedHeight: MediaQuery.of(context).size.height * 0.4,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => context.pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black26,
                  shape: const CircleBorder(),
                ),
              ),
              actions: [
                // Save Button
                AnimatedOpacity(
                  opacity: _hasChanges ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_hasChanges,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: IconButton(
                        onPressed: _isSaving ? null : _saveComment,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFCCFF00),
                          foregroundColor: Colors.black,
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
                            : const Icon(Icons.check),
                      ),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Hero(
                  tag: 'wishlist_img_${item.id}',
                  child: InteractiveViewer(
                    child: item.imageUrl != null
                        ? TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: progress),
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutExpo,
                            builder: (context, value, child) {
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  // 1층: 배경 (완벽한 흑백)
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
                                  // 2층: 컬러 (ShaderMask로 왼쪽만 투명도 해제)
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
                                  // 3층: 스캔 라인 (위치 보정)
                                  if (value < 1.0)
                                    Align(
                                      alignment: Alignment(value * 2 - 1, 0),
                                      child: Container(
                                        width: 2,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.yellowAccent,
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.white24,
                                size: 64,
                              ),
                            ),
                          ),
                  ),
                ),
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
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              i18n.formatCurrency(item.totalGoal),
                              style: const TextStyle(
                                color: Colors.white,
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
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              i18n.formatCurrency(remaining),
                              style: const TextStyle(
                                color: Color(0xFFCCFF00), // Lime
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
                    TweenAnimationBuilder<double>(
                      key: ValueKey(progress),
                      tween: Tween<double>(end: progress),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutExpo,
                      builder: (context, value, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(value * 100).toInt()}% 달성',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: value,
                              backgroundColor: Colors.grey[800],
                              color: const Color(0xFFCCFF00),
                              minHeight: 12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Comment Section (Editable)
                    const Text(
                      '나의 다짐',
                      style: TextStyle(
                        color: Colors.white,
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: "미래의 나에게 보내는 응원 메시지",
                              hintStyle: TextStyle(color: Colors.white30),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            cursorColor: const Color(0xFFCCFF00),
                          ),
                          if (_hasChanges)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '저장하려면 상단 체크 버튼을 눌러주세요',
                                style: TextStyle(
                                  color: const Color(0xFFCCFF00).withAlpha(179),
                                  fontSize: 12,
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
