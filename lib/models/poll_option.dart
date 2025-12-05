// lib/models/poll_option.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PollOption {
  final String id;
  final String text;
  final int votes;
  final List<String> votedBy; // List of user IDs

  const PollOption({
    required this.id,
    required this.text,
    this.votes = 0,
    this.votedBy = const [],
  });

  factory PollOption.fromMap(Map<String, dynamic> map, String id) {
    return PollOption(
      id: id,
      text: map['text'] as String? ?? '',
      votes: map['votes'] as int? ?? 0,
      votedBy: List<String>.from(map['votedBy'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'votes': votes,
      'votedBy': votedBy,
    };
  }

  PollOption copyWith({
    String? id,
    String? text,
    int? votes,
    List<String>? votedBy,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      votes: votes ?? this.votes,
      votedBy: votedBy ?? this.votedBy,
    );
  }

  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0;
    return (votes / totalVotes) * 100;
  }
}

// Extend CommunityPost to support polls
class PollData {
  final List<PollOption> options;
  final DateTime endTime;
  final int totalVotes;
  final bool allowMultipleVotes;

  const PollData({
    required this.options,
    required this.endTime,
    this.totalVotes = 0,
    this.allowMultipleVotes = false,
  });

  factory PollData.fromMap(Map<String, dynamic> map) {
    final optionsMap = map['options'] as Map<String, dynamic>? ?? {};
    final options = optionsMap.entries.map((entry) {
      return PollOption.fromMap(entry.value as Map<String, dynamic>, entry.key);
    }).toList();

    return PollData(
      options: options,
      endTime: (map['endTime'] as Timestamp).toDate(),
      totalVotes: map['totalVotes'] as int? ?? 0,
      allowMultipleVotes: map['allowMultipleVotes'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'options': {for (var option in options) option.id: option.toMap()},
      'endTime': Timestamp.fromDate(endTime),
      'totalVotes': totalVotes,
      'allowMultipleVotes': allowMultipleVotes,
    };
  }

  bool get isEnded => DateTime.now().isAfter(endTime);

  bool hasUserVoted(String userId) {
    return options.any((option) => option.votedBy.contains(userId));
  }

  PollOption? getUserVote(String userId) {
    return options.firstWhere(
      (option) => option.votedBy.contains(userId),
      orElse: () => options.first,
    );
  }
}
