class UserModel {
  final String uid;
  final String? displayName;
  final String? photoURL;
  final String? email;
  final String? username;
  final bool? profileSetupCompleted;
  final int inkmarks;
  final int pollsCreated;
  final int communitiesCreated;
  final int followingCount;
  final int voteCount;
  final int createdAt;

  UserModel({
    required this.uid,
    this.displayName,
    this.photoURL,
    this.email,
    this.username,
    this.profileSetupCompleted,
    this.inkmarks = 0,
    this.pollsCreated = 0,
    this.communitiesCreated = 0,
    this.followingCount = 0,
    this.voteCount = 0,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      email: map['email'],
      username: map['username'],
      profileSetupCompleted: map['profileSetupCompleted'],
      inkmarks: map['inkmarks'] ?? 0,
      pollsCreated: map['pollsCreated'] ?? 0,
      communitiesCreated: map['communitiesCreated'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      voteCount: map['voteCount'] ?? 0,
      createdAt: map['createdAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoURL': photoURL,
      'email': email,
      'username': username,
      'profileSetupCompleted': profileSetupCompleted,
      'inkmarks': inkmarks,
      'pollsCreated': pollsCreated,
      'communitiesCreated': communitiesCreated,
      'followingCount': followingCount,
      'voteCount': voteCount,
      'createdAt': createdAt,
    };
  }
}
