import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/utils/i18n.dart';

import 'package:vive_app/features/saving/domain/category_model.dart';
import 'package:vive_app/features/saving/providers/category_provider.dart';
import 'package:vive_app/features/saving/providers/saving_provider.dart';
import 'package:vive_app/features/wishlist/providers/wishlist_provider.dart';
import '../../home/providers/navigation_provider.dart';

class SavingRecordScreen extends ConsumerStatefulWidget {
  const SavingRecordScreen({super.key});

  @override
  ConsumerState<SavingRecordScreen> createState() => _SavingRecordScreenState();
}

class _SavingRecordScreenState extends ConsumerState<SavingRecordScreen> {
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  String? _selectedCategoryId;
  bool _addToCategories = false;

  @override
  void dispose() {
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  void _addAmount(int amount) {
    final current = int.tryParse(_amountController.text) ?? 0;
    _amountController.text = (current + amount).toString();
  }

  Future<void> _submit() async {
    final i18n = I18n.of(context);

    // Sanitize input: remove commas and spaces
    final cleanText = _amountController.text
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    // Use int.tryParse for strict integer parsing as requested
    final amount = int.tryParse(cleanText);

    if (_selectedCategoryId == null || amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(i18n.snackBarSelect)));
      }
      return;
    }

    try {
      String finalCategoryName = '';
      final categories = ref.read(categoryProvider).value ?? [];

      if (_selectedCategoryId == 'other') {
        final customName = _customCategoryController.text.trim();
        if (customName.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(i18n.snackBarSelect)));
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

      // 1. Save record
      await ref
          .read(savingProvider.notifier)
          .addSaving(
            category: finalCategoryName,
            amount: amount,
            createdAt: DateTime.now(),
          );

      // 2. Update Wishlist (Add funds to ALL items)
      final wishlistNotifier = ref.read(wishlistProvider.notifier);
      // Cast to double for wishlist calculations as wishlist still uses double for money
      await wishlistNotifier.addSavingToAllGoals(amount.toDouble());

      if (mounted) {
        // 3. Show Feedback
        _showSuccessDialog(i18n);
      }
    } catch (e) {
      if (mounted) {
        // Friendly error message
        String message = i18n.isKorean
            ? '저장 중 오류가 발생했습니다. 입력값을 확인해주세요.'
            : 'Failed to save. Please check your input.';

        if (e.toString().contains('ID 유실') ||
            e.toString().contains('null ID')) {
          message = '서버 응답 오류: ID 유실';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(I18n i18n) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
                backgroundColor: const Color(0xFF1A1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                title: Center(
                  child: Text(
                    i18n.dialogGreatJob,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      i18n.dialogSaved,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop(); // Close dialog
                      }

                      // Reset Form
                      _amountController.clear();
                      _customCategoryController.clear();
                      setState(() {
                        _selectedCategoryId = null;
                        _addToCategories = false;
                      });

                      // Navigate to Stats Tab (Index 2)
                      ref.read(navigationIndexProvider.notifier).state = 2;
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      i18n.dialogAwesome,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .scale(duration: 400.ms, curve: Curves.elasticOut)
              .shimmer(
                delay: 400.ms,
                duration: 1200.ms,
                color: const Color(0xFFCCFF00),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final categoriesAsync = ref.watch(categoryProvider);
    final categories = categoriesAsync.asData?.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.recordSavingTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    i18n.whatDidYouResist,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...categories.map((category) {
                        final isSelected = _selectedCategoryId == category.id;
                        return GestureDetector(
                          onLongPress: category.isCustom
                              ? () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        i18n.isKorean
                                            ? '카테고리 삭제'
                                            : 'Delete Category',
                                      ),
                                      content: Text(
                                        i18n.isKorean
                                            ? "'${category.name}' 카테고리를 삭제하시겠습니까?"
                                            : "Delete '${category.name}'?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => context.pop(),
                                          child: Text(
                                            i18n.isKorean ? '취소' : 'Cancel',
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            ref
                                                .read(categoryProvider.notifier)
                                                .deleteCategory(category.id);
                                            if (isSelected) {
                                              setState(
                                                () =>
                                                    _selectedCategoryId = null,
                                              );
                                            }
                                            context.pop();
                                          },
                                          child: Text(
                                            i18n.isKorean ? '삭제' : 'Delete',
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              : null,
                          child: ChoiceChip(
                            label: Text(
                              category.name,
                            ), // i18n support needed later?
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(
                                () => _selectedCategoryId = selected
                                    ? category.id
                                    : null,
                              );
                            },
                            backgroundColor: Colors.white,
                            selectedColor: Colors.black,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        );
                      }),
                      ChoiceChip(
                        label: Text(i18n.categoryName('Other')),
                        selected: _selectedCategoryId == 'other',
                        onSelected: (selected) {
                          setState(
                            () =>
                                _selectedCategoryId = selected ? 'other' : null,
                          );
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.black,
                        labelStyle: TextStyle(
                          color: _selectedCategoryId == 'other'
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  if (_selectedCategoryId == 'other') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customCategoryController,
                      decoration: InputDecoration(
                        labelText: i18n.categoryName(
                          'Other',
                        ), // "Direct Input" or "Category Name"
                        border: const OutlineInputBorder(),
                        hintText: 'ex) Bubble Tea',
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _addToCategories,
                      onChanged: (value) {
                        setState(() {
                          _addToCategories = value ?? false;
                        });
                      },
                      title: Text(
                        i18n.isKorean ? '새 카테고리로 추가' : 'Add to categories',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                  const SizedBox(height: 32),
                  Text(
                    i18n.howMuchSaved,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: i18n.isKorean ? '' : '\$ ',
                      suffixText: i18n.isKorean ? '원' : '',
                      border: const OutlineInputBorder(),
                      labelText: i18n.amountLabel,
                    ),
                    style: const TextStyle(fontSize: 24),
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
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      i18n.submitButton,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Today's Records List
                  _TodaysRecordsList(),
                ]),
              ),
            ),
          ],
        ),
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
    return OutlinedButton(
      onPressed: () => onPressed(amount),
      style: OutlinedButton.styleFrom(
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

    return savingAsync.when(
      data: (savings) {
        final now = DateTime.now();
        final todayParams = DateTime(now.year, now.month, now.day);

        // Filter for today's records
        final todaysRecords = savings.where((s) {
          final sDate = DateTime(
            s.createdAt.year,
            s.createdAt.month,
            s.createdAt.day,
          );
          return sDate.isAtSameMomentAs(todayParams);
        }).toList();

        // Auto-expand logic: if count increases, expand
        if (todaysRecords.length > _previousCount) {
          // Schedule state change to avoid build-phase setState error
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
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    i18n.isKorean ? "오늘의 기록" : "Today's Records",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white54,
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
                            if (item.id.isEmpty) {
                              return const SizedBox.shrink(); // Skip rendering invalid items
                            }

                            return Dismissible(
                                  key: ValueKey(item.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    try {
                                      // Call delete
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
                                            duration: const Duration(
                                              seconds: 2,
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                      return true; // Remove from UI
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              i18n.isKorean
                                                  ? "삭제 실패: ${e.toString()}"
                                                  : "Delete failed: ${e.toString()}",
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                      return false; // Snap back
                                    }
                                  },
                                  onDismissed: (_) {},
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
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
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white10),
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '+ ${i18n.formatCurrency(item.amount.toDouble())}',
                                          style: const TextStyle(
                                            color: Color(0xFFD4FF00), // Lime
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
