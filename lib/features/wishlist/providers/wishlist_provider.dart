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
      print(
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
      print('Adding wishlist item to Supabase: ${item.title}');
      final response = await ref
          .read(supabaseProvider)
          .from('wishlists')
          .insert({...item.toJson(), 'user_id': user.id})
          .select()
          .single();

      print('Supabase response: $response');

      // Check raw response for ID before parsing (because fromJson now generates a fallback UUID)
      if (response['id'] == null) {
        throw Exception('서버 오류: ID 생성 실패 (Server returned null ID)');
      }

      final newItem = WishlistModel.fromJson(response);
      print('Parsed item ID: ${newItem.id}');

      // Update state with the new item containing the valid ID
      final previousList = state.valueOrNull ?? [];
      state = AsyncValue.data([...previousList, newItem]);
    } catch (e) {
      print('Error adding wishlist item: $e'); // Debug log
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
      print('Deleting wishlist item from Supabase: $id');
      // 1. Perform server deletion FIRST
      // Using select() to ensure we get a response, though standard delete throws on error
      await ref.read(supabaseProvider).from('wishlists').delete().eq('id', id);

      // 2. If valid execution, Remove from local state
      final previousList = state.valueOrNull ?? [];
      final updatedList = previousList.where((item) => item.id != id).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      print('Error deleting wishlist item: $e');
      // No state change needed as we haven't touched it yet
      throw Exception('Failed to delete wishlist item: $e');
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
      print('Error in addSavingToAllGoals: $e');
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
      print('Error updating comment: $e');
      throw Exception('Failed to update comment: $e');
    }
  }

  Future<String?> addFundsToSelectedItem(double amount) async {
    final wishlist = await future;
    if (wishlist.isEmpty) return null;

    final selectedIndex = ref.read(selectedWishlistIndexProvider);
    // Safety check: if index is out of bounds, default to 0 or return null
    if (selectedIndex < 0 || selectedIndex >= wishlist.length) return null;

    final targetItem = wishlist[selectedIndex];
    final authNotifier = ref.read(authProvider.notifier);
    final user = ref.read(authProvider).asData?.value;

    final updatedAmount = targetItem.savedAmount + amount;
    final isNowAchieved =
        updatedAmount >= targetItem.totalGoal && !targetItem.isAchieved;
    final achievedAt = isNowAchieved ? DateTime.now() : targetItem.achievedAt;

    if (authNotifier.isGuest || user == null) {
      final index = _guestWishlist.indexWhere((i) => i.id == targetItem.id);
      if (index != -1) {
        _guestWishlist[index] = targetItem.copyWith(
          savedAmount: updatedAmount,
          isAchieved: isNowAchieved ? true : targetItem.isAchieved,
          achievedAt: achievedAt,
        );
        state = AsyncValue.data([..._guestWishlist]);
        return targetItem.title;
      }
      return null;
    }

    // Optimistic Update
    final updatedList = List<WishlistModel>.from(wishlist);
    updatedList[selectedIndex] = targetItem.copyWith(
      savedAmount: updatedAmount,
      isAchieved: isNowAchieved ? true : targetItem.isAchieved,
      achievedAt: achievedAt,
    );
    state = AsyncValue.data(updatedList);

    try {
      final updates = <String, dynamic>{'saved_amount': updatedAmount.toInt()};
      if (isNowAchieved) {
        updates['is_achieved'] = true;
        updates['achieved_at'] = achievedAt?.toIso8601String();
      }

      await ref
          .read(supabaseProvider)
          .from('wishlists')
          .update(updates)
          .eq('id', targetItem.id!);

      // No need to invalidateSelf() if optimistic update is successful and accurate
      // ref.invalidateSelf();
      return targetItem.title;
    } catch (e) {
      // Revert state on error if needed, or invalidate to re-fetch truth
      ref.invalidateSelf();
      print('Error in addFundsToSelectedItem: $e');
      throw Exception('Failed to add funds: $e');
    }
  }
}

final wishlistProvider = wishlistNotifierProvider;
