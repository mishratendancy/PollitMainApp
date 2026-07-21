import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/poll.dart';
import '../models/option.dart';
import '../models/poll_view_data.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../theme/pollit_theme.dart';
import '../pages/poll_detail_screen.dart';

class PollCard extends StatefulWidget {
  const PollCard({
    super.key,
    required this.pollData,
    required this.firestoreService,
    this.isDetailView = false,
    this.onCommentTap,
  });

  final PollViewData pollData;
  final FirestoreService firestoreService;
  final bool isDetailView;
  final VoidCallback? onCommentTap;

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _voteAnimController;
  bool _isVoting = false;
  bool _showAddOptionForm = false;
  bool _isSubmittingOption = false;
  final TextEditingController _addOptionController = TextEditingController();
  int? _commentCount;

  @override
  void initState() {
    super.initState();
    _voteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    if (widget.pollData.poll.commentCount > 0) {
      _commentCount = widget.pollData.poll.commentCount;
    } else {
      _fetchCommentCount();
    }
  }

  Future<void> _fetchCommentCount() async {
    try {
      final count = await widget.firestoreService.getCommentCount(
        widget.pollData.poll.community,
        widget.pollData.poll.id,
      );
      debugPrint('Fetched count: $count for poll ${widget.pollData.poll.id}');
      if (mounted && count > 0) {
        setState(() {
          _commentCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error fetching comment count: $e');
    }
  }

  @override
  void didUpdateWidget(PollCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pollData.poll.id != widget.pollData.poll.id) {
      _commentCount = null;
      if (widget.pollData.poll.commentCount > 0) {
        _commentCount = widget.pollData.poll.commentCount;
      } else {
        _fetchCommentCount();
      }
    }
  }

  void _showCustomSnackBar(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        backgroundColor: PollitColors.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: PollitColors.cardBorder, width: 1),
        ),
        margin: const EdgeInsets.only(bottom: 24, left: 40, right: 40),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAddOptionForm(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: PollitColors.cardBorder,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.only(left: 14, right: 14, top: 2, bottom: 2),
      child: Row(
        children: [
          const Icon(
            Icons.radio_button_unchecked,
            size: 18,
            color: PollitColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _addOptionController,
              autofocus: true,
              style: const TextStyle(color: PollitColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Add an option...',
                hintStyle: TextStyle(color: PollitColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _submitAddOption(),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _showAddOptionForm = false;
                _addOptionController.clear();
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.redAccent),
            ),
          ),
          GestureDetector(
            onTap: _isSubmittingOption ? null : _submitAddOption,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: PollitColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: _isSubmittingOption
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAddOption() async {
    final text = _addOptionController.text.trim();
    if (text.isEmpty || _isSubmittingOption) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;

    setState(() {
      _isSubmittingOption = true;
    });

    try {
      final newId = await widget.firestoreService.addOption(
        communitySlug: widget.pollData.poll.community,
        pollId: widget.pollData.poll.id,
        optionText: text,
        uid: auth.user!.uid,
        pollCreatorUid: widget.pollData.poll.creatorUid,
      );

      if (newId != null) {
        final newOption = PollOption(
          id: newId,
          text: text,
          voteCount: 0,
          addedByUid: auth.user!.uid,
        );

        if (mounted) {
          setState(() {
            widget.pollData.options.add(newOption);
            _showAddOptionForm = false;
            _isSubmittingOption = false;
          });
          _showCustomSnackBar('Option added successfully!');
        }
      }
    } catch (e) {
      debugPrint('Error adding option: $e');
      if (mounted) {
        setState(() {
          _isSubmittingOption = false;
        });
        _showCustomSnackBar('Failed to add option. Please try again.');
      }
    }
    _addOptionController.clear();
  }

  Future<void> _handleVote(String optionId) async {
    final hasVoted = widget.pollData.votedOptionId != null;
    if (hasVoted || _isVoting) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;

    final feedProvider = Provider.of<FeedProvider>(context, listen: false);

    setState(() {
      _isVoting = true;
    });

    feedProvider.recordOptimisticVote(widget.pollData.poll.id, optionId);
    _voteAnimController.forward();

    try {
      await widget.firestoreService.submitVote(
        communitySlug: widget.pollData.poll.community,
        pollId: widget.pollData.poll.id,
        optionId: optionId,
        uid: auth.user!.uid,
      );
      
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
        _showCustomSnackBar('Failed to vote. Please try again.');
      }
    }
  }

  void _navigateToDetail({bool scrollToComments = false}) {
    if (widget.isDetailView) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PollDetailScreen(pollData: widget.pollData, scrollToComments: scrollToComments),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.05);
          const end = Offset.zero;
          final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final slideAnimation = Tween<Offset>(begin: begin, end: end).animate(curve);
          final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  void dispose() {
    _voteAnimController.dispose();
    _addOptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    
    final votedOptionId = widget.pollData.votedOptionId;
    final hasVoted = votedOptionId != null;
    final poll = widget.pollData.poll;
    
    final bool canAddOption = user != null && 
        !hasVoted && 
        !(poll.optionLock ?? false) && 
        !widget.pollData.options.any((o) => o.addedByUid == user.uid);

    if (hasVoted && !_isVoting && _voteAnimController.value == 0.0) {
      _voteAnimController.value = 1.0;
    }
    
    final theme = Theme.of(context);
    final date = DateTime.fromMillisecondsSinceEpoch(poll.createdAt);
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

    var options = List<PollOption>.from(widget.pollData.options);
    options.sort((a, b) => a.text.compareTo(b.text));

    return GestureDetector(
      onTap: widget.isDetailView ? null : () => _navigateToDetail(scrollToComments: false),
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
                  poll.community.isNotEmpty ? poll.community[0].toUpperCase() : 'P',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'p/${poll.community}',
                style: const TextStyle(
                  color: PollitColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '· Posted by u/${poll.creatorName ?? 'Anonymous'} · $timeString',
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
            poll.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: PollitColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (poll.description != null && poll.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              poll.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: PollitColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          
          // Options List without StreamBuilder
          Column(
            children: options.map((o) {
              final isThisSelected = votedOptionId == o.id;
              final totalVotes = poll.voteCount;
              final percent = totalVotes == 0 
                ? 0.0 
                : (o.voteCount / totalVotes) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionTile(
                  option: o,
                  percent: percent,
                  selected: isThisSelected,
                  hasVoted: hasVoted,
                  isVoting: _isVoting,
                  onTap: hasVoted ? null : () => _handleVote(o.id),
                  animController: _voteAnimController,
                ),
              );
            }).toList(),
          ),
          
          // Add Option Button
          if (canAddOption)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _showAddOptionForm
                  ? _buildAddOptionForm(context)
                  : GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAddOptionForm = true;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: PollitColors.cardBorder.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, color: PollitColors.accent, size: 16),
                            const SizedBox(width: 6),
                            const Text(
                              'Add option',
                              style: TextStyle(
                                color: PollitColors.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          
          const SizedBox(height: 12),
          
          // Footer Action Bar
          Row(
            children: [
              _buildFooterButton(
                icon: Icons.arrow_upward_rounded, // Reddit-style upvote arrow for votes
                label: '${poll.voteCount}',
              ),
              const Spacer(),
              _buildFooterButton(
                icon: Icons.chat_bubble_outline,
                label: '${_commentCount ?? widget.pollData.poll.commentCount}',
                onTap: widget.isDetailView
                    ? widget.onCommentTap
                    : () => _navigateToDetail(scrollToComments: true),
              ),
              const SizedBox(width: 8),
              _buildFooterButton(
                icon: Icons.share_outlined,
                label: '',
                onTap: () {
                  _showCustomSnackBar('Share functionality coming soon!');
                }
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFooterButton({required IconData icon, required String label, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () {
        _showCustomSnackBar('Action not implemented yet!');
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: BoxDecoration(
          color: PollitColors.surfaceLight.withValues(alpha: 0.5), // Pill background
          borderRadius: BorderRadius.circular(20), // Pill shape
          border: Border.all(color: PollitColors.cardBorder, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: PollitColors.textPrimary),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: PollitColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
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
                        color: selected 
                            ? PollitColors.accent.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
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
                color: selected ? PollitColors.accent.withValues(alpha: 0.6) : PollitColors.cardBorder,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
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
                        ? PollitColors.accent
                        : PollitColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.bold : FontWeight.w600,
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
