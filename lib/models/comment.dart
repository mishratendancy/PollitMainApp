class PollComment {
  final String id;
  final String community;
  final String pollId;
  final String text;
  final String authorUid;
  final String? authorName;
  final String? authorPhotoURL;
  final int createdAt;
  final int score;
  final int upvoteCount;
  final int downvoteCount;
  final String? parentId;

  PollComment({
    required this.id,
    required this.community,
    required this.pollId,
    required this.text,
    required this.authorUid,
    this.authorName,
    this.authorPhotoURL,
    required this.createdAt,
    this.score = 0,
    this.upvoteCount = 0,
    this.downvoteCount = 0,
    this.parentId,
  });

  factory PollComment.fromMap(Map<String, dynamic> map, String id) {
    return PollComment(
      id: id,
      community: map['community'] ?? '',
      pollId: map['pollId'] ?? '',
      text: map['text'] ?? '',
      authorUid: map['authorUid'] ?? '',
      authorName: map['authorName'],
      authorPhotoURL: map['authorPhotoURL'],
      createdAt: map['createdAt'] ?? 0,
      score: map['score'] ?? 0,
      upvoteCount: map['upvoteCount'] ?? 0,
      downvoteCount: map['downvoteCount'] ?? 0,
      parentId: map['parentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'community': community,
      'pollId': pollId,
      'text': text,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoURL': authorPhotoURL,
      'createdAt': createdAt,
      'score': score,
      'upvoteCount': upvoteCount,
      'downvoteCount': downvoteCount,
      'parentId': parentId,
    };
  }
}

class CommentVote {
  final int direction; // 1 or -1
  final int votedAt;

  CommentVote({
    required this.direction,
    required this.votedAt,
  });

  factory CommentVote.fromMap(Map<String, dynamic> map) {
    return CommentVote(
      direction: map['direction'] ?? 0,
      votedAt: map['votedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'direction': direction,
      'votedAt': votedAt,
    };
  }
}
