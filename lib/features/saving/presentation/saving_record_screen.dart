import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/i18n.dart';
import 'package:vive_app/core/theme/app_theme.dart';
import 'package:vive_app/core/services/bank_account_service.dart';

import 'package:vive_app/features/saving/domain/category_model.dart';
import 'package:vive_app/features/saving/providers/category_provider.dart';
import 'package:vive_app/features/saving/providers/saving_provider.dart';
import 'package:vive_app/features/wishlist/providers/wishlist_provider.dart';
import 'package:vive_app/core/theme/theme_provider.dart';

class SavingRecordScreen extends ConsumerStatefulWidget {
  const SavingRecordScreen({super.key});

  @override
  ConsumerState<SavingRecordScreen> createState() => _SavingRecordScreenState();
}

class _SavingRecordScreenState extends ConsumerState<SavingRecordScreen>
    with WidgetsBindingObserver {
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _bankAccountService = BankAccountService();
  late ConfettiController _confettiController;
  String? _selectedCategoryId;
  bool _addToCategories = false;
  String? _selectedWishlistId;
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
    _customCategoryController.dispose();
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
    final current = int.tryParse(_amountController.text) ?? 0;
    _amountController.text = (current + amount).toString();
  }

  void _selectWishlist(String id) {
    setState(() {
      if (_selectedWishlistId == id) {
        _selectedWishlistId = null;
      } else {
        _selectedWishlistId = id;
      }
    });
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
    final String url =
        'supertoss://send?bank=092&accountNo=$accountNo&amount=$amount';
    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        setState(() {
          _isWaitingForTransfer = true;
        });
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('토스 앱을 실행할 수 없습니다.')));
        }
      }
    } catch (e) {
      debugPrint('Deep Link Error: $e');
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
      builder: (context) => AlertDialog(
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
              Navigator.pop(context);
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
              Navigator.pop(context);
              await _performActualSaving();
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
      if (_selectedCategoryId == 'other') {
        final customName = _customCategoryController.text.trim();
        finalCategoryName = customName;
        if (_addToCategories) {
          await ref.read(categoryProvider.notifier).addCategory(customName);
        }
      } else {
        final category = categories.firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => const CategoryModel(id: 'unknown', name: 'Unknown'),
        );
        finalCategoryName = category.name;
      }

      // 1. 저축 데이터 저장
      await ref
          .read(savingProvider.notifier)
          .addSaving(
            category: finalCategoryName,
            amount: amount,
            createdAt: DateTime.now(),
            wishlistIds: _selectedWishlistId != null
                ? [_selectedWishlistId!]
                : [],
          );

      // 2. 위시리스트 금액 업데이트
      if (_selectedWishlistId != null) {
        await ref.read(wishlistProvider.notifier).addFundsToSelectedItems(
          amount.toDouble(),
          [_selectedWishlistId!],
        );
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        _confettiController.play();

        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          _amountController.clear();
          _customCategoryController.clear();
          setState(() {
            _selectedCategoryId = null;
            _selectedWishlistId = null;
            _addToCategories = false;
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

    // [수정된 스마트 동기화 로직]
    ref.listen(wishlistProvider, (previous, next) {
      if (next is AsyncData) {
        final wishlists = next.asData!.value;
        if (wishlists.isEmpty) return;

        // 1. 현재 활성화된(달성 전) 목표들 중 '대표'를 찾음
        final activeWishlists = wishlists.where((w) => !w.isAchieved).toList();
        if (activeWishlists.isEmpty) return;

        final currentRep = activeWishlists.firstWhere(
          (w) => w.isRepresentative,
          orElse: () => activeWishlists.first,
        );

        // 2. [핵심] 현재 선택된 ID가 실제 '대표'와 다르다면 강제 동기화
        if (_selectedWishlistId != currentRep.id) {
          setState(() => _selectedWishlistId = currentRep.id);
        }
      }
    });

    // Theme Access
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final themeMode = ref.watch(themeNotifierProvider);
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;
    final isPure = colors.background != const Color(0xFF121212); // Check mode

    return Scaffold(
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
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ...categories.map((category) {
                        final isSelected = _selectedCategoryId == category.id;
                        return GestureDetector(
                          onLongPress: category.isCustom
                              ? () {
                                  // Simplified delete dialog for custom categories
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: colors.surface,
                                      title: Text(
                                        i18n.isKorean ? '삭제' : 'Delete',
                                        style: TextStyle(
                                          color: colors.textMain,
                                        ),
                                      ),
                                      content: Text(
                                        "'${category.name}'",
                                        style: TextStyle(color: colors.textSub),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => context.pop(),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            ref
                                                .read(categoryProvider.notifier)
                                                .deleteCategory(category.id);
                                            if (isSelected)
                                              setState(
                                                () =>
                                                    _selectedCategoryId = null,
                                              );
                                            context.pop();
                                          },
                                          child: const Text(
                                            "Delete",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              : null,
                          child: FilterChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(
                                () => _selectedCategoryId = selected
                                    ? category.id
                                    : null,
                              );
                            },
                            backgroundColor: isPureFinance
                                ? colors.surface
                                : Colors.black, // Cyberpunk: Black
                            selectedColor: isPureFinance
                                ? colors.accent
                                : Colors
                                      .black, // Cyberpunk: Keep background black
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? (isPureFinance
                                        ? Colors.white
                                        : const Color(
                                            0xFFD4FF00,
                                          )) // Cyberpunk: Neon Green
                                  : (isPureFinance
                                        ? colors.textMain
                                        : Colors.white70),
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                color: isSelected
                                    ? (isPureFinance
                                          ? colors.accent
                                          : const Color(
                                              0xFFD4FF00,
                                            )) // Cyberpunk: Neon Green
                                    : (isPureFinance
                                          ? Colors.transparent
                                          : Colors.white12),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                          ),
                        );
                      }),
                      // Other Category
                      FilterChip(
                        label: Text(i18n.categoryName('Other')),
                        selected: _selectedCategoryId == 'other',
                        onSelected: (selected) {
                          setState(
                            () =>
                                _selectedCategoryId = selected ? 'other' : null,
                          );
                        },
                        backgroundColor: isPureFinance
                            ? colors.surface
                            : Colors.black,
                        selectedColor: isPureFinance
                            ? colors.accent
                            : Colors.black,
                        labelStyle: TextStyle(
                          color: _selectedCategoryId == 'other'
                              ? (isPureFinance
                                    ? Colors.white
                                    : const Color(0xFFD4FF00))
                              : (isPureFinance
                                    ? colors.textMain
                                    : Colors.white70),
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color: _selectedCategoryId == 'other'
                                ? (isPureFinance
                                      ? colors.accent
                                      : const Color(0xFFD4FF00))
                                : (isPureFinance
                                      ? Colors.transparent
                                      : Colors.white12),
                            width: _selectedCategoryId == 'other' ? 2 : 1,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_selectedCategoryId == 'other') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customCategoryController,
                      decoration: InputDecoration(
                        labelText: i18n.categoryName('Other'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        filled: true,
                        fillColor: colors.surface,
                        hintText: 'ex) Bubble Tea',
                        hintStyle: TextStyle(color: colors.textSub),
                        labelStyle: TextStyle(color: colors.textSub),
                      ),
                      style: TextStyle(color: colors.textMain),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _addToCategories,
                      onChanged: (value) =>
                          setState(() => _addToCategories = value ?? false),
                      title: Text(
                        i18n.isKorean ? '새 카테고리로 추가' : 'Add to categories',
                        style: TextStyle(color: colors.textMain),
                      ),
                      checkColor: Colors.white,
                      activeColor: colors.accent,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],

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
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: colors.textMain,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: i18n.amountLabel,
                        hintStyle: TextStyle(color: colors.textSub),
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
                  _buildSectionTitle(
                    i18n.isKorean ? '함께 채울 목표 선택' : 'Goals to fill together',
                    colors,
                  ),
                  const SizedBox(height: 16),

                  // Wishlist Multi-Selection
                  ref
                      .watch(wishlistProvider)
                      .when(
                        data: (wishlists) {
                          final activeWishlists = wishlists
                              .where((w) => !w.isAchieved)
                              .toList();

                          if (activeWishlists.isEmpty) {
                            return Text(
                              i18n.isKorean
                                  ? '진행 중인 목표가 없습니다.'
                                  : 'No active goals.',
                              style: TextStyle(
                                color: colors.textSub,
                                fontSize: 14,
                              ),
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: activeWishlists.map((item) {
                              final isSelected = _selectedWishlistId == item.id;
                              return GestureDetector(
                                onTap: () => _selectWishlist(item.id!),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width:
                                      (MediaQuery.of(context).size.width - 56) /
                                      2, // 2-column style
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPureFinance
                                        ? (isSelected
                                              ? colors.accent.withOpacity(0.08)
                                              : colors.surface)
                                        : Colors.black, // 배경을 어둡게 하여 눈부심 방지
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? Border.all(
                                            color: isPureFinance
                                                ? colors.accent
                                                : const Color(
                                                    0xFFD4FF00,
                                                  ), // 선택 시 그린 네온 테두리
                                            width: 2,
                                          )
                                        : Border.all(
                                            color: isPureFinance
                                                ? colors.border
                                                : Colors.white10,
                                          ),
                                    boxShadow: (isSelected && !isPureFinance)
                                        ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFD4FF00,
                                              ).withOpacity(0.3),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: TextStyle(
                                            color: isSelected
                                                ? (isPureFinance
                                                      ? colors.accent
                                                      : const Color(0xFFD4FF00))
                                                : (isPureFinance
                                                      ? colors.textMain
                                                      : Colors.white70),
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        size: 20,
                                        color: isSelected
                                            ? (isPureFinance
                                                  ? colors.accent
                                                  : const Color(0xFFD4FF00))
                                            : (isPureFinance
                                                  ? colors.textSub
                                                  : Colors.white24),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                  const SizedBox(height: 40),

                  // Save Button
                  Builder(
                    builder: (context) {
                      final limeColor = const Color(0xFFD4FF00);
                      final amountText = _amountController.text.isEmpty
                          ? '0'
                          : _amountController.text;

                      if (isPureFinance) {
                        return GestureDetector(
                          onTap: _isLoading ? null : _submit,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.accent.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
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
                                            fontWeight: FontWeight.bold,
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
                                            fontWeight: FontWeight.w500,
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

                      return GestureDetector(
                        onTap: _isLoading ? null : _submit,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: limeColor, width: 3),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: limeColor.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
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
                                    color: Color(0xFFD4FF00),
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
                                            color: Colors.white,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '토스뱅크로 ${amountText}원 송금',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: limeColor.withOpacity(0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_isLoading)
                                const CircularProgressIndicator(
                                  color: Color(0xFFD4FF00),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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
}
