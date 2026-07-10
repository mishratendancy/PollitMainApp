import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/pollit_theme.dart';
import 'topic_selection_screen.dart';

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
      title: 'Every Vote\nIs Fair.',
      subtitle:
          'Unlike other platforms, the most popular\noptions don\'t jump to the top. See all\nchoices at a glance without bias.',
    ),
    _OnboardingPageData(
      label: 'Discover',
      title: 'Vote to\nSee Results.',
      subtitle:
          'Can\'t see poll results until you vote.\nThis ensures genuine opinions—no\nbandwagon effect, just honest votes.',
    ),
    _OnboardingPageData(
      label: 'Connect',
      title: 'Join Your\nCommunity.',
      subtitle:
          'Find communities that match your interests.\nFollow topics, join discussions, and shape\nconversations that matter to you.',
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

  void _navigateToTopics() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const TopicSelectionScreen(),
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
      _navigateToTopics();
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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final topPad = MediaQuery.of(context).padding.top;

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
                child: Column(
                  children: [
                    SizedBox(height: topPad + 16),

                    // Top bar: Logo + Skip
                    Opacity(
                      opacity: _fadeIn.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Text(
                              'Pollit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _navigateToTopics,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Glow space (upper half is just the gradient)
                    const Spacer(flex: 3),

                    // Page label pill
                    Opacity(
                      opacity: _fadeIn.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideUp.value * 0.3),
                        child: _buildPageContent(),
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Bottom navigation
                    Opacity(
                      opacity: _fadeIn.value,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPad + 20),
                        child: _buildBottomNav(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPageContent() {
    return SizedBox(
      height: 260,
      child: PageView.builder(
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
              final opacity = (1 - parallax.abs() * 0.5).clamp(0.0, 1.0);

              return Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(parallax * -30, 0),
                  child: child,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    data.subtitle,
                    style: const TextStyle(
                      color: Color(0xFFD8D8D8),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  double _swipeOffset = 0;
  bool _swiping = false;
  bool _swipeCompleted = false;

  Widget _buildBottomNav() {
    const double pillHeight = 60;
    const double thumbSize = 48;
    const double thumbPad = 6;
    final isLast = _currentPage == _pages.length - 1;
    final label = isLast ? 'Swipe to get started' : 'Swipe to continue';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final maxOffset = trackWidth - thumbSize - thumbPad * 2;
            final progress = maxOffset > 0
                ? (_swipeOffset / maxOffset).clamp(0.0, 1.0)
                : 0.0;

            final bgAlpha = 0.08 - (progress * 0.06);
            final fillAlpha = progress * 0.15;
            final labelOpacity =
                _swiping ? (1.0 - progress).clamp(0.0, 0.75) : 0.75;

            return GestureDetector(
              onHorizontalDragStart: (_) {
                setState(() {
                  _swiping = true;
                  _swipeCompleted = false;
                });
              },
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _swipeOffset =
                      (_swipeOffset + details.delta.dx).clamp(0.0, maxOffset);
                });
              },
              onHorizontalDragEnd: (_) {
                if (_swipeOffset > maxOffset * 0.7) {
                  setState(() {
                    _swipeOffset = maxOffset;
                    _swipeCompleted = true;
                  });
                  Future.delayed(const Duration(milliseconds: 400), () {
                    _nextPage();
                    if (mounted) {
                      setState(() {
                        _swipeOffset = 0;
                        _swiping = false;
                        _swipeCompleted = false;
                      });
                    }
                  });
                } else {
                  setState(() {
                    _swipeOffset = 0;
                    _swiping = false;
                  });
                }
              },
              child: AnimatedContainer(
                duration: _swiping
                    ? Duration.zero
                    : const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: pillHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(pillHeight / 2),
                  color: Colors.white.withValues(alpha: bgAlpha),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Filled track behind thumb
                    AnimatedPositioned(
                      duration: _swiping
                          ? Duration.zero
                          : const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: thumbPad * 2 + thumbSize + _swipeOffset,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(pillHeight / 2),
                          color: PollitColors.accent
                              .withValues(alpha: fillAlpha),
                        ),
                      ),
                    ),
                    // Label text
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Opacity(
                          key: ValueKey('$label$_swiping'),
                          opacity: labelOpacity,
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Draggable thumb
                    AnimatedPositioned(
                      duration: _swiping
                          ? Duration.zero
                          : const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      left: thumbPad + _swipeOffset,
                      top: thumbPad,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: thumbSize,
                        height: thumbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _swipeCompleted
                              ? PollitColors.accent
                              : isLast
                                  ? PollitColors.accent
                                  : Color.lerp(
                                      Colors.white.withValues(alpha: 0.12),
                                      PollitColors.accent,
                                      progress,
                                    ),
                          boxShadow: [
                            BoxShadow(
                              color: PollitColors.accent
                                  .withValues(alpha: 0.15 + progress * 0.35),
                              blurRadius: 12 + progress * 8,
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutBack,
                          transitionBuilder: (child, anim) {
                            return ScaleTransition(
                              scale: anim,
                              child: FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                            );
                          },
                          child: _swipeCompleted
                              ? const Icon(
                                  Icons.check_rounded,
                                  key: ValueKey('tick'),
                                  color: Colors.white,
                                  size: 24,
                                )
                              : const Icon(
                                  Icons.arrow_forward_rounded,
                                  key: ValueKey('arrow'),
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
              onTap: _navigateToTopics,
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

