import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/poll.dart';
import '../models/option.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../theme/pollit_theme.dart';

class PollCard extends StatefulWidget {
  const PollCard({
    super.key,
    required this.poll,
    required this.firestoreService,
  });

  final Poll poll;
  final FirestoreService firestoreService;

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _voteAnimController;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    _voteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  Future<void> _handleVote(String optionId) async {
    final feedProvider = Provider.of<FeedProvider>(context, listen: false);
    final hasVoted = feedProvider.getVotedOptionId(widget.poll.community, widget.poll.id) != null;
    if (hasVoted || _isVoting) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user == null) return;

    setState(() {
      _isVoting = true;
    });

    feedProvider.recordOptimisticVote(widget.poll.community, widget.poll.id, optionId);
    _voteAnimController.forward();

    try {
      await widget.firestoreService.submitVote(
        communitySlug: widget.poll.community,
        pollId: widget.poll.id,
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
    final feedProvider = Provider.of<FeedProvider>(context);
    final votedOptionId = feedProvider.getVotedOptionId(widget.poll.community, widget.poll.id);
    final hasVoted = votedOptionId != null;

    if (hasVoted && !_isVoting && _voteAnimController.value == 0.0) {
      _voteAnimController.value = 1.0;
    }
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
                  final isThisSelected = votedOptionId == o.id;
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
                      hasVoted: hasVoted,
                      isVoting: _isVoting,
                      onTap: hasVoted ? null : () => _handleVote(o.id),
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
                color: PollitColors.cardBorder,
                width: 1,
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
