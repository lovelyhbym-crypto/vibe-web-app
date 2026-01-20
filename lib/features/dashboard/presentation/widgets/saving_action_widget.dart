import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vive_app/core/services/bank_account_service.dart';
import 'package:vive_app/features/saving/providers/saving_provider.dart';

class SavingActionWidget extends ConsumerStatefulWidget {
  const SavingActionWidget({super.key});

  @override
  ConsumerState<SavingActionWidget> createState() => _SavingActionWidgetState();
}

class _SavingActionWidgetState extends ConsumerState<SavingActionWidget>
    with WidgetsBindingObserver {
  bool _isWaitingForTransfer = false;
  final _bankAccountService = BankAccountService();

  @override
  void initState() {
    super.initState();
    // 앱 생명주기 감시를 위해 Observer 등록
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 메모리 누수 방지를 위해 Observer 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 포그라운드로 복귀(resumed)하고 송금 대기 중일 때 다이얼로그 표시
    if (state == AppLifecycleState.resumed && _isWaitingForTransfer) {
      _showSuccessDialog();
    }
  }

  Future<void> _launchBankApp() async {
    // 1. 강한 진동 피드백
    await HapticFeedback.heavyImpact();

    // 2. 계좌 정보 가져오기
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

    // 3. 토스 딥링크 실행 (금액 10,000원 고정)
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
        // 웹 테스트용 시뮬레이션: 앱 실행 실패 시에도 다이얼로그 강제 호출
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
      builder: (context) => AlertDialog(
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
              Navigator.pop(context);
            },
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4FF00),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              // 실제 저축 로직 실행
              await _recordSaving();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('네(확인)'),
          ),
        ],
      ),
    );
  }

  Future<void> _recordSaving() async {
    try {
      debugPrint('Executing addSaving: Category: 인질 구출, Amount: 10000');
      // 카테고리 "인질 구출", 금액 10000원 고정 호출
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

  @override
  Widget build(BuildContext context) {
    const limeColor = Color(0xFFD4FF00);

    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: _launchBankApp,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: limeColor, width: 3), // 테두리 강조
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
    );
  }
}
