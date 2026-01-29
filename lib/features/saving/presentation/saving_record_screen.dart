import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vive_app/core/utils/i18n.dart';
import 'package:vive_app/core/theme/app_theme.dart';
import 'package:vive_app/core/services/bank_account_service.dart';
import 'package:vive_app/core/services/sound_service.dart';

import 'package:vive_app/features/saving/domain/category_model.dart';
import 'package:vive_app/features/saving/providers/category_provider.dart';
import 'package:vive_app/features/saving/providers/saving_provider.dart';
import 'package:vive_app/features/wishlist/providers/wishlist_provider.dart';
import 'package:vive_app/core/theme/theme_provider.dart';
import 'package:vive_app/features/home/providers/navigation_provider.dart';
import 'package:vive_app/features/dashboard/providers/reward_state_provider.dart';
import 'package:vive_app/features/saving/presentation/widgets/custom_keypad.dart';
import 'package:vive_app/core/ui/bouncy_button.dart';

class SavingRecordScreen extends ConsumerStatefulWidget {
  const SavingRecordScreen({super.key});

  @override
  ConsumerState<SavingRecordScreen> createState() => _SavingRecordScreenState();
}

class _SavingRecordScreenState extends ConsumerState<SavingRecordScreen>
    with WidgetsBindingObserver {
  final _amountController = TextEditingController();
  final _bankAccountService = BankAccountService();
  late ConfettiController _confettiController;
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isWaitingForTransfer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForTransfer) {
      _showSuccessDialog();
    }
  }

  void _addAmount(int amount) {
    // [Added] Sensory Feedback: Chip Sound & Light Vibration
    SoundService().playChip();
    HapticFeedback.lightImpact();

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
      FocusScope.of(context).unfocus();
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
    // 1. Sound: 유리창 깨지는 소리 시뮬레이션 (삭제: 목표 탭 진입 시 재생)
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
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;

    if (mounted) {
      // Haptic Feedback for impact
      HapticFeedback.mediumImpact();

      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.95), // Pitch black overlay
        pageBuilder: (context, anim1, anim2) {
          return PopScope(
            canPop: false, // Prevent back button
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.broken_image_rounded,
                      size: 80,
                      color: Colors.white24,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "실패가 확정되었습니다.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                      ),
                    ),
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
                        border: Border.all(
                          color: colors.danger.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "약속하신 벌칙",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            penaltyText ?? "설정된 벌칙이 없습니다.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (penaltyText != null)
                            const Text(
                              "지금 즉시 수행하십시오.",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 200,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: colors.danger.withOpacity(0.5),
                        ),
                        onPressed: () {
                          // [Added] Trigger Shatter Sound for next screen
                          ref
                              .read(rewardStateProvider.notifier)
                              .triggerShatter();
                          Navigator.of(context).pop(); // Close overlay
                        },
                        child: const Text(
                          "수행하겠습니다",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        transitionBuilder: (context, anim1, anim2, child) {
          return FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      );
    }

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
      builder: (context) => AlertDialog(
        backgroundColor: colors?.background ?? const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors?.danger ?? Colors.redAccent),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: colors?.danger ?? Colors.redAccent,
            ),
            SizedBox(width: 8),
            Text(
              '마지막 경고',
              style: TextStyle(
                color: colors?.danger ?? Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '패배를 인정하시겠습니까?\n이 선택은 되돌릴 수 없으며,\n설정하신 벌칙을 즉시 수행해야 합니다.',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text(
              '얼마를 낭비했습니까?',
              style: TextStyle(color: colors?.textSub ?? Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '금액 입력',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: colors?.danger ?? Colors.redAccent,
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: colors?.danger ?? Colors.redAccent,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors?.danger ?? Colors.red[900],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              _executeDefeatSequence(amount);
            },
            child: const Text('패배 확정'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    final cleanerText = _amountController.text
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    final amount = int.tryParse(cleanerText);
    final i18n = I18n.of(context);

    // 기본 검증
    if (_selectedCategoryId == null || amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(i18n.snackBarSelect)));
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

    // 1. 강한 진동
    await HapticFeedback.heavyImpact();

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

    // 3. 토스 딥링크 실행
    // 계좌번호 정제 (하이픈, 공백 제거)
    final cleanAccountNo = accountNo.replaceAll(RegExp(r'[^0-9]'), '');
    final String url =
        'supertoss://send?bank=092&accountNo=$cleanAccountNo&amount=$amount';
    final Uri uri = Uri.parse(url);

    try {
      final bool canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        setState(() {
          _isWaitingForTransfer = true;
        });
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: canLaunchUrl may fail on some Android versions even with <queries>
        // Try launching directly as a last resort
        try {
          setState(() {
            _isWaitingForTransfer = true;
          });
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (innerError) {
          // 웹 테스트용 시뮬레이션: 앱 실행 실패 시에도 다이얼로그 강제 호출
          debugPrint(
            'Toss app not found (inner). Simulation Mode: Showing success dialog.',
          );
          _showSuccessDialog();
        }
      }
    } catch (e) {
      debugPrint(
        'Deep Link Error: $e. Simulation Mode: Showing success dialog.',
      );
      _showSuccessDialog();
    }
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

              // 2. 보상 장전 (전역 폭죽 신호 + 사운드)
              ref.read(rewardStateProvider.notifier).triggerConfetti();
              // [Added] Sensory Feedback: Firework Sound & Strong Vibration
              SoundService().playFirework();
              HapticFeedback.vibrate();

              // 3. 저축 데이터 기록
              await _performActualSaving();

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

  Future<void> _performActualSaving() async {
    if (_isLoading) return;

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

    if (amount == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String finalCategoryName = '';
      final categories = ref.read(categoryProvider).value ?? [];

      final category = categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => const CategoryModel(id: 'unknown', name: 'Unknown'),
      );
      finalCategoryName = category.name;

      // 목표 확인
      final wishlistAsync = ref.read(wishlistProvider);
      final activeWishlists = wishlistAsync.maybeWhen(
        data: (list) => list.where((w) => !w.isAchieved).toList(),
        orElse: () => [],
      );

      if (activeWishlists.isEmpty) return;
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
            wishlistIds: [targetWishlistId],
          );

      if (mounted) {
        HapticFeedback.mediumImpact();
        // [수정] 이동 후 해당 화면에서 폭죽을 터뜨리므로 로컬 폭죽은 제거
        // _confettiController.play();

        if (mounted) {
          _amountController.clear();
          setState(() {
            _selectedCategoryId = null;
            _isLoading = false;
            _isWaitingForTransfer = false;
          });
          FocusScope.of(context).unfocus();

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
    } catch (e) {
      debugPrint('Saving error: $e');
      setState(() => _isLoading = false);
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
                    children: categories.map((category) {
                      final isSelected = _selectedCategoryId == category.id;
                      final iconData = _getIconData(category.iconPath);

                      return BouncyButton(
                        onTap: () {
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
                                ? colors.accent.withOpacity(0.2)
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
                                      color: colors.accent.withOpacity(0.4),
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
                    }).toList(),
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
                                color: Colors.black.withOpacity(0.05),
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

                  const SizedBox(height: 40),
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
                          onTap: _isLoading ? () {} : _submit,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(18),
                              // PRD-compliant shadow
                              boxShadow: [
                                BoxShadow(
                                  color: colors.accent.withOpacity(0.3),
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
                                          '송금으로 구출하기',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${amountText}원 송금하기',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withOpacity(
                                              0.9,
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

                      return BouncyButton(
                        onTap: _isLoading ? () {} : _submit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(20),
                            // PRD: Neon Glow Optimization
                            boxShadow: [
                              BoxShadow(
                                color: colors.accent.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
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
                                        const Text(
                                          '송금으로 구출하기',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '토스뱅크로 ${amountText}원 송금',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black.withOpacity(
                                              0.7,
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

                  const SizedBox(height: 16),

                  // Defeat Button (시인성 강화 버전)
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.danger.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: TextButton.icon(
                        onPressed: _showDefeatDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: colors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.warning_amber_rounded, size: 20),
                        label: const Text(
                          "패배 버튼",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),
                  // List
                  _TodaysRecordsList(),
                ],
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
                  color: Colors.white.withOpacity(0.05),
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
                    color: colors.textSub.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
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
            if (mounted)
              setState(() {
                _isExpanded = true;
                _previousCount = todaysRecords.length;
              });
          });
        } else if (todaysRecords.length < _previousCount) {
          Future.microtask(() {
            if (mounted)
              setState(() {
                _previousCount = todaysRecords.length;
              });
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
                                        Text(
                                          _getCategoryIcon(item.category),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          item.category,
                                          style: TextStyle(
                                            color: colors.textMain,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '+ ${i18n.formatCurrency(item.amount.toDouble())}',
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? colors.textMain
                                                : colors.accent,
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
