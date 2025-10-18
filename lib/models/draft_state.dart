import 'dart:convert';

enum TakeStatus { todo, recorded, approved }

class DraftState {
  final String entryId;
  final String title; // Custom title for the draft
  final String category; // Category for the draft
  final int nextIndex; // 0..29 - nächste aufzunehmende Affirmation
  final List<TakeStatus> perTakeStatus; // Status pro Take
  final String? lastPartialFile; // falls eine Aufnahme pausiert wurde
  final List<int> bookmarks; // optionale Marker (z.B. neu aufnehmen)

  // New fields for pause functionality
  final List<String> selectedAffirmations;
  final List<String> customAffirmations;
  final String currentStep;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> recordedTakes; // Store actual recording file paths

  DraftState({
    required this.entryId,
    this.title = 'Draft',
    this.category = 'custom',
    this.nextIndex = 0,
    this.perTakeStatus = const [],
    this.lastPartialFile,
    this.bookmarks = const [],
    this.selectedAffirmations = const [],
    this.customAffirmations = const [],
    this.currentStep = 'affirmation_selection',
    required this.createdAt,
    required this.updatedAt,
    this.recordedTakes = const [],
  });

  DraftState copyWith({
    String? entryId,
    String? title,
    String? category,
    int? nextIndex,
    List<TakeStatus>? perTakeStatus,
    String? lastPartialFile,
    List<int>? bookmarks,
    List<String>? selectedAffirmations,
    List<String>? customAffirmations,
    String? currentStep,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? recordedTakes,
  }) {
    return DraftState(
      entryId: entryId ?? this.entryId,
      title: title ?? this.title,
      category: category ?? this.category,
      nextIndex: nextIndex ?? this.nextIndex,
      perTakeStatus: perTakeStatus ?? this.perTakeStatus,
      lastPartialFile: lastPartialFile ?? this.lastPartialFile,
      bookmarks: bookmarks ?? this.bookmarks,
      selectedAffirmations: selectedAffirmations ?? this.selectedAffirmations,
      customAffirmations: customAffirmations ?? this.customAffirmations,
      currentStep: currentStep ?? this.currentStep,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recordedTakes: recordedTakes ?? this.recordedTakes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entryId': entryId,
      'title': title,
      'category': category,
      'nextIndex': nextIndex,
      'perTakeStatus': jsonEncode(perTakeStatus.map((s) => s.name).toList()),
      'lastPartialFile': lastPartialFile,
      'bookmarks': jsonEncode(bookmarks),
      'selectedAffirmations': jsonEncode(selectedAffirmations),
      'customAffirmations': jsonEncode(customAffirmations),
      'currentStep': currentStep,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'recordedTakes': jsonEncode(recordedTakes),
    };
  }

  factory DraftState.fromJson(Map<String, dynamic> json) {
    return DraftState(
      entryId: json['entryId'],
      title: json['title'] ?? 'Draft',
      category: json['category'] ?? 'custom',
      nextIndex: json['nextIndex'] ?? 0,
      perTakeStatus: _parseTakeStatusList(json['perTakeStatus']),
      lastPartialFile: json['lastPartialFile'],
      bookmarks: _parseIntList(json['bookmarks']),
      selectedAffirmations: _parseStringList(json['selectedAffirmations']),
      customAffirmations: _parseStringList(json['customAffirmations']),
      currentStep: json['currentStep'] ?? 'affirmation_selection',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      recordedTakes: _parseStringList(json['recordedTakes']),
    );
  }

  static List<TakeStatus> _parseTakeStatusList(dynamic data) {
    if (data is String) {
      final List<dynamic> list = jsonDecode(data);
      return list
          .map(
            (s) => TakeStatus.values.firstWhere(
              (e) => e.name == s,
              orElse: () => TakeStatus.todo,
            ),
          )
          .toList();
    } else if (data is List) {
      return data
          .map(
            (s) => TakeStatus.values.firstWhere(
              (e) => e.name == s,
              orElse: () => TakeStatus.todo,
            ),
          )
          .toList();
    }
    return [];
  }

  static List<int> _parseIntList(dynamic data) {
    if (data is String) {
      return List<int>.from(jsonDecode(data));
    } else if (data is List) {
      return List<int>.from(data);
    }
    return [];
  }

  static List<String> _parseStringList(dynamic data) {
    if (data is String) {
      return List<String>.from(jsonDecode(data));
    } else if (data is List) {
      return List<String>.from(data);
    }
    return [];
  }

  // Helper methods
  bool get hasRecordedTakes =>
      perTakeStatus.any((status) => status == TakeStatus.recorded);
  bool get hasApprovedTakes =>
      perTakeStatus.any((status) => status == TakeStatus.approved);
  int get recordedCount =>
      perTakeStatus.where((status) => status == TakeStatus.recorded).length;
  int get approvedCount =>
      perTakeStatus.where((status) => status == TakeStatus.approved).length;
  int get todoCount =>
      perTakeStatus.where((status) => status == TakeStatus.todo).length;

  bool isTakeRecorded(int index) {
    if (index >= perTakeStatus.length) return false;
    return perTakeStatus[index] == TakeStatus.recorded ||
        perTakeStatus[index] == TakeStatus.approved;
  }

  bool isTakeApproved(int index) {
    if (index >= perTakeStatus.length) return false;
    return perTakeStatus[index] == TakeStatus.approved;
  }

  TakeStatus getTakeStatus(int index) {
    if (index >= perTakeStatus.length) return TakeStatus.todo;
    return perTakeStatus[index];
  }

  DraftState setTakeStatus(int index, TakeStatus status) {
    if (index >= perTakeStatus.length) {
      // Extend the list with todo statuses up to the required index
      final newStatuses = List<TakeStatus>.from(perTakeStatus);
      while (newStatuses.length <= index) {
        newStatuses.add(TakeStatus.todo);
      }
      newStatuses[index] = status;
      return copyWith(perTakeStatus: newStatuses);
    } else {
      final newStatuses = List<TakeStatus>.from(perTakeStatus);
      newStatuses[index] = status;
      return copyWith(perTakeStatus: newStatuses);
    }
  }

  DraftState addBookmark(int index) {
    if (bookmarks.contains(index)) return this;
    return copyWith(bookmarks: [...bookmarks, index]);
  }

  DraftState removeBookmark(int index) {
    return copyWith(bookmarks: bookmarks.where((i) => i != index).toList());
  }
}
