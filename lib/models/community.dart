class Community {
  final String slug;
  final String displayName;
  final String? description;
  final String creatorUid;
  final int createdAt;
  final int followerCount;
  final int memberCount;

  Community({
    required this.slug,
    required this.displayName,
    this.description,
    required this.creatorUid,
    required this.createdAt,
    this.followerCount = 0,
    this.memberCount = 0,
  });

  factory Community.fromMap(Map<String, dynamic> map) {
    return Community(
      slug: map['slug'] ?? '',
      displayName: map['displayName'] ?? '',
      description: map['description'],
      creatorUid: map['creatorUid'] ?? '',
      createdAt: map['createdAt'] ?? 0,
      followerCount: map['followerCount'] ?? 0,
      memberCount: map['memberCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'slug': slug,
      'displayName': displayName,
      'description': description,
      'creatorUid': creatorUid,
      'createdAt': createdAt,
      'followerCount': followerCount,
      'memberCount': memberCount,
    };
  }
}
