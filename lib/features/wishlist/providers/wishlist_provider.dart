import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vive_app/core/network/supabase_client.dart';
import 'package:vive_app/features/auth/providers/auth_provider.dart';
import '../../auth/providers/user_profile_provider.dart';
import '../domain/wishlist_model.dart';

part 'wishlist_provider.g.dart';

class SelectedWishlistIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final selectedWishlistIndexProvider =
    NotifierProvider<SelectedWishlistIndexNotifier, int>(
      SelectedWishlistIndexNotifier.new,
    );

final selectedWishlistIdsProvider = StateProvider<List<String>>((ref) => []);

@Riverpod(keepAlive: true)
class WishlistNotifier extends _$WishlistNotifier {
  // Local storage for guest users
  final List<WishlistModel> _guestWishlist = [];

  @override
  FutureOr<List<WishlistModel>> build() async {
    final authNotifier = ref.watch(authProvider.notifier);
    final user = ref.watch(authProvider).asData?.value;

    if (authNotifier.isGuest || user == null) {
      return _guestWishlist;
    }

    // Fetch from Supabase for logged-in users
    final response = await ref
        .read(supabaseProvider)
        .from('wishlists')
        .select()
        .order('created_at');

    final safeResponse = response
        .where((e) => e['id'] != null && e['id'].toString().isNotEmpty)
        .toList();

    if (safeResponse.length < response.length) {
      debugPrint(
        'Filtered out ${response.length - safeResponse.length} items with invalid IDs from server fetch',
      );
    }

    return safeResponse.map((e) => WishlistModel.fromJson(e)).toList();
  }

  Future<void> addWishlist(WishlistModel item) async {
    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).asData?.value;

    if (authNotifier.isGuest || user == null) {
      // Generate a temporary ID for local items
      final newItem = item.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      _guestWishlist.add(newItem);
      state = AsyncValue.data([..._guestWishlist]);
      return;
    }

    try {
      debugPrint('Adding wishlist item to Supabase: ${item.title}');
      final response = await ref
          .read(supabaseProvider)
          .from('wishlists')
          .insert({...item.toJson(), 'user_id': user.id})
          .select()
          .single();

      debugPrint('Supabase response: $response');

      if (response['id'] == null) {
        throw Exception('서버 오류: ID 생성 실패 (Server returned null ID)');
      }

      final newItem = WishlistModel.fromJson(response);
      final previousList = state.valueOrNull ?? [];
      state = AsyncValue.data([...previousList, newItem]);
    } catch (e) {
      debugPrint('Error adding wishlist item: $e');

      // [PGRST204 Fix] Missing column 'broken_image_index' (or others)
      if (e.toString().contains('PGRST204')) {
        debugPrint('Retrying without new columns (broken_image_index)...');
        try {
          // Remove potential new columns preventing insert
          final safeJson = item.toJson();
          safeJson.remove('broken_image_index');
          safeJson.remove('quest_saved_amount'); // Also might be missing
          safeJson.remove('consecutive_valid_days');
          safeJson.remove('penalty_amount');

          final response = await ref
              .read(supabaseProvider)
              .from('wishlists')
              .insert({...safeJson, 'user_id': user.id})
              .select()
              .single();

          if (response['id'] == null) throw Exception('Retry failed: ID null');

          final newItem = WishlistModel.fromJson(response);
          final previousList = state.valueOrNull ?? [];
          state = AsyncValue.data([...previousList, newItem]);
          return; // Success on retry
        } catch (retryError) {
          debugPrint('Retry failed: $retryError');
          throw Exception('Failed to add wishlist item (Retry): $retryError');
        }
      }
      throw Exception('Failed to add wishlist item: $e');
    }
  }

  // ... (deleteWishlist methods unchanged)

  // ...

  Future<void> deleteWishlist(String id) async {
    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).asData?.value;

    // NOTE: We are only removing the goal itself.
    // The accumulated saving records (money saved) are preserved in the total savings history.
    // If we wanted to remove the saved amount from the total, we would need to deduct `item.savedAmount`
    // from the total savings or mark the related saving records as deleted.
    // Currently, the requirement is to keep the history.

    if (authNotifier.isGuest || user == null) {
      _guestWishlist.removeWhere((item) => item.id == id);
      state = AsyncValue.data([..._guestWishlist]);
      return;
    }

    try {
      debugPrint('Deleting wishlist item from Supabase: $id');
      // 1. Perform server deletion FIRST
      // Using select() to ensure we get a response, though standard delete throws on error
      await ref.read(supabaseProvider).from('wishlists').delete().eq('id', id);

      // 2. If valid execution, Remove from local state
      final previousList = state.valueOrNull ?? [];
      final updatedList = previousList.where((item) => item.id != id).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      debugPrint('Error deleting wishlist item: $e');
      // No state change needed as we haven't touched it yet
      throw Exception('Failed to delete wishlist item: $e');
    }
  }

  Future<void> deleteWishlists(List<String> ids) async {
    if (ids.isEmpty) return;

    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).asData?.value;

    if (authNotifier.isGuest || user == null) {
      _guestWishlist.removeWhere((item) => ids.contains(item.id));
      state = AsyncValue.data([..._guestWishlist]);
      return;
    }

    try {
      debugPrint('Deleting multiple wishlist items from Supabase: $ids');
      // 1. Perform server deletion FIRST
      // Supabase's 'in_' filter allows matching any value in a list
      await ref
          .read(supabaseProvider)
          .from('wishlists')
          .delete()
          .filter('id', 'in', ids);

      // 2. If valid execution, Remove from local state
      final previousList = state.valueOrNull ?? [];
      final updatedList = previousList
          .where((item) => !ids.contains(item.id))
          .toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      debugPrint('Error deleting multiple wishlist items: $e');
      throw Exception('Failed to delete wishlist items: $e');
    }
  }

  Future<void> addSavingToAllGoals(double amount) async {
    final wishlist = await future;
    if (wishlist.isEmpty) return;

    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).asData?.value;

    // Optimistic Update
    final updatedList = wishlist.map((item) {
      final newSaved = item.savedAmount + amount;
      final isNowAchieved = newSaved >= item.totalGoal && !item.isAchieved;
      return item.copyWith(
        savedAmount: newSaved,
        isAchieved: isNowAchieved ? true : item.isAchieved,
        achievedAt: isNowAchieved ? DateTime.now() : item.achievedAt,
      );
    }).toList();

    state = AsyncValue.data(updatedList);

    if (authNotifier.isGuest || user == null) {
      // Local storage update
      for (var i = 0; i < _guestWishlist.length; i++) {
        final original = _guestWishlist[i];
        final newSaved = original.savedAmount + amount;
        final isNowAchieved =
            newSaved >= original.totalGoal && !original.isAchieved;
        _guestWishlist[i] = _guestWishlist[i].copyWith(
          savedAmount: newSaved,
          isAchieved: isNowAchieved ? true : original.isAchieved,
          achievedAt: isNowAchieved ? DateTime.now() : original.achievedAt,
        );
      }
      return;
    }

    try {
      // Parallel update for all items in Supabase
      await Future.wait(
        updatedList.map((item) {
          final updates = <String, dynamic>{
            'saved_amount': item.savedAmount.toInt(),
          };
          if (item.isAchieved) {
            updates['is_achieved'] = true;
            updates['achieved_at'] = item.achievedAt?.toIso8601String();
          }
          return ref
              .read(supabaseProvider)
              .from('wishlists')
              .update(updates)
              .eq('id', item.id!);
        }),
      );
    } catch (e) {
      // Revert state on error or invalidate
      ref.invalidateSelf();
      debugPrint('Error in addSavingToAllGoals: $e');
      throw Exception('Failed to add funds to all goals: $e');
    }
  }

  Future<void> updateComment(String id, String comment) async {
    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).asData?.value;

    // Optimistic Update
    final previousList = state.valueOrNull ?? [];
    final index = previousList.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final updatedItem = previousList[index].copyWith(comment: comment);
    final updatedList = List<WishlistModel>.from(previousList);
    updatedList[index] = updatedItem;

    state = AsyncValue.data(updatedList);

    if (authNotifier.isGuest || user == null) {
      final guestIndex = _guestWishlist.indexWhere((item) => item.id == id);
      if (guestIndex != -1) {
        _guestWishlist[guestIndex] = updatedItem;
      }
      return;
    }

    try {
      await ref
          .read(supabaseProvider)
          .from('wishlists')
          .update({'comment': comment})
          .eq('id', id);
    } catch (e) {
      // Revert state on error
      ref.invalidateSelf();
      debugPrint('Error updating comment: $e');
      throw Exception('Failed to update comment: $e');
    }
  }

  Future<void> updateWishlist(
    String id, {
    String? title,
    double? price,
    DateTime? targetDate,
    String? imageUrl,
  }) async {
    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).asData?.value;

    final previousList = state.valueOrNull ?? [];
    final index = previousList.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final originalItem = previousList[index];
    final newTotalGoal = price ?? originalItem.totalGoal;
    final isNowAchieved = originalItem.savedAmount >= newTotalGoal;

    final updatedItem = originalItem.copyWith(
      title: title ?? originalItem.title,
      price: price ?? originalItem.price,
      totalGoal: newTotalGoal,
      targetDate: targetDate ?? originalItem.targetDate,
      imageUrl: imageUrl ?? originalItem.imageUrl,
      isAchieved: isNowAchieved,
      achievedAt: (isNowAchieved && !originalItem.isAchieved)
          ? DateTime.now()
          : (isNowAchieved ? originalItem.achievedAt : null),
    );

    final updatedList = List<WishlistModel>.from(previousList);
    updatedList[index] = updatedItem;

    // Optimistic Update
    state = AsyncValue.data(updatedList);

    if (authNotifier.isGuest || user == null) {
      final guestIndex = _guestWishlist.indexWhere((item) => item.id == id);
      if (guestIndex != -1) {
        _guestWishlist[guestIndex] = updatedItem;
      }
      return;
    }

    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (price != null) {
        updates['price'] = price.toInt();
        updates['total_goal'] = price.toInt();
      }
      if (targetDate != null)
        updates['target_date'] = targetDate.toIso8601String();
      if (imageUrl != null) updates['image_url'] = imageUrl;

      // [핵심] 달성 상태 항상 명시적 업데이트
      updates['is_achieved'] = isNowAchieved;
      updates['achieved_at'] = updatedItem.achievedAt?.toIso8601String();

      if (updates.isEmpty) return;

      await ref
          .read(supabaseProvider)
          .from('wishlists')
          .update(updates)
          .eq('id', id);
    } catch (e) {
      ref.invalidateSelf();
      debugPrint('Error updating wishlist: $e');
      throw Exception('Failed to update wishlist: $e');
    }
  }

  /// 확장된 addFundsToSelectedItems: 여러 위시리스트에 동시에 정액을 추가
  Future<void> addFundsToSelectedItems(
    double amount,
    List<String> selectedIds,
  ) async {
    if (selectedIds.isEmpty) return;

    final wishlist = await future;
    if (wishlist.isEmpty) return;

    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).asData?.value;

    // 1. Optimistic Update를 위한 새로운 리스트 생성
    final updatedList = wishlist.map((item) {
      if (selectedIds.contains(item.id)) {
        if (item.isBroken) {
          // [퀘스트 연동] 깨진 아이템인 경우 퀘스트 로직 적용
          return _applyQuestLogic(item, amount);
        }

        final updatedAmount = item.savedAmount + amount;
        final isNowAchieved =
            updatedAmount >= item.totalGoal && !item.isAchieved;
        return item.copyWith(
          savedAmount: updatedAmount,
          isAchieved: isNowAchieved ? true : item.isAchieved,
          achievedAt: isNowAchieved ? DateTime.now() : item.achievedAt,
        );
      }
      return item;
    }).toList();

    // 로컬 상태 즉시 업데이트 (Optimistic)
    state = AsyncValue.data(updatedList);

    // 게스트 모드 처리
    if (authNotifier.isGuest || user == null) {
      for (var i = 0; i < _guestWishlist.length; i++) {
        if (selectedIds.contains(_guestWishlist[i].id)) {
          final original = _guestWishlist[i];
          final updatedAmount = original.savedAmount + amount;
          final isNowAchieved =
              updatedAmount >= original.totalGoal && !original.isAchieved;

          _guestWishlist[i] = original.copyWith(
            savedAmount: updatedAmount,
            isAchieved: isNowAchieved ? true : original.isAchieved,
            achievedAt: isNowAchieved ? DateTime.now() : original.achievedAt,
          );
        }
      }
      return;
    }

    try {
      // 2. Supabase Parallel Update
      await Future.wait(
        updatedList.where((item) => selectedIds.contains(item.id)).map((item) {
          final updates = <String, dynamic>{
            'saved_amount': item.savedAmount.toInt(),
          };

          if (item.isBroken) {
            // [퀘스트 연동] 깨진 아이템인 경우 퀘스트 관련 모든 필드 업데이트
            updates.addAll({
              'is_broken': item.isBroken,
              'quest_saved_amount': item.questSavedAmount,
              'consecutive_valid_days': item.consecutiveValidDays,
              'broken_at': item.brokenAt?.toIso8601String(),
              'last_quest_saving_date': item.lastQuestSavingDate
                  ?.toIso8601String(),
            });
          }

          if (item.isAchieved) {
            updates['is_achieved'] = true;
            updates['achieved_at'] = item.achievedAt?.toIso8601String();
          }

          return ref
              .read(supabaseProvider)
              .from('wishlists')
              .update(updates)
              .eq('id', item.id!);
        }),
      );
    } catch (e) {
      debugPrint('Error in addFundsToSelectedItems: $e');
      // [중요] 스키마 캐시 에러(PGRST204)인 경우 강제 새로고침을 하지 않음
      // 이를 통해 DB에 컬럼이 없더라도 로컬 상태는 유지되어 누적 저축/퀘스트가 작동함
      if (e.toString().contains('PGRST204')) {
        debugPrint(
          'Warning: Supabase columns for Quest are missing. Persistence may fail, but local state is kept.',
        );
      } else {
        ref.invalidateSelf();
      }
    }
  }

  // Deprecated: selection logic is now handled by addFundsToSelectedItems
  Future<String?> addFundsToSelectedItem(double amount) async {
    final selectedIndex = ref.read(selectedWishlistIndexProvider);
    final wishlist = state.valueOrNull ?? [];
    if (selectedIndex < 0 || selectedIndex >= wishlist.length) return null;

    final targetId = wishlist[selectedIndex].id;
    if (targetId == null) return null;

    await addFundsToSelectedItems(amount, [targetId]);
    return wishlist[selectedIndex].title;
  }

  Future<void> deleteAllWishlists() async {
    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).asData?.value;

    if (authNotifier.isGuest || user == null) {
      _guestWishlist.clear();
      state = AsyncValue.data([]);
      return;
    }

    try {
      debugPrint('Deleting ALL wishlist items for user: ${user.id}');
      await ref
          .read(supabaseProvider)
          .from('wishlists')
          .delete()
          .eq('user_id', user.id);

      state = const AsyncValue.data([]);
    } catch (e) {
      debugPrint('Error deleting all wishlists: $e');
      throw Exception('Failed to delete all wishlists: $e');
    }
  }

  Future<void> setRepresentative(String id) async {
    final user = ref.read(authProvider).asData?.value;

    try {
      if (user != null) {
        // 1. 모든 항목의 is_representative를 false로 일괄 업데이트
        await ref
            .read(supabaseProvider)
            .from('wishlists')
            .update({'is_representative': false})
            .eq('user_id', user.id); // 전체 업데이트 (해당 유저 기준)

        // 2. 선택한 항목만 true로 업데이트
        await ref
            .read(supabaseProvider)
            .from('wishlists')
            .update({'is_representative': true})
            .eq('id', id);
      } else {
        // Guest mode support
        for (var i = 0; i < _guestWishlist.length; i++) {
          _guestWishlist[i] = _guestWishlist[i].copyWith(
            isRepresentative: _guestWishlist[i].id == id,
          );
        }
      }

      ref.invalidateSelf(); // 상태 새로고침
    } catch (e) {
      debugPrint('Error in setRepresentative: $e');
      throw Exception('Failed to set representative goal: $e');
    }
  }

  /// 나태의 안개 정화 (blurLevel 차감)
  Future<void> purifyFog(String id) async {
    final wishlist = state.valueOrNull ?? [];
    final index = wishlist.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final original = wishlist[index];
    final newBlur = (original.blurLevel - 1.0).clamp(0.0, 10.0);

    // Optimistic Update
    final updatedItem = original.copyWith(
      blurLevel: newBlur,
      lastSavedAt: DateTime.now(), // 저축 시점 갱신
    );
    final updatedList = List<WishlistModel>.from(wishlist);
    updatedList[index] = updatedItem;
    state = AsyncValue.data(updatedList);

    final authNotifier = ref.read(authProvider.notifier);
    if (authNotifier.isGuest) {
      final guestIndex = _guestWishlist.indexWhere((item) => item.id == id);
      if (guestIndex != -1) _guestWishlist[guestIndex] = updatedItem;
      return;
    }

    try {
      await ref
          .read(supabaseProvider)
          .from('wishlists')
          .update({
            'blur_level': newBlur,
            'last_saved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      debugPrint('Error purifying fog: $e');
      ref.invalidateSelf();
    }
  }

  /// 꿈의 파괴 (100% 확률로 파괴, 이미지 랜덤 1~2)
  Future<bool> shatterDream(String id) async {
    final wishlist = state.valueOrNull ?? [];
    final index = wishlist.indexWhere((item) => item.id == id);
    if (index == -1) return false;

    // 1. 랜덤 이미지 인덱스 결정 (1 or 2)
    final random = Random();
    final brokenIndex = random.nextInt(2) + 1; // 1 or 2

    final original = wishlist[index];

    // Optimistic Update
    final updatedItem = original.copyWith(
      isBroken: true,
      brokenImageIndex: brokenIndex,
      brokenAt: DateTime.now(),
      questSavedAmount: 0.0,
      consecutiveValidDays: 0,
    );
    final updatedList = List<WishlistModel>.from(wishlist);
    updatedList[index] = updatedItem;
    state = AsyncValue.data(updatedList);

    final authNotifier = ref.read(authProvider.notifier);
    if (authNotifier.isGuest) {
      final guestIndex = _guestWishlist.indexWhere((item) => item.id == id);
      if (guestIndex != -1) _guestWishlist[guestIndex] = updatedItem;
      return true;
    }

    try {
      await ref
          .read(supabaseProvider)
          .from('wishlists')
          .update({
            'is_broken': true,
            'broken_image_index': brokenIndex,
            'broken_at': DateTime.now().toIso8601String(),
            'quest_saved_amount': 0,
            'consecutive_valid_days': 0,
          })
          .eq('id', id);
      return true;
    } catch (e) {
      debugPrint('Error shattering dream: $e');
      if (e.toString().contains('PGRST204')) {
        debugPrint(
          'Warning: Supabase columns for Quest are missing. Working in local mode.',
        );
      } else {
        ref.invalidateSelf();
      }
      // UI 입장에서는 일단 로컬 상태가 파괴되었으므로 true 반환
      return true;
    }
  }

  /// 퀘스트 진행도 계산 공통 로직 (낙관적 업데이트 및 서버 동기화 겸용)
  WishlistModel _applyQuestLogic(WishlistModel item, double amount) {
    if (!item.isBroken) return item;

    // 1. 연속 저축 카운트 계산
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int newConsecutive = item.consecutiveValidDays;

    if (item.lastQuestSavingDate == null) {
      newConsecutive = 1;
    } else {
      final lastDate = DateTime(
        item.lastQuestSavingDate!.year,
        item.lastQuestSavingDate!.month,
        item.lastQuestSavingDate!.day,
      );
      final difference = today.difference(lastDate).inDays;

      if (difference == 0) {
        // 오늘 이미 저축함, 카운트 유지
      } else if (difference == 1) {
        newConsecutive += 1;
      } else {
        newConsecutive = 1; // 연속 끊김 -> 리셋
      }
    }

    // 2. 금액 누적 (퀘스트 누적액은 계속 추적하되, 이번 로직 수정으로 10% 한 방 조건을 위해 amount 자체를 비교)
    final newQuestAmount = item.questSavedAmount + amount;
    final newSavedAmount = item.savedAmount + amount;

    // 3. 성공 조건 검사
    // - 조건 A: 2일 연속 송금 (기존 3일 -> 2일)
    // - 조건 B: 목표 금액의 10%를 '한 번에' 송금 (기존 누적 10% -> 1회 10%)
    final conditionA = newConsecutive >= 2;
    final conditionB = amount >= (item.totalGoal * 0.1);
    final isRecovered = conditionA || conditionB;

    if (isRecovered) {
      // 복구 성공: 모든 퀘스트 필드 초기화 및 isBroken 해제, 페널티 제거
      debugPrint('REDEMPTION SUCCESS: Goal "${item.title}" restored!');
      return item.copyWith(
        isBroken: false,
        savedAmount: newSavedAmount,
        brokenAt: null,
        questSavedAmount: 0.0,
        consecutiveValidDays: 0,
        lastQuestSavingDate: null,
        penaltyAmount: 0.0, // [보상] 성공 확률(게이지) 복구
      );
    } else {
      // 진행 중
      return item.copyWith(
        savedAmount: newSavedAmount,
        questSavedAmount: newQuestAmount,
        consecutiveValidDays: newConsecutive,
        lastQuestSavingDate: now,
      );
    }
  }

  /// 구원 퀘스트(Redemption Quest) 판정 로직
  Future<void> processQuestSaving(String id, double amount) async {
    final wishlist = state.valueOrNull ?? [];
    final index = wishlist.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final item = wishlist[index];
    if (!item.isBroken) return;

    // 공통 로직 적용
    final updatedItem = _applyQuestLogic(item, amount);

    // 반영 (Optimistic)
    final updatedList = List<WishlistModel>.from(wishlist);
    updatedList[index] = updatedItem;
    state = AsyncValue.data(updatedList);

    final authNotifier = ref.read(authProvider.notifier);
    if (authNotifier.isGuest) {
      final guestIndex = _guestWishlist.indexWhere((it) => it.id == id);
      if (guestIndex != -1) _guestWishlist[guestIndex] = updatedItem;
      return;
    }

    try {
      await ref
          .read(supabaseProvider)
          .from('wishlists')
          .update({
            'saved_amount': updatedItem.savedAmount.toInt(),
            'is_broken': updatedItem.isBroken,
            'quest_saved_amount': updatedItem.questSavedAmount,
            'consecutive_valid_days': updatedItem.consecutiveValidDays,
            'broken_at': updatedItem.brokenAt?.toIso8601String(),
            'last_quest_saving_date': updatedItem.lastQuestSavingDate
                ?.toIso8601String(),
          })
          .eq('id', id);
    } catch (e) {
      debugPrint('Error processing quest saving: $e');
      if (e.toString().contains('PGRST204')) {
        debugPrint(
          'Warning: Supabase columns for Quest are missing. Persistence may fail, but local state is kept.',
        );
      } else {
        ref.invalidateSelf();
      }
    }
  }

  /// [통합] 일반 상태의 아이템 금액 업데이트 (퀘스트가 아닌 경우)
  Future<void> updateSavedAmount(double amount) async {
    final list = state.valueOrNull;
    if (list == null || list.isEmpty) return;

    // 달성되지 않은 첫 번째 아이템을 찾아 업데이트
    final activeItem = list.firstWhere(
      (item) => !item.isAchieved,
      orElse: () => list.first,
    );
    if (activeItem.id != null) {
      await addFundsToSelectedItems(amount, [activeItem.id!]);
    }
  }

  /// Desire Control System: Pivot Tax Update
  /// 페널티 적용 여부에 따라 저축액을 90%로 삭감하고 목표를 수정함
  /// Desire Control System: Pivot Tax Update
  /// 페널티 적용 여부에 따라 저축액을 90%로 삭감하고 목표를 수정함
  Future<void> updateWishlistWithPenalty(
    WishlistModel newItem, {
    required bool applyPenalty,
    required bool consumeFreePass,
  }) async {
    // 1. Penalty Calculation (Store separately, do NOT touch savedAmount)
    double penaltyValue = 0.0;
    bool shouldShatter = false;
    int brokenIndex = 0;

    if (applyPenalty) {
      // Find current state
      final currentItem = state.valueOrNull?.firstWhere(
        (e) => e.id == newItem.id,
        orElse: () => newItem,
      );

      if (currentItem != null) {
        // [Merciless Logic] Penalty is 20% of Total Goal + Existing Penalty
        // Saved Amount is SAFE. Penalty increases cumulatively.
        final additionalPenalty = currentItem.totalGoal * 0.2;
        penaltyValue = currentItem.penaltyAmount + additionalPenalty;

        shouldShatter = true;
        brokenIndex = Random().nextInt(2) + 1; // 1 or 2
      }
    }

    // 2. Update Basic Info
    await updateWishlist(
      newItem.id!,
      title: newItem.title,
      price: newItem.price,
      targetDate: newItem.targetDate,
      imageUrl: newItem.imageUrl,
    );

    // 3. Update Penalty & Shatter Status
    // Always call this if penalty applied OR if we need to reset penalty (though currently we only add)
    if (applyPenalty) {
      await _updatePenaltyAndShatter(
        newItem.id!,
        penaltyValue,
        shouldShatter: shouldShatter,
        brokenIndex: brokenIndex,
      );
    }

    // 4. Force Consume Free Pass (Delegate to Notifier)
    if (consumeFreePass) {
      // userProfileNotifier now handles both DB and Local sync.
      // It will update Supabase if user is logged in.
      await ref.read(userProfileNotifierProvider.notifier).useFreePass();

      // No need to invalidate. The notifier updates its own state.
    }
  }

  Future<void> _updatePenaltyAndShatter(
    String id,
    double penaltyValue, {
    required bool shouldShatter,
    required int brokenIndex,
  }) async {
    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).asData?.value;

    final previousList = state.valueOrNull ?? [];
    final index = previousList.indexWhere((item) => item.id == id);
    if (index == -1) return;

    // Apply updates locally
    // We update penaltyAmount. savedAmount is untouched.
    var updatedItem = previousList[index].copyWith(penaltyAmount: penaltyValue);

    if (shouldShatter) {
      updatedItem = updatedItem.copyWith(
        isBroken: true,
        brokenImageIndex: brokenIndex,
        brokenAt: DateTime.now(),
        questSavedAmount: 0.0,
        consecutiveValidDays: 0,
      );
    }

    final updatedList = List<WishlistModel>.from(previousList);
    updatedList[index] = updatedItem;

    // Optimistic Update
    state = AsyncValue.data(updatedList);

    if (authNotifier.isGuest || user == null) {
      final guestIndex = _guestWishlist.indexWhere((item) => item.id == id);
      if (guestIndex != -1) _guestWishlist[guestIndex] = updatedItem;
      return;
    }

    try {
      final updates = <String, dynamic>{'penalty_amount': penaltyValue};

      if (shouldShatter) {
        updates.addAll({
          'is_broken': true,
          'broken_image_index': brokenIndex,
          'broken_at': DateTime.now().toIso8601String(),
          'quest_saved_amount': 0,
          'consecutive_valid_days': 0,
        });
      }

      await ref
          .read(supabaseProvider)
          .from('wishlists')
          .update(updates)
          .eq('id', id);
    } catch (e) {
      // Handle PGRST204 (Missing columns in old schema) gracefully
      if (e.toString().contains('PGRST204')) {
        debugPrint('Warning: Columns missing. Penalty applied locally.');
        return; // Keep optimistic update
      }

      ref.invalidateSelf(); // Only invalidate for other errors
      throw Exception('Failed to update penalty: $e');
    }
  }
}

final wishlistProvider = wishlistNotifierProvider;

/// 위시리스트 상태에 대한 편의 확장
extension WishlistAsyncValueX on AsyncValue<List<WishlistModel>> {
  WishlistModel? get activeItem {
    final list = valueOrNull;
    if (list == null || list.isEmpty) return null;

    // 1. 깨진 아이템이 있다면 최우선으로 반환
    try {
      return list.firstWhere((item) => item.isBroken && !item.isAchieved);
    } catch (_) {
      // 2. 깨진 게 없다면 달성되지 않은 첫 번째 아이템 반환 (없으면 첫 번째 아이템)
      return list.firstWhere(
        (item) => !item.isAchieved,
        orElse: () => list.first,
      );
    }
  }
}
