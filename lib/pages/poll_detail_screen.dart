import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/poll_view_data.dart';
import '../models/comment.dart';
import '../providers/auth_provider.dart';
import '../providers/poll_detail_provider.dart';
import '../services/firestore_service.dart';
import '../theme/pollit_theme.dart';
import '../widgets/poll_card.dart';

class PollDetailScreen extends StatelessWidget {
  const PollDetailScreen({
    super.key,
    required this.pollData,
    this.scrollToComments = false,
  });

  final PollViewData pollData;
  final bool scrollToComments;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return ChangeNotifierProvider(
      create: (_) => PollDetailProvider(
        communitySlug: pollData.poll.community,
        pollId: pollId,
        currentUid: authProvider.user?.uid,
        initialData: pollData,
      ),
      child: _PollDetailScreenBody(scrollToComments: scrollToComments),
    );
  }

  String get pollId => pollData.poll.id;
}

class _PollDetailScreenBody extends StatefulWidget {
  const _PollDetailScreenBody({this.scrollToComments = false});

  final bool scrollToComments;

  @override
  State<_PollDetailScreenBody> createState() => _PollDetailScreenBodyState();
}

class _PollDetailScreenBodyState extends State<_PollDetailScreenBody> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsHeaderKey = GlobalKey();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String? _replyingToCommentId;
  String? _replyingToAuthorName;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routeAnimation = ModalRoute.of(context)?.animation;
      if (routeAnimation != null) {
        if (routeAnimation.isCompleted) {
          if (widget.scrollToComments) _scheduleScrollToComments();
        } else {
          void listener(AnimationStatus status) {
            if (status == AnimationStatus.completed) {
              routeAnimation.removeStatusListener(listener);
              if (widget.scrollToComments) _scheduleScrollToComments();
            }
          }
          routeAnimation.addStatusListener(listener);
        }
      } else if (widget.scrollToComments) {
        _scheduleScrollToComments();
      }
    });

    // Removed auto-scroll on focus to match standard app UX
    // (letting the list naturally resize when keyboard appears)
  }

  void _scheduleScrollToComments({int attempt = 0, double alignment = 0.0}) {
    if (!mounted) return;
    if (_commentsHeaderKey.currentContext != null) {
      Scrollable.ensureVisible(
        _commentsHeaderKey.currentContext!,
        alignment: alignment,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else if (attempt < 5) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _scheduleScrollToComments(attempt: attempt + 1, alignment: alignment);
      });
    }
  }

  void _submitComment() async {
    if (_isSubmittingComment) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final provider = Provider.of<PollDetailProvider>(context, listen: false);
      await provider.postComment(_commentController.text, parentId: _replyingToCommentId);
      _commentController.clear();
      if (mounted) {
        setState(() {
          _replyingToCommentId = null;
          _replyingToAuthorName = null;
        });
        _commentFocusNode.unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  void _setReplyTarget(String commentId, String authorName) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToAuthorName = authorName;
    });
    _commentFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PollDetailProvider>(context);
    final theme = Theme.of(context);

    // Group comments by parentId
    final rootComments = provider.comments.where((c) => c.parentId == null).toList();
    final repliesMap = <String, List<PollComment>>{};
    for (final comment in provider.comments) {
      if (comment.parentId != null) {
        repliesMap.putIfAbsent(comment.parentId!, () => []).add(comment);
      }
    }

    return Scaffold(
      backgroundColor: PollitColors.background,
      appBar: AppBar(
        backgroundColor: PollitColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: PollitColors.textPrimary),
        title: const Text('Post', style: TextStyle(color: PollitColors.textPrimary)),
      ),
      body: RepaintBoundary(
        child: Column(
          children: [
          // 1. Scrollable List Body
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.only(
                  bottom: 100, // Reduced padding, rely on Scaffold's resizeToAvoidBottomInset
                ),
                children: [
                  if (provider.pollData != null)
                    PollCard(
                      pollData: provider.pollData!,
                      firestoreService: FirestoreService(),
                      isDetailView: true,
                      onCommentTap: () {
                        _scheduleScrollToComments();
                        if (!_commentFocusNode.hasFocus) {
                          _commentFocusNode.requestFocus();
                        }
                      },
                    ),
                const Divider(color: PollitColors.cardBorder, thickness: 1),
                
                // Comments Section
                Padding(
                  key: _commentsHeaderKey,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Comments',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: PollitColors.textPrimary,
                    ),
                  ),
                ),
                
                if (rootComments.isEmpty && !provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No comments yet. Be the first to share your thoughts!',
                        style: TextStyle(color: PollitColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                ...rootComments.map((comment) {
                  return CommentThreadWidget(
                    comment: comment,
                    repliesMap: repliesMap,
                    provider: provider,
                    onReply: (id, name) => _setReplyTarget(id, name),
                    depth: 0,
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
          
          // 2. Fixed Comment Input Bar with zero-lag SafeArea
          SafeArea(
            top: false,
            maintainBottomViewPadding: true, // Prevents a jerky jump at the very end of keyboard dismiss
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: PollitColors.surface,
                border: Border(top: BorderSide(color: PollitColors.cardBorder, width: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_replyingToAuthorName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Text(
                            'Replying to $_replyingToAuthorName',
                            style: const TextStyle(color: PollitColors.accent, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _replyingToCommentId = null;
                                _replyingToAuthorName = null;
                              });
                            },
                            child: const Icon(Icons.close, size: 16, color: PollitColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    style: const TextStyle(color: PollitColors.textPrimary, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: PollitColors.textMuted, fontSize: 15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: PollitColors.cardBorder, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: PollitColors.cardBorder, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: PollitColors.accent, width: 1),
                      ),
                      filled: true,
                      fillColor: PollitColors.surfaceLight.withValues(alpha: 0.3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _commentController,
                        builder: (context, value, child) {
                          final hasText = value.text.trim().isNotEmpty;
                          return GestureDetector(
                            onTap: hasText && !_isSubmittingComment ? _submitComment : null,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _isSubmittingComment
                                  ? const Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: PollitColors.accent),
                                      ),
                                    )
                                  : Icon(
                                      Icons.send_rounded,
                                      color: hasText && !_isSubmittingComment ? PollitColors.accent : PollitColors.textMuted,
                                      size: 24,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    maxLines: 4,
                    minLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class CommentThreadWidget extends StatelessWidget {
  const CommentThreadWidget({
    super.key,
    required this.comment,
    required this.repliesMap,
    required this.provider,
    required this.onReply,
    required this.depth,
    this.isLastChild = true,
  });

  final PollComment comment;
  final Map<String, List<PollComment>> repliesMap;
  final PollDetailProvider provider;
  final Function(String, String) onReply;
  final int depth;
  final bool isLastChild;

  @override
  Widget build(BuildContext context) {
    final replies = repliesMap[comment.id] ?? [];
    
    // Convert time
    final date = DateTime.fromMillisecondsSinceEpoch(comment.createdAt);
    final diff = DateTime.now().difference(date);
    String timeString;
    if (diff.inDays > 0) timeString = '${diff.inDays}d ago';
    else if (diff.inHours > 0) timeString = '${diff.inHours}h ago';
    else if (diff.inMinutes > 0) timeString = '${diff.inMinutes}m ago';
    else timeString = 'now';

    final voteStatus = provider.getCommentVote(comment.id); // 1, -1, or 0

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thread Line & Avatar Column
          SizedBox(
            width: 44, // 16 padding left + 28 avatar width
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: PollitColors.accent.withValues(alpha: 0.2),
                    backgroundImage: comment.authorPhotoURL != null ? NetworkImage(comment.authorPhotoURL!) : null,
                    child: comment.authorPhotoURL == null
                        ? Text(
                            comment.authorName?.isNotEmpty == true ? comment.authorName![0].toUpperCase() : 'A',
                            style: const TextStyle(fontSize: 12, color: PollitColors.accent),
                          )
                        : null,
                  ),
                ),
                if (replies.isNotEmpty)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: 8), 
                      color: PollitColors.cardBorder,
                    ),
                  ),
              ],
            ),
          ),
          
          // Content Column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 8, 
                right: depth == 0 ? 16.0 : 0.0, 
                bottom: 8
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author & Time
                  Row(
                    children: [
                      Text(
                        comment.authorName ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: PollitColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeString,
                        style: const TextStyle(
                          color: PollitColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Body
                  Text(
                    comment.text,
                    style: const TextStyle(
                      color: PollitColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Actions (Upvote, Downvote, Reply)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Upvote Pill
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          provider.handleCommentVote(comment.id, 1);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: voteStatus == 1 ? PollitColors.accent.withValues(alpha: 0.15) : PollitColors.surfaceLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: voteStatus == 1 ? PollitColors.accent : PollitColors.cardBorder, width: 0.5),
                          ),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color: voteStatus == 1 ? PollitColors.accent : PollitColors.textMuted,
                          ),
                        ),
                      ),
                      // Score
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${comment.score}',
                          style: TextStyle(
                            color: voteStatus == 1 
                                ? PollitColors.accent 
                                : voteStatus == -1 
                                    ? PollitColors.error 
                                    : PollitColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Downvote Pill
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          provider.handleCommentVote(comment.id, -1);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: voteStatus == -1 ? PollitColors.error.withValues(alpha: 0.15) : PollitColors.surfaceLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: voteStatus == -1 ? PollitColors.error : PollitColors.cardBorder, width: 0.5),
                          ),
                          child: Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color: voteStatus == -1 ? PollitColors.error : PollitColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Reply Pill
                      GestureDetector(
                        onTap: () => onReply(comment.id, comment.authorName ?? 'Anonymous'),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: PollitColors.surfaceLight.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: PollitColors.cardBorder, width: 0.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.reply_rounded, size: 16, color: PollitColors.textMuted),
                              SizedBox(width: 6),
                              Text(
                                'Reply',
                                style: TextStyle(
                                  color: PollitColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Render Replies
                  if (replies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        children: List.generate(replies.length, (index) {
                          return CommentThreadWidget(
                            comment: replies[index],
                            repliesMap: repliesMap,
                            provider: provider,
                            onReply: onReply,
                            depth: depth + 1,
                            isLastChild: index == replies.length - 1,
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
