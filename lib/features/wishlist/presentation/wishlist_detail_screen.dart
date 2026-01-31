import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
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
import 'package:vive_app/core/ui/vibe_image_effect.dart';
import 'package:flutter/services.dart';
import 'package:vive_app/features/auth/providers/user_profile_provider.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/services/haptic_service.dart';
import 'widgets/countdown_timer_widget.dart';
import 'package:vive_app/core/ui/floating_input_field.dart';
import '../../../core/ui/bouncy_button.dart';

class WishlistDetailScreen extends ConsumerStatefulWidget {
  final WishlistModel item;

  const WishlistDetailScreen({super.key, required this.item});

  @override
  ConsumerState<WishlistDetailScreen> createState() =>
      _WishlistDetailScreenState();
}

class _WishlistDetailScreenState extends ConsumerState<WishlistDetailScreen>
    with WidgetsBindingObserver {
  late TextEditingController _penaltyController;
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  DateTime? _editedDate;
  XFile? _selectedImage;
  final _imageService = ImageService();
  bool _isEditing = false;
  bool _hasChanges = false;
  bool _isSaving = false;
  int _animationTriggerId = 0;
  bool _isSpinning = false;

  void _spinPenaltySlotMachine() async {
    if (_isSpinning) return;
    // Prevent spinning if read-only
    final item = widget.item;
    final progress = item.totalGoal > 0
        ? ((item.savedAmount - item.penaltyAmount) /
              item.totalGoal) // Using basic progress for check
        : 0.0;
    if (item.isAchieved || progress >= 1.0) return;

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
      if (!mounted) return;
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
      // Trigger change detection manually since programmatic updates might not always fire listeners dependent on focus
      // But controller listener should catch it. logic in _onTextChanged will handle _hasChanges.
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _penaltyController = TextEditingController(text: widget.item.penaltyText);
    _titleController = TextEditingController(text: widget.item.title);
    _priceController = TextEditingController(
      text: widget.item.price.toInt().toString(),
    );
    _editedDate = widget.item.targetDate;
    _penaltyController.addListener(_onTextChanged);
    _titleController.addListener(_onTextChanged);
    _priceController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _penaltyController.removeListener(_onTextChanged);
    _titleController.removeListener(_onTextChanged);
    _priceController.removeListener(_onTextChanged);
    _penaltyController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetAnimation();
    }
  }

  void _resetAnimation() {
    if (mounted) {
      setState(() {
        _animationTriggerId++;
      });
    }
  }

  void _onTextChanged() {
    final originalPenalty = widget.item.penaltyText ?? '';
    final originalTitle = widget.item.title;
    final originalPrice = widget.item.price.toInt().toString();

    final currentPenalty = _penaltyController.text;
    final currentTitle = _titleController.text;
    final currentPrice = _priceController.text;

    setState(() {
      _hasChanges =
          originalPenalty != currentPenalty ||
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

    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    try {
      FocusScope.of(context).unfocus();

      String? uploadedImageUrl = widget.item.imageUrl; // Default to existing
      if (_selectedImage != null) {
        uploadedImageUrl = await _imageService.uploadImage(_selectedImage!);
      }

      final title = _titleController.text;
      final price = double.tryParse(_priceController.text) ?? widget.item.price;

      // Construct the potential new item state
      final newItem = widget.item.copyWith(
        title: title,
        price: price,
        totalGoal: price, // Assuming total goal updates with price
        targetDate: _editedDate,
        imageUrl: uploadedImageUrl,
        penaltyText: _penaltyController.text,
      );

      // Delegate to penalty check logic
      await _checkPenaltyAndSave(newItem);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e'), backgroundColor: colors.danger),
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

  Future<void> _checkPenaltyAndSave(WishlistModel newItem) async {
    final original = widget.item;

    // 0. Check for Significant Changes (Title, Price, Date, Image)
    // "나의 다짐(Comment)" only changes should NOT trigger penalty.
    final isTitleChanged = newItem.title != original.title;
    final isPriceChanged = newItem.price != original.price;
    final isDateChanged = newItem.targetDate != original.targetDate;
    final isImageChanged = newItem.imageUrl != original.imageUrl;

    final isSignificantChange =
        isTitleChanged || isPriceChanged || isDateChanged || isImageChanged;

    if (!isSignificantChange) {
      // Just updating comment or no real change -> Free
      await _executeFinalSave(
        newItem,
        applyPenalty: false,
        consumeFreePass: false,
      );
      return;
    }

    // 1. Strict Safety Zone (Only if NO savings exist)
    // "무료 기회 썼으면 얄짤없이 패널티" -> No 10% buffer allowed.
    // If you have saved even 1 won, you are subject to the rules.
    if (original.savedAmount <= 0) {
      // Nothing to lose, so free change
      await _executeFinalSave(
        newItem,
        applyPenalty: false,
        consumeFreePass: false,
      );
      return;
    }

    // 2. Check Free Pass (Reactive)
    final userProfile = await ref.read(userProfileNotifierProvider.future);

    if (userProfile.hasFreePass) {
      final confirm = await _showFreePassDialog();
      if (confirm) {
        await _executeFinalSave(
          newItem,
          applyPenalty: false,
          consumeFreePass: true,
        );
      }
      return; // If cancelled, do nothing (stay in edit mode)
    }

    // 3. Taxpayer (Penalty: -20% Success Probability)
    // Penalty is 20% of TOTAL GOAL, not saved amount.
    final penalty = original.totalGoal * 0.2;
    final confirm = await _showPenaltyDialog(original.savedAmount, penalty);

    if (confirm) {
      await _executeFinalSave(
        newItem,
        applyPenalty: true,
        consumeFreePass: false,
      );
    }
  }

  Future<void> _executeFinalSave(
    WishlistModel newItem, {
    required bool applyPenalty,
    required bool consumeFreePass,
  }) async {
    try {
      // Use the robust provider method we fixed earlier
      await ref
          .read(wishlistProvider.notifier)
          .updateWishlistWithPenalty(
            newItem,
            applyPenalty: applyPenalty,
            consumeFreePass: consumeFreePass,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  applyPenalty ? '페널티가 적용되어 수정되었습니다.' : '성공적으로 수정되었습니다!',
                  style: const TextStyle(
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
      debugPrint('Save error: $e');
      throw e; // Rethrow to be caught by _saveChanges
    }
  }

  // Simplified entry point - Just enters edit mode
  void _enterEditMode() {
    setState(() {
      _isEditing = true;
    });
  }

  // Deprecated _handlePivotAttempt logic removed.
  // The functionality is now integrated into _checkPenaltyAndSave within _saveChanges.

  Future<bool> _showFreePassDialog() async {
    return await showDialog<bool>(
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
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이번만 무료로 목표를 변경해드립니다.\n다음부터는 패널티가 적용되니 신중하게 결정해주세요!',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
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
                child: const Text('무료 환승하기'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showPenaltyDialog(
    double currentSaved,
    double penaltyAmount,
  ) async {
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final totalGoal = widget.item.totalGoal;
    final double safeTotal = totalGoal > 0 ? totalGoal : 1.0;

    // Probability Calculation
    // Current Progress
    final double currentProgress = (currentSaved / safeTotal);
    // New Progress = (Saved - Penalty) / Goal
    final double newProgress = ((currentSaved - penaltyAmount) / safeTotal);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Color(0xFF2A0000), // Dark Red
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors.danger),
            ),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.danger),
                SizedBox(width: 8),
                Text(
                  '[위험] 페널티 발생',
                  style: TextStyle(
                    color: colors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이미 무료 기회를 사용하셨습니다.\n성공 확률이 -20% 감소합니다.',
                  style: TextStyle(color: Colors.white, height: 1.5),
                ),
                const SizedBox(height: 12),
                Text(
                  '⚠ 주의: 목표물도 파괴되며\n구원 퀘스트를 수행해야 복구됩니다.',
                  style: TextStyle(
                    color: colors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '또한, 확률 게이지가 빚(Debt)으로 전환됩니다.',
                  style: TextStyle(
                    color: colors.danger,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                // Preview Visualization
                Text(
                  '성공 확률 변화',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    // Background
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // Original (Gray/White)
                    FractionallySizedBox(
                      widthFactor: currentProgress.clamp(0.0, 1.0),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    // New Probability Animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: currentProgress, end: newProgress),
                      duration: const Duration(milliseconds: 2000),
                      curve: Curves.elasticOut,
                      onEnd: () {
                        HapticService.heavy();
                      },
                      builder: (context, value, child) {
                        // Value can be negative
                        final isNegative = value < 0;
                        final displayWidth = value.clamp(
                          0.0,
                          1.0,
                        ); // Only positive part fits in bar?
                        // If negative, maybe show red bar going left? or just Empty?
                        // User wants "Red text -10%".
                        // Let's show the bar shrinking. If negative, it disappears (width 0).

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            FractionallySizedBox(
                              widthFactor: displayWidth > 0
                                  ? displayWidth
                                  : 0.001,
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors.danger,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // If negative, show label explicitly
                            if (isNegative)
                              Positioned(
                                left: 0,
                                top: 16,
                                child: Text(
                                  "DEBT ZONE",
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
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(currentProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.grey,
                      size: 16,
                    ),
                    Text(
                      '${(newProgress * 100).toInt()}%', // e.g. -10%
                      style: TextStyle(
                        color: colors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
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
                  '취소',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.danger,
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

  Future<void> _deleteWishlistAction() async {
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '정말 포기하시겠습니까?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
            children: [
              const TextSpan(
                text: "지금 포기하면 당신이 견뎌낸 그 모든 고통스러운 시간들은 아무런 의미 없는 ",
              ),
              TextSpan(
                text: "'실패 기록'",
                style: TextStyle(
                  color: colors.danger.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: "으로 남게 됩니다.\n\n정말 당신의 노력을 버리시겠습니까?"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              '취소',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: const Text(
              '목표 파기',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        SoundService().playShatter();
        HapticService.heavy();
        await Future.delayed(const Duration(milliseconds: 100));
        HapticService.heavy();
        await ref
            .read(wishlistProvider.notifier)
            .deleteWishlist(widget.item.id!);
        if (mounted) context.pop();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')));
      }
    }
  }

  void _showEdgeMenu(WishlistModel item) {
    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Menu",
      barrierColor: Colors.transparent,
      pageBuilder: (context, _, __) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context), // 화면 다른 곳 누르면 닫기
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(0.2)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 40),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildMenuAction(
                        "목표물 변경",
                        isLocked: item.isBroken,
                        onTap: () {
                          Navigator.pop(context);
                          _enterEditMode();
                        },
                      ),
                      const SizedBox(height: 60),
                      _buildMenuAction(
                        "포기하기",
                        isDanger: true,
                        isLocked: item.isBroken,
                        onTap: () {
                          Navigator.pop(context);
                          _deleteWishlistAction();
                        },
                      ),
                      if (item.isBroken) ...[
                        const SizedBox(height: 80),
                        SizedBox(
                          width: 250,
                          child: Text(
                            "부서진 꿈을 방치한 채 도망갈 수 없습니다.\n[긴급 복구 퀘스트]를 먼저 완료하십시오.",
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: colors.danger,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim, __, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }

  Widget _buildMenuAction(
    String label, {
    required VoidCallback onTap,
    bool isDanger = false,
    bool isLocked = false,
  }) {
    return BouncyButton(
      onTap: isLocked
          ? () {
              HapticService.vibrate();
            }
          : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Subtle neon glow for menu actions
          boxShadow: [
            if (!isLocked)
              BoxShadow(
                color: (isDanger ? const Color(0xFFFF0000) : Colors.white)
                    .withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Opacity(
          opacity: isLocked ? 0.3 : 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLocked) ...[
                const Icon(Icons.lock, color: Colors.white54, size: 24),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 32,
                  color: isDanger ? const Color(0xFFFF0000) : Colors.white,
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.w200,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [추가] 프로바이더에서 현재 아이템의 최신 상태를 실시간으로 감시
    final wishlistState = ref.watch(wishlistProvider);
    // [Fix] Keep UserProfile alive and reactive
    ref.watch(userProfileNotifierProvider);

    final item = wishlistState.maybeWhen(
      data: (list) => list.firstWhere(
        (e) => e.id == widget.item.id,
        orElse: () => widget.item,
      ),
      orElse: () => widget.item,
    );

    final i18n = I18n.of(context);
    final progress = item.totalGoal > 0
        ? ((item.savedAmount - item.penaltyAmount) / item.totalGoal)
        : 0.0;
    // Remaining amount ignores penalty as per user instruction "Don't touch remaining amount"
    final remaining = item.totalGoal - item.savedAmount;

    final colors = Theme.of(context).extension<VibeThemeExtension>()!.colors;
    final themeMode = ref.watch(themeNotifierProvider);
    final isPureFinance = themeMode == VibeThemeMode.pureFinance;

    return BackgroundGradient(
      child: Scaffold(
        backgroundColor: isPureFinance ? colors.background : Colors.transparent,
        body: Stack(
          children: [
            CustomScrollView(
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
                  leading: IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      size: 32, // Larger, thin icon
                      color: isPureFinance ? Colors.black : colors.accent,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  actions: [], // Actions removed for Side Edge Menu
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
                                '${item.savedAmount}-$_animationTriggerId',
                              ), // 저축액 변화 및 트리거 발생 시 애니메이션 실행
                              tween: Tween<double>(
                                begin: 0.0,
                                end: progress.clamp(
                                  0.0,
                                  1.0,
                                ), // Image effect stays positive
                              ),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Stack(
                                  children: [
                                    VibeImageEffect(
                                      imageUrl: item.imageUrl,
                                      localImage: _selectedImage,
                                      blurLevel: item.blurLevel,
                                      isBroken: item.isBroken,
                                      width: width,
                                      height: height,
                                      progress: value,
                                    ),
                                    // [Refinement] Image-Timer Vignette
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.8),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.4],
                                          ),
                                        ),
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
                                                color: colors.accent
                                                    .withOpacity(0.8),
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
                        // [Time Pressure] Countdown Timer Overlay
                        if (item.targetDate != null &&
                            !item.isAchieved &&
                            !_isEditing)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: CountdownTimerWidget(
                              targetDate: item.targetDate!,
                              isAchieved: item.isAchieved,
                            ),
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
                        const SizedBox(height: 32),
                        // Title and D-Day Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _isEditing
                                  ? TextField(
                                      controller: _titleController,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: colors.textMain,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: '목표 이름 수정', // 라벨 부여
                                        filled: true,
                                        fillColor: colors.surface,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: isPureFinance
                                              ? BorderSide.none
                                              : BorderSide(
                                                  color: colors.accent
                                                      .withOpacity(0.5),
                                                ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: isPureFinance
                                            ? colors.textMain
                                            : const Color(0xFFF2F2F7),
                                        letterSpacing: -1.5,
                                        height: 1.1,
                                      ),
                                    ),
                            ),
                            if (_isEditing) // Show date picker ONLY when editing
                              GestureDetector(
                                onTap: _pickDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colors.accent,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    _editedDate != null
                                        ? DateFormat(
                                            'yyyy.MM.dd',
                                          ).format(_editedDate!)
                                        : '기한 설정',
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
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: isPureFinance
                                  ? null
                                  : Border.all(color: colors.border, width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isPureFinance
                                        ? colors.background
                                        : colors.accent.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.rocket_launch,
                                    color: isPureFinance
                                        ? colors.textSub
                                        : colors.accent,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '목표를 위해 오늘 아껴야 할 금액',
                                        style: TextStyle(
                                          color: isPureFinance
                                              ? colors.textSub
                                              : Colors.white38,
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        i18n.formatCurrency(item.dailyQuota),
                                        style: GoogleFonts.robotoMono(
                                          color: isPureFinance
                                              ? colors.textMain
                                              : colors.accent,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(
                          height: 36,
                        ), // Increased spacing to separate from Daily Goal
                        // Price Info Block (Grouping Price & Remaining)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
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
                                            : Colors.white38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _isEditing
                                        ? TextField(
                                            controller: _priceController,
                                            keyboardType: TextInputType.number,
                                            style: GoogleFonts.robotoMono(
                                              color: isPureFinance
                                                  ? colors.accent
                                                  : Colors.blueAccent,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.5,
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: colors.surface,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: isPureFinance
                                                    ? BorderSide.none
                                                    : BorderSide(
                                                        color: colors.accent
                                                            .withOpacity(0.5),
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
                                            style: GoogleFonts.robotoMono(
                                              color: isPureFinance
                                                  ? colors.textMain
                                                  : Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.5,
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
                                            : Colors.white38,
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      i18n.formatCurrency(remaining),
                                      style: GoogleFonts.robotoMono(
                                        color: isPureFinance
                                            ? colors.textMain
                                            : Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                                  '성공 확률 : ',
                                  style: TextStyle(
                                    color: isPureFinance
                                        ? colors.textSub
                                        : Colors.white38,
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: GoogleFonts.robotoMono(
                                    color: progress < 0
                                        ? colors.danger
                                        : (isPureFinance
                                              ? colors.textMain
                                              : colors.accent),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TweenAnimationBuilder<double>(
                              key: ValueKey(
                                '${item.savedAmount}-$_animationTriggerId',
                              ),
                              tween: Tween<double>(end: progress),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                final progressValue = value.clamp(0.0, 1.0);
                                final isLow = value <= 0;
                                final isHigh = value >= 0.8;

                                Widget indicator = LinearProgressIndicator(
                                  value: progressValue,
                                  backgroundColor: isPureFinance
                                      ? colors.border
                                      : const Color(0xFF1C1C1E),
                                  color: isPureFinance
                                      ? colors.textMain
                                      : (value < 0
                                            ? colors.danger
                                            : colors.accent),
                                  minHeight: 6.0,
                                  borderRadius: BorderRadius.circular(3.0),
                                );

                                if (isPureFinance) return indicator;

                                if (isLow) {
                                  // Stage 3: Visual pressure shimmer for 0%
                                  return indicator
                                      .animate(
                                        onPlay: (controller) =>
                                            controller.repeat(reverse: true),
                                      )
                                      .shimmer(
                                        duration: 2.seconds,
                                        color: Colors.white24,
                                        stops: [0.0, 0.5, 1.0],
                                      )
                                      .tint(color: Colors.white10);
                                }

                                // Stage 1: Pulse animation
                                Widget animatedGauge = indicator
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(reverse: true),
                                    )
                                    .custom(
                                      duration: 1500.ms,
                                      builder: (context, animValue, child) {
                                        return Opacity(
                                          opacity: 0.7 + (animValue * 0.3),
                                          child: child,
                                        );
                                      },
                                    );

                                if (isHigh) {
                                  // Stage 2: Neon Glow for 80%+
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.accent.withOpacity(0.6),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: animatedGauge,
                                  );
                                }

                                return animatedGauge;
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 64),

                        // Penalty Section (Editable)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '실패 시 나에게 주는 벌칙',
                              style: TextStyle(
                                color: isPureFinance
                                    ? colors.textMain
                                    : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!(item.isAchieved ||
                                progress >= 1.0)) // Only show if editable
                              BouncyButton(
                                onTap: _spinPenaltySlotMachine,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isSpinning
                                        ? (isPureFinance
                                              ? colors.accent
                                              : const Color(0xFFD4FF00))
                                        : (isPureFinance
                                              ? colors.surface
                                              : Colors.black26),
                                    borderRadius: BorderRadius.circular(
                                      8,
                                    ), // sharper corners
                                    border: Border.all(
                                      color: isPureFinance
                                          ? colors.border
                                          : const Color(0xFFD4FF00),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isPureFinance
                                                    ? colors.accent
                                                    : const Color(0xFFD4FF00))
                                                .withOpacity(0.3),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.casino,
                                        size: 16,
                                        color: _isSpinning
                                            ? Colors.black
                                            : (isPureFinance
                                                  ? colors.textMain
                                                  : const Color(0xFFD4FF00)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "운명의 뽑기",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _isSpinning
                                              ? Colors.black
                                              : (isPureFinance
                                                    ? colors.textMain
                                                    : const Color(0xFFD4FF00)),
                                          fontWeight:
                                              FontWeight.w900, // weight w900
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
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
                              FloatingInputField(
                                controller: _penaltyController,
                                label: (item.isAchieved || progress >= 1.0)
                                    ? "성공한 목표에는 벌칙이 없습니다"
                                    : "실패 시 수행할 벌칙을 입력하세요",
                                readOnly: item.isAchieved || progress >= 1.0,
                                maxLines: 4,
                                style: TextStyle(
                                  color: isPureFinance
                                      ? colors.textMain
                                      : Colors.white,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                accentColor: isPureFinance
                                    ? colors.accent
                                    : const Color(0xFFD4FF00),
                              ),
                              if (_hasChanges)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child:
                                      Text(
                                            '수정 사항이 있습니다. 하단의 SAVE 버튼을 눌러 확정하세요.',
                                            style: TextStyle(
                                              color: isPureFinance
                                                  ? colors.accent
                                                  : const Color(0xFFD4FF00),
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                          .animate(
                                            onPlay: (controller) => controller
                                                .repeat(reverse: true),
                                          )
                                          .fadeIn(duration: 1000.ms)
                                          .fadeOut(duration: 1000.ms),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 160), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Side Edge Handle
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 20,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _showEdgeMenu(item),
                onLongPress: () => _showEdgeMenu(item),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: (_hasChanges && !_isSaving)
            ? BouncyButton(
                    onTap: _saveChanges,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(30),
                        // PRD: 시선을 강탈하는 초강력 네온 광광 효과 (Multi-layered Glow)
                        boxShadow: [
                          BoxShadow(
                            color: colors.accent.withOpacity(0.6),
                            blurRadius: 25,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: colors.accent.withOpacity(0.4),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        "SAVE CHANGES",
                        style: GoogleFonts.robotoMono(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .slideY(
                    begin: 1.0,
                    end: 0.0,
                    curve: Curves.bounceOut,
                    duration: 600.ms,
                  )
                  .fadeIn(duration: 400.ms)
            : null,
      ),
    );
  }
}
