import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await ref
            .read(authProvider.notifier)
            .signIn(
              email: _emailController.text,
              password: _passwordController.text,
            );
      } else {
        await ref
            .read(authProvider.notifier)
            .signUp(
              email: _emailController.text,
              password: _passwordController.text,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verification email sent!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.waves,
                  size: 64,
                  color: Colors.white,
                ), // White Icon
                const SizedBox(height: 32),
                Text(
                  _isLogin ? '로그인' : '회원가입',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Colors.white, // White text
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '이메일로 간편하게 시작하세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400], // Light grey text
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(
                    color: Colors.white, // White input text
                    fontWeight: FontWeight.bold,
                  ),
                  cursorColor: const Color(0xFFD4FF00), // Lime cursor
                  decoration: InputDecoration(
                    labelText: '이메일',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    hintText: '이메일 주소 입력',
                    hintStyle: const TextStyle(
                      color: Colors.white60,
                    ), // Lighter hint
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A), // Dark input background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD4FF00), // Lime focus border
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _PasswordTextField(controller: _passwordController),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4FF00), // Lime button
                    foregroundColor: Colors.black, // Black text on Lime
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
                            ),
                          ),
                        )
                      : Text(
                          _isLogin ? '로그인하기' : '이메일로 시작하기',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '또는',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 24),

                // Google Login Button
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).signInWithGoogle();
                  },
                  icon: const Icon(
                    Icons.g_mobiledata,
                    size: 28,
                  ), // Placeholder icon
                  label: const Text('Google로 계속하기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Kakao Login Button
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).signInWithKakao();
                  },
                  icon: const Icon(
                    Icons.chat_bubble,
                    size: 20,
                    color: Color(0xFF3C1E1E),
                  ), // Placeholder icon
                  label: const Text('카카오로 3초만에 시작하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500), // Kakao Yellow
                    foregroundColor: const Color(0xFF3C1E1E), // Kakao Brown
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    setState(() => _isLogin = !_isLogin);
                  },
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(fontSize: 15, color: Colors.grey[400]),
                      children: [
                        TextSpan(
                          text: _isLogin ? '계정이 없으신가요? ' : '이미 계정이 있으신가요? ',
                        ),
                        TextSpan(
                          text: _isLogin ? '회원가입' : '로그인하기',
                          style: const TextStyle(
                            color: Colors.white, // White link text
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                TextButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).loginAsGuest();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.grey[600],
                  ),
                  child: const Text(
                    '로그인 없이 둘러보기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordTextField extends StatefulWidget {
  final TextEditingController controller;

  const _PasswordTextField({required this.controller});

  @override
  State<_PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<_PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      cursorColor: const Color(0xFFD4FF00),
      decoration: InputDecoration(
        labelText: '비밀번호',
        labelStyle: TextStyle(color: Colors.grey[400]),
        hintText: '비밀번호 입력',
        hintStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4FF00), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[400],
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
      obscureText: _obscureText,
    );
  }
}
