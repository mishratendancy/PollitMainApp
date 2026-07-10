import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poll.dart';
import '../models/option.dart';
import '../models/community.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  /// Check if the user has already voted on this poll
  Future<bool> hasUserVoted(String communitySlug, String pollId, String uid) async {
    final doc = await _db
        .collection('communities')
        .doc(communitySlug)
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(uid)
        .get();
    return doc.exists;
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
        .doc('${communitySlug}_$pollId');
    batch.set(votedPollRef, {
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
}
