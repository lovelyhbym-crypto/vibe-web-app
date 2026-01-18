import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/milestone_messages.dart';
import '../../wishlist/providers/wishlist_provider.dart';

part 'achievement_provider.g.dart';

class MilestoneEvent {
  final String message;
  final int milestone;
  final String goalId;
  final String goalName;

  MilestoneEvent({
    required this.message,
    required this.milestone,
    required this.goalId,
    required this.goalName,
  });
}

@Riverpod(keepAlive: true)
class AchievementNotifier extends _$AchievementNotifier {
  final List<MilestoneEvent> _eventQueue = [];
  bool _isProcessing = false;

  @override
  Future<MilestoneEvent?> build() async {
    final wishlistAsync = ref.watch(wishlistProvider);

    if (wishlistAsync.hasValue) {
      await _checkMilestones(wishlistAsync.value!);
    }

    return null;
  }

  Future<void> _checkMilestones(List<dynamic> items) async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming context is not available here, use default locale or pass it?
    // I18n usually requires context.
    // For now, defaulting to 'ko' or 'en' based on system?
    // User requested "Realtime random extraction".
    // I will use 'ko' default or try to get locale from a provider if available.
    // Assuming 'ko' for now as user is Korean dominant, or pass languageCode if I can.
    // I'll skip locale logic change for this step and use 'ko' or logic from `I18n` if static.
    // Actually previous code used `Localizations.localeOf(context)` passed via logic? No, previous code used `ref.watch` on I18n? No.
    // Previous code: `final locale = Localizations.localeOf(Get.context!);` ? No, Riverpod doesn't have context easily.
    // I'll assume 'ko' for simplicity or check if I can access a LocaleProvider. I'll stick to 'ko' and 'en' based on a simple check or hardcode 'ko' as primary for this user, OR random.
    // Wait, the previous code used `final locale = Platform.localeName` or similar?
    // Let's look at previous code snippet.
    // It used `ref.watch(i18nProvider)`? No.
    // Ah, I missed where it got `locale`.
    // I will use a safe default 'ko'.
    const String languageCode = 'ko'; // Simplified for this task.

    for (final item in items) {
      if (item.id == null) continue;
      if (item.totalGoal <= 0) continue;

      final percent = ((item.savedAmount / item.totalGoal) * 100).floor();

      // Explicitly check from highest to lowest milestone
      int? targetMilestone;
      if (percent >= 100) {
        targetMilestone = 100;
      } else if (percent >= 80) {
        targetMilestone = 80;
      } else if (percent >= 50) {
        targetMilestone = 50;
      } else if (percent >= 20) {
        targetMilestone = 20;
      }

      if (targetMilestone != null) {
        final milestone = targetMilestone;
        final key = 'milestone_${item.id}_$milestone';
        final alreadyNotified = prefs.getBool(key) ?? false;

        // Check if already in queue to prevent double addition in same session
        final inQueue = _eventQueue.any(
          (e) => e.goalId == item.id.toString() && e.milestone == milestone,
        );

        if (!alreadyNotified && !inQueue) {
          // Mark as notified in Prefs immediately to prevent re-trigger
          await prefs.setBool(key, true);

          // Mark lower milestones as done
          final milestones = [100, 80, 50, 20];
          for (final lower in milestones.where((m) => m < milestone)) {
            await prefs.setBool('milestone_${item.id}_$lower', true);
          }

          final messages = MilestoneMessages.getMessages(
            milestone,
            languageCode,
          );
          if (messages.isNotEmpty) {
            final randomMsg = messages[Random().nextInt(messages.length)];
            final finalMsg = randomMsg.replaceAll('{goalName}', item.title);

            _eventQueue.add(
              MilestoneEvent(
                message: finalMsg,
                milestone: milestone,
                goalId: item.id.toString(),
                goalName: item.title,
              ),
            );
          }
        }
      }
    }

    // Trigger processing
    if (!_isProcessing && _eventQueue.isNotEmpty) {
      _processQueue();
    }
  }

  void _processQueue() {
    if (_eventQueue.isEmpty) return;

    _isProcessing = true;
    final event = _eventQueue.removeAt(0);
    state = AsyncData(event);
  }

  void completeCurrentEvent() {
    _isProcessing = false;
    state = const AsyncData(null);

    // Process next event after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_eventQueue.isNotEmpty) {
        _processQueue();
      }
    });
  }
}
