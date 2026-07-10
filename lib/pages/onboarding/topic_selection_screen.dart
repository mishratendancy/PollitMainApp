import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/pollit_theme.dart';
import 'dart:ui';
import '../app_shell.dart';

class TopicSelectionScreen extends StatefulWidget {
  const TopicSelectionScreen({super.key});

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _selected = {};
  late final AnimationController _entryController;
  late final Animation<double> _headerOpacity;
  late final Animation<double> _headerSlide;

  static const _topics = [
    _Topic('Technology', Icons.devices_rounded),
    _Topic('Politics', Icons.account_balance_rounded),
    _Topic('Sports', Icons.sports_basketball_rounded),
    _Topic('Entertainment', Icons.movie_creation_rounded),
    _Topic('Science', Icons.science_rounded),
    _Topic('Gaming', Icons.sports_esports_rounded),
    _Topic('Music', Icons.music_note_rounded),
    _Topic('Food & Cooking', Icons.restaurant_rounded),
    _Topic('Travel', Icons.flight_rounded),
    _Topic('Finance', Icons.trending_up_rounded),
    _Topic('Health', Icons.favorite_rounded),
    _Topic('Education', Icons.school_rounded),
    _Topic('Art & Design', Icons.palette_rounded),
    _Topic('Fitness', Icons.fitness_center_rounded),
    _Topic('Books', Icons.auto_stories_rounded),
    _Topic('Environment', Icons.eco_rounded),
    _Topic('Fashion', Icons.checkroom_rounded),
    _Topic('Photography', Icons.camera_alt_rounded),
    _Topic('Crypto', Icons.currency_bitcoin_rounded),
    _Topic('Movies & TV', Icons.live_tv_rounded),
    _Topic('Startups', Icons.rocket_launch_rounded),
    _Topic('Relationships', Icons.people_rounded),
    _Topic('Pets', Icons.pets_rounded),
    _Topic('DIY & Crafts', Icons.handyman_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _headerSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _toggleTopic(String topic) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selected.contains(topic)) {
        _selected.remove(topic);
      } else {
        _selected.add(topic);
      }
    });
  }

  void _continue() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AppShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.2, 1.0),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final hasEnoughSelections = _selected.length >= 3;

    return Scaffold(
      backgroundColor: PollitColors.background,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  AnimatedBuilder(
                    animation: _entryController,
                    builder: (context, _) {
                      return Opacity(
                        opacity: _headerOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _headerSlide.value),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Spacer(),
                                  TextButton(
                                    onPressed: _continue,
                                    child: const Text(
                                      'Skip',
                                      style: TextStyle(
                                        color: PollitColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'What interests\nyou most?',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Pick at least 3 topics to personalize your feed. You can always change these later.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: PollitColors.textSecondary,
                                      height: 1.5,
                                    ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Topics Wrap
                  Wrap(
                    spacing: 12,
                    runSpacing: 14,
                    children: _topics.map((topic) {
                      final isSelected = _selected.contains(topic.label);
                      return _TopicChip(
                        topic: topic,
                        isSelected: isSelected,
                        onTap: () => _toggleTopic(topic.label),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Floating Bottom Action
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPad > 0 ? bottomPad + 8 : 24,
              child: Center(
                child: GestureDetector(
                  onTap: hasEnoughSelections ? _continue : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          color: hasEnoughSelections ? PollitColors.accent.withValues(alpha: 0.05) : PollitColors.surfaceLight.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: hasEnoughSelections ? PollitColors.accent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                              child: child,
                            ),
                          ),
                          child: hasEnoughSelections
                              ? const Row(
                                  key: ValueKey('continue'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Continue',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                  ],
                                )
                              : Text(
                                  '${_selected.length}/3 selected',
                                  key: const ValueKey('counter'),
                                  style: const TextStyle(
                                    color: PollitColors.textMuted,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Topic {
  const _Topic(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _TopicChip extends StatefulWidget {
  const _TopicChip({
    required this.topic,
    required this.isSelected,
    required this.onTap,
  });

  final _Topic topic;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TopicChip> createState() => _TopicChipState();
}

class _TopicChipState extends State<_TopicChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? PollitColors.accent
                : PollitColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : PollitColors.cardBorder.withValues(alpha: 0.5),
              width: 1,
            ),

          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  widget.topic.icon,
                  key: ValueKey(widget.isSelected),
                  size: 20,
                  color: widget.isSelected
                      ? Colors.black
                      : PollitColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.topic.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? Colors.black
                      : PollitColors.textPrimary,
                  fontSize: 14,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
