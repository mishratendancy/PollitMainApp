import 'poll.dart';
import 'option.dart';

class PollViewData {
  final Poll poll;
  final List<PollOption> options;
  final String? votedOptionId;

  PollViewData({
    required this.poll,
    required this.options,
    this.votedOptionId,
  });

  PollViewData copyWith({
    Poll? poll,
    List<PollOption>? options,
    String? votedOptionId,
  }) {
    return PollViewData(
      poll: poll ?? this.poll,
      options: options ?? this.options,
      votedOptionId: votedOptionId ?? this.votedOptionId,
    );
  }
}
