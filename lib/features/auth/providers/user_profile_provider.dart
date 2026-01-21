import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';

part 'user_profile_provider.g.dart';

@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  static const _storageKey = 'user_profile_v1';

  @override
  FutureOr<UserProfile> build() async {
    return _loadProfile();
  }

  Future<UserProfile> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr != null) {
      try {
        return UserProfile.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        // Fallback or error handling
      }
    }
    // Default profile
    return const UserProfile(id: 'user_default', hasFreePass: true);
  }

  Future<void> _saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(profile.toJson()));
    state = AsyncValue.data(profile);
  }

  Future<void> useFreePass() async {
    final current = state.value;
    if (current == null) return;

    if (current.hasFreePass) {
      final updated = current.copyWith(hasFreePass: false);
      await _saveProfile(updated);
    }
  }

  // Debug/Reset method
  Future<void> resetProfile() async {
    final newProfile = const UserProfile(id: 'user_default', hasFreePass: true);
    await _saveProfile(newProfile);
  }
}
