import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/ui/glass_card.dart';
import '../../../../core/utils/i18n.dart';
import '../../domain/wishlist_model.dart';
import '../../../../core/ui/full_image_viewer.dart';

class AchievedDetailScreen extends StatelessWidget {
  final WishlistModel item;

  const AchievedDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient (Subtle)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2C2C2C), Colors.black],
              ),
            ),
          ),

          CustomScrollView(
            slivers: [
              // 1. Top Image (Hero) - 50% Height
              SliverAppBar(
                expandedHeight: size.height * 0.5,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  background: GestureDetector(
                    onTap: () {
                      if (item.imageUrl != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FullImageViewer(
                              imageUrl: item.imageUrl!,
                              heroTag:
                                  'achieved_img_${item.id}', // Same tag for seamless transition
                            ),
                          ),
                        );
                      }
                    },
                    child: Hero(
                      tag: 'achieved_img_${item.id}',
                      child: item.imageUrl != null
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[900],
                              child: const Center(
                                child: Icon(
                                  Icons.emoji_events,
                                  size: 80,
                                  color: Colors.white24,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // 2. Content Body
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge & Date
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700), // Gold
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFD700,
                                  ).withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Mission Complete',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat(
                              'yyyy.MM.dd',
                            ).format(item.achievedAt ?? DateTime.now()),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Purchase Info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '구매 가격',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              i18n.formatCurrency(item.totalGoal),
                              style: const TextStyle(
                                color: Color(0xFFCCFF00), // Neon Green
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // My Pledge (Comment)
                      if (item.comment != null && item.comment!.isNotEmpty) ...[
                        const Text(
                          '나의 다짐',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          child: Text(
                            item.comment!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Close Button (Floating)
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => context.pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
                shape: const CircleBorder(),
              ),
            ),
          ),

          // Bottom Close Button (Optional, for easy reach)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white54,
                ),
                label: const Text(
                  '닫기',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
