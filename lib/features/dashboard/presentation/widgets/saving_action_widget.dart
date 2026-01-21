import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vive_app/core/services/bank_account_service.dart';
import 'package:vive_app/features/saving/providers/saving_provider.dart';
import 'package:vive_app/features/home/providers/navigation_provider.dart';
import 'package:vive_app/features/dashboard/providers/reward_state_provider.dart';
import 'package:vive_app/features/wishlist/providers/wishlist_provider.dart';

class SavingActionWidget extends ConsumerStatefulWidget {
  const SavingActionWidget({super.key});

  @override
  ConsumerState<SavingActionWidget> createState() => _SavingActionWidgetState();
}

class _SavingActionWidgetState extends ConsumerState<SavingActionWidget>
    with WidgetsBindingObserver {
  bool _isWaitingForTransfer = false;
  final _bankAccountService = BankAccountService();
  final _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isWaitingForTransfer) {
      _showSuccessDialog();
    }
  }

  Future<void> _launchBankApp() async {
    await HapticFeedback.heavyImpact();
    final info = await _bankAccountService.getAccountInfo();
    final accountNo = info['accountNumber'];

    if (accountNo == null || accountNo.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('송금 계좌 정보가 설정되어 있지 않습니다.')),
        );
      }
      return;
    }

    final String url =
        'supertoss://send?bank=092&accountNo=$accountNo&amount=10000';
    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        setState(() {
          _isWaitingForTransfer = true;
        });
        await launchUrl(uri);
      } else {
        debugPrint(
          'Toss app not found. Simulation Mode: Showing success dialog.',
        );
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint(
        'Deep Link Error: $e. Simulation Mode: Showing success dialog.',
      );
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('송금을 완료했나요?', style: TextStyle(color: Colors.white)),
        content: const Text(
          '확인을 누르면 실제 저축 데이터가 생성됩니다.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isWaitingForTransfer = false;
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4FF00),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              if (mounted) Navigator.pop(dialogContext);

              final wishlists = ref.read(wishlistProvider).valueOrNull ?? [];
              if (wishlists.isEmpty) return;

              final representative = wishlists.firstWhere(
                (w) => w.isRepresentative,
                orElse: () => wishlists.first,
              );
              final targetId = representative.id;

              // 1. 보상 장전 (전역 폭죽 신호)
              ref.read(rewardStateProvider.notifier).triggerConfetti();

              if (targetId != null) {
                // 2. 안개 정화
                await ref.read(wishlistProvider.notifier).purifyFog(targetId);

                // 3. 위시리스트 금액 업데이트 (중요: SOS 저축액은 10,000원으로 고정)
                await ref
                    .read(wishlistProvider.notifier)
                    .addFundsToSelectedItems(10000.0, [targetId]);
              }

              // 4. 저축 데이터 기록
              await _recordSaving();

              // 5. 목표 탭으로 즉시 이동 (인덱스 1)
              if (mounted) {
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

  Future<void> _recordSaving() async {
    try {
      await ref
          .read(savingProvider.notifier)
          .addSaving(
            category: "인질 구출",
            amount: 10000,
            createdAt: DateTime.now(),
          );

      setState(() {
        _isWaitingForTransfer = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('성공적으로 구출했습니다!')));
      }
    } catch (e) {
      debugPrint('Saving Error: $e');
    }
  }

  void _showDefeatDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '패배를 인정하시겠습니까?',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('얼마를 낭비했습니까?', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '금액 입력',
                hintStyle: TextStyle(color: Colors.white30),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.redAccent),
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
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              Navigator.pop(context);
              _executeDefeatSequence(amount);
            },
            child: const Text('패배 선언'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDefeatSequence(double amount) async {
    // 1. Sound: 유리창 깨지는 소리 재생 (안전 모드: 오디오 파일 부재로 주석 처리)
    debugPrint(
      'Sound Simulation: Glass Breaking Sound Played (Amount: $amount)',
    );
    /*
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(AssetSource('audio/glass_break.mp3'));
    } catch (e) {
      debugPrint('Sound Audio Error: $e');
    }
    */

    // 2. State: 현재 위시리스트파괴
    final wishlists = ref.read(wishlistProvider).valueOrNull ?? [];
    if (wishlists.isNotEmpty) {
      final representative = wishlists.firstWhere(
        (w) => w.isRepresentative,
        orElse: () => wishlists.first,
      );
      final targetId = representative.id;
      if (targetId != null) {
        await ref.read(wishlistProvider.notifier).shatterDream(targetId);
      }
    }

    // 3. Navigation: 즉시 위시리스트 탭으로 강제 전환
    if (mounted) {
      HapticFeedback.vibrate();
      context.go('/');
      ref.read(navigationIndexProvider.notifier).setIndex(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    const limeColor = Color(0xFFD4FF00);

    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onTap: _launchBankApp,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: limeColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: limeColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded, size: 50, color: limeColor),
                    const SizedBox(height: 16),
                    const Text(
                      "송금하고 구출하기",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "토스뱅크로 10,000원 송금",
                      style: TextStyle(
                        fontSize: 12,
                        color: limeColor.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showDefeatDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.broken_image_outlined, size: 18),
            label: const Text(
              "유혹에 패배함 (꿈 파괴)",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
