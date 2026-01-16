import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/image_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../core/utils/i18n.dart';
import '../../../../core/ui/bouncy_button.dart';
import '../domain/wishlist_model.dart';
import '../providers/wishlist_provider.dart';

class AddWishlistDialog extends ConsumerStatefulWidget {
  const AddWishlistDialog({super.key});

  @override
  ConsumerState<AddWishlistDialog> createState() => _AddWishlistDialogState();
}

class _AddWishlistDialogState extends ConsumerState<AddWishlistDialog> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageService = ImageService();

  XFile? _selectedImage;
  bool _isUploading = false;

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

  Future<void> _submit() async {
    final title = _titleController.text;
    final price = double.tryParse(_priceController.text) ?? 0.0;

    if (title.isEmpty || price <= 0) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final themeMode = ref.watch(themeNotifierProvider);
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;

    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        i18n.wishlistAddTitle,
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
                              ? NetworkImage(_selectedImage!.path)
                              : FileImage(File(_selectedImage!.path))
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: _selectedImage == null
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
                    i18n.add,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }
}
