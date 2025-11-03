import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_prefs.dart';
import '../models/entry.dart';
import '../models/draft_state.dart';
import '../models/listen_log.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../services/device_service.dart';
import '../utils/mood_theme.dart';

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Audio Service Provider
final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

// Notification Service Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Device Service Provider
final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

// User Preferences Provider
final userPrefsProvider = StateNotifierProvider<UserPrefsNotifier, UserPrefs>((
  ref,
) {
  final storageService = ref.watch(storageServiceProvider);
  return UserPrefsNotifier(storageService);
});

// Provider, der darauf wartet, dass die UserPrefs geladen sind
final userPrefsLoadedProvider = FutureProvider<UserPrefs>((ref) async {
  final notifier = ref.read(userPrefsProvider.notifier);
  return await notifier.ensureLoaded();
});

class UserPrefsNotifier extends StateNotifier<UserPrefs> {
  final StorageService _storageService;
  Completer<UserPrefs>? _loadCompleter;

  UserPrefsNotifier(this._storageService) : super(UserPrefs()) {
    _loadUserPrefs();
  }

  Future<void> _loadUserPrefs() async {
    _loadCompleter = Completer<UserPrefs>();
    try {
      final prefs = await _storageService.getUserPrefs();
      state = prefs;

      // Initialize already earned badges for existing users
      await initializeEarnedBadges();

      // Signalisiere dass das Laden abgeschlossen ist
      if (!_loadCompleter!.isCompleted) {
        _loadCompleter!.complete(state);
      }
    } catch (e) {
      if (!_loadCompleter!.isCompleted) {
        _loadCompleter!.completeError(e);
      }
    }
  }

  /// Wartet darauf, dass die UserPrefs geladen sind
  /// Gibt die geladenen UserPrefs zurück
  Future<UserPrefs> ensureLoaded() async {
    if (_loadCompleter == null) {
      // Falls das Laden noch nicht gestartet wurde, starte es
      _loadUserPrefs();
    }
    if (_loadCompleter!.isCompleted) {
      // Falls bereits geladen, gib sofort zurück
      return state;
    }
    // Warte auf das Laden
    return await _loadCompleter!.future;
  }

  Future<void> updateDisplayName(String? displayName) async {
    state = state.copyWith(displayName: displayName);
    await _storageService.saveUserPrefs(state);
    // Note: Caller should trigger pushUserPrefsIfEnabled after this
  }

  Future<void> updateSelectedTopic(String topic) async {
    state = state.copyWith(selectedTopic: topic);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updateLevel(String level) async {
    state = state.copyWith(level: level);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updateConsent(bool accepted) async {
    state = state.copyWith(consentAccepted: accepted);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updatePrivacy(bool accepted) async {
    state = state.copyWith(privacyAccepted: accepted);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updateAGB(bool accepted) async {
    state = state.copyWith(agbAccepted: accepted);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updatePushAllowed(bool allowed) async {
    state = state.copyWith(pushAllowed: allowed);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updateNotificationTime(int hour, int minute) async {
    state = state.copyWith(
      notificationHour: hour,
      notificationMinute: minute,
    );
    await _storageService.saveUserPrefs(state);
  }

  // Sync settings updates
  Future<void> updateSyncEnabled(bool enabled) async {
    state = state.copyWith(syncEnabled: enabled);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updateLastSyncAt(DateTime? lastSyncAt) async {
    state = state.copyWith(lastSyncAt: lastSyncAt);
    await _storageService.saveUserPrefs(state);
  }

  // Replace entire prefs (used for cloud merge)
  Future<void> replaceAll(UserPrefs newPrefs) async {
    state = newPrefs;
    await _storageService.saveUserPrefs(state);
  }

  Future<void> setSyncPromptShown() async {
    state = state.copyWith(syncPromptShown: true);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> addMood(MoodEntry mood) async {
    final updatedMoods = List<MoodEntry>.from(state.moods);
    // Remove existing mood for the same date
    updatedMoods.removeWhere(
      (m) =>
          m.date.year == mood.date.year &&
          m.date.month == mood.date.month &&
          m.date.day == mood.date.day,
    );
    updatedMoods.add(mood);

    state = state.copyWith(moods: updatedMoods);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updateVibration(bool enabled) async {
    state = state.copyWith(vibrationEnabled: enabled);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updateTemperature(bool enabled) async {
    state = state.copyWith(temperatureEnabled: enabled);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updateLastBackgroundMusic(String musicId) async {
    state = state.copyWith(lastBackgroundMusic: musicId);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updateLevelBackgroundMusic(String level, String musicId) async {
    final updatedLevelMusic = Map<String, String>.from(
      state.levelBackgroundMusic,
    );
    updatedLevelMusic[level] = musicId;
    state = state.copyWith(levelBackgroundMusic: updatedLevelMusic);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> updateProfileImage(String? imagePath) async {
    state = state.copyWith(profileImagePath: imagePath);
    await _storageService.saveUserPrefs(state);
    // Note: Caller should trigger profile image sync after this
  }

  Future<void> updateDefaultBackgroundVolume(double volume) async {
    state = state.copyWith(defaultBackgroundVolume: volume);
    await _storageService.saveUserPrefs(state);
  }

  Future<void> addEarnedBadge(String badgeId) async {
    if (!state.earnedBadgeIds.contains(badgeId)) {
      final updatedBadgeIds = List<String>.from(state.earnedBadgeIds);
      updatedBadgeIds.add(badgeId);
      state = state.copyWith(earnedBadgeIds: updatedBadgeIds);
      await _storageService.saveUserPrefs(state);
    }
  }

  // Initialize already earned badges (for existing users)
  Future<void> initializeEarnedBadges() async {
    if (state.earnedBadgeIds.isEmpty) {
      try {
        final allBadges = await _storageService.getEarnedBadges();
        final earnedBadges = allBadges
            .where((badge) => badge['earned'] == true)
            .toList();

        final badgeIds = earnedBadges
            .map((badge) => badge['id'] as String)
            .toList();

        if (badgeIds.isNotEmpty) {
          state = state.copyWith(earnedBadgeIds: badgeIds);
          await _storageService.saveUserPrefs(state);
          debugPrint(
            'Initialized ${badgeIds.length} already earned badges: $badgeIds',
          );
        }
      } catch (e) {
        debugPrint('Error initializing earned badges: $e');
      }
    }
  }

  String? getLevelBackgroundMusic(String level) {
    return state.levelBackgroundMusic[level];
  }

  bool get isFirstTime =>
      !state.consentAccepted || !state.privacyAccepted || !state.agbAccepted;

  // Reset user preferences for testing
  Future<void> resetForTesting() async {
    state = UserPrefs.reset();
    await _storageService.saveUserPrefs(state);
  }
}

// Entries Provider
final entriesProvider = StateNotifierProvider<EntriesNotifier, List<Entry>>((
  ref,
) {
  final storageService = ref.watch(storageServiceProvider);
  return EntriesNotifier(storageService);
});

class EntriesNotifier extends StateNotifier<List<Entry>> {
  final StorageService _storageService;

  EntriesNotifier(this._storageService) : super([]) {
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await _storageService.getEntries();
    state = entries;

    // Migrate old entries to new format
    await migrateOldEntries();
  }

  Future<void> addEntry(Entry entry) async {
    await _storageService.saveEntry(entry);
    state = [entry, ...state];
  }

  Future<void> updateEntry(Entry entry) async {
    await _storageService.saveEntry(entry);
    state = state.map((e) => e.id == entry.id ? entry : e).toList();
  }

  // Migrate old entries to new format
  Future<void> migrateOldEntries() async {
    final entries = await _storageService.getEntries();
    bool needsMigration = false;

    for (final entry in entries) {
      // Check if this entry needs migration (has old format takes)
      final takesData = entry.takes;
      if (takesData.isNotEmpty && takesData.first.contains('[')) {
        // This is an old format entry, migrate it
        needsMigration = true;
        await _storageService.saveEntry(entry); // This will save in new format
      }
    }

    if (needsMigration) {
      // Reload entries after migration
      await _loadEntries();
    }
  }

  Future<void> deleteEntry(String id) async {
    await _storageService.deleteEntry(id);
    state = state.where((e) => e.id != id).toList();
  }

  Future<List<Entry>> getEntriesByCategory(String category) async {
    return await _storageService.getEntriesByCategory(category);
  }
}

// Draft States Provider
final draftStatesProvider =
    StateNotifierProvider<DraftStatesNotifier, Map<String, DraftState>>((ref) {
      final storageService = ref.watch(storageServiceProvider);
      return DraftStatesNotifier(storageService);
    });

class DraftStatesNotifier extends StateNotifier<Map<String, DraftState>> {
  final StorageService _storageService;

  DraftStatesNotifier(this._storageService) : super({}) {
    _loadDraftStates();
  }

  Future<void> _loadDraftStates() async {
    // Load all draft states directly from the database
    final draftStates = await _storageService.getAllDraftStates();
    final draftStatesMap = <String, DraftState>{};

    for (final draftState in draftStates) {
      draftStatesMap[draftState.entryId] = draftState;
    }

    state = draftStatesMap;
  }

  Future<void> saveDraftState(String entryId, DraftState draftState) async {
    await _storageService.saveDraftState(draftState);
    state = {...state, entryId: draftState};
  }

  Future<void> addDraft(DraftState draftState) async {
    await _storageService.saveDraftState(draftState);
    state = {...state, draftState.entryId: draftState};
  }

  Future<void> deleteDraftState(String entryId) async {
    await _storageService.deleteDraftState(entryId);
    state = Map.from(state)..remove(entryId);
  }

  DraftState? getDraftState(String entryId) {
    return state[entryId];
  }
}

// Listen Logs Provider
final listenLogsProvider =
    StateNotifierProvider<ListenLogsNotifier, List<ListenLog>>((ref) {
      final storageService = ref.watch(storageServiceProvider);
      return ListenLogsNotifier(storageService);
    });

class ListenLogsNotifier extends StateNotifier<List<ListenLog>> {
  final StorageService _storageService;

  ListenLogsNotifier(this._storageService) : super([]) {
    _loadListenLogs();
  }

  Future<void> _loadListenLogs() async {
    final logs = await _storageService.getListenLogs();
    state = logs;
  }

  Future<void> addListenLog(ListenLog log) async {
    await _storageService.saveListenLog(log);
    state = [log, ...state];
  }

  Future<void> refreshListenLogs() async {
    await _loadListenLogs();
  }

  Future<List<ListenLog>> getLogsForEntry(String entryId) async {
    return await _storageService.getListenLogsByEntry(entryId);
  }
}

// Statistics Provider
final statisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final storageService = ref.watch(storageServiceProvider);

  final totalListenTime = await storageService.getTotalListenTime();
  final currentStreak = await storageService.getCurrentStreak();
  final todayListenTime = await storageService.getListenTimeForDate(
    DateTime.now(),
  );
  final yesterdayListenTime = await storageService.getListenTimeForDate(
    DateTime.now().subtract(Duration(days: 1)),
  );
  final weekListenTime = await storageService.getListenTimeForWeek();
  final monthListenTime = await storageService.getListenTimeForMonth();
  final totalAffirmations = await storageService.getTotalAffirmations();
  final totalRecordings = await storageService.getTotalRecordings();

  return {
    'totalListenMinutes': totalListenTime,
    'currentStreak': currentStreak,
    'todayListenMinutes': todayListenTime,
    'yesterdayListenMinutes': yesterdayListenTime,
    'weekListenMinutes': weekListenTime,
    'monthListenMinutes': monthListenTime,
    'totalAffirmations': totalAffirmations,
    'totalRecordings': totalRecordings,
  };
});

// Statistics Notifier to refresh statistics
final statisticsNotifierProvider =
    StateNotifierProvider<StatisticsNotifier, void>((ref) {
      return StatisticsNotifier(ref);
    });

class StatisticsNotifier extends StateNotifier<void> {
  final Ref _ref;

  StatisticsNotifier(this._ref) : super(null);

  Future<void> refreshStatistics() async {
    // Get old badge IDs before refresh
    final userPrefs = _ref.read(userPrefsProvider);
    final oldBadgeIds = Set<String>.from(userPrefs.earnedBadgeIds);

    // Refresh statistics
    _ref.invalidate(statisticsProvider);
    _ref.invalidate(recentListenLogsProvider);
    _ref.invalidate(moodStatisticsProvider);
    _ref.invalidate(recentActivitiesProvider);
    _ref.invalidate(badgesProvider);
    _ref.invalidate(highestBadgeProvider);

    // Check for new badges
    try {
      final storageService = _ref.read(storageServiceProvider);
      final allBadges = await storageService.getEarnedBadges();
      final earnedBadges = allBadges
          .where((badge) => badge['earned'] == true)
          .toList();

      // Find new badges
      for (final badge in earnedBadges) {
        final badgeId = badge['id'] as String;
        if (!oldBadgeIds.contains(badgeId)) {
          // New badge earned!
          await _ref.read(userPrefsProvider.notifier).addEarnedBadge(badgeId);

          // Show congratulations popup
          _ref.read(badgeNotificationProvider.notifier).showBadge(badge);
          break; // Show only one badge at a time
        }
      }
    } catch (e) {
      debugPrint('Error checking for new badges: $e');
    }
  }
}

// Recent Listen Logs Provider
final recentListenLogsProvider = FutureProvider<List<ListenLog>>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return await storageService.getRecentListenLogs(limit: 2);
});

// Mood Statistics Provider
final moodStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return await storageService.getMoodStatistics();
});

// Recent Activities Provider
final recentActivitiesProvider = FutureProvider<List<ListenLog>>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return await storageService.getRecentActivities(limit: 5);
});

// Badges Provider
final badgesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return await storageService.getEarnedBadges();
});

// Highest Badge Provider
final highestBadgeProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return await storageService.getHighestEarnedBadge();
});

// Badge Notification Provider - holds newly earned badge to show popup
final badgeNotificationProvider =
    StateNotifierProvider<BadgeNotificationNotifier, Map<String, dynamic>?>((
      ref,
    ) {
      return BadgeNotificationNotifier();
    });

class BadgeNotificationNotifier extends StateNotifier<Map<String, dynamic>?> {
  BadgeNotificationNotifier() : super(null);

  void showBadge(Map<String, dynamic> badge) {
    state = badge;
  }

  void clearBadge() {
    state = null;
  }
}

// Current Mood Theme Provider
final currentMoodThemeProvider = Provider<MoodTheme>((ref) {
  final userPrefs = ref.watch(userPrefsProvider);

  // Get today's mood
  final today = DateTime.now();
  final todayMood = userPrefs.moods.firstWhere(
    (mood) =>
        mood.date.year == today.year &&
        mood.date.month == today.month &&
        mood.date.day == today.day,
    orElse: () => MoodEntry(date: today, mood: ''),
  );

  // Return theme based on mood
  return MoodTheme.fromMood(todayMood.mood);
});
