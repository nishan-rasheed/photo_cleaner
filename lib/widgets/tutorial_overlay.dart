import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const TutorialOverlay({super.key, required this.onDismiss});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: InkWell(
        onTap: widget.onDismiss,
        child: Stack(
          children: [
            // Swipe Up Gesture
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                        Icons.touch_app_rounded,
                        color: Colors.white,
                        size: 64,
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .moveY(
                        begin: 50,
                        end: -50,
                        duration: 1500.ms,
                        curve: Curves.easeInOut,
                      )
                      .fadeOut(begin: 1, delay: 1000.ms, duration: 500.ms),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: const Text(
                      "Swipe Up to Delete",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms).scale(),
                ],
              ),
            ),

            // Swipe Left/Right Gesture
            Positioned(
              bottom: 150,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white70,
                            size: 32,
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .moveX(begin: 10, end: -10, duration: 1000.ms),
                      const SizedBox(width: 20),
                      const Icon(
                        Icons.touch_app_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(width: 20),
                      const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white70,
                            size: 32,
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .moveX(begin: -10, end: 10, duration: 1000.ms),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Text(
                      "Swipe Left/Right to Browse",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms).scale(),
                ],
              ),
            ),

            // Dismiss Button
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child:
                    TextButton(
                          onPressed: widget.onDismiss,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Got it!",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 1000.ms)
                        .moveY(begin: 20, end: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
