import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:vive_app/core/network/supabase_client.dart';
import 'package:vive_app/features/auth/providers/auth_provider.dart';
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

      // Check raw response for ID before parsing (because fromJson now generates a fallback UUID)
      if (response['id'] == null) {
        throw Exception('서버 오류: ID 생성 실패 (Server returned null ID)');
      }

      final newItem = WishlistModel.fromJson(response);
      debugPrint('Parsed item ID: ${newItem.id}');

      // Update state with the new item containing the valid ID
      final previousList = state.valueOrNull ?? [];
      state = AsyncValue.data([...previousList, newItem]);
    } catch (e) {
      debugPrint('Error adding wishlist item: $e'); // Debug log
      throw Exception('Failed to add wishlist item: $e');
    }
  }

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

  /// 꿈의 파괴 (isBroken 설정 및 퀘스트 초기화)
  Future<void> shatterDream(String id) async {
    final wishlist = state.valueOrNull ?? [];
    final index = wishlist.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final original = wishlist[index];

    // Optimistic Update: 퀘스트 필드 초기화
    final updatedItem = original.copyWith(
      isBroken: true,
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
      return;
    }

    try {
      await ref
          .read(supabaseProvider)
          .from('wishlists')
          .update({
            'is_broken': true,
            'broken_at': DateTime.now().toIso8601String(),
            'quest_saved_amount': 0,
            'consecutive_valid_days': 0,
          })
          .eq('id', id);
    } catch (e) {
      debugPrint('Error shattering dream: $e');
      // [중요] 스키마 캐시 에러(PGRST204)인 경우 강제 새로고침을 하지 않음
      // 이를 통해 DB에 컬럼이 없더라도 로컬 상태는 유지되어 퀘스트 카드가 계속 유지됨
      if (e.toString().contains('PGRST204')) {
        debugPrint(
          'Warning: Supabase columns for Quest are missing. Working in local mode.',
        );
      } else {
        ref.invalidateSelf();
      }
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

    // 2. 금액 누적
    final newQuestAmount = item.questSavedAmount + amount;
    final newSavedAmount = item.savedAmount + amount;

    // 3. 성공 조건 검사 (3일 연속 또는 원래 가격의 10% 지불 중 하나만 달성해도 성공)
    final conditionA = newConsecutive >= 3;
    final conditionB = newQuestAmount >= (item.totalGoal * 0.1);
    final isRecovered = conditionA || conditionB;

    if (isRecovered) {
      // 복구 성공: 모든 퀘스트 필드 초기화 및 isBroken 해제
      debugPrint('REDEMPTION SUCCESS: Goal "${item.title}" restored!');
      return item.copyWith(
        isBroken: false,
        savedAmount: newSavedAmount,
        brokenAt: null,
        questSavedAmount: 0.0,
        consecutiveValidDays: 0,
        lastQuestSavingDate: null,
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
