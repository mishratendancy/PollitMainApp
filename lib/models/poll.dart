class Poll {
  final String id;
  final String community;
  final String title;
  final String? description;
  final int voteCount;
  final String creatorUid;
  final String? creatorName;
  final String? creatorPhotoURL;
  final int createdAt;
  final bool? optionLock;
  final int? timeLock;
  final int commentCount;

  Poll({
    required this.id,
    required this.community,
    required this.title,
    this.description,
    this.voteCount = 0,
    required this.creatorUid,
    this.creatorName,
    this.creatorPhotoURL,
    required this.createdAt,
    this.optionLock,
    this.timeLock,
    this.commentCount = 0,
  });

  factory Poll.fromMap(Map<String, dynamic> map, String id) {
    return Poll(
      id: id,
      community: map['community'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      voteCount: map['voteCount'] ?? 0,
      creatorUid: map['creatorUid'] ?? '',
      creatorName: map['creatorName'],
      creatorPhotoURL: map['creatorPhotoURL'],
      createdAt: map['createdAt'] ?? 0,
      optionLock: map['optionLock'],
      timeLock: map['timeLock'],
      commentCount: map['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'community': community,
      'title': title,
      'description': description,
      'voteCount': voteCount,
      'creatorUid': creatorUid,
      'creatorName': creatorName,
      'creatorPhotoURL': creatorPhotoURL,
      'createdAt': createdAt,
      'optionLock': optionLock,
      'timeLock': timeLock,
      'commentCount': commentCount,
    };
  }
}
