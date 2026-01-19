import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/background_gradient.dart';
import '../../../core/ui/glass_card.dart';
import '../../../core/utils/i18n.dart';
import '../../wishlist/domain/wishlist_model.dart';
import '../providers/wishlist_provider.dart';
import 'package:vive_app/core/theme/theme_provider.dart';
import 'package:vive_app/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/image_service.dart';
import 'package:intl/intl.dart';

class WishlistDetailScreen extends ConsumerStatefulWidget {
  final WishlistModel item;

  const WishlistDetailScreen({super.key, required this.item});

  @override
  ConsumerState<WishlistDetailScreen> createState() =>
      _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends ConsumerState<WishlistDetailScreen> {
  late TextEditingController _commentController;
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  DateTime? _editedDate;
  XFile? _selectedImage;
  final _imageService = ImageService();
  bool _isEditing = false;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.item.comment);
    _titleController = TextEditingController(text: widget.item.title);
    _priceController = TextEditingController(
      text: widget.item.price.toInt().toString(),
    );
    _editedDate = widget.item.targetDate;
    _commentController.addListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);
    _priceController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _commentController.removeListener(_onTextChanged);
    _titleController.removeListener(_onTextChanged);
    _priceController.removeListener(_onTextChanged);
    _commentController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final originalComment = widget.item.comment ?? '';
    final originalTitle = widget.item.title;
    final originalPrice = widget.item.price.toInt().toString();

    final currentComment = _commentController.text;
    final currentTitle = _titleController.text;
    final currentPrice = _priceController.text;

    setState(() {
      _hasChanges =
          originalComment != currentComment ||
          originalTitle != currentTitle ||
          originalPrice != currentPrice ||
          _editedDate != widget.item.targetDate ||
          _selectedImage != null;
    });
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('카메라', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('갤러리', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final image = await _imageService.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _hasChanges = true;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    if (!_isEditing) return;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _editedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(
                context,
              ).extension<VibeThemeExtension>()!.colors.accent,
              onPrimary: Colors.white,
              surface: Colors.grey[900]!,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _editedDate) {
      setState(() {
        _editedDate = picked;
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || widget.item.id == null) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      FocusScope.of(context).unfocus(); // Close keyboard

      String? uploadedImageUrl;
      if (_selectedImage != null) {
        uploadedImageUrl = await _imageService.uploadImage(_selectedImage!);
      }

      final title = _titleController.text;
      final price = double.tryParse(_priceController.text) ?? widget.item.price;

      await ref
          .read(wishlistProvider.notifier)
          .updateWishlist(
            widget.item.id!,
            title: title != widget.item.title ? title : null,
            price: price != widget.item.price ? price : null,
            targetDate: _editedDate != widget.item.targetDate
                ? _editedDate
                : null,
            imageUrl: uploadedImageUrl,
          );

      // Save comment if changed
      if (_commentController.text != (widget.item.comment ?? '')) {
        await ref
            .read(wishlistProvider.notifier)
            .updateComment(widget.item.id!, _commentController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                const Text(
                  '성공적으로 수정되었습니다!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1A1A1A),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.greenAccent, width: 2),
            ),
          ),
        );
        setState(() {
          _isEditing = false;
          _hasChanges = false;
          _selectedImage = null;
        });
      }
    } catch (e) {
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
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = I18n.of(context);
    final item = widget.item;
    final progress = item.totalGoal > 0
        ? (item.savedAmount / item.totalGoal).clamp(0.0, 1.0)
        : 0.0;
    final remaining = item.totalGoal - item.savedAmount;

    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final themeMode = ref.watch(themeNotifierProvider);
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;

    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: isPureFinance ? colors.background : Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight:
                  (item.imageUrl != null ||
                      _selectedImage != null ||
                      _isEditing)
                  ? 300
                  : 60,
              pinned: true,
              backgroundColor: isPureFinance
                  ? colors.background
                  : Colors.transparent,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isPureFinance ? Colors.black : Colors.black87,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
              actions: [
                // Edit Button
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isEditing ? Icons.close : Icons.edit,
                      color: Colors.black87,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_isEditing) {
                          // Cancel edits
                          _isEditing = false;
                          _titleController.text = widget.item.title;
                          _priceController.text = widget.item.price
                              .toInt()
                              .toString();
                          _editedDate = widget.item.targetDate;
                          _selectedImage = null;
                        } else {
                          _isEditing = true;
                        }
                      });
                    },
                  ),
                ),
                // Save Button (visible when changes exist or editing)
                if (_isEditing || _hasChanges)
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(
                              Icons.check,
                              color: Colors.black87,
                              size: 28,
                            ),
                    ),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double width = constraints.maxWidth;
                        final double height = constraints.maxHeight;

                        return TweenAnimationBuilder<double>(
                          key: ValueKey(
                            item.savedAmount,
                          ), // [중요] 저축액 변화시에만 애니메이션 실행
                          tween: Tween<double>(begin: 0.0, end: progress),
                          duration: const Duration(milliseconds: 1200),
                          builder: (context, value, child) {
                            // 공통 이미지 위젯 (색상 간섭 제거 및 크기 고정)
                            Widget buildUnifiedImage(bool isGrayscale) {
                              final img = _selectedImage != null
                                  ? (kIsWeb
                                        ? Image.network(
                                            _selectedImage!.path,
                                            width: width,
                                            height: height,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_selectedImage!.path),
                                            width: width,
                                            height: height,
                                            fit: BoxFit.cover,
                                          ))
                                  : (item.imageUrl != null
                                        ? Image.network(
                                            item.imageUrl!,
                                            width: width,
                                            height: height,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(color: Colors.grey[900]));

                              if (isGrayscale) {
                                return ColorFiltered(
                                  colorFilter: const ColorFilter.matrix([
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0.2126,
                                    0.7152,
                                    0.0722,
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    1,
                                    0,
                                  ]),
                                  child: img,
                                );
                              }
                              return img;
                            }

                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: buildUnifiedImage(true), // 바닥: 흑백
                                ),
                                ClipRect(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: value, // 게이지: 컬러
                                    child: buildUnifiedImage(false),
                                  ),
                                ),
                                // (C) 스캔 라인 효과
                                if (value > 0 && value < 1.0)
                                  Positioned(
                                    left: width * value - 1,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 2,
                                      decoration: BoxDecoration(
                                        color: colors.accent,
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.accent.withOpacity(
                                              0.8,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                // (D) 수정 모드 오버레이
                                if (_isEditing)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        color: Colors.black45,
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              '사진 변경',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and D-Day Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _isEditing
                              ? TextField(
                                  controller: _titleController,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: isPureFinance
                                        ? colors.textMain
                                        : Colors.white,
                                    height: 1.2,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '목표 이름',
                                    hintStyle: TextStyle(
                                      color: isPureFinance
                                          ? colors.textSub
                                          : Colors.white30,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                )
                              : Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: isPureFinance
                                        ? colors.textMain
                                        : Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                        ),
                        if ((item.targetDate != null || _editedDate != null) &&
                                !item.isAchieved ||
                            _isEditing)
                          GestureDetector(
                            onTap: _isEditing ? _pickDate : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.accent,
                                  width: 1.5,
                                ),
                                boxShadow: _isEditing
                                    ? [
                                        BoxShadow(
                                          color: colors.accent.withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                _isEditing && _editedDate != null
                                    ? DateFormat(
                                        'yyyy.MM.dd',
                                      ).format(_editedDate!)
                                    : () {
                                        final baseDate = _isEditing
                                            ? _editedDate
                                            : item.targetDate;
                                        if (baseDate == null) return '기한 설정';

                                        final now = DateTime.now();
                                        final today = DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                        );
                                        final target = DateTime(
                                          baseDate.year,
                                          baseDate.month,
                                          baseDate.day,
                                        );
                                        final days = target
                                            .difference(today)
                                            .inDays;
                                        if (days == 0) return 'D-Day';
                                        if (days < 0) return '기한 도과';
                                        return 'D-$days';
                                      }(),
                                style: TextStyle(
                                  color: colors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Daily Goal Section (Secondary Color Highlight)
                    if (item.targetDate != null &&
                        !item.isAchieved &&
                        item.dailyQuota > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isPureFinance
                              ? colors.accent.withOpacity(0.05)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPureFinance
                                ? colors.accent.withOpacity(0.3)
                                : colors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.accent.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.rocket_launch,
                                color: colors.accent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '목표를 위해 오늘 아껴야 할 금액',
                                    style: TextStyle(
                                      color: isPureFinance
                                          ? colors.textSub
                                          : Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    i18n.formatCurrency(item.dailyQuota),
                                    style: TextStyle(
                                      color: colors.accent,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Price Info
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '총 가격',
                                style: TextStyle(
                                  color: isPureFinance
                                      ? colors.textSub
                                      : Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _isEditing
                                  ? TextField(
                                      controller: _priceController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        color: isPureFinance
                                            ? colors.accent
                                            : Colors.blueAccent,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: isPureFinance
                                            ? colors.surface
                                            : Colors.white.withOpacity(0.1),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: colors.accent,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: colors.accent.withOpacity(
                                              0.5,
                                            ),
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                        suffixText: '원',
                                        helperText: '수정할 목표 금액을 입력하세요',
                                        helperStyle: TextStyle(
                                          color: isPureFinance
                                              ? colors.textSub
                                              : Colors.white60,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      i18n.formatCurrency(item.totalGoal),
                                      style: TextStyle(
                                        color: isPureFinance
                                            ? colors.textMain
                                            : Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '남은 금액',
                                style: TextStyle(
                                  color: isPureFinance
                                      ? colors.textSub
                                      : Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                i18n.formatCurrency(remaining),
                                style: TextStyle(
                                  color: isPureFinance
                                      ? colors.textMain
                                      : Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Progress Bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(progress * 100).toInt()}% 달성',
                              style: TextStyle(
                                color: isPureFinance
                                    ? colors.textMain
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: isPureFinance
                              ? colors.border
                              : Colors.grey[800],
                          color: isPureFinance
                              ? colors.accent
                              : const Color(0xFFD4FF00), // 밝은 네온 노랑/초록으로 통일
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Comment Section (Editable)
                    Text(
                      '나의 다짐',
                      style: TextStyle(
                        color: isPureFinance ? colors.textMain : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _commentController,
                            maxLines: 4,
                            minLines: 1,
                            style: TextStyle(
                              color: isPureFinance
                                  ? colors.textMain
                                  : Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            readOnly: item.isAchieved || progress >= 1.0,
                            decoration: InputDecoration(
                              hintText: (item.isAchieved || progress >= 1.0)
                                  ? "달성 완료된 다짐입니다"
                                  : "미래의 나에게 보내는 응원 메시지",
                              hintStyle: TextStyle(
                                color: isPureFinance
                                    ? colors.textSub
                                    : Colors.white30,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              fillColor: isPureFinance
                                  ? colors.surface
                                  : Colors.transparent,
                              filled: isPureFinance,
                            ),
                            cursorColor: isPureFinance
                                ? colors.textSub
                                : colors
                                      .success, // Pure: Grey, Cyber: Cyan (Gauge)
                          ),
                          if (_hasChanges)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '저장하려면 상단 체크 버튼을 눌러주세요',
                                style: TextStyle(
                                  color: isPureFinance
                                      ? colors.textSub
                                      : colors.success.withAlpha(
                                          179,
                                        ), // Pure: Grey, Cyber: Lime
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
