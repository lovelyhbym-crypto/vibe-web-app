import 'package:flutter/material.dart';

class BackgroundGradient extends StatelessWidget {
  final Widget child;

  const BackgroundGradient({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Layer
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A1A2E), // Deep Navy
                Colors.black,
              ],
            ),
          ),
        ),

        // Spot 1: Purple (Top Left)
        Positioned(
          top: -100,
          left: -50,
          width: 400,
          height: 400,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.purple.withOpacity(0.2), Colors.transparent],
                center: Alignment.center,
                radius: 0.8,
              ),
            ),
          ),
        ),

        // Spot 2: Teal (Center Right)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: -100,
          width: 300,
          height: 300,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.teal.withOpacity(0.15), Colors.transparent],
                center: Alignment.center,
                radius: 0.8,
              ),
            ),
          ),
        ),

        // Spot 3: Blue (Bottom Left)
        Positioned(
          bottom: -50,
          left: -50,
          width: 350,
          height: 350,
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.blueAccent.withOpacity(0.1),
                  Colors.transparent,
                ],
                center: Alignment.center,
                radius: 0.8,
              ),
            ),
          ),
        ),

        // Content
        child,
      ],
    );
  }
}
