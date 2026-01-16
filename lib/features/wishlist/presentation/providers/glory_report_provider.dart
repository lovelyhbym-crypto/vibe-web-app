import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../saving/providers/saving_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../../saving/domain/saving_model.dart';
import '../../domain/wishlist_model.dart';
import '../../../../core/services/ai_service.dart';

class GloryReportState {
  final bool has30Savings;
  final bool hasAchieved;
  final bool has3ConsecutiveDays;
  final Map<String, dynamic> aiInputData;
  final String aiReportText; // [NEW] AI Report
  final bool isLoadingAi; // [NEW] Loading State

  bool get isReady => has30Savings && hasAchieved && has3ConsecutiveDays;

  const GloryReportState({
    required this.has30Savings,
    required this.hasAchieved,
    required this.has3ConsecutiveDays,
    this.aiInputData = const {},
    this.aiReportText = '',
    this.isLoadingAi = false,
  });

  GloryReportState copyWith({
    bool? has30Savings,
    bool? hasAchieved,
    bool? has3ConsecutiveDays,
    Map<String, dynamic>? aiInputData,
    String? aiReportText,
    bool? isLoadingAi,
  }) {
    return GloryReportState(
      has30Savings: has30Savings ?? this.has30Savings,
      hasAchieved: hasAchieved ?? this.hasAchieved,
      has3ConsecutiveDays: has3ConsecutiveDays ?? this.has3ConsecutiveDays,
      aiInputData: aiInputData ?? this.aiInputData,
      aiReportText: aiReportText ?? this.aiReportText,
      isLoadingAi: isLoadingAi ?? this.isLoadingAi,
    );
  }
}

// Helper method for AI Data Aggregation
Map<String, dynamic> _prepareAIData(
  List<SavingModel> savings,
  List<WishlistModel> wishlists,
) {
  // 1. Total Saved & Category Counts
  int totalSaved = 0;
  final Map<String, int> categoryCounts = {};

  for (final item in savings) {
    totalSaved += item.amount;
    categoryCounts[item.category] = (categoryCounts[item.category] ?? 0) + 1;
  }

  // 2. Streak Logic (Consecutive Days)
  int currentStreak = 0;
  if (savings.isNotEmpty) {
    final sorted = List<SavingModel>.from(savings)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int tempStreak = 1;
    for (int i = 0; i < sorted.length - 1; i++) {
      final current = sorted[i].createdAt;
      final next = sorted[i + 1].createdAt;

      final currentDate = DateTime(current.year, current.month, current.day);
      final nextDate = DateTime(next.year, next.month, next.day);

      final diff = currentDate.difference(nextDate).inDays;

      if (diff == 1) {
        tempStreak++;
      } else if (diff > 1) {
        break;
      }
    }
    currentStreak = tempStreak;
  }

  // 3. Achieved Wish (Most Recent)
  String achievedWish = "None";
  if (wishlists.isNotEmpty) {
    final achievedList = wishlists.where((item) => item.isAchieved).toList();

    if (achievedList.isNotEmpty) {
      achievedList.sort((a, b) {
        final aTime = a.achievedAt ?? a.createdAt;
        final bTime = b.achievedAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      final recent = achievedList.first;
      achievedWish = "${recent.title} (${recent.totalGoal}원)";
    }
  }

  return {
    "total_saved": totalSaved,
    "top_items": categoryCounts,
    "streak_days": currentStreak,
    "achieved_wish": achievedWish,
    "user_vow": "",
  };
}

class GloryReportNotifier extends StateNotifier<GloryReportState> {
  final Ref ref;
  final AiService aiService;

  GloryReportNotifier({required this.ref, required this.aiService})
    : super(
        const GloryReportState(
          has30Savings: false,
          hasAchieved: false,
          has3ConsecutiveDays: false,
        ),
      ) {
    _init();
  }

  void _init() {
    // Listen to changes
    ref.listen(savingProvider, (_, __) => _updateStats());
    ref.listen(wishlistProvider, (_, __) => _updateStats());
    // Initial fetch
    _updateStats();
  }

  void _updateStats() {
    final savingsAsync = ref.read(savingProvider);
    final wishlistAsync = ref.read(wishlistProvider);

    bool has30Savings = state.has30Savings;
    bool hasAchieved = state.hasAchieved;
    bool has3ConsecutiveDays = state.has3ConsecutiveDays;

    // Containers
    List<SavingModel> savingsData = [];
    List<WishlistModel> wishlistData = [];

    if (savingsAsync.hasValue) {
      final savings = savingsAsync.value!;
      savingsData = savings;
      has30Savings = savings.length >= 30;

      if (savings.isNotEmpty) {
        final sorted = List<SavingModel>.from(savings)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        int consecutive = 1;
        for (int i = 0; i < sorted.length - 1; i++) {
          final diff =
              DateTime(
                    sorted[i].createdAt.year,
                    sorted[i].createdAt.month,
                    sorted[i].createdAt.day,
                  )
                  .difference(
                    DateTime(
                      sorted[i + 1].createdAt.year,
                      sorted[i + 1].createdAt.month,
                      sorted[i + 1].createdAt.day,
                    ),
                  )
                  .inDays;

          if (diff == 1) {
            consecutive++;
            if (consecutive >= 3) {
              has3ConsecutiveDays = true;
              break;
            }
          } else if (diff > 1) {
            consecutive = 1;
          }
        }
        // [DEBUG] CHEAT MODE
        has3ConsecutiveDays = true;
      }
    }

    if (wishlistAsync.hasValue) {
      wishlistData = wishlistAsync.value!;
      hasAchieved = wishlistData.any((item) => item.isAchieved);
    }

    final aiData = _prepareAIData(savingsData, wishlistData);

    state = state.copyWith(
      has30Savings: has30Savings,
      hasAchieved: hasAchieved,
      has3ConsecutiveDays: has3ConsecutiveDays,
      aiInputData: aiData,
    );
  }

  Future<void> generateAiReport() async {
    if (state.isLoadingAi) return;
    if (state.aiReportText.isNotEmpty) return; // Prevent regenerate for now

    state = state.copyWith(isLoadingAi: true);

    try {
      final report = await aiService.generateLifestyleReport(state.aiInputData);

      if (mounted) {
        state = state.copyWith(aiReportText: report, isLoadingAi: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          aiReportText: "시스템 오류로 리포트를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.",
          isLoadingAi: false,
        );
      }
    }
  }

  void resetReport() {
    state = state.copyWith(
      aiReportText: "새로운 분석을 시작할 데이터가 없습니다.",
      isLoadingAi: false,
    );
  }
}

final gloryReportProvider =
    StateNotifierProvider<GloryReportNotifier, GloryReportState>((ref) {
      final aiService = ref.watch(aiServiceProvider);
      return GloryReportNotifier(ref: ref, aiService: aiService);
    });
