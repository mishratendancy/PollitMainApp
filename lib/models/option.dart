class PollOption {
  final String id;
  final String text;
  final int voteCount;
  final String? addedByUid;

  PollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
    this.addedByUid,
  });

  factory PollOption.fromMap(Map<String, dynamic> map, String id) {
    return PollOption(
      id: id,
      text: map['text'] ?? '',
      voteCount: map['voteCount'] ?? 0,
      addedByUid: map['addedByUid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'voteCount': voteCount,
      'addedByUid': addedByUid,
    };
  }
}
