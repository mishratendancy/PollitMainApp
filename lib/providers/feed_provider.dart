import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/poll.dart';
import '../models/option.dart';
import '../models/poll_view_data.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

class FeedProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<PollViewData> _feedData = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  DocumentSnapshot? _lastDocument;
  
  String? _currentUid;

  List<PollViewData> get feedData => _feedData;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  FeedProvider() {
    // Initial fetch handled after auth is updated
  }

  void updateAuth(AuthProvider auth) {
    final newUid = auth.user?.uid;
    if (_currentUid != newUid) {
      _currentUid = newUid;
      refreshFeed(); // Refresh feed completely when user changes to update vote statuses
    }
  }

  Future<void> refreshFeed() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _firestoreService.getGlobalFeedWithData(
        limit: 10,
        uid: _currentUid,
      );
      
      _feedData = result['viewDataList'] as List<PollViewData>;
      _lastDocument = result['lastDocument'] as DocumentSnapshot?;
      _hasMore = _feedData.length == 10; // Simple check, if we got limit, there might be more
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _firestoreService.getGlobalFeedWithData(
        limit: 10,
        startAfter: _lastDocument,
        uid: _currentUid,
      );
      
      final moreData = result['viewDataList'] as List<PollViewData>;
      if (moreData.isEmpty) {
        _hasMore = false;
      } else {
        _feedData.addAll(moreData);
        _lastDocument = result['lastDocument'] as DocumentSnapshot?;
        _hasMore = moreData.length == 10;
      }
    } catch (e) {
      // Just print error for loadMore to not disrupt the existing feed
      debugPrint('Error loading more feed: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Optimistically update the UI while the vote saves to Firestore
  void recordOptimisticVote(String pollId, String optionId) {
    final index = _feedData.indexWhere((data) => data.poll.id == pollId);
    if (index != -1) {
      final currentData = _feedData[index];
      
      // Prevent duplicate votes visually
      if (currentData.votedOptionId != null) return;

      // Update the option count
      final updatedOptions = currentData.options.map((opt) {
        if (opt.id == optionId) {
          return PollOption(
            id: opt.id,
            text: opt.text,
            voteCount: opt.voteCount + 1,
            addedByUid: opt.addedByUid,
          );
        }
        return opt;
      }).toList();
      
      // Update the poll vote count
      final updatedPoll = Poll(
        id: currentData.poll.id,
        community: currentData.poll.community,
        title: currentData.poll.title,
        description: currentData.poll.description,
        voteCount: currentData.poll.voteCount + 1,
        creatorUid: currentData.poll.creatorUid,
        creatorName: currentData.poll.creatorName,
        creatorPhotoURL: currentData.poll.creatorPhotoURL,
        createdAt: currentData.poll.createdAt,
        optionLock: currentData.poll.optionLock,
        timeLock: currentData.poll.timeLock,
      );

      _feedData[index] = currentData.copyWith(
        poll: updatedPoll,
        options: updatedOptions,
        votedOptionId: optionId,
      );
      
      notifyListeners();
    }
  }
}
