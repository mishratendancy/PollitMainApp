import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/poll.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

class FeedProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Poll> _polls = [];
  bool _isLoading = true;
  String? _error;
  
  // Vote State Management
  Map<String, String> _votedOptions = {};
  StreamSubscription<Map<String, String>>? _votedPollsSubscription;
  String? _currentUid;

  List<Poll> get polls => _polls;
  bool get isLoading => _isLoading;
  String? get error => _error;

  FeedProvider() {
    _initGlobalFeed();
  }

  void _initGlobalFeed() {
    _isLoading = true;
    notifyListeners();

    _firestoreService.getGlobalFeedStream().listen(
      (pollList) {
        _polls = pollList;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void updateAuth(AuthProvider auth) {
    final newUid = auth.user?.uid;
    if (_currentUid != newUid) {
      _currentUid = newUid;
      _votedPollsSubscription?.cancel();
      _votedPollsSubscription = null;

      if (_currentUid == null) {
        // User logged out
        _votedOptions = {};
        notifyListeners();
      } else {
        // User logged in
        _votedPollsSubscription = _firestoreService.getUserVotedPollsStream(_currentUid!).listen((newVotedOptions) {
          if (!mapEquals(_votedOptions, newVotedOptions)) {
            // Use immutable update
            _votedOptions = Map.unmodifiable(newVotedOptions);
            notifyListeners();
          }
        });
      }
    }
  }

  /// Get the option ID the user voted for on a specific poll, if any
  String? getVotedOptionId(String communitySlug, String pollId) {
    final key = FirestoreService.buildVoteKey(communitySlug, pollId);
    return _votedOptions[key];
  }

  /// Optimistically update the UI while the vote saves to Firestore
  void recordOptimisticVote(String communitySlug, String pollId, String optionId) {
    final key = FirestoreService.buildVoteKey(communitySlug, pollId);
    final updatedMap = Map<String, String>.from(_votedOptions);
    updatedMap[key] = optionId;
    _votedOptions = Map.unmodifiable(updatedMap);
    notifyListeners();
  }

  @override
  void dispose() {
    _votedPollsSubscription?.cancel();
    super.dispose();
  }
}
