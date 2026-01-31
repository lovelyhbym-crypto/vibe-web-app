import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nerve/core/network/supabase_client.dart';
import 'package:nerve/features/auth/providers/auth_provider.dart';
import '../models/user_profile.dart';

part 'user_profile_provider.g.dart';

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  static const _storageKey = 'user_profile_v1';

  @override
  FutureOr<UserProfile> build() async {
    // Watch auth provider to rebuild when login state changes
    final authState = ref.watch(authProvider);
    return _initProfile(authState.asData?.value);
  }

  Future<UserProfile> _initProfile(User? user) async {
    // 1. Auth State is passed as argument

    // 2. If Guest, use SharedPreferences (Legacy/Local)
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        try {
          return UserProfile.fromJson(jsonDecode(jsonStr));
        } catch (_) {}
      }
      return const UserProfile(id: 'guest_user', hasFreePass: true);
    }

    // 3. If Logged In, Fetch from Supabase
    try {
      final response = await ref
          .read(supabaseProvider)
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        // Create if not exists
        final newProfile = UserProfile(
          id: user.id,
          hasFreePass: true,
          nickname: user.userMetadata?['full_name'] ?? 'ENGINEER',
          createdAt: DateTime.now(),
        );
        await ref
            .read(supabaseProvider)
            .from('user_profiles')
            .insert(newProfile.toJson());
        return newProfile;
      }

      return UserProfile.fromJson(response);
    } catch (e) {
      // Fallback to local if offline or error
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        try {
          return UserProfile.fromJson(jsonDecode(jsonStr));
        } catch (_) {}
      }
      return UserProfile(id: user.id, hasFreePass: true);
    }
  }

  Future<void> useFreePass() async {
    final current = state.value;
    if (current == null) return;

    // Optimistic Update
    final updated = current.copyWith(hasFreePass: false);
    state = AsyncValue.data(updated);

    // Persist
    final user = ref.read(authProvider).asData?.value;

    // 1. Local Persistence (Always)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(updated.toJson()));

    // 2. Remote Persistence (If Logged In)
    if (user != null) {
      try {
        await ref
            .read(supabaseProvider)
            .from('user_profiles')
            .update({'has_free_pass': false})
            .eq('id', user.id);
      } catch (e) {
        // If server update fails, invalidate to refetch later?
        // Or trust local for now.
        print('Error updating user profile: $e');
      }
    }
  }

  // Increment Failed Count
  Future<void> incrementFailedCount() async {
    final current = state.value;
    if (current == null) return;

    // Optimistic Update
    final updated = current.copyWith(failedCount: current.failedCount + 1);
    state = AsyncValue.data(updated);

    // Persist
    final user = ref.read(authProvider).asData?.value;

    // 1. Local Persistence
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(updated.toJson()));

    // 2. Remote Persistence (If Logged In)
    if (user != null) {
      try {
        await ref
            .read(supabaseProvider)
            .rpc('increment_failed_count', params: {'user_id': user.id});
      } catch (e) {
        // Simple update fallback if RPC not available
        try {
          await ref
              .read(supabaseProvider)
              .from('user_profiles')
              .update({'failed_count': updated.failedCount})
              .eq('id', user.id);
        } catch (innerE) {
          print('Error updating failed count: $innerE');
        }
      }
    }
  }

  // Update Nickname
  Future<void> updateNickname(String newNickname) async {
    final current = state.value;
    if (current == null) return;

    // Optimistic Update
    final updated = current.copyWith(nickname: newNickname);
    state = AsyncValue.data(updated);

    // Persist
    final user = ref.read(authProvider).asData?.value;

    // 1. Local Persistence (Always)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(updated.toJson()));

    // 2. Remote Persistence (If Logged In)
    if (user != null) {
      try {
        await ref
            .read(supabaseProvider)
            .from('user_profiles')
            .update({'nickname': newNickname})
            .eq('id', user.id);
      } catch (e) {
        print('Error updating nickname: $e');
      }
    }
  }

  // Debug/Reset
  Future<void> resetProfile() async {
    // ... Implementation if needed, mostly for dev
  }
}
