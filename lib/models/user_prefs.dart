// Sentinel value for copyWith to distinguish between null and not provided
const Object _undefined = Object();

class UserPrefs {
  final String? displayName;
  final String selectedTopic; // selbstbewusstsein|selbstwert|aengste|custom
  final String level; // beginner|advanced|open
  final bool consentAccepted;
  final bool privacyAccepted;
  final bool agbAccepted;
  final bool pushAllowed;
  final bool? vibrationEnabled;
  final bool? temperatureEnabled;
  final String? lastBackgroundMusic; // Last selected background music (legacy)
  final Map<String, String>
  levelBackgroundMusic; // Level-specific background music
  final double?
  defaultBackgroundVolume; // Default volume for new sessions (0.0 - 1.0)
  final List<MoodEntry> moods;
  final String? profileImagePath; // Path to profile image
  final List<String> earnedBadgeIds; // List of earned badge IDs

  UserPrefs({
    this.displayName,
    this.selectedTopic = 'selbstbewusstsein',
    this.level = 'beginner',
    this.consentAccepted = false,
    this.privacyAccepted = false,
    this.agbAccepted = false,
    this.pushAllowed = false,
    this.vibrationEnabled,
    this.temperatureEnabled,
    this.lastBackgroundMusic,
    this.levelBackgroundMusic = const {},
    this.defaultBackgroundVolume = 0.5, // Default to 50%
    this.moods = const [],
    this.profileImagePath,
    this.earnedBadgeIds = const [],
  });

  UserPrefs copyWith({
    String? displayName,
    String? selectedTopic,
    String? level,
    bool? consentAccepted,
    bool? privacyAccepted,
    bool? agbAccepted,
    bool? pushAllowed,
    bool? vibrationEnabled,
    bool? temperatureEnabled,
    String? lastBackgroundMusic,
    Map<String, String>? levelBackgroundMusic,
    double? defaultBackgroundVolume,
    List<MoodEntry>? moods,
    Object? profileImagePath = _undefined,
    List<String>? earnedBadgeIds,
  }) {
    return UserPrefs(
      displayName: displayName ?? this.displayName,
      selectedTopic: selectedTopic ?? this.selectedTopic,
      level: level ?? this.level,
      consentAccepted: consentAccepted ?? this.consentAccepted,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
      agbAccepted: agbAccepted ?? this.agbAccepted,
      pushAllowed: pushAllowed ?? this.pushAllowed,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      temperatureEnabled: temperatureEnabled ?? this.temperatureEnabled,
      lastBackgroundMusic: lastBackgroundMusic ?? this.lastBackgroundMusic,
      levelBackgroundMusic: levelBackgroundMusic ?? this.levelBackgroundMusic,
      defaultBackgroundVolume:
          defaultBackgroundVolume ?? this.defaultBackgroundVolume,
      moods: moods ?? this.moods,
      profileImagePath: profileImagePath == _undefined
          ? this.profileImagePath
          : profileImagePath as String?,
      earnedBadgeIds: earnedBadgeIds ?? this.earnedBadgeIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'selectedTopic': selectedTopic,
      'level': level,
      'consentAccepted': consentAccepted,
      'privacyAccepted': privacyAccepted,
      'agbAccepted': agbAccepted,
      'pushAllowed': pushAllowed,
      'vibrationEnabled': vibrationEnabled,
      'temperatureEnabled': temperatureEnabled,
      'lastBackgroundMusic': lastBackgroundMusic,
      'levelBackgroundMusic': levelBackgroundMusic,
      'defaultBackgroundVolume': defaultBackgroundVolume,
      'moods': moods.map((m) => m.toJson()).toList(),
      'profileImagePath': profileImagePath,
      'earnedBadgeIds': earnedBadgeIds,
    };
  }

  factory UserPrefs.fromJson(Map<String, dynamic> json) {
    return UserPrefs(
      displayName: json['displayName'],
      selectedTopic: json['selectedTopic'] ?? 'selbstbewusstsein',
      level: json['level'] ?? 'beginner',
      consentAccepted: json['consentAccepted'] ?? false,
      privacyAccepted: json['privacyAccepted'] ?? false,
      agbAccepted: json['agbAccepted'] ?? false,
      pushAllowed: json['pushAllowed'] ?? false,
      vibrationEnabled: json['vibrationEnabled'],
      temperatureEnabled: json['temperatureEnabled'],
      lastBackgroundMusic: json['lastBackgroundMusic'],
      levelBackgroundMusic: Map<String, String>.from(
        json['levelBackgroundMusic'] ?? {},
      ),
      defaultBackgroundVolume: (json['defaultBackgroundVolume'] ?? 0.5)
          .toDouble(),
      moods:
          (json['moods'] as List<dynamic>?)
              ?.map((m) => MoodEntry.fromJson(m))
              .toList() ??
          [],
      profileImagePath: json['profileImagePath'],
      earnedBadgeIds:
          (json['earnedBadgeIds'] as List<dynamic>?)
              ?.map((id) => id.toString())
              .toList() ??
          [],
    );
  }

  // Reset to default values for testing
  static UserPrefs reset() {
    return UserPrefs();
  }
}

class MoodEntry {
  final DateTime date;
  final String mood; // wütend|traurig|passiv|fröhlich|euphorisch

  MoodEntry({required this.date, required this.mood});

  Map<String, dynamic> toJson() {
    return {'date': date.toIso8601String(), 'mood': mood};
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(date: DateTime.parse(json['date']), mood: json['mood']);
  }
}
