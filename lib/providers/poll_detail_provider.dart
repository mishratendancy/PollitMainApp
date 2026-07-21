import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/poll_view_data.dart';
import '../models/comment.dart';
import '../services/firestore_service.dart';

class PollDetailProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final String communitySlug;
  final String pollId;
  final String? currentUid;

  PollViewData? _pollData;
  List<PollComment> _comments = [];
  Map<String, int> _commentVoteStatus = {}; // 1 for upvote, -1 for downvote
  
  bool _isLoading = true;
  String? _error;
  
  StreamSubscription? _commentsSubscription;
  StreamSubscription? _optionsSubscription;
  StreamSubscription? _pollSubscription;

  PollViewData? get pollData => _pollData;
  List<PollComment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PollDetailProvider({
    required this.communitySlug,
    required this.pollId,
    required this.currentUid,
    PollViewData? initialData,
  }) {
    if (initialData != null) {
      _pollData = initialData;
      _isLoading = false;
    }
    _init();
  }

  void _init() {
    // 1. Subscribe to Comments (Real-time)
    _commentsSubscription = _firestoreService.getPollCommentsStream(communitySlug, pollId).listen(
      (newComments) {
        _comments = newComments;
        _fetchCommentVotes(newComments);
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );

    // 2. Subscribe to Poll and Options for real-time vote updates on this specific screen
    _pollSubscription = _firestoreService.getPollStream(communitySlug, pollId).listen((pollData) {
      if (_pollData != null) {
        _pollData = _pollData!.copyWith(poll: pollData);
        notifyListeners();
      }
    });

    _optionsSubscription = _firestoreService.getPollOptionsStream(communitySlug, pollId).listen((options) {
      if (_pollData != null) {
        _pollData = _pollData!.copyWith(options: options);
        notifyListeners();
      }
    });
  }

  int getCommentVote(String commentId) {
    return _commentVoteStatus[commentId] ?? 0;
  }

  void _fetchCommentVotes(List<PollComment> comments) {
    if (currentUid == null) return;
    for (var comment in comments) {
      if (!_commentVoteStatus.containsKey(comment.id)) {
        // Optimistically set to 0 while loading so we don't fetch repeatedly
        _commentVoteStatus[comment.id] = 0;
        _firestoreService.getCommentVote(communitySlug, pollId, comment.id, currentUid!).then((vote) {
          if (vote != 0) {
            _commentVoteStatus[comment.id] = vote;
            notifyListeners();
          }
        });
      }
    }
  }

  void handleCommentVote(String commentId, int direction) {
    if (currentUid == null) return;
    
    final currentVote = getCommentVote(commentId);
    
    // Toggle off if same direction clicked again
    final newVote = currentVote == direction ? 0 : direction;
    
    _commentVoteStatus[commentId] = newVote;
    notifyListeners();
    
    _firestoreService.submitCommentVote(
      communitySlug: communitySlug,
      pollId: pollId,
      commentId: commentId,
      uid: currentUid!,
      direction: newVote,
      previousDirection: currentVote,
    );
  }
  
  Future<void> postComment(String text, {String? parentId}) async {
    if (currentUid == null || text.trim().isEmpty) return;
    
    await _firestoreService.addComment(
      communitySlug: communitySlug,
      pollId: pollId,
      uid: currentUid!,
      text: text.trim(),
      parentId: parentId,
    );
  }

  @override
  void dispose() {
    _commentsSubscription?.cancel();
    _optionsSubscription?.cancel();
    _pollSubscription?.cancel();
    super.dispose();
  }
}
