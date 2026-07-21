import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poll.dart';
import '../models/option.dart';
import '../models/community.dart';
import '../models/comment.dart';
import '../models/poll_view_data.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Centralized helper to generate a consistent key for a poll vote
  static String buildVoteKey(String communitySlug, String pollId) => '${communitySlug}_$pollId';

  /// Fetch a stream of the latest polls across all communities (global feed)
  Stream<List<Poll>> getGlobalFeedStream({int limit = 20}) {
    // Note: To query across all subcollections 'polls', we use a collectionGroup query
    return _db
        .collectionGroup('polls')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Poll.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Future-based global feed fetching with options and vote status included
  Future<Map<String, dynamic>> getGlobalFeedWithData({
    required int limit,
    DocumentSnapshot? startAfter,
    String? uid,
  }) async {
    Query query = _db.collectionGroup('polls').orderBy('createdAt', descending: true).limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    final querySnapshot = await query.get();
    
    final polls = querySnapshot.docs.map((doc) => Poll.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
    
    final viewDataFutures = polls.map((poll) async {
      final optionsQuery = await _db
          .collection('communities')
          .doc(poll.community)
          .collection('polls')
          .doc(poll.id)
          .collection('options')
          .get();
          
      final options = optionsQuery.docs.map((doc) => PollOption.fromMap(doc.data(), doc.id)).toList();
      
      String? votedOptionId;
      if (uid != null) {
        final voteDoc = await _db
            .collection('communities')
            .doc(poll.community)
            .collection('polls')
            .doc(poll.id)
            .collection('votes')
            .doc(uid)
            .get();
            
        if (voteDoc.exists && voteDoc.data() != null) {
          votedOptionId = voteDoc.data()!['optionId'] as String?;
        }
      }
      
      return PollViewData(
        poll: poll,
        options: options,
        votedOptionId: votedOptionId,
      );
    });
    
    final viewDataList = await Future.wait(viewDataFutures);
    
    return {
      'viewDataList': viewDataList,
      'lastDocument': querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null,
    };
  }

  /// Helper to get a PollViewData for a single poll
  Future<PollViewData> getPollViewData(Poll poll, String? uid) async {
    final optionsQuery = await _db
        .collection('communities')
        .doc(poll.community)
        .collection('polls')
        .doc(poll.id)
        .collection('options')
        .get();
        
    final options = optionsQuery.docs.map((doc) => PollOption.fromMap(doc.data(), doc.id)).toList();
    
    String? votedOptionId;
    if (uid != null) {
      final voteDoc = await _db
          .collection('communities')
          .doc(poll.community)
          .collection('polls')
          .doc(poll.id)
          .collection('votes')
          .doc(uid)
          .get();
          
      if (voteDoc.exists && voteDoc.data() != null) {
        votedOptionId = voteDoc.data()!['optionId'] as String?;
      }
    }
    
    return PollViewData(
      poll: poll,
      options: options,
      votedOptionId: votedOptionId,
    );
  }

  /// Fetch a stream of polls created by a specific user
  Stream<List<Poll>> getUserPollsStream(String uid, {int limit = 20}) {
    return _db
        .collectionGroup('polls')
        .where('creatorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Poll.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Fetch options for a specific poll
  Stream<List<PollOption>> getPollOptionsStream(String communitySlug, String pollId) {
    return _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('options')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PollOption.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get total comments count using efficient aggregate query
  Future<int> getCommentCount(String communitySlug, String pollId) async {
    final snapshot = await _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('comments')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Check if the user has already voted on this poll, returns optionId if voted
  Future<String?> getUserVoteOptionId(String communitySlug, String pollId, String uid) async {
    final doc = await _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(uid)
        .get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['optionId'] as String?;
    }
    return null;
  }

  /// Stream all of the user's voted polls and their selected optionIds
  Stream<Map<String, String>> getUserVotedPollsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('votedPollRefs')
        .snapshots()
        .map((snapshot) {
      final map = <String, String>{};
      for (final doc in snapshot.docs) {
        if (doc.data().containsKey('optionId')) {
          map[doc.id] = doc.data()['optionId'] as String;
        } else {
          // Legacy vote (voted before the optionId update)
          map[doc.id] = 'LEGACY_UNKNOWN';
        }
      }
      return map;
    });
  }

  /// Submit a vote using a batch write to satisfy Firestore rules
  Future<void> submitVote({
    required String communitySlug,
    required String pollId,
    required String optionId,
    required String uid,
  }) async {
    final batch = _db.batch();

    // 1. Create the vote document
    final voteRef = _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(uid);
    
    batch.set(voteRef, {
      'optionId': optionId,
      'votedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // 2. Increment poll voteCount
    final pollRef = _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId);
    
    batch.update(pollRef, {'voteCount': FieldValue.increment(1)});

    // 3. Increment option voteCount
    final optionRef = _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('options')
        .doc(optionId);
    
    batch.update(optionRef, {'voteCount': FieldValue.increment(1)});

    // 4. Increment user's total voteCount
    final userRef = _db.collection('users').doc(uid);
    batch.update(userRef, {'voteCount': FieldValue.increment(1)});
    
    // 5. Add to user's votedPollRefs
    final votedPollRef = _db
        .collection('users')
        .doc(uid)
        .collection('votedPollRefs')
        .doc(buildVoteKey(communitySlug, pollId));
    batch.set(votedPollRef, {
      'optionId': optionId,
      'votedAt': DateTime.now().millisecondsSinceEpoch,
    });

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Error submitting vote: $e');
      rethrow;
    }
  }

  /// Create a new poll along with its options
  Future<void> createPoll({
    required String communitySlug,
    required String title,
    String? description,
    required List<String> options,
    required String uid,
    String? creatorName,
    String? creatorPhotoURL,
  }) async {
    final batch = _db.batch();

    // 1. Ensure community exists
    final communityRef = _db.collection('communities').doc(communitySlug);
    // Note: If community exists, set with merge: true to avoid overwriting follower counts.
    // If it doesn't exist, this creates it.
    batch.set(communityRef, {
      'slug': communitySlug,
      'displayName': communitySlug, // Simplistic, could be better
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Create the Poll document
    final pollRef = communityRef.collection('polls').doc();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    batch.set(pollRef, {
      'community': communitySlug,
      'title': title,
      'description': description,
      'voteCount': 0,
      'creatorUid': uid,
      'creatorName': creatorName,
      'creatorPhotoURL': creatorPhotoURL,
      'createdAt': now,
    });

    // 3. Create the Option documents
    for (final optionText in options) {
      if (optionText.trim().isEmpty) continue;
      final optionRef = pollRef.collection('options').doc();
      batch.set(optionRef, {
        'text': optionText.trim(),
        'voteCount': 0,
        'creatorUid': uid,
      });
    }

    // 4. Increment user's pollsCreated count
    final userRef = _db.collection('users').doc(uid);
    batch.update(userRef, {
      'pollsCreated': FieldValue.increment(1),
    });

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('Error creating poll: $e');
      rethrow;
    }
  }

  /// Add a new option to an existing poll
  Future<String?> addOption({
    required String communitySlug,
    required String pollId,
    required String optionText,
    required String uid,
    String? pollCreatorUid,
  }) async {
    if (optionText.trim().isEmpty) return null;
    
    final batch = _db.batch();
    final optionRef = _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('options')
        .doc();
        
    batch.set(optionRef, {
      'text': optionText.trim(),
      'voteCount': 0,
      'creatorUid': pollCreatorUid ?? uid,
      'addedByUid': uid,
    });
    
    await batch.commit();
    return optionRef.id;
  }

  /// Get a single poll stream
  Stream<Poll> getPollStream(String communitySlug, String pollId) {
    return _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .snapshots()
        .map((doc) => Poll.fromMap(doc.data() as Map<String, dynamic>, doc.id));
  }

  /// Get comments for a poll
  Stream<List<PollComment>> getPollCommentsStream(String communitySlug, String pollId) {
    return _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PollComment.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Add a comment
  Future<void> addComment({
    required String communitySlug,
    required String pollId,
    required String uid,
    required String text,
    String? parentId,
  }) async {
    final batch = _db.batch();

    final commentRef = _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('comments')
        .doc();

    final userDoc = await _db.collection('users').doc(uid).get();
    final authorName = userDoc.data()?['displayName'] ?? 'Anonymous';
    final authorPhotoURL = userDoc.data()?['photoURL'];

    batch.set(commentRef, {
      'text': text,
      'authorUid': uid,
      'authorName': authorName,
      'authorPhotoURL': authorPhotoURL,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'score': 0,
      'upvoteCount': 0,
      'downvoteCount': 0,
      if (parentId != null) 'parentId': parentId,
    });

    // We no longer update a comment count in a subcollection, and we cannot update a 'commentCount' 
    // field on the Poll itself because Firestore security rules only allow 'voteCount' updates.
    // We fetch comment counts dynamically using count() aggregations instead.
    
    await batch.commit();
  }

  /// Submit comment vote
  Future<int> getCommentVote(String communitySlug, String pollId, String commentId, String uid) async {
    final doc = await _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('comments')
        .doc(commentId)
        .collection('votes')
        .doc(uid)
        .get();
    
    if (doc.exists && doc.data() != null) {
      return doc.data()!['direction'] as int? ?? 0;
    }
    return 0;
  }

  /// Submit comment vote
  Future<void> submitCommentVote({
    required String communitySlug,
    required String pollId,
    required String commentId,
    required String uid,
    required int direction,
    required int previousDirection,
  }) async {
    final batch = _db.batch();

    final voteRef = _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('comments')
        .doc(commentId)
        .collection('votes')
        .doc(uid);

    final commentRef = _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('comments')
        .doc(commentId);

    if (direction == 0) {
      // Remove vote
      batch.delete(voteRef);
    } else {
      // Set vote
      batch.set(voteRef, {
        'direction': direction,
        'votedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }

    // Update score
    int upDiff = 0;
    int downDiff = 0;

    if (previousDirection == 1) upDiff -= 1;
    if (previousDirection == -1) downDiff -= 1;

    if (direction == 1) upDiff += 1;
    if (direction == -1) downDiff += 1;

    batch.update(commentRef, {
      'upvoteCount': FieldValue.increment(upDiff),
      'downvoteCount': FieldValue.increment(downDiff),
      'score': FieldValue.increment(upDiff - downDiff),
    });

    await batch.commit();
  }
}
