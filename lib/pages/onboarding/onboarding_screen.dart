import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/pollit_theme.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _entryController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPageData(
      label: 'Vote',
      title: 'Every\nVote\nIs Fair.',
      subtitle: 'See all choices at a glance, completely free from popularity bias.',
    ),
    _OnboardingPageData(
      label: 'Discover',
      title: 'Vote\nTo\nSee Results.',
      subtitle: 'Honest opinions only. Results stay hidden until you cast your vote.',
    ),
    _OnboardingPageData(
      label: 'Connect',
      title: 'Join\nYour\nCommunity.',
      subtitle: 'Follow topics and dive right into the conversations you care about.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideUp = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _navigateToAuth() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthScreen(),
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

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _navigateToAuth();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: PollitColors.background,
      body: AnimatedBuilder(
        animation: _entryController,
        builder: (context, _) {
          return Stack(
            children: [
              // === BLURRED GRADIENT ===
              ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 60,
                  sigmaY: 60,
                  tileMode: TileMode.decal,
                ),
                child: CustomPaint(
                  size: size,
                  painter: const _AuroraGlowPainter(),
                ),
              ),

              // === CONTENT ===
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top bar: Editorial Header + Skip
                      Opacity(
                        opacity: _fadeIn.value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'POLLIT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _navigateToAuth,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: const Text(
                                    'SKIP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Page Content (Giant Typography)
                      Expanded(
                        child: Opacity(
                          opacity: _fadeIn.value,
                          child: _buildPageContent(),
                        ),
                      ),

                      // Bottom navigation
                      Opacity(
                        opacity: _fadeIn.value,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                          child: _buildBottomNav(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageContent() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _pages.length,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemBuilder: (context, index) {
        final data = _pages[index];

        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double parallax = 0;
            if (_pageController.position.haveDimensions) {
              parallax = (_pageController.page ?? 0) - index;
            }
            final opacity = (1 - parallax.abs() * 0.6).clamp(0.0, 1.0);

            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(parallax * -60, 0), // Stronger parallax
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Stack(
              children: [
                // Giant Title and Subtitle at bottom right
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Editorial Title (Last line is bold)
                      ...data.title.toUpperCase().split('\n').asMap().entries.map((entry) {
                        final isLast = entry.key == data.title.split('\n').length - 1;
                        return Text(
                          entry.value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: isLast ? FontWeight.w800 : FontWeight.w300,
                            height: 1.0,
                            letterSpacing: isLast ? -1.5 : -1.0,
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      // Subtitle
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.70,
                        child: Text(
                          data.subtitle,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13,
                            height: 1.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    final isLast = _currentPage == _pages.length - 1;
    final label = isLast ? 'Get started' : 'Continue';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (isLast) {
              _navigateToAuth();
            } else {
              _nextPage();
            }
          },
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              borderRadius: BorderRadius.circular(30),
            ),
            alignment: Alignment.center,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Already a Pollster row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already a Pollster? ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 13,
              ),
            ),
            GestureDetector(
              onTap: _navigateToAuth,
              child: Text(
                'Log in',
                style: TextStyle(
                  color: PollitColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.label,
    required this.title,
    required this.subtitle,
  });

  final String label;
  final String title;
  final String subtitle;
}

class _AuroraGlowPainter extends CustomPainter {
  const _AuroraGlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Diagonal sweep from top-left to mid-right
    final sweep1 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: const Alignment(0.6, 0.5),
        colors: [
          PollitColors.accentLight.withValues(alpha: 0.55),
          PollitColors.accent.withValues(alpha: 0.30),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.7, 0)
      ..cubicTo(w * 0.55, h * 0.15, w * 0.35, h * 0.30, w * 0.1, h * 0.50)
      ..cubicTo(w * -0.05, h * 0.38, 0, h * 0.18, 0, 0)
      ..close();
    canvas.drawPath(path1, sweep1);

    // Wide flowing band across the upper-middle
    final sweep2 = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(-0.8, -0.3),
        end: const Alignment(1.0, 0.4),
        colors: [
          PollitColors.accentDark.withValues(alpha: 0.40),
          PollitColors.accent.withValues(alpha: 0.50),
          PollitColors.accentLight.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.65, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path2 = Path()
      ..moveTo(0, h * 0.10)
      ..cubicTo(w * 0.25, h * 0.05, w * 0.50, h * 0.18, w, h * 0.22)
      ..lineTo(w, h * 0.42)
      ..cubicTo(w * 0.60, h * 0.38, w * 0.30, h * 0.28, 0, h * 0.35)
      ..close();
    canvas.drawPath(path2, sweep2);

    // Accent ribbon from right side curving down
    final sweep3 = Paint()
      ..shader = LinearGradient(
        begin: const Alignment(0.5, -0.5),
        end: const Alignment(-0.3, 0.8),
        colors: [
          PollitColors.accentLight.withValues(alpha: 0.45),
          PollitColors.accent.withValues(alpha: 0.30),
          PollitColors.accentDark.withValues(alpha: 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.30, 0.60, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path3 = Path()
      ..moveTo(w, h * 0.05)
      ..cubicTo(w * 0.75, h * 0.20, w * 0.55, h * 0.35, w * 0.30, h * 0.45)
      ..cubicTo(w * 0.45, h * 0.50, w * 0.70, h * 0.42, w, h * 0.38)
      ..close();
    canvas.drawPath(path3, sweep3);

    // Soft bottom-left glow to ground the composition
    final bottomGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, 0.7),
        radius: 0.8,
        colors: [
          PollitColors.accentDark.withValues(alpha: 0.25),
          PollitColors.accent.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bottomGlow);
  }

  @override
  bool shouldRepaint(_AuroraGlowPainter old) => false;
}

