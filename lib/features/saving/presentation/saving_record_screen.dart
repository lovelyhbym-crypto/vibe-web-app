import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:nerve/core/utils/i18n.dart';
import 'package:nerve/core/theme/app_theme.dart';
import 'package:nerve/core/services/bank_account_service.dart';
import 'package:nerve/core/services/sound_service.dart';
import 'package:nerve/core/services/haptic_service.dart';

import 'package:nerve/features/saving/domain/category_model.dart';
import 'package:nerve/features/saving/providers/category_provider.dart';
import 'package:nerve/features/saving/providers/saving_provider.dart';
import 'package:nerve/features/wishlist/providers/wishlist_provider.dart';
import 'package:nerve/features/wishlist/domain/wishlist_model.dart';
import 'package:nerve/core/theme/theme_provider.dart';
import 'package:nerve/features/auth/presentation/widgets/engine_core_widget.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:nerve/features/home/providers/navigation_provider.dart';
import 'package:nerve/features/dashboard/providers/reward_state_provider.dart';
import 'package:nerve/features/saving/presentation/widgets/custom_keypad.dart';
import 'package:nerve/core/ui/bouncy_button.dart';

class SavingRecordScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;
  const SavingRecordScreen({super.key, this.initialData});

  @override
  ConsumerState<SavingRecordScreen> createState() => _SavingRecordScreenState();
}

class _SavingRecordScreenState extends ConsumerState<SavingRecordScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _bankAccountService = BankAccountService();
  late ConfettiController _confettiController;
  String? _selectedCategoryId;
  bool _isTrophyMode = false;
  bool _isLoading = false;
  bool _isWaitingForTransfer = false;
  late AnimationController _syncController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _syncController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // [Auto-Preset] Handle initial data
    if (widget.initialData != null) {
      _amountController.text = widget.initialData!['initialAmount'] ?? '';
      _memoController.text = widget.initialData!['initialMemo'] ?? '';
      _selectedCategoryId = widget.initialData!['initialCategoryId'];
      _isTrophyMode = widget.initialData!['isTrophyMode'] ?? false;

      // If trophy mode, force amount to 0 and set default note
      if (_isTrophyMode) {
        _amountController.text = '0';
        if (_memoController.text.isEmpty) {
          _memoController.text = '유혹방어';
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    _memoController.dispose();
    _confettiController.dispose();
    _syncController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForTransfer) {
      _showSuccessDialog();
    }
  }

  Future<void> _showSyncOverlay() async {
    final completer = Completer<void>();

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (context) => _NeuralSyncOverlay(
        onComplete: () {
          entry?.remove();
          completer.complete();
        },
        isRapidMode: _isTrophyMode, // [Rapid Sync]
      ),
    );

    Overlay.of(context).insert(entry);
    return completer.future;
  }

  void _addAmount(int amount) {
    // [Added] Sensory Feedback: Chip Sound & Light Vibration
    SoundService().playChip();
    HapticService.light();

    final current = int.tryParse(_amountController.text) ?? 0;
    _amountController.text = (current + amount).toString();
  }

  IconData _getIconData(String? iconPath) {
    if (iconPath == null) return Icons.category;
    switch (iconPath) {
      case 'fastfood':
        return Icons.fastfood;
      case 'local_bar':
        return Icons.local_bar;
      case 'local_taxi':
        return Icons.local_taxi;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'more_horiz':
        return Icons.more_horiz;
      default:
        return Icons.category;
    }
  }

  Future<void> _showKeypad(BuildContext context) async {
    // 키패드 호출 (Modal Bottom Sheet)
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 높이 제어 가능
      backgroundColor: Colors.transparent, // 배경 투명 (Glassmorphism 유지)
      builder: (context) => CustomKeypad(onKeyTap: _onKeyTap),
    );

    // 키패드가 닫힌 후 필요한 작업이 있다면 여기에 작성
    // 예: 포커스 해제 등
    if (mounted) {
      FocusScope.of(this.context).unfocus();
    }
  }

  void _onKeyTap(String key) {
    String currentText = _amountController.text.replaceAll(',', '');

    if (key == 'back') {
      if (currentText.isNotEmpty) {
        currentText = currentText.substring(0, currentText.length - 1);
      }
    } else if (key == '00') {
      if (currentText.isNotEmpty && currentText.length < 7) {
        currentText += '00';
      }
    } else {
      // Numbers 0-9
      if (currentText.length < 8) {
        if (currentText == '0') {
          currentText = key;
        } else {
          currentText += key;
        }
      }
    }

    // Format with commas handled via int parsing? Or explicit?
    // User requested "input logic". existing code usually expects plain text?
    // _submit uses integer parsing which handles raw digits.
    // But UI usually shows formatted with commas.
    // I will format it nicely:
    if (currentText.isEmpty) {
      _amountController.text = "";
      return;
    }

    final number = int.tryParse(currentText);
    if (number != null) {
      // Simple comma formatting
      final formatted = number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      _amountController.text = formatted;
    } else {
      _amountController.text = currentText;
    }
  }

  void _executeDefeatSequence(double amount) async {
    // 1. Sound: 유리창 깨지는 소리 시뮬레이션
    debugPrint('Sound Simulation: Glass Breaking Sound (Deferred)');

    // 2. State: 현재 위시리스트 파괴
    final wishlistAsync = ref.read(wishlistProvider);
    final activeWishlists = wishlistAsync.maybeWhen(
      data: (list) => list.where((w) => !w.isAchieved).toList(),
      orElse: () => [],
    );

    String? penaltyText;
    if (activeWishlists.isNotEmpty) {
      final target = activeWishlists.first;
      penaltyText = target.penaltyText;
      if (target.id != null) {
        await ref.read(wishlistProvider.notifier).shatterDream(target.id!);
      }
    }

    // 3. Confrontation Mode (Full Screen Overlay)
    if (!mounted) return;
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;

    // System failure impact
    HapticService.vibrate();

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      pageBuilder: (context, anim1, anim2) {
        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              fit: StackFit.expand,
              children: [
                // [Visual FX] Scanline Effect
                IgnorePointer(
                  child:
                      Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.5, 0.51, 1.0],
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.1),
                                  Colors.black.withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                                tileMode: TileMode.repeated,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .moveY(begin: -10, end: 10, duration: 2000.ms),
                ),

                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                            Icons.broken_image_rounded,
                            size: 80,
                            color: colors.danger,
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .shake(
                            duration: 100.ms,
                            hz: 5,
                            offset: const Offset(2, 0),
                          ) // Glitch jitter
                          .tint(
                            color: Colors.white,
                            duration: 50.ms,
                          ), // Glitch flash

                      const SizedBox(height: 32),

                      const Text(
                        "[SYSTEM BREACH]",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Text(
                        "유혹 방어 실패",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.0,
                          shadows: [Shadow(color: Colors.red, blurRadius: 20)],
                        ),
                      ).animate().fadeIn().shake(duration: 500.ms),

                      const SizedBox(height: 48),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A0000),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.danger, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: colors.danger.withValues(alpha: 0.2),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "[REMEDIATION] 강제 복구 프로토콜 이행",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              penaltyText ?? "설정된 프로토콜이 없습니다.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                height: 1.5,
                                fontFamily:
                                    'Courier', // Monospace for high-tech feel
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (penaltyText != null)
                              const Text(
                                "시스템 정상화를 위해 즉시 위 절차를 이행하십시오.",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Action Button
                      SizedBox(
                            width: 240,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.danger,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    4,
                                  ), // Angular High-tech look
                                ),
                                elevation: 10,
                                shadowColor: colors.danger,
                              ),
                              onPressed: () {
                                // [Added] Trigger Glitch & Shatter Sound for next screen
                                ref
                                    .read(rewardStateProvider.notifier)
                                    .triggerShatter();
                                Navigator.of(context).pop(); // Close overlay
                              },
                              child: const Text(
                                "프로토콜 수용 및 이행 시작",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                          )
                          .animate(target: 1)
                          .shake(
                            delay: 500.ms,
                            duration: 200.ms,
                          ), // Glitch on user interaction hint
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, anim1, anim2, child) {
        // Hard sharp cut or quick fade for glitch feel
        return FadeTransition(opacity: anim1, child: child);
      },
    );

    // 4. Navigation: 즉시 위시리스트 탭으로 강제 전환
    if (mounted) {
      context.go('/');
      ref.read(navigationIndexProvider.notifier).setIndex(1);
    }
  }

  void _showDefeatDialog() {
    final theme = Theme.of(context);
    final vibeTheme = theme.extension<VibeThemeExtension>();
    final colors = vibeTheme?.colors;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Animate(
        effects: [
          FadeEffect(duration: 100.ms),
          ShakeEffect(
            duration: 200.ms,
            hz: 10,
            offset: const Offset(5, 0),
          ), // [Visual FX] Glitch on appear
        ],
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F0F0F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Sharp edges
            side: BorderSide(color: colors?.danger ?? Colors.red, width: 2),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Center Title (Korean)
              Text(
                "지출 확정 보고서",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors?.danger ?? Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5, // Increased letter spacing
                ),
              ),
              const SizedBox(height: 4),
              // 2. Centered Code Tag
              Text(
                "[CODE: 402_LEAK]",
                style: TextStyle(
                  color: (colors?.danger ?? Colors.red).withValues(alpha: 0.3),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Main Label (Korean)
              const Center(
                child: Text(
                  '지출 금액을 입력하십시오',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Neon Input Box (Cleaned)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  border: Border.all(
                    color: colors?.danger ?? Colors.redAccent,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: (colors?.danger ?? Colors.red).withValues(
                        alpha: 0.1,
                      ),
                      blurRadius: 4, // Reduced blur for clean look
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ), // Minimal padding
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center, // Centered Text
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Courier',
                  ),
                  cursorColor: colors?.danger,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              children: [
                // Cancel Button (Balanced)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(
                        alpha: 0.1,
                      ), // Dark Grey
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '취소',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm Button (Balanced)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors?.danger ?? Colors.red[900],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      final amount = double.tryParse(controller.text) ?? 0;
                      Navigator.pop(context);
                      _executeDefeatSequence(amount);
                    },
                    child: const Text(
                      '지출 확정',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    debugPrint(
      '[DEBUG] _submit called. isLoading: $_isLoading, isTrophyMode: $_isTrophyMode',
    );
    if (_isLoading) {
      debugPrint('[DEBUG] _submit ignored due to isLoading: true');
      return;
    }

    final cleanerText = _amountController.text
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    final amount = int.tryParse(cleanerText);
    final i18n = I18n.of(context);

    // 기본 검증
    // [수정] 전리품 모드일 때는 카테고리 선택을 강제하지 않음 (orElse에서 처리됨)
    final bool isCategoryValid = _isTrophyMode || _selectedCategoryId != null;

    if (!isCategoryValid || amount == null || (!_isTrophyMode && amount <= 0)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(i18n.snackBarSelect)));
      }
      return;
    }

    // 전리품 모드라면 은행 확인 없이 바로 저장 루틴 진입
    if (_isTrophyMode) {
      final bool success = await _performActualSaving();
      if (success && mounted) {
        // [Victory Feedback Loop] WoW Effect & Navigation
        ref.read(rewardStateProvider.notifier).triggerConfetti();
        SoundService().playFirework();

        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          context.pop(); // 유혹 파괴 프로토콜 화면으로 복귀
        }
      }
      return;
    }

    // 목표 확인
    final wishlistAsync = ref.read(wishlistProvider);
    final activeWishlists = wishlistAsync.maybeWhen(
      data: (list) => list.where((w) => !w.isAchieved).toList(),
      orElse: () => [],
    );

    if (activeWishlists.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('목표를 먼저 설정하세요')));
      }
      return;
    }

    // 1. 엔진 가동감 (Medium Impact)
    await HapticService.medium();

    // 2. 계좌 정보 확인
    final info = await _bankAccountService.getAccountInfo();
    final accountNo = info['accountNumber'];

    if (accountNo == null || accountNo.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('송금 계좌 정보가 설정되어 있지 않습니다. 설정에서 등록해주세요.')),
        );
      }
      return;
    }

    // 3. 토스 딥링크 실행 (Step 3: Protocol with Fallback)
    await _bankAccountService.launchToss(
      accountNo: accountNo,
      amount: amount,
      onFallback: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '토스 연결 실패. 계좌번호가 복사되었습니다. 은행 앱을 직접 열어주세요.',
                style: TextStyle(
                  color: Color(0xFFD4FF00), // neonLime
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              shape: const StadiumBorder(),
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            ),
          );
        }
      },
    );

    // [Step 4] Mark waiting if successful or even if fallback (user will confirm later)
    setState(() {
      _isWaitingForTransfer = true;
    });
  }

  void _showSuccessDialog() {
    final theme = Theme.of(context);
    final vibeTheme = theme.extension<VibeThemeExtension>();
    final colors = vibeTheme?.colors;
    final isPureFinance = colors is PureFinanceColors;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors?.surface ?? Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '송금을 완료했나요?',
          style: TextStyle(
            color: colors?.textMain ?? Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '확인을 누르면 실제 저축 데이터가 기록됩니다.',
          style: TextStyle(color: colors?.textSub ?? Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isWaitingForTransfer = false;
              });
              Navigator.pop(dialogContext);
            },
            child: Text(
              '취소',
              style: TextStyle(color: colors?.textSub ?? Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors?.accent ?? const Color(0xFFD4FF00),
              foregroundColor: isPureFinance ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              // 1. 팝업 먼저 닫기 (dialogContext 사용)
              Navigator.pop(dialogContext);

              // 2. 저축 데이터 기록 (Neural Sync Protocol 포함)
              // [버그 수정] 사용자가 무결성 검사에서 '다시 확인'을 눌렀을 경우 여기서 중단되어야 함
              final bool success = await _performActualSaving();
              if (success != true) return; // '다시 확인하기'를 눌렀을 때 차가운 침묵을 실현

              // 3. 보상 및 효과 (검증 완료 후 실행)
              ref.read(rewardStateProvider.notifier).triggerConfetti();
              // [Added] Sensory Feedback: Firework Sound & Strong Vibration
              SoundService().playFirework();
              HapticService.vibrate();

              // 4. 목표 탭으로 즉시 이동 (메인 context 사용)
              if (mounted) {
                // context.go('/') 대신 GoRouter.of(context).go('/') 사용 권장되나 context.go()도 screen context면 문제없음
                context.go('/');
                ref.read(navigationIndexProvider.notifier).setIndex(1);
              }
            },
            child: const Text('네(확인)'),
          ),
        ],
      ),
    );
  }

  Future<bool> _performActualSaving() async {
    if (_isLoading) return false;

    final theme = Theme.of(context);
    final vibeTheme = theme.extension<VibeThemeExtension>();
    final colors = vibeTheme?.colors;
    final isPureFinance = colors is PureFinanceColors;
    final i18n = I18n.of(context);

    final cleanText = _amountController.text
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    final amount = int.tryParse(cleanText);

    if (amount == null || amount < 0) {
      debugPrint('PerformActualSaving Failed: Invalid amount $amount');
      return false;
    }

    setState(() {
      _isLoading = true;
    });

    debugPrint('Starting _performActualSaving... isLoading set to true');

    try {
      // [Neural Sync Protocol] 5-Second Sync Overlay
      await _showSyncOverlay();

      // [Neural Sync Protocol] 10% Probability Integrity Check
      // [Rapid Sync] Skip if Trophy Mode
      if (!_isTrophyMode && math.Random().nextInt(10) == 0) {
        final bool? isHonest = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const _IntegrityCheckDialog(),
        );

        if (isHonest != true) {
          setState(() => _isLoading = false);
          return false; // 차가운 침묵: 모든 보상 시퀀스 중단
        }
      }

      String finalCategoryName = '';
      final categories = ref.read(categoryProvider).value ?? [];

      final category = categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => _isTrophyMode
            ? const CategoryModel(
                id: 'system_optimization',
                name: '유혹방어 & 자산지킴',
              )
            : const CategoryModel(id: 'unknown', name: 'Unknown'),
      );
      finalCategoryName = category.name;

      // 목표 확인 (비동기 처리)
      // [CRITICAL FIX] 앱이 재시작되었거나 로딩 중일 수 있으므로 future를 대기해야 함
      debugPrint('Fetching wishlist data...');
      List<WishlistModel> allWishlists = [];
      try {
        allWishlists = await ref.read(wishlistProvider.future);
      } catch (e) {
        debugPrint('Failed to load wishlists: $e');
        setState(() => _isLoading = false);
        return false;
      }

      final activeWishlists = allWishlists.where((w) => !w.isAchieved).toList();

      if (activeWishlists.isEmpty) {
        setState(() => _isLoading = false);
        debugPrint('No active wishlists found.');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('활성화된 목표가 없습니다.')));
        }
        return false;
      }
      final targetWishlistId = activeWishlists.first.id!;

      debugPrint(
        'Executing performActualSaving: Category: $finalCategoryName, Amount: $amount, Target: $targetWishlistId',
      );

      // 1. 저축 데이터 저장
      await ref
          .read(savingProvider.notifier)
          .addSaving(
            category: finalCategoryName,
            amount: amount,
            createdAt: DateTime.now(),
            note: _memoController.text.trim(),
            wishlistIds: [targetWishlistId],
          );

      if (mounted) {
        HapticService.success();
        // [수정] 이동 후 해당 화면에서 폭죽을 터뜨리므로 로컬 폭죽은 제거
        // _confettiController.play();

        if (mounted) {
          _amountController.clear();
          setState(() {
            _selectedCategoryId = null;
            _isLoading = false;
            _isWaitingForTransfer = false;
          });
          if (mounted) {
            FocusScope.of(context).unfocus();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                i18n.isKorean ? '성공적으로 구출했습니다!' : 'Saved successfully!',
                style: TextStyle(
                  color: isPureFinance ? colors.textMain : Colors.white,
                ),
              ),
              backgroundColor: isPureFinance
                  ? colors.surface
                  : const Color(0xFF1A1A1A),
            ),
          );
        }
      }
      return true; // 성공 시에만 true 반환
    } catch (e) {
      debugPrint('Saving error: $e');
      setState(() => _isLoading = false);
      return false; // 에러 시 false 반환
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final categoriesAsync = ref.watch(categoryProvider);
    final categories = categoriesAsync.asData?.value ?? [];

    // Theme Access
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final themeMode = ref.watch(themeNotifierProvider);
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;
    final isPure = colors.background != const Color(0xFF121212); // Check mode

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent OS keyboard resizing
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          i18n.recordSavingTitle,
          style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textMain),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(i18n.whatDidYouResist, colors),
                  const SizedBox(height: 16),

                  // Category Grid
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: categories
                        .where(
                          (c) => c.id != 'system_optimization',
                        ) // [UI Refinement] Hide System Category
                        .map((category) {
                          final isSelected = _selectedCategoryId == category.id;
                          final iconData = _getIconData(category.iconPath);

                          return BouncyButton(
                            onTap: () {
                              debugPrint(
                                '[DEBUG] Category tapped: ${category.id}',
                              );
                              setState(() {
                                if (isSelected) {
                                  _selectedCategoryId = null;
                                } else {
                                  _selectedCategoryId = category.id;
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colors.accent.withValues(alpha: 0.2)
                                    : colors.surface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: isSelected
                                      ? colors
                                            .accent // Neon Green
                                      : Colors.transparent,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colors.accent.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    iconData,
                                    size: 20,
                                    color: isSelected
                                        ? colors.accent
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? colors.accent
                                          : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),

                  const SizedBox(height: 40),
                  _buildSectionTitle(i18n.howMuchSaved, colors),
                  const SizedBox(height: 16),

                  // Amount Input
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                      boxShadow: isPure
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                              ),
                            ]
                          : null,
                    ),
                    child: TextField(
                      controller: _amountController,
                      // [Step 1] Custom Keypad Setup
                      readOnly: true, // Prevent system keyboard
                      onTap: () => _showKeypad(context),
                      showCursor: true, // Show cursor to indicate focus
                      keyboardType: TextInputType.none, // No system keyboard
                      style: TextStyle(
                        color: colors.textMain,
                        fontSize: 24,
                        fontWeight: FontWeight.w900, // Thick font
                      ),
                      decoration: InputDecoration(
                        hintText: '0', // Hint is '0'
                        hintStyle: TextStyle(
                          color: colors.textSub,
                          fontWeight: FontWeight.w900, // Thick hint
                        ),
                        border: InputBorder.none,
                        suffixText: i18n.isKorean ? "원" : "",
                        suffixStyle: TextStyle(
                          color: colors.textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        prefixText: i18n.isKorean ? "" : "\$ ",
                        prefixStyle: TextStyle(
                          color: colors.textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _QuickAmountButton(
                        label: '+1,000',
                        amount: 1000,
                        onPressed: _addAmount,
                      ),
                      _QuickAmountButton(
                        label: '+5,000',
                        amount: 5000,
                        onPressed: _addAmount,
                      ),
                      _QuickAmountButton(
                        label: '+10,000',
                        amount: 10000,
                        onPressed: _addAmount,
                      ),
                    ],
                  ),

                  // Memo Section (Conditional with Animation)
                  Visibility(
                    visible: _isTrophyMode,
                    child: AnimatedOpacity(
                      opacity: _isTrophyMode ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeIn,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 32),
                          _buildInlineSyncAnimation(colors),
                          const SizedBox(height: 8),
                          _buildSectionTitle('메모 (전리품 기록)', colors),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border),
                            ),
                            child: TextField(
                              controller: _memoController,
                              style: TextStyle(color: colors.textMain),
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: i18n.isKorean
                                    ? '유혹을 이겨낸 소감을 기록하세요...'
                                    : 'Add a trophy note...',
                                hintStyle: TextStyle(
                                  color: colors.textSub.withValues(alpha: 0.5),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  _buildTargetGoalCard(colors, isPureFinance),

                  const SizedBox(height: 40),

                  // Save Button
                  Builder(
                    builder: (context) {
                      final amountText = _amountController.text.isEmpty
                          ? '0'
                          : _amountController.text;

                      if (isPureFinance) {
                        return BouncyButton(
                          onTap: _isLoading
                              ? () {}
                              : () {
                                  debugPrint(
                                    '[DEBUG] Save Button (PureFinance) tapped. Calling _submit.',
                                  );
                                  _submit();
                                },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: _isTrophyMode
                                  ? const Color(0xFFA6CC00) // Deeper neon lime
                                  : colors.accent,
                              borderRadius: BorderRadius.circular(18),
                              // PRD-compliant shadow
                              boxShadow: [
                                BoxShadow(
                                  color: colors.accent.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.send_rounded,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _isTrophyMode
                                              ? "전리품 기록 저장 및 동기화"
                                              : (i18n.isKorean
                                                    ? '송금으로 구출하기'
                                                    : 'Rescue with Transfer'),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _isTrophyMode
                                              ? '파괴 결과 저장하기'
                                              : '$amountText원 송금하기',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (_isLoading)
                                  const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                        effects: [
                          CustomEffect(
                            duration: 2500.ms,
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              final glowOpacity =
                                  0.2 + (value * 0.3); // 0.2 -> 0.5
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 24,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colors.accent.withValues(
                                        alpha: glowOpacity,
                                      ),
                                      blurRadius: 10, // Reduced from 20
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: child,
                              );
                            },
                          ),
                        ],
                        child: BouncyButton(
                          onTap: _isLoading
                              ? () {}
                              : () {
                                  debugPrint(
                                    '[DEBUG] Save Button tapped. Calling _submit.',
                                  );
                                  _submit();
                                },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.send_rounded,
                                    size: 50,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _isTrophyMode
                                              ? "전리품 기록 저장 및 동기화"
                                              : (i18n.isKorean
                                                    ? '송금으로 구출하기'
                                                    : 'Rescue with Transfer'),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _isTrophyMode
                                              ? '파괴 결과 저장하기'
                                              : '토스뱅크로 $amountText원 송금',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_isLoading)
                                const CircularProgressIndicator(
                                  color: Colors.black,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Defeat Button (Asset Leak Declaration)
                  // [Modified] Step 1: Defeat Button Overhaul
                  // Defeat Button (Asset Leak Declaration)
                  // Defeat Button (Asset Leak Declaration)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                      effects: [
                        CustomEffect(
                          duration: 2500.ms,
                          curve: Curves.easeInOut,
                          builder: (context, value, child) {
                            final glowOpacity =
                                0.2 + (value * 0.3); // Restore missing variable
                            return Container(
                              decoration: BoxDecoration(
                                color: colors.danger.withValues(
                                  alpha: 0.1,
                                ), // Faint background
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.danger,
                                  width: 2,
                                ), // Solid Red Border
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.danger.withValues(
                                      alpha: glowOpacity,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                        ),
                      ],
                      child: InkWell(
                        onTap: _showDefeatDialog,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 24,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 45, // Reduced from 50 (10% decrease)
                                color: colors
                                    .danger, // Changed to red for visibility
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "지출 발생 신고",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 20,
                                            color:
                                                colors.danger, // Changed to red
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "[CODE: 402_LEAK]",
                                          style: TextStyle(
                                            color: colors.danger.withValues(
                                              alpha: 0.7,
                                            ),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Courier',
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "유혹 방어 실패 시 피해 규모를 기록하십시오.",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: colors.danger.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  // List
                  _TodaysRecordsList(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // System Warning (Step 1 of Neural Sync Protocol - Optimized)
          IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Opacity(
                  opacity: 0.1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '허위 정보 입력 시 시스템 오류로 인해 자산 기록이 모두 꼬일 수 있습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.greenAccent,
                Colors.pinkAccent,
                Colors.white,
              ],
              gravity: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineSyncAnimation(VibeColors colors) {
    return AnimatedBuilder(
      animation: _syncController,
      builder: (context, child) {
        final flickerVal =
            (math.sin(DateTime.now().millisecondsSinceEpoch / 50) * 0.2) + 0.8;
        final slideProgress = _syncController.value;

        // [Rapid Sync] Speed up inline animation if Trophy Mode
        // This is a visual trick: we use the same controller but map the value differently
        // effectively speeding it up visually if we wanted, but here we rely on controller duration.
        // Since controller duration is set in initState, this is just rendering.

        return SizedBox(
          height: 30,
          child: Stack(
            children: [
              Positioned(
                left: (slideProgress * 300) - 100,
                child: Opacity(
                  opacity: flickerVal.clamp(0.4, 1.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4FF00),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFD4FF00,
                              ).withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'system sync...',
                        style: TextStyle(
                          color: Color(0xFFD4FF00),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTargetGoalCard(VibeColors colors, bool isPureFinance) {
    return ref
        .watch(wishlistProvider)
        .when(
          data: (wishlists) {
            final activeWishlists = wishlists
                .where((w) => !w.isAchieved)
                .toList();
            if (activeWishlists.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  "설정된 목표가 없습니다",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final target = activeWishlists.first;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "인질로 잡힌 목표",
                  style: TextStyle(
                    color: colors.textSub.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      if (target.imageUrl != null &&
                          target.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            target.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 48,
                              height: 48,
                              color: colors.surface,
                              child: Icon(Icons.image, color: colors.textSub),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image, color: colors.textSub),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          target.title,
                          style: TextStyle(
                            color: colors.textMain,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        );
  }

  Widget _buildSectionTitle(String title, VibeColors colors) {
    return Text(
      title,
      style: TextStyle(
        color: colors.textMain,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  final String label;
  final int amount;
  final Function(int) onPressed;

  const _QuickAmountButton({
    required this.label,
    required this.amount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    return OutlinedButton(
      onPressed: () => onPressed(amount),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textMain,
        side: BorderSide(color: colors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(label),
    );
  }
}

class _TodaysRecordsList extends ConsumerStatefulWidget {
  @override
  ConsumerState<_TodaysRecordsList> createState() => _TodaysRecordsListState();
}

class _TodaysRecordsListState extends ConsumerState<_TodaysRecordsList> {
  bool _isExpanded = true;
  int _previousCount = 0;

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final savingAsync = ref.watch(savingProvider);
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;

    return savingAsync.when(
      data: (savings) {
        final now = DateTime.now();
        final todayParams = DateTime(now.year, now.month, now.day);
        final todaysRecords = savings.where((s) {
          final sDate = DateTime(
            s.createdAt.year,
            s.createdAt.month,
            s.createdAt.day,
          );
          return sDate.isAtSameMomentAs(todayParams);
        }).toList();

        // Auto-expand logic
        if (todaysRecords.length > _previousCount) {
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _isExpanded = true;
                _previousCount = todaysRecords.length;
              });
            }
          });
        } else if (todaysRecords.length < _previousCount) {
          Future.microtask(() {
            if (mounted) {
              setState(() {
                _previousCount = todaysRecords.length;
              });
            }
          });
        }

        if (todaysRecords.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    i18n.isKorean ? "오늘의 기록" : "Today's Records",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textSub,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colors.textSub,
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded
                  ? Column(
                      children: [
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: todaysRecords.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = todaysRecords[index];
                            if (item.id.isEmpty) return const SizedBox.shrink();

                            return Dismissible(
                                  key: ValueKey(item.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    try {
                                      await ref
                                          .read(savingProvider.notifier)
                                          .deleteSaving(item.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              i18n.isKorean
                                                  ? "기록이 삭제되었습니다"
                                                  : "Record deleted",
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                          ),
                                        );
                                      }
                                      return true;
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Delete failed: ${e.toString()}",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return false;
                                    }
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withAlpha(204),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        if (item.category == '유혹방어 & 자산지킴')
                                          const Icon(
                                            Icons.whatshot,
                                            color: Color(
                                              0xFFD4FF00,
                                            ), // [Visual Tuning] Neon Lime Icon
                                            size: 24,
                                          )
                                        else
                                          Text(
                                            _getCategoryIcon(item.category),
                                            style: const TextStyle(
                                              fontSize: 20,
                                            ),
                                          ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            (item.note ?? '').isNotEmpty
                                                ? item.note!
                                                : item.category,
                                            style: TextStyle(
                                              color:
                                                  item.category == '유혹방어 & 자산지킴'
                                                  ? Colors
                                                        .white // [Visual Tuning] Revert Title to White
                                                  : colors.textMain,
                                              fontWeight:
                                                  item.category == '유혹방어 & 자산지킴'
                                                  ? FontWeight.w900
                                                  : FontWeight.w500,
                                              fontSize: 15,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '+ ${i18n.formatCurrency(item.amount.toDouble())}',
                                          style: TextStyle(
                                            color:
                                                item.category == '유혹방어 & 자산지킴'
                                                ? const Color(
                                                    0xFFD4FF00,
                                                  ) // [Visual Tuning] Neon Lime Amount
                                                : (Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.light
                                                      ? colors.textMain
                                                      : colors.accent),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideX(
                                  begin: 0.1,
                                  end: 0,
                                  curve: Curves.easeOutQuart,
                                );
                          },
                        ),
                        const SizedBox(height: 48),
                      ],
                    )
                  : const SizedBox(height: 24),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text("Error: $e"),
    );
  }
}

String _getCategoryIcon(String category) {
  final lower = category.toLowerCase();
  if (lower.contains('커피') || lower.contains('coffee')) return '☕';
  if (lower.contains('술') || lower.contains('alcohol')) return '🍺';
  if (lower.contains('택시') || lower.contains('taxi')) return '🚕';
  if (lower.contains('야식') || lower.contains('snack')) return '🍔';
  if (lower.contains('배달') || lower.contains('food')) return '🛵';
  if (lower.contains('쇼핑') || lower.contains('shopping')) return '🛍️';
  if (lower.contains('담배') || lower.contains('cigarette')) return '🚬';
  if (lower.contains('게임') || lower.contains('game')) return '🎮';
  return '💸';
}

class _NeuralSyncOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final bool isRapidMode;

  const _NeuralSyncOverlay({
    required this.onComplete,
    this.isRapidMode = false,
  });

  @override
  State<_NeuralSyncOverlay> createState() => _NeuralSyncOverlayState();
}

class _NeuralSyncOverlayState extends State<_NeuralSyncOverlay> {
  List<String> _logs = [
    "[SYNC] 금융망 데이터 정밀 스캔 중...",
    "[VERIFY] 송금 신호와 실제 내역 교차 검증...",
    "[NERVE] 입력된 정보의 진실성 판별 중...",
    "[AUTH] 외부 금융 서버 응답 대기 중...",
  ];
  int _logIndex = 0;
  Timer? _logTimer;

  @override
  void initState() {
    super.initState();

    // [Rapid Sync] 설정을 반영한 타이머/로그 설정
    final totalDuration = widget.isRapidMode ? 1500 : 5000;

    if (widget.isRapidMode) {
      _logs = ["[SYSTEM] 전리품 데이터 고속 업로드 중..."];
    }

    // Timer Interval: Total / Message Count
    // Rapid: 1500 / 1 = 1500ms
    // Normal: 5000 / 4 = 1250ms
    final interval = (totalDuration / _logs.length).floor();

    _logTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (mounted) {
        setState(() {
          _logIndex = (_logIndex + 1) % _logs.length;
        });
      }
    });

    Future.delayed(Duration(milliseconds: totalDuration), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _logTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EngineCoreWidget(isAccelerated: true),
            const Padding(
              padding: EdgeInsets.only(top: 48),
            ), // Increased vertical spacing
            // Fade-in/out Log Text
            Container(
              height: 24,
              child:
                  Text(
                        _logs[_logIndex],
                        key: ValueKey(_logIndex),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD4FF00),
                          fontFamily: 'Courier',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                      .animate(key: ValueKey('anim_$_logIndex'))
                      .fadeIn(duration: (widget.isRapidMode ? 200 : 300).ms)
                      .then(delay: (widget.isRapidMode ? 1000 : 750).ms)
                      .fadeOut(duration: (widget.isRapidMode ? 200 : 200).ms),
            ),
            const Padding(padding: EdgeInsets.only(top: 16)),
            const Text(
                  "PROCESSSING NEURAL SYNC...",
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w300,
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2.seconds, color: Colors.white10),
          ],
        ),
      ),
    );
  }
}

class _IntegrityCheckDialog extends StatelessWidget {
  const _IntegrityCheckDialog();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;

    return AlertDialog(
      backgroundColor: const Color(0xFF121212),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFD4FF00), width: 1),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.report_problem_rounded,
            color: Color(0xFFD4FF00),
            size: 24,
          ),
          const Padding(padding: EdgeInsets.only(right: 12)),
          Text(
            '데이터 정밀 검증 실패',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      content: const Text(
        '송금 신호와 입력 정보 사이의 비대칭이 감지되었습니다. 부정확한 기록은 자산 엔진의 분석 오차를 발생시킵니다. 실제 송금 여부를 다시 확인하십시오.',
        style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(false), // '다시 확인' -> false 반환
          child: Text('다시 확인', style: TextStyle(color: colors.textSub)),
        ),
        ElevatedButton(
          onPressed: () =>
              Navigator.of(context).pop(true), // '데이터 확정' -> true 반환
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4FF00),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 0,
          ),
          child: const Text(
            '데이터 확정',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
