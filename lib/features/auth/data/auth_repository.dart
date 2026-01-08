import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<void> signInWithGoogle() async {
    // Determine redirect URL based on platform
    final redirectTo = kIsWeb
        ? 'https://vibe-web-app-ten.vercel.app'
        : 'io.supabase.flutter://login-callback';

    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      debugPrint(
        'RedirectTo가 작동하지 않는다면, Supabase 대시보드 -> Auth -> URL Configuration에 $redirectTo 주소가 정확히 등록되어 있는지 확인하세요.',
      );
      rethrow;
    }
  }

  Future<void> signInWithKakao() async {
    // Determine redirect URL based on platform
    final redirectTo = kIsWeb
        ? 'https://vibe-web-app-ten.vercel.app'
        : 'io.supabase.flutter://login-callback';

    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Kakao Sign-In Error: $e');
      debugPrint(
        'RedirectTo가 작동하지 않는다면, Supabase 대시보드 -> Auth -> URL Configuration에 $redirectTo 주소가 정확히 등록되어 있는지 확인하세요.',
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
