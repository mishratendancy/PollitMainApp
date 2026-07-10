class Vote {
  final String optionId;
  final String? addedOptionId;
  final int votedAt;

  Vote({
    required this.optionId,
    this.addedOptionId,
    required this.votedAt,
  });

  factory Vote.fromMap(Map<String, dynamic> map) {
    return Vote(
      optionId: map['optionId'] ?? '',
      addedOptionId: map['addedOptionId'],
      votedAt: map['votedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'optionId': optionId,
      'addedOptionId': addedOptionId,
      'votedAt': votedAt,
    };
  }
}
