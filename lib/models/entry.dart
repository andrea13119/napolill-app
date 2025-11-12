import '../utils/constants.dart';

class Entry {
  final String id;
  final String title;
  final String category; // selbstbewusstsein|selbstwert|aengste|custom
  final String level; // beginner|advanced|open
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> takes; // Dateipfade zu M4A pro Satz
  final String? bgLoopPath; // 1h-Solfeggio
  final String? modeDefault; // meditation|endless

  Entry({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
    required this.takes,
    this.bgLoopPath,
    this.modeDefault,
  });

  Entry copyWith({
    String? id,
    String? title,
    String? category,
    String? level,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? takes,
    String? bgLoopPath,
    String? modeDefault,
  }) {
    return Entry(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      takes: takes ?? this.takes,
      bgLoopPath: bgLoopPath ?? this.bgLoopPath,
      modeDefault: modeDefault ?? this.modeDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'takes': takes.join('|'), // Convert list to pipe-separated string
      'bgLoopPath': bgLoopPath,
      'modeDefault': modeDefault,
    };
  }

  factory Entry.fromJson(Map<String, dynamic> json) {
    // Handle both old format (List) and new format (pipe-separated String)
    List<String> takes = [];
    final takesData = json['takes'];

    if (takesData is String) {
      // New format: pipe-separated string
      takes = takesData.split('|');
    } else if (takesData is List) {
      // Old format: list of strings
      takes = List<String>.from(takesData);
    }

    return Entry(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      level: json['level'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      takes: takes,
      bgLoopPath: json['bgLoopPath'],
      modeDefault: json['modeDefault'],
    );
  }

  // Helper methods
  int get takeCount => takes.where((take) => take.isNotEmpty).length;
  bool get isComplete => takeCount > 0;
  String get displayTitle => title.isNotEmpty ? title : 'Unbenannt';

  String get categoryDisplayName {
    switch (category) {
      case 'selbstbewusstsein':
        return 'Selbstbewusstsein';
      case 'selbstwert':
        return 'Selbstwert';
      case 'aengste':
        return 'Ängste lösen';
      case 'custom':
        return 'Eigene Ziele';
      default:
        return category;
    }
  }

  String get levelDisplayName {
    return AppStrings.mapLevelToLabel(level);
  }
}
