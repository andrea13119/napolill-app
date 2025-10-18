class ListenLog {
  final String entryId;
  final String entryTitle;
  final String category;
  final String level;
  final String mode; // 'meditation' or 'endless'
  final DateTime startedAt;
  final DateTime endedAt;
  final int minutes;
  final int seconds;

  ListenLog({
    required this.entryId,
    required this.entryTitle,
    required this.category,
    required this.level,
    required this.mode,
    required this.startedAt,
    required this.endedAt,
    required this.minutes,
    required this.seconds,
  });

  ListenLog copyWith({
    String? entryId,
    String? entryTitle,
    String? category,
    String? level,
    String? mode,
    DateTime? startedAt,
    DateTime? endedAt,
    int? minutes,
    int? seconds,
  }) {
    return ListenLog(
      entryId: entryId ?? this.entryId,
      entryTitle: entryTitle ?? this.entryTitle,
      category: category ?? this.category,
      level: level ?? this.level,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      minutes: minutes ?? this.minutes,
      seconds: seconds ?? this.seconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'entryTitle': entryTitle,
      'category': category,
      'level': level,
      'mode': mode,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'minutes': minutes,
      'seconds': seconds,
    };
  }

  factory ListenLog.fromJson(Map<String, dynamic> json) {
    return ListenLog(
      entryId: json['entryId'],
      entryTitle: json['entryTitle'] ?? '',
      category: json['category'] ?? '',
      level: json['level'] ?? '',
      mode: json['mode'] ?? 'meditation',
      startedAt: DateTime.parse(json['startedAt']),
      endedAt: DateTime.parse(json['endedAt']),
      minutes: json['minutes'],
      seconds: json['seconds'] ?? 0,
    );
  }

  // Helper methods
  Duration get duration => Duration(minutes: minutes, seconds: seconds);

  bool isOnDate(DateTime date) {
    return startedAt.year == date.year &&
        startedAt.month == date.month &&
        startedAt.day == date.day;
  }

  bool isInDateRange(DateTime startDate, DateTime endDate) {
    return startedAt.isAfter(startDate.subtract(Duration(days: 1))) &&
        startedAt.isBefore(endDate.add(Duration(days: 1)));
  }
}
