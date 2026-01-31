import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:nerve/features/dashboard/providers/reward_state_provider.dart';

class FullImageViewer extends ConsumerStatefulWidget {
  final String imageUrl;
  final String heroTag;

  const FullImageViewer({
    super.key,
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  ConsumerState<FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends ConsumerState<FullImageViewer>
    with TickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flashAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeOut));

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Start flash effect on entry
    _flashController.forward();
  }

  @override
  void dispose() {
    _flashController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewardState = ref.watch(rewardStateProvider);

    // 폭죽 상태 감시
    ref.listen(rewardStateProvider.select((s) => s.showConfetti), (prev, next) {
      if (next) {
        _confettiController.play();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dismissible Wrapper for Vertical Swipe to Close
          Dismissible(
            key: const Key('full_image_viewer_dismiss'),
            direction: DismissDirection.vertical,
            onDismissed: (_) => context.pop(),
            child: GestureDetector(
              onTap: () => context.pop(), // Close on background tap
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: widget.heroTag,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: rewardState.isMonochrome ? 1.0 : 0.0,
                        end: rewardState.isMonochrome ? 1.0 : 0.0,
                      ),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, saturation, child) {
                        return ColorFiltered(
                          colorFilter: ColorFilter.matrix([
                            0.2126 + 0.7874 * (1 - saturation),
                            0.7152 - 0.7152 * (1 - saturation),
                            0.0722 - 0.0722 * (1 - saturation),
                            0,
                            0,
                            0.2126 - 0.2126 * (1 - saturation),
                            0.7152 + 0.2848 * (1 - saturation),
                            0.0722 - 0.0722 * (1 - saturation),
                            0,
                            0,
                            0.2126 - 0.2126 * (1 - saturation),
                            0.7152 - 0.7152 * (1 - saturation),
                            0.0722 + 0.9278 * (1 - saturation),
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Confetti Widget at the top
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Color(0xFFD4FF00),
              ],
            ),
          ),

          // Flash Overlay (White -> Transparent)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _flashAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _flashAnimation.value,
                  child: Container(color: Colors.white),
                );
              },
            ),
          ),

          // Close Button (Optional convenience)
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}
