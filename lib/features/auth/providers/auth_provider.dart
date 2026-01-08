import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import '../data/auth_repository.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(ref.watch(supabaseProvider));
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  bool _isGuest = false;
  bool get isGuest => _isGuest;

  @override
  Stream<User?> build() {
    return ref.watch(supabaseProvider).auth.onAuthStateChange.map((event) {
      if (event.session?.user != null) {
        _isGuest = false; // Reset guest if logged in
      }
      return event.session?.user;
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    final client = ref.read(supabaseProvider);
    await client.auth.signInWithPassword(email: email, password: password);
    _isGuest = false;
  }

  Future<void> signUp({required String email, required String password}) async {
    final client = ref.read(supabaseProvider);
    await client.auth.signUp(email: email, password: password);
    _isGuest = false;
  }

  Future<void> signInWithGoogle() async {
    await ref.read(authRepositoryProvider).signInWithGoogle();
    _isGuest = false;
  }

  Future<void> signInWithKakao() async {
    await ref.read(authRepositoryProvider).signInWithKakao();
    _isGuest = false;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    _isGuest = false;
    ref.invalidateSelf();
  }

  void loginAsGuest() {
    _isGuest = true;
    ref.notifyListeners(); // Force a rebuild to trigger router redirect check
  }
}

final authProvider = authNotifierProvider;
