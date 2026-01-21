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

class AddWishlistDialog extends ConsumerStatefulWidget {
  final WishlistModel? item; // Optional for Edit Mode

  const AddWishlistDialog({super.key, this.item});

  @override
  ConsumerState<AddWishlistDialog> createState() => _AddWishlistDialogState();
}

class _AddWishlistDialogState extends ConsumerState<AddWishlistDialog> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageService = ImageService();

  XFile? _selectedImage;
  DateTime? _targetDate;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _titleController.text = widget.item!.title;
      _priceController.text = widget.item!.price.toInt().toString();
      _targetDate = widget.item!.targetDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
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
            dialogBackgroundColor: colors.background,
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

    if (title.isEmpty || price <= 0) {
      return;
    }

    // Edit Mode Penalty Logic
    if (widget.item != null) {
      await _checkPenaltyAndSubmit(title, price);
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

  Future<void> _checkPenaltyAndSubmit(String title, double price) async {
    final original = widget.item!;
    final progress = original.savedAmount > 0
        ? original.savedAmount / original.totalGoal
        : 0.0;

    // 1. Safety Zone (< 10%)
    if (progress < 0.1 || original.savedAmount <= 0) {
      await _executeEdit(title, price, applyPenalty: false);
      return;
    }

    final userProfile = await ref.read(userProfileNotifierProvider.future);

    // 2. Free Pass
    if (userProfile.hasFreePass) {
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
        await ref.read(userProfileNotifierProvider.notifier).useFreePass();
        await _executeEdit(title, price, applyPenalty: false);
      }
      return;
    }

    // 3. Penalty Warning
    final currentSaved = original.savedAmount;
    final afterPenalty = currentSaved * 0.9;
    final loss = currentSaved - afterPenalty;

    final confirmPenalty = await showDialog<bool>(
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
              '페널티 경고',
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
              '목표를 변경하면 공든 탑의 10%가 무너집니다.\n그래도 변경하시겠습니까?',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '현재 모은 돈',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${currentSaved.toInt()}원',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.grey),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '변경 후 (-10%)',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      Text(
                        '${afterPenalty.toInt()}원',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('돌아가기', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('페널티 감수 확인'),
          ),
        ],
      ),
    );

    if (confirmPenalty == true) {
      await _executeEdit(title, price, applyPenalty: true);
    }
  }

  Future<void> _executeEdit(
    String title,
    double price, {
    required bool applyPenalty,
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
      );

      await ref
          .read(wishlistProvider.notifier)
          .updateWishlistWithPenalty(newItem, applyPenalty: applyPenalty);

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
              shadowColor: Colors.black.withOpacity(0.1),
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
