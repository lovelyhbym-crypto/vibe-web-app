import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/image_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../core/utils/i18n.dart';
import '../../../../core/ui/bouncy_button.dart';
import '../domain/wishlist_model.dart';
import '../providers/wishlist_provider.dart';
import '../../auth/providers/user_profile_provider.dart';
import 'package:flutter/services.dart';

class AddWishlistDialog extends ConsumerStatefulWidget {
  final WishlistModel? item; // Optional for Edit Mode

  const AddWishlistDialog({super.key, this.item});

  @override
  ConsumerState<AddWishlistDialog> createState() => _AddWishlistDialogState();
}

class _AddWishlistDialogState extends ConsumerState<AddWishlistDialog> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _penaltyController = TextEditingController();
  final _imageService = ImageService();

  XFile? _selectedImage;
  DateTime? _targetDate;
  bool _isUploading = false;
  bool _isSpinning = false;

  void _spinPenaltySlotMachine() async {
    if (_isSpinning) return;

    setState(() => _isSpinning = true);

    final penalties = [
      "배달 앱(배민/쿠팡이츠 등) 하루 동안 삭제",
      "사진첩의 쓸데없는 사진 20개 정리하기",
      "물 1.5L 마시기(물 마실때마다 어플 생각)",
      "스마트폰 없이 딱 15분동안 동네 산책하기",
      "오늘 밤 자기 전 무지출 전략 세우기",
      "하루 동안 '감사합니다' 혹은 '수고하셨습니다' 인사 5번 하기",
      "지금 즉시 책상 혹은 방 바닥 청소하기",
      "집에 있는 안 쓰는 물건 하나 비우기 (기부/나눔)",
      "내일 하루 액상과당(제로 음료 포함) 0mg 실천",
      "내일 평소보다 1시간 일찍 일어나기",
    ];

    // Slot Machine Animation Effect
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!context.mounted) return;
      setState(() {
        _penaltyController.text = penalties[i % penalties.length];
      });
    }

    // Final Random Selection
    final random = DateTime.now().millisecondsSinceEpoch % penalties.length;
    if (mounted) {
      setState(() {
        _penaltyController.text = penalties[random];
        _isSpinning = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _titleController.text = widget.item!.title;
      _priceController.text = widget.item!.price.toInt().toString();
      _penaltyController.text = widget.item!.penaltyText ?? '';
      _targetDate = widget.item!.targetDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _penaltyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _imageService.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)), // 10 years
      builder: (context, child) {
        final colors = Theme.of(
          context,
        ).extension<VibeThemeExtension>()!.colors;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.accent,
              onPrimary: Colors.black,
              surface: colors.surface,
              onSurface: colors.textMain,
            ),
            dialogTheme: DialogThemeData(backgroundColor: colors.background),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _targetDate = pickedDate;
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final penaltyText = _penaltyController.text;

    if (title.isEmpty || price <= 0) {
      return;
    }

    // Edit Mode Penalty Logic
    if (widget.item != null) {
      await _checkPenaltyAndSubmit(title, price, penaltyText);
      return;
    }

    // Add Mode (Existing Logic)
    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _imageService.uploadImage(_selectedImage!);
      }

      final newItem = WishlistModel(
        title: title,
        price: price,
        totalGoal: price, // Assuming goal equals price for now
        imageUrl: imageUrl,
        targetDate: _targetDate,
        penaltyText: penaltyText,
      );

      await ref.read(wishlistProvider.notifier).addWishlist(newItem);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('목표가 추가되었습니다.')));
      }
    } catch (e) {
      debugPrint('AddWishlistDialog error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '저장 실패: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _checkPenaltyAndSubmit(
    String title,
    double price,
    String penaltyText,
  ) async {
    final original = widget.item!;
    final progress = original.savedAmount > 0
        ? original.savedAmount / original.totalGoal
        : 0.0;

    // 1. Safety Zone (< 10%)
    if (progress < 0.1 || original.savedAmount <= 0) {
      if (!context.mounted) return;
      await _executeEdit(
        title,
        price,
        penaltyText,
        applyPenalty: false,
        consumeFreePass: false,
      );
      return;
    }

    final userProfile = await ref.read(userProfileNotifierProvider.future);

    if (!mounted) return;
    // 2. Free Pass
    if (userProfile.hasFreePass) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.indigo[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.cyanAccent),
          ),
          title: const Row(
            children: [
              Icon(Icons.star, color: Colors.yellowAccent),
              SizedBox(width: 8),
              Text(
                '첫 번째 변경 무료',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            '이번만 무료로 목표를 변경해드립니다.\n다음부터는 패널티가 적용되니 신중하게 결정해주세요!',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('변경하기'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        if (!mounted) return;
        await _executeEdit(
          title,
          price,
          penaltyText,
          applyPenalty: false,
          consumeFreePass: true,
        );
      }
      return;
    }

    // 3. Penalty Warning
    final currentSaved = original.savedAmount;
    final penaltyAmount = currentSaved * 0.2; // 20% penalty

    final confirmPenalty = await _showPenaltyDialog(
      currentSaved,
      penaltyAmount,
    );

    if (confirmPenalty == true) {
      if (!mounted) return;
      await _executeEdit(
        title,
        price,
        penaltyText,
        applyPenalty: true,
        consumeFreePass: false,
      );
    }
  }

  Future<bool> _showPenaltyDialog(double currentAmount, double penalty) async {
    final afterAmount = currentAmount - penalty;
    final totalGoal = widget.item!.totalGoal;

    final double safeTotal = totalGoal > 0 ? totalGoal : 1.0;
    final double startProgress = (currentAmount / safeTotal).clamp(0.0, 1.0);
    final double endProgress = (afterAmount / safeTotal);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A0000), // Dark Red
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.redAccent),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text(
                  '[위험] 페널티 발생',
                  style: TextStyle(
                    color: Colors.redAccent,
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
                  '이미 무료 기회를 사용하셨습니다.\n목표 수정시 20% 페널티가 부과됩니다.', // 20% text
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  '⚠ 주의: 목표물도 파괴되며\n구원 퀘스트를 수행해야 복구됩니다.',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                // Preview Visualization
                const Text(
                  '게이지 변화',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    // Background
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    // Original (Faded)
                    FractionallySizedBox(
                      widthFactor: startProgress,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    // New Amount (Red)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: startProgress, end: endProgress),
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.easeInOutQuart,
                      onEnd: () {
                        HapticFeedback.heavyImpact();
                      },
                      builder: (context, value, child) {
                        final isNegative = value < 0;
                        final widthFactor = value.abs();

                        return Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey[800],
                            ),
                            FractionallySizedBox(
                              widthFactor: widthFactor.clamp(0.0, 1.0),
                              child: Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isNegative
                                      ? const Color(0xFFFF0000)
                                      : Colors.redAccent,
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isNegative
                                                  ? const Color(0xFFFF0000)
                                                  : Colors.red)
                                              .withValues(alpha: 0.8),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isNegative)
                              const Positioned(
                                right: 0,
                                child: Text(
                                  "DEBT",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currentAmount.toInt()}',
                      style: const TextStyle(
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '${afterAmount.toInt()} (-${penalty.toInt()})',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  '돌아가기',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('페널티 감수하고 변경'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _executeEdit(
    String title,
    double price,
    String penaltyText, {
    required bool applyPenalty,
    required bool consumeFreePass,
  }) async {
    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl = widget.item!.imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _imageService.uploadImage(_selectedImage!);
      }

      final newItem = widget.item!.copyWith(
        title: title,
        price: price,
        totalGoal: price, // Assuming totalGoal follows price update
        imageUrl: imageUrl,
        targetDate: _targetDate,
        penaltyText: penaltyText,
      );

      await ref
          .read(wishlistProvider.notifier)
          .updateWishlistWithPenalty(
            newItem,
            applyPenalty: applyPenalty,
            consumeFreePass: consumeFreePass,
          );

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(applyPenalty ? '페널티가 적용되어 수정되었습니다.' : '목표가 수정되었습니다.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Edit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 실패: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        widget.item == null ? i18n.wishlistAddTitle : '목표 수정',
        style: TextStyle(color: colors.textMain),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Picker UI
            GestureDetector(
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isPureFinance ? colors.background : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: kIsWeb
                              ? NetworkImage(
                                  _selectedImage != null
                                      ? _selectedImage!.path
                                      : widget.item?.imageUrl ?? '',
                                ) // logic handled below
                              : FileImage(File(_selectedImage!.path))
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : (widget.item?.imageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(widget.item!.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null),
                ),
                alignment: Alignment.center,
                child: (_selectedImage == null && widget.item?.imageUrl == null)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo,
                            color: colors.textSub,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '사진 등록',
                            style: TextStyle(color: colors.textSub),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: i18n.itemNameLabel,
                labelStyle: TextStyle(color: colors.textSub),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.accent),
                ),
              ),
              style: TextStyle(color: colors.textMain),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: i18n.priceLabel,
                labelStyle: TextStyle(color: colors.textSub),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.accent),
                ),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(color: colors.textMain),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 20, color: colors.textSub),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _targetDate == null
                            ? '목표 달성일 (기한 없음)'
                            : '달성일: ${DateFormat('yyyy-MM-dd').format(_targetDate!)}',
                        style: TextStyle(
                          color: _targetDate == null
                              ? colors.textSub
                              : colors.textMain,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.textSub),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Penalty Input Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '실패 시 나에게 주는 벌칙',
                      style: TextStyle(
                        color: colors.textSub,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: _spinPenaltySlotMachine,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isSpinning ? colors.accent : colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isSpinning
                                ? Colors.transparent
                                : colors.accent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.casino,
                              size: 14,
                              color: _isSpinning ? Colors.black : colors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "운명의 뽑기",
                              style: TextStyle(
                                fontSize: 11,
                                color: _isSpinning
                                    ? Colors.black
                                    : colors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _penaltyController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "예: 배달 앱 하루 삭제",
                    hintStyle: TextStyle(
                      color: colors.textSub.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: isPureFinance
                        ? colors.background
                        : Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: TextStyle(color: colors.textMain, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => context.pop(),
          child: Text(i18n.cancel, style: TextStyle(color: colors.textSub)),
        ),
        BouncyButton(
          onTap: _isUploading ? () {} : _submit,
          child: ElevatedButton(
            onPressed: _isUploading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: isPureFinance
                  ? Colors.white
                  : const Color(0xFFCCFF00),
              foregroundColor: isPureFinance ? colors.textMain : Colors.black,
              surfaceTintColor: Colors.transparent, // 방지: M3의 흰색 배경 위 보라색 색조
              elevation: isPureFinance ? 2 : 0, // 하얀 배경에서 구분되도록 약간의 그림자 추가
              shadowColor: Colors.black.withValues(alpha: 0.1),
              side: isPureFinance
                  ? BorderSide(color: colors.border)
                  : BorderSide.none,
              disabledBackgroundColor: Colors.grey[700],
              disabledForegroundColor: Colors.white38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.item == null ? i18n.add : '수정 완료',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}
