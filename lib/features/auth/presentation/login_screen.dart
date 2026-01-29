import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import 'package:vive_app/core/ui/bouncy_button.dart';
import 'widgets/engine_core_widget.dart';

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
    HapticFeedback.mediumImpact();
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

  void _showEmailLoginSheet({required bool initialIsLogin}) {
    setState(() => _isLogin = initialIsLogin);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent, // Required for BackdropFilter to show through
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xAA121212),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 32,
                  right: 32,
                  top: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLogin ? '이메일 로그인' : '이메일 회원가입',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _TerminalInputField(
                      controller: _emailController,
                      label: '이메일',
                      hint: 'example@vibe.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    _TerminalInputField(
                      controller: _passwordController,
                      label: '비밀번호',
                      hint: '비밀번호를 입력하세요',
                      isPassword: true,
                    ),
                    const SizedBox(height: 48),
                    _TerminalPrimaryButton(
                      label: _isLogin ? '로그인' : '가입하기',
                      isLoading: _isLoading,
                      onTap: () async {
                        setSheetState(() => _isLoading = true);
                        await _submit();
                        setSheetState(() => _isLoading = false);
                        if (mounted &&
                            ref.read(authProvider).asData?.value != null) {
                          Navigator.pop(context);
                        }
                      },
                      isFilled: true,
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(
                          _isLogin ? "회원가입" : "로그인하기",
                          style: const TextStyle(
                            color: Color(0xFFCCFF00),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFCCFF00); // Electric Lime
    const deepNavyBlack = Color(0xFF0A0A0E);

    return Scaffold(
      backgroundColor: deepNavyBlack,
      body: Stack(
        children: [
          // Layer 1: Minimal Grid
          Positioned.fill(
            child: CustomPaint(painter: _GridBackgroundPainter(opacity: 0.02)),
          ),

          // Layer 2: Engine Core Background (The true base layer for rings)
          // 점선 원들이 모든 글로우와 패널 뒤에 위치하도록 함
          const Center(child: EngineCoreWidget()),

          // Layer 3: Blurry Environment Lights (Translucent Overlays)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [accentColor.withOpacity(0.08), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [accentColor.withOpacity(0.06), Colors.transparent],
                ),
              ),
            ),
          ),

          // Layer 4: Core Sync Glow
          Center(
            child:
                Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentColor.withOpacity(0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.1, 1.1),
                      duration: 2.seconds,
                      curve: Curves.easeInOut,
                    )
                    .fadeOut(
                      begin: 0.3,
                      duration: 2.seconds,
                      curve: Curves.easeInOut,
                    ),
          ),

          // Content Layer (Top-most)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                        vertical: 24.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top: Branding
                          Column(
                                children: [
                                  const SizedBox(height: 12),
                                  // VIBE Logo with Shimmer and Synced Halo
                                  Text(
                                        'VIBE',
                                        style: TextStyle(
                                          fontSize: 64,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                          color: accentColor,
                                          letterSpacing: -3.0,
                                          height: 1.0,
                                          shadows: [
                                            Shadow(
                                              color: accentColor.withOpacity(
                                                0.5,
                                              ),
                                              offset: const Offset(4, 4),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      )
                                      .animate(
                                        onPlay: (c) => c.repeat(reverse: true),
                                      )
                                      .custom(
                                        duration: 1.seconds, // 엔진 코어와 동기화
                                        curve: Curves.easeInOutSine,
                                        builder: (context, value, child) {
                                          return Text(
                                            'VIBE',
                                            style: TextStyle(
                                              fontSize: 64,
                                              fontWeight: FontWeight.w900,
                                              fontStyle: FontStyle.italic,
                                              color: accentColor,
                                              letterSpacing: -3.0,
                                              height: 1.0,
                                              shadows: [
                                                // Halo (후광) 효과: 엔진과 동기화
                                                Shadow(
                                                  color: accentColor
                                                      .withOpacity(0.4 * value),
                                                  offset: Offset.zero,
                                                  blurRadius: 10 + (20 * value),
                                                ),
                                                Shadow(
                                                  color: accentColor
                                                      .withOpacity(0.5),
                                                  offset: const Offset(4, 4),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                      .animate(onPlay: (c) => c.repeat())
                                      .shimmer(
                                        duration: 3.seconds, // 3초 주기의 고급스러운 빛줄기
                                        color: Colors.white24,
                                        angle: math.pi / 4,
                                      ),
                                  const SizedBox(height: 8), // 간격 좁힘
                                  Text(
                                    'Visionary Incentive & Behavioral Engine'
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w100, // 더 얇게 처리
                                      color: Colors.white70,
                                      letterSpacing: 2.0,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '> 당신의 목표를 실현하는 저축 엔진',
                                    style: TextStyle(
                                      fontSize: 12, // 크기 축소
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white38, // 투명도 하향
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              )
                              .animate()
                              .fadeIn(duration: 1200.ms)
                              .slideY(begin: 0.1, end: 0),

                          const SizedBox(height: 32), // 슬로건-엔진 간격 확장하여 답답함 해소
                          // Center: Engine Core Slot (Layout Placeholder)
                          // 실제 엔진은 배경 Stack으로 이동하여 레이어 깊이감 확보
                          const SizedBox(height: 300),

                          const SizedBox(height: 16), // 24 -> 16px 압축
                          // Bottom: Actions (Premium Glass Console Refined)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 32.0,
                            ), // 60 -> 32px로 조정 (공간 확보)
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 4,
                                  sigmaY: 4,
                                ), // 10 -> 8로 추가 조정 (가독성+투시 균형)
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0,
                                    vertical: 24.0, // 32 -> 24px 압축
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      0.01,
                                    ), // 0.02 -> 0.01로 극도의 투명화
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white24, // 선명한 경계선
                                      width: 0.5,
                                    ),
                                    boxShadow: [
                                      // 은은한 네온 라임색 안개 효과 (뒤쪽 점선을 위해 더 연하게)
                                      BoxShadow(
                                        color: accentColor.withOpacity(
                                          0.03,
                                        ), // 0.05 -> 0.03
                                        blurRadius: 30,
                                        spreadRadius: -15,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Spacer(flex: 2),
                                          Flexible(
                                            flex: 10,
                                            child: _SocialButton(
                                              icon: Icons.g_mobiledata,
                                              label: '구글',
                                              onTap: () {
                                                HapticFeedback.mediumImpact();
                                                ref
                                                    .read(authProvider.notifier)
                                                    .signInWithGoogle();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            flex: 10,
                                            child: _SocialButton(
                                              icon: Icons.chat_bubble,
                                              label: '카카오',
                                              onTap: () {
                                                HapticFeedback.mediumImpact();
                                                ref
                                                    .read(authProvider.notifier)
                                                    .signInWithKakao();
                                              },
                                            ),
                                          ),
                                          const Spacer(flex: 2),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      GestureDetector(
                                        onTap: () => _showEmailLoginSheet(
                                          initialIsLogin: true,
                                        ),
                                        child: const Text(
                                          '이메일로 시작하기',
                                          style: TextStyle(
                                            color: Colors.white70, // 시인성 추가 상향
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: 0.5,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Colors.white24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 800.ms),

                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _showEmailLoginSheet(initialIsLogin: false);
                            },
                            child: Text(
                              _isLogin
                                  ? "아직 회원이 아니신가요? 회원가입"
                                  : "이미 회원이신가요? 로그인하기",
                              style: const TextStyle(
                                color: Colors.white, // 완전 불투명 흰색 (가독성 극대화)
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TerminalInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isPassword;
  final TextInputType? keyboardType;

  const _TerminalInputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.keyboardType,
  });

  @override
  State<_TerminalInputField> createState() => _TerminalInputFieldState();
}

class _TerminalInputFieldState extends State<_TerminalInputField> {
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFCCFF00);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: _isFocused ? accentColor : Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.isPassword,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: accentColor,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
          ),
          keyboardType: widget.keyboardType,
        ),
      ],
    );
  }
}

class _TerminalPrimaryButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final bool isFilled;

  const _TerminalPrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
    this.isFilled = false,
  });

  @override
  State<_TerminalPrimaryButton> createState() => _TerminalPrimaryButtonState();
}

class _TerminalPrimaryButtonState extends State<_TerminalPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFCCFF00);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: widget.isFilled
                ? (_isPressed ? accentColor.withOpacity(0.8) : accentColor)
                : (_isPressed ? accentColor : Colors.transparent),
            border: Border.all(color: accentColor, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isFilled
                        ? Colors.black
                        : (_isPressed ? Colors.black : accentColor),
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFCCFF00);

    return BouncyButton(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          // 1단계: 차폐(Occlusion) - Scaffold 배경색과 동일한 불투명 색상으로 배경 엔진을 완전히 가림
          color: const Color(0xFF0A0A0E),
          border: Border.all(color: accentColor.withOpacity(0.5), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          // 2단계: 미학(Aesthetics) - 그 위에 은은한 화이트 틴트를 주어 기존 글래스모피즘 톤 유지
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  final double opacity;
  _GridBackgroundPainter({this.opacity = 0.02});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1;
    const double gridSize = 40;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
