import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vive_app/core/network/supabase_client.dart';
import 'package:vive_app/features/auth/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class FailedDreamsScreen extends ConsumerStatefulWidget {
  const FailedDreamsScreen({super.key});

  @override
  ConsumerState<FailedDreamsScreen> createState() => _FailedDreamsScreenState();
}

class _FailedDreamsScreenState extends ConsumerState<FailedDreamsScreen> {
  late Future<List<Map<String, dynamic>>> _failedDreamsFuture;

  @override
  void initState() {
    super.initState();
    _failedDreamsFuture = _fetchFailedDreams();
  }

  Future<List<Map<String, dynamic>>> _fetchFailedDreams() async {
    final user = ref.read(authProvider).asData?.value;
    if (user == null) return [];

    try {
      final response = await ref
          .read(supabaseProvider)
          .from('failed_wishlists')
          .select()
          .eq('user_id', user.id)
          .order('failed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching failed dreams: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark ominous theme
    const backgroundColor = Color(0xFF121212);
    const cardColor = Color(0xFF1A1A1A);
    const textColor = Colors.white70;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: backgroundColor,
            iconTheme: const IconThemeData(color: textColor),
            title: const Text(
              '망각의 묘지',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            elevation: 0,
            floating: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "당신이 포기한 꿈들이 이곳에 잠들어 있습니다.",
                  style: TextStyle(
                    color: textColor.withOpacity(0.4),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _failedDreamsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: textColor),
                  ),
                );
              }

              final dreams = snapshot.data ?? [];

              if (dreams.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.nightlight_round,
                          size: 48,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '아직 포기한 꿈이 없습니다.',
                          style: TextStyle(
                            color: textColor.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final dream = dreams[index];
                  final title = dream['title'] as String;
                  final savedAmount =
                      (dream['saved_amount'] as num?)?.toDouble() ?? 0.0;
                  final totalGoal =
                      (dream['total_goal'] as num?)?.toDouble() ?? 1.0;

                  final failedAtRaw = dream['failed_at'] as String?;
                  final failedAt = failedAtRaw != null
                      ? DateTime.parse(failedAtRaw)
                      : DateTime.now();

                  // Simulated Resisted Stats (Simple heuristic as we lack JSON data)
                  // We can estimate based on "savedAmount" roughly
                  // e.g., 5000 won ~ 1 coffee.
                  final estimatedCoffee = (savedAmount / 5000).floor();

                  final progress = (savedAmount / totalGoal).clamp(0.0, 1.0);

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white24,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.white24,
                                ),
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                color: Colors.white24,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white10,
                            color: Colors.white30,
                            minHeight: 6,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Details
                        _buildDetailRow(
                          Icons.calendar_today,
                          '사망 일자: ${failedAt.toString().substring(0, 10)}',
                        ),
                        if (estimatedCoffee > 0)
                          _buildDetailRow(
                            Icons.coffee,
                            '참았던 기록: 커피 ${estimatedCoffee}잔 분량',
                          ),
                        _buildDetailRow(
                          Icons.savings,
                          '총 저축액: ${NumberFormat('#,###').format(savedAmount.toInt())}원',
                        ),
                        _buildDetailRow(
                          Icons.remove_circle_outline,
                          '남았던 금액: ${NumberFormat('#,###').format((totalGoal - savedAmount).toInt())}원',
                        ),
                      ],
                    ),
                  );
                }, childCount: dreams.length),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white24),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
