import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../../core/utils/i18n.dart';
import 'package:vive_app/core/theme/app_theme.dart';

import 'package:vive_app/features/saving/domain/category_model.dart';
import 'package:vive_app/features/saving/providers/category_provider.dart';
import 'package:vive_app/features/saving/providers/saving_provider.dart';
import 'package:vive_app/features/wishlist/providers/wishlist_provider.dart';
import 'package:vive_app/core/theme/theme_provider.dart';
import 'package:vive_app/features/dashboard/providers/achievement_provider.dart';

class SavingRecordScreen extends ConsumerStatefulWidget {
  const SavingRecordScreen({super.key});

  @override
  ConsumerState<SavingRecordScreen> createState() => _SavingRecordScreenState();
}

class _SavingRecordScreenState extends ConsumerState<SavingRecordScreen> {
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  late ConfettiController _confettiController;
  String? _selectedCategoryId;
  bool _addToCategories = false;
  String? _selectedWishlistId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customCategoryController.dispose();
    _confettiController.dispose();
    super.dispose();
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

    final theme = Theme.of(context);
    final vibeTheme = theme.extension<VibeThemeExtension>();
    final colors = vibeTheme?.colors;
    final isPureFinance = colors is PureFinanceColors;
    final i18n = I18n.of(context);

    // 입력값 정제
    final cleanText = _amountController.text
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    final amount = int.tryParse(cleanText);

    if (_selectedCategoryId == null || amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(i18n.snackBarSelect)));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 카테고리 처리 로직
      String finalCategoryName = '';
      final categories = ref.read(categoryProvider).value ?? [];
      if (_selectedCategoryId == 'other') {
        final customName = _customCategoryController.text.trim();
        if (customName.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(i18n.snackBarSelect)));
            setState(() => _isLoading = false);
          }
          return;
        }
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
      final wishlistNotifier = ref.read(wishlistProvider.notifier);
      if (_selectedWishlistId != null) {
        await wishlistNotifier.addFundsToSelectedItems(amount.toDouble(), [
          _selectedWishlistId!,
        ]);
      }

      if (mounted) {
        // [변경 1] 상태 업데이트 감지를 위해 500ms 대기 (안정성 확보)
        await Future.delayed(const Duration(milliseconds: 500));

        // 마일스톤 발생 여부 확인
        final hasMilestone =
            ref.read(achievementNotifierProvider).asData?.value != null;

        // 이펙트 실행
        HapticFeedback.mediumImpact();
        _confettiController.play();

        // 사용자 경험을 위해 1.5초 대기
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          // 입력폼 초기화
          _amountController.clear();
          _customCategoryController.clear();
          setState(() {
            _selectedCategoryId = null;
            _selectedWishlistId = null;
            _addToCategories = false;
            _isLoading = false;
          });
          FocusScope.of(context).unfocus();

          // [변경 2] 마일스톤이 없을 때만 일반 배너 표시
          if (!hasMilestone) {
            // 기존 스낵바 정리
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        // [변경 3] 문구 단순화: "성공적으로 저축했습니다!"로 고정
                        i18n.isKorean ? '성공적으로 저축했습니다!' : 'Saved successfully!',
                        style: TextStyle(
                          // 테마별 텍스트 가시성 확보
                          color: colors?.textMain ?? Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                backgroundColor: isPureFinance
                    ? colors.surface
                    : const Color(0xFF1A1A1A),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isPureFinance ? colors.border : Colors.greenAccent,
                    width: isPureFinance ? 1 : 2,
                  ),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        String message = i18n.isKorean ? '저장 중 오류가 발생했습니다.' : 'Failed to save.';
        if (e.toString().contains('ID 유실')) message = '서버 응답 오류: ID 유실';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
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
                                : colors.surface,
                            selectedColor: colors.accent,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isPureFinance
                                        ? colors.textMain
                                        : colors.textMain),
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: BorderSide(
                                color: isSelected
                                    ? colors.accent
                                    : (isPureFinance
                                          ? Colors.transparent
                                          : colors.border),
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
                        backgroundColor: colors.surface,
                        selectedColor: colors.accent,
                        labelStyle: TextStyle(
                          color: _selectedCategoryId == 'other'
                              ? Colors.white
                              : colors.textMain,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color: _selectedCategoryId == 'other'
                                ? colors.accent
                                : colors.border,
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
                            runSpacing: 8,
                            children: activeWishlists.map((item) {
                              final isSelected = _selectedWishlistId == item.id;
                              return FilterChip(
                                label: Text(item.title),
                                selected: isSelected,
                                onSelected: (_) => _selectWishlist(item.id!),
                                backgroundColor: colors.surface,
                                selectedColor: colors.accent.withOpacity(0.2),
                                side: BorderSide(
                                  color: isSelected
                                      ? colors.accent
                                      : colors.border,
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? colors.accent
                                      : colors.textMain,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              i18n.submitButton,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
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
