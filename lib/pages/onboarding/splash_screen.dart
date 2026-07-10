import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/pollit_theme.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _slideUp;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideUp = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();

    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            reverseTransitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const OnboardingScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: WavyGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: AnimatedBuilder(
              animation: _entryController,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row
                    Opacity(
                      opacity: _fadeIn.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideUp.value * 0.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'POLLIT\nAPP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                letterSpacing: 0.5,
                                height: 1.1,
                              ),
                            ),
                            Icon(
                              Icons.how_to_vote_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Bottom Row
                    Opacity(
                      opacity: _fadeIn.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideUp.value),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6.0),
                              child: Text(
                                '${DateTime.now().year}',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'MORE\nTHAN JUST\nPOLLING',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                height: 0.95,
                                letterSpacing: -1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class WavyGradientBackground extends StatefulWidget {
  const WavyGradientBackground({super.key, this.child});
  final Widget? child;

  @override
  State<WavyGradientBackground> createState() => _WavyGradientBackgroundState();
}

class _WavyGradientBackgroundState extends State<WavyGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base
        Container(color: Colors.white),

        // Blurred color blobs -> creates the wavy gradient
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * pi;
            // Smooth morphing drift
            final driftX1 = sin(t) * 30;
            final driftY1 = cos(t) * 20;
            final driftX2 = cos(t + pi / 2) * 40;
            final driftY2 = sin(t + pi / 4) * 25;
            final driftX3 = sin(t + pi) * 25;
            final driftY3 = cos(t + pi) * 35;

            return ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Stack(
                children: [
                  Positioned(
                    top: -120 + driftY1,
                    left: -60 + driftX1,
                    child: _blob(340, const Color(0xFF041215)), // near-black teal
                  ),
                  Positioned(
                    top: -40 + driftY2,
                    right: -80 + driftX2,
                    child: _blob(320, PollitColors.accentDark), // deep teal
                  ),
                  Positioned(
                    top: 140 + driftY3,
                    left: -40 + driftX3,
                    child: _blob(360, PollitColors.accent), // bright teal
                  ),
                  Positioned(
                    bottom: -150,
                    left: -80,
                    child: _blob(400, Colors.white), // fades to white bottom
                  ),
                  Positioned(
                    bottom: -100,
                    right: -100,
                    child: _blob(350, Colors.white),
                  ),
                ],
              ),
            );
          },
        ),

        // Grain (wrapped in RepaintBoundary to cache the expensive painting)
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: _GrainOverlay(),
            ),
          ),
        ),

        if (widget.child != null) widget.child!,
      ],
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

/// Static film-grain noise painted with tiny translucent dots.
/// Seeded so it doesn't change every rebuild/flicker.
class _GrainOverlay extends StatelessWidget {
  const _GrainOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GrainPainter(),
      child: Container(),
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Reset seed inside paint to guarantee consistent output on every paint call
    final r = Random(42); 
    final paint = Paint();
    const density = 7000; // finer grain
    for (var i = 0; i < density; i++) {
      final dx = r.nextDouble() * size.width;
      final dy = r.nextDouble() * size.height;
      final opacity = r.nextDouble() * 0.05; // subtle opacity
      paint.color = r.nextBool()
          ? Colors.white.withValues(alpha: opacity)
          : Colors.black.withValues(alpha: opacity);
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1.5, 1.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) => false;
}
