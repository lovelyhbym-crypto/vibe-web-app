import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../wishlist/providers/wishlist_provider.dart';

class WishlistStatusWidget extends ConsumerWidget {
  const WishlistStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const limeColor = Color(0xFFD4FF00);
    final wishlistAsync = ref.watch(wishlistProvider);

    final activeGoal = wishlistAsync.asData?.value
        .where((item) => !item.isAchieved)
        .firstOrNull;

    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: () => context.push('/wishlist'),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white12, // Subtle border
              width: 1,
            ),
            // No lime glow for this one to prioritize the Action widget?
            // Or mild glow as requested "All widgets... lime glow".
            boxShadow: [
              BoxShadow(
                color: limeColor.withAlpha(13),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: activeGoal == null
              ? _buildEmptyState()
              : _buildProgressState(activeGoal, limeColor),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add, size: 32, color: Colors.white54),
        SizedBox(height: 8),
        Text(
          "Add Goal",
          style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildProgressState(dynamic goal, Color color) {
    final progress = (goal.savedAmount / goal.totalGoal).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.white12,
                color: color,
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              "$percent%",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            goal.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
