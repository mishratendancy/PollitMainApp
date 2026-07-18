import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/pollit_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_sidebar.dart';
import 'onboarding/auth_screen.dart';

class PollitHomePage extends StatefulWidget {
  const PollitHomePage({super.key});

  @override
  State<PollitHomePage> createState() => _PollitHomePageState();
}

class _PollitHomePageState extends State<PollitHomePage>
    with SingleTickerProviderStateMixin {
  final Map<String, String> _votes = {};
  late final AnimationController _entryController;

  static final List<_PollData> _mockPolls = [
    _PollData(
      id: 'p1',
      community: 'Weekend',
      headline: 'Favorite way to recharge?',
      description:
          'Options stay in alphabetical order so you can scan everything fairly.',
      options: [
        _OptionData(label: 'Cooking', percent: 22, votes: 184),
        _OptionData(label: 'Gaming', percent: 18, votes: 151),
        _OptionData(label: 'Hiking', percent: 31, votes: 259),
        _OptionData(label: 'Reading', percent: 29, votes: 242),
      ],
    ),
    _PollData(
      id: 'p2',
      community: 'Product',
      headline: 'Should we cap free polls at 25 options?',
      description: 'Pollsters are advised to stay under 25 options on the free tier.',
      options: [
        _OptionData(label: 'No — keep it flexible', percent: 37, votes: 412),
        _OptionData(label: 'Yes — clarity over clutter', percent: 63, votes: 701),
      ],
    ),
    _PollData(
      id: 'p3',
      community: 'Technology',
      headline: 'Best programming language for beginners?',
      description: 'Vote to see what the community thinks — all options shown alphabetically.',
      options: [
        _OptionData(label: 'JavaScript', percent: 28, votes: 342),
        _OptionData(label: 'Python', percent: 45, votes: 551),
        _OptionData(label: 'Rust', percent: 12, votes: 147),
        _OptionData(label: 'Swift', percent: 15, votes: 183),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _onVote(String pollId, String optionLabel) {
    setState(() => _votes[pollId] = optionLabel);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: PollitColors.background,
      drawer: const AppSidebar(),
      appBar: AppBar(
        backgroundColor: PollitColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Pollit',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile & settings',
            color: PollitColors.surface,
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: PollitColors.cardBorder, width: 0.5),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                await Provider.of<AuthProvider>(context, listen: false).logout();
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
            itemBuilder: (context) {
              final profile = Provider.of<AuthProvider>(context, listen: false).userProfile;
              final username = profile?['username'] ?? 'User';
              
              return [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    '@$username',
                    style: TextStyle(
                      color: PollitColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'profile',
                  child: Text('Profile'),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text(
                    'Log out',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(
          parent: _entryController,
          curve: Curves.easeOut,
        ),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: _mockPolls.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your vote counts',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vote to see results. Options are always shown fairly.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: PollitColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            final poll = _mockPolls[index - 1];
            final voted = _votes[poll.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _PollCard(
                poll: poll,
                selectedLabel: voted,
                onVote: (label) => _onVote(poll.id, label),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PollData {
  const _PollData({
    required this.id,
    required this.community,
    required this.headline,
    required this.description,
    required this.options,
  });

  final String id;
  final String community;
  final String headline;
  final String description;
  final List<_OptionData> options;

  List<_OptionData> get sortedOptions {
    final copy = List<_OptionData>.from(options);
    copy.sort((a, b) => a.label.compareTo(b.label));
    return copy;
  }
}

class _OptionData {
  const _OptionData({
    required this.label,
    required this.percent,
    required this.votes,
  });

  final String label;
  final int percent;
  final int votes;
}

class _PollCard extends StatefulWidget {
  const _PollCard({
    required this.poll,
    required this.selectedLabel,
    required this.onVote,
  });

  final _PollData poll;
  final String? selectedLabel;
  final ValueChanged<String> onVote;

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _voteAnimController;

  @override
  void initState() {
    super.initState();
    _voteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.selectedLabel != null) {
      _voteAnimController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _PollCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedLabel != null && oldWidget.selectedLabel == null) {
      _voteAnimController.forward();
    }
  }

  @override
  void dispose() {
    _voteAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasVoted = widget.selectedLabel != null;
    final options = widget.poll.sortedOptions;

    return Container(
      decoration: BoxDecoration(
        color: PollitColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: PollitColors.cardBorder,
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: PollitColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.poll.community,
                    style: TextStyle(
                      color: PollitColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    hasVoted ? 'Results unlocked' : 'Vote to view',
                    key: ValueKey(hasVoted),
                    style: TextStyle(
                      color: hasVoted
                          ? PollitColors.accent
                          : PollitColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.poll.headline,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.poll.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: PollitColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((o) {
              final selected = widget.selectedLabel == o.label;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionTile(
                  option: o,
                  selected: selected,
                  hasVoted: hasVoted,
                  onTap: hasVoted ? null : () => widget.onVote(o.label),
                  animController: _voteAnimController,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.hasVoted,
    required this.onTap,
    required this.animController,
  });

  final _OptionData option;
  final bool selected;
  final bool hasVoted;
  final VoidCallback? onTap;
  final AnimationController animController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? PollitColors.accent.withValues(alpha: 0.1)
              : PollitColors.surfaceLight.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? PollitColors.accent.withValues(alpha: 0.4)
                : Colors.transparent,
            width: selected ? 1 : 0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    !hasVoted
                        ? Icons.how_to_vote_outlined
                        : selected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                    key: ValueKey('$hasVoted$selected'),
                    size: 20,
                    color: selected
                        ? PollitColors.accent
                        : PollitColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: PollitColors.textPrimary,
                    ),
                  ),
                ),
                if (hasVoted)
                  AnimatedBuilder(
                    animation: animController,
                    builder: (context, _) {
                      return Opacity(
                        opacity: animController.value,
                        child: Text(
                          '${option.percent}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: PollitColors.accent,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            if (hasVoted) ...[
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: animController,
                builder: (context, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (option.percent / 100) * animController.value,
                      minHeight: 4,
                      backgroundColor: PollitColors.surfaceLight,
                      color: selected
                          ? PollitColors.accent
                          : PollitColors.accent.withValues(alpha: 0.4),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),
              AnimatedBuilder(
                animation: animController,
                builder: (context, _) {
                  return Opacity(
                    opacity: animController.value,
                    child: Text(
                      '${option.votes} votes',
                      style: TextStyle(
                        color: PollitColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
