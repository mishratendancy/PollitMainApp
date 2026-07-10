import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../theme/pollit_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../services/firestore_service.dart';
import '../models/poll.dart';
import '../models/option.dart';
import '../widgets/app_sidebar.dart';
import 'onboarding/auth_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isTopBarVisible = true;

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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: PollitColors.background,
      drawer: const AppSidebar(),
      body: Stack(
        children: [
          // The Feed List
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.forward) {
                if (!_isTopBarVisible) setState(() => _isTopBarVisible = true);
              } else if (notification.direction == ScrollDirection.reverse) {
                if (_isTopBarVisible) setState(() => _isTopBarVisible = false);
              }
              return false;
            },
            child: Consumer<FeedProvider>(
              builder: (context, feedProvider, child) {
                if (feedProvider.isLoading && feedProvider.polls.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (feedProvider.error != null) {
                  return Center(
                    child: Text(
                      'Error: ${feedProvider.error}',
                      style: const TextStyle(color: PollitColors.error),
                    ),
                  );
                }

                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entryController,
                    curve: Curves.easeOut,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(4, topPadding + 80, 4, 24),
                    itemCount: feedProvider.polls.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: PollitColors.background,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: PollitColors.accent.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: PollitColors.accent.withValues(alpha: 0.8), size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'Search Poll-it',
                                style: TextStyle(
                                  color: PollitColors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final pollIndex = index - 1;
                      final isFirstPoll = pollIndex == 0;
                      final isLastPoll = pollIndex == feedProvider.polls.length - 1;

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: isFirstPoll ? const BorderSide(color: PollitColors.cardBorder) : BorderSide.none,
                            left: const BorderSide(color: PollitColors.cardBorder),
                            right: const BorderSide(color: PollitColors.cardBorder),
                            bottom: isLastPoll ? const BorderSide(color: PollitColors.cardBorder) : BorderSide.none,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (isFirstPoll) const SizedBox(height: 16),
                            
                            // The Inner Frame (Poll Card)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: PollitColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: PollitColors.cardBorder),
                              ),
                              child: _PollCard(
                                poll: feedProvider.polls[pollIndex],
                                firestoreService: _firestoreService,
                              ),
                            ),
                            
                            // Divider between inner frames
                            if (!isLastPoll)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: PollitColors.cardBorder,
                                ),
                              ),
                            if (isLastPoll) const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          // The Animated Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: _isTopBarVisible ? topPadding + 60 : topPadding + 16, // Collapses to a 16px border below status bar
              decoration: BoxDecoration(
                color: PollitColors.background,
                border: Border(
                  bottom: BorderSide(
                    color: PollitColors.cardBorder.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isTopBarVisible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_isTopBarVisible,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu, color: PollitColors.textPrimary),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Poll-it',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.account_circle_outlined, color: PollitColors.textPrimary),
                            tooltip: 'Profile & settings',
                            color: PollitColors.surface,
                            offset: const Offset(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: PollitColors.cardBorder, width: 0.5),
                            ),
                            onSelected: (value) async {
                              if (value == 'logout') {
                                await Provider.of<AuthProvider>(context, listen: false).logout();
                                if (mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                                    (_) => false,
                                  );
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
                                    style: const TextStyle(
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
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollCard extends StatefulWidget {
  const _PollCard({
    required this.poll,
    required this.firestoreService,
  });

  final Poll poll;
  final FirestoreService firestoreService;

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _voteAnimController;
  bool _hasVoted = false;
  String? _selectedOptionId;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _voteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkVoteStatus();
  }

  Future<void> _checkVoteStatus() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      final voted = await widget.firestoreService.hasUserVoted(
        widget.poll.community, 
        widget.poll.id, 
        auth.user!.uid,
      );
      if (mounted && voted) {
        setState(() {
          _hasVoted = true;
        });
        _voteAnimController.value = 1.0;
      }
    }
  }

  Future<void> _handleVote(String optionId) async {
    if (_hasVoted || _isVoting) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;

    setState(() {
      _isVoting = true;
      _selectedOptionId = optionId;
    });

    try {
      await widget.firestoreService.submitVote(
        communitySlug: widget.poll.community,
        pollId: widget.poll.id,
        optionId: optionId,
        uid: auth.user!.uid,
      );
      
      if (mounted) {
        setState(() {
          _hasVoted = true;
          _isVoting = false;
        });
        _voteAnimController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVoting = false;
          _selectedOptionId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to vote. Please try again.')),
        );
      }
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
    final date = DateTime.fromMillisecondsSinceEpoch(widget.poll.createdAt);
    final diff = DateTime.now().difference(date);
    String timeString;
    if (diff.inDays > 0) {
      timeString = '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      timeString = '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      timeString = '${diff.inMinutes}m';
    } else {
      timeString = 'just now';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reddit-style Header
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: PollitColors.accent.withValues(alpha: 0.6),
                child: Text(
                  widget.poll.community.isNotEmpty ? widget.poll.community[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'p/${widget.poll.community}',
                style: const TextStyle(
                  color: PollitColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '· Posted by u/${widget.poll.creatorName ?? 'Anonymous'} · $timeString',
                  style: const TextStyle(
                    color: PollitColors.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Title
          Text(
            widget.poll.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: PollitColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (widget.poll.description != null && widget.poll.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.poll.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: PollitColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          // Options List
          StreamBuilder<List<PollOption>>(
            stream: widget.firestoreService.getPollOptionsStream(
              widget.poll.community, 
              widget.poll.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return const Text('Failed to load options', style: TextStyle(color: PollitColors.error));
              }

              var options = snapshot.data ?? [];
              options.sort((a, b) => a.text.compareTo(b.text));

              return Column(
                children: options.map((o) {
                  final isThisSelected = _selectedOptionId == o.id;
                  final totalVotes = widget.poll.voteCount;
                  final percent = totalVotes == 0 
                    ? 0.0 
                    : (o.voteCount / totalVotes) * 100;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _OptionTile(
                      option: o,
                      percent: percent,
                      selected: isThisSelected,
                      hasVoted: _hasVoted,
                      isVoting: _isVoting,
                      onTap: _hasVoted ? null : () => _handleVote(o.id),
                      animController: _voteAnimController,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          
          const SizedBox(height: 12),
          
          // Footer Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFooterButton(
                icon: Icons.show_chart,
                label: '${widget.poll.voteCount} vote${widget.poll.voteCount == 1 ? '' : 's'}',
              ),
              _buildFooterButton(
                icon: Icons.chat_bubble_outline,
                label: '0 Comments',
              ),
              _buildFooterButton(
                icon: Icons.more_horiz,
                label: 'More',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButton({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        // Optional: add a subtle hover/tap background color if wrapped in InkWell later
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: PollitColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: PollitColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.percent,
    required this.selected,
    required this.hasVoted,
    required this.isVoting,
    required this.onTap,
    required this.animController,
  });

  final PollOption option;
  final double percent;
  final bool selected;
  final bool hasVoted;
  final bool isVoting;
  final VoidCallback? onTap;
  final AnimationController animController;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isVoting ? null : onTap,
      child: Stack(
        children: [
          // Background Progress Bar Fill (Only visible after voting)
          if (hasVoted)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: animController,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (percent / 100) * animController.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: PollitColors.surfaceLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Foreground content
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: PollitColors.cardBorder,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isVoting && selected 
                    ? const SizedBox(
                        width: 18, 
                        height: 18, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : Icon(
                    !hasVoted
                        ? Icons.radio_button_unchecked
                        : selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                    key: ValueKey('$hasVoted$selected'),
                    size: 18,
                    color: selected
                        ? PollitColors.textPrimary
                        : PollitColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
                          '${percent.toStringAsFixed(0)}% (${option.voteCount})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: PollitColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
