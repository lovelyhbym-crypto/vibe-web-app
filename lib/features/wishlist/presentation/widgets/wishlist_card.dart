import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vive_app/core/theme/app_theme.dart';
import 'package:vive_app/core/theme/theme_provider.dart';
import 'package:vive_app/core/ui/bouncy_button.dart';
import 'package:vive_app/core/ui/vibe_image_effect.dart';
import 'package:vive_app/core/utils/i18n.dart';
import 'package:vive_app/features/wishlist/domain/wishlist_model.dart';
import 'package:vive_app/features/wishlist/providers/wishlist_provider.dart';

class WishlistCard extends ConsumerWidget {
  final WishlistModel item;
  final int animationTriggerId;

  const WishlistCard({
    super.key,
    required this.item,
    this.animationTriggerId = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = I18n.of(context);
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final themeMode = ref.watch(themeNotifierProvider);
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;

    final progress = item.totalGoal > 0
        ? ((item.savedAmount - item.penaltyAmount) / item.totalGoal)
        : 0.0;

    // Percentage for display
    final percentage = (progress * 100).toInt();

    final cardContent = item.imageUrl == null
        ? _buildNoImageContent(
            context,
            ref,
            i18n,
            colors,
            isPureFinance,
            progress,
            percentage,
          )
        : _buildImageContent(
            context,
            ref,
            i18n,
            colors,
            isPureFinance,
            progress,
            percentage,
          );

    return BouncyButton(
      onTap: () {
        context.push('/wishlist/detail', extra: item);
      },
      child: cardContent,
    );
  }

  Widget _buildNoImageContent(
    BuildContext context,
    WidgetRef ref,
    I18n i18n,
    VibeColors colors,
    bool isPureFinance,
    double progress,
    int percentage,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref, i18n, colors, isPureFinance),
            const SizedBox(height: 12),
            _buildProgressBar(colors, isPureFinance, progress),
            const SizedBox(height: 8),
            _buildFooter(i18n, colors, isPureFinance, progress, percentage),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(
    BuildContext context,
    WidgetRef ref,
    I18n i18n,
    VibeColors colors,
    bool isPureFinance,
    double progress,
    int percentage,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Hero(
                tag: 'wishlist_img_${item.id}',
                child: TweenAnimationBuilder<double>(
                  key: ValueKey('$progress-$animationTriggerId'),
                  tween: Tween<double>(
                    begin: 0.0,
                    end: progress.clamp(0.0, 1.0),
                  ),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return VibeImageEffect(
                      imageUrl: item.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      blurLevel: item.currentBlurPoints,
                      isBroken: item.isBroken,
                      brokenImageIndex: item.brokenImageIndex,
                      progress: value,
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, ref, i18n, colors, isPureFinance),
                const SizedBox(height: 12),
                _buildProgressBar(colors, isPureFinance, progress),
                const SizedBox(height: 12),
                _buildFooter(i18n, colors, isPureFinance, progress, percentage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    I18n i18n,
    VibeColors colors,
    bool isPureFinance,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            item.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isPureFinance ? const Color(0xFF191F28) : colors.textMain,
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
            item.isRepresentative ? Icons.star : Icons.star_border,
            color: item.isRepresentative
                ? const Color(0xFFFFC107)
                : (isPureFinance ? Colors.grey[400] : colors.textSub),
            size: 22,
          ),
          onPressed: () =>
              ref.read(wishlistProvider.notifier).setRepresentative(item.id!),
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    VibeColors colors,
    bool isPureFinance,
    double progress,
  ) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('$progress-$animationTriggerId'),
      tween: Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return LinearProgressIndicator(
          value: value,
          backgroundColor: isPureFinance
              ? colors.border
              : (Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[300]), // Safer default
          color: isPureFinance
              ? colors.textMain
              : (value < 0 ? Colors.redAccent : const Color(0xFFD4FF00)),
          minHeight: 3.0,
          borderRadius: BorderRadius.circular(2.0),
        );
      },
    );
  }

  Widget _buildFooter(
    I18n i18n,
    VibeColors colors,
    bool isPureFinance,
    double progress,
    int percentage,
  ) {
    // Determine default color based on theme and requirements
    // User requested "평소에는 하얀색" (Usually White) for Vibe mode.
    // For PureFinance, we stick to standard text colors (Black/Grey) for readability on white card.
    final defaultColor = isPureFinance ? Colors.grey[500]! : Colors.white;
    final valueColor = isPureFinance ? colors.textMain : Colors.white;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Success Probability
        AnimatedValueText(
          valueKey: percentage,
          text: '성공 확률 : $percentage%',
          defaultColor: defaultColor,
          isNegative: progress < 0,
          baseFontSize: 12,
        ),

        // Remaining Amount
        Row(
          children: [
            Text(
              '남은 금액: ',
              style: TextStyle(
                color: isPureFinance ? const Color(0xFF8B95A1) : Colors.white60,
                fontSize: 12,
                fontWeight: isPureFinance ? FontWeight.normal : FontWeight.w400,
              ),
            ),
            AnimatedValueText(
              valueKey: (item.totalGoal - item.savedAmount).toInt(),
              text: i18n.formatCurrency(item.totalGoal - item.savedAmount),
              defaultColor: valueColor,
              isNegative: false,
              baseFontSize: isPureFinance ? 13 : 12,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ],
    );
  }
}

class AnimatedValueText extends StatefulWidget {
  final int valueKey; // Used to trigger animation on change
  final String text;
  final Color defaultColor;
  final bool isNegative;
  final double baseFontSize;
  final FontWeight fontWeight;

  const AnimatedValueText({
    super.key,
    required this.valueKey,
    required this.text,
    required this.defaultColor,
    this.isNegative = false,
    this.baseFontSize = 12,
    this.fontWeight = FontWeight.normal,
  });

  @override
  State<AnimatedValueText> createState() => _AnimatedValueTextState();
}

class _AnimatedValueTextState extends State<AnimatedValueText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(covariant AnimatedValueText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animations if default color changes (theme switch)
    if (oldWidget.defaultColor != widget.defaultColor) {
      _updateAnimations();
    }

    // Trigger animation if value changes
    if (oldWidget.valueKey != widget.valueKey) {
      _controller.forward(from: 0.0);
    }
  }

  void _updateAnimations() {
    _colorAnim = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: widget.defaultColor,
          end: const Color(0xFFD4FF00), // Neon Green Flash
        ),
        weight: 20, // Fast IN
      ),
      TweenSequenceItem(
        tween: ConstantTween(const Color(0xFFD4FF00)), // Hold Color
        weight: 50, // Stay Green for half the time
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFFD4FF00),
          end: widget.defaultColor,
        ),
        weight: 30, // Slow OUT
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2), // Scale Up
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.2), // Hold Scale
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0), // Scale Down
        weight: 40,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If negative (penalty state), force Red and skip Flash animation?
    // Or flash from Red to Neon Green?
    // Usually penalty text stays Red.
    if (widget.isNegative) {
      return Text(
        widget.text,
        style: TextStyle(
          fontSize: widget.baseFontSize,
          color: Colors.redAccent,
          fontWeight: widget.fontWeight,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: widget.baseFontSize,
              fontWeight: widget.fontWeight,
              color: _controller.isAnimating
                  ? _colorAnim.value
                  : widget.defaultColor,
            ),
          ),
        );
      },
    );
  }
}
