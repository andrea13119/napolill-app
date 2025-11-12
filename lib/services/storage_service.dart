import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/user_prefs.dart';
import '../models/entry.dart';
import '../models/draft_state.dart';
import '../models/listen_log.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Database? _database;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _database = await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDirectory.path, 'napolill.db');

    return await openDatabase(
      dbPath,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Entries table
    await db.execute('''
      CREATE TABLE entries (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        level TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        takes TEXT NOT NULL,
        bgLoopPath TEXT,
        modeDefault TEXT
      )
    ''');

    // Draft states table
    await db.execute('''
      CREATE TABLE draft_states (
        entryId TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        nextIndex INTEGER NOT NULL,
        perTakeStatus TEXT NOT NULL,
        lastPartialFile TEXT,
        bookmarks TEXT NOT NULL,
        selectedAffirmations TEXT NOT NULL,
        customAffirmations TEXT NOT NULL,
        currentStep TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        recordedTakes TEXT NOT NULL
      )
    ''');

    // Listen logs table
    await db.execute('''
      CREATE TABLE listen_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entryId TEXT NOT NULL,
        entryTitle TEXT NOT NULL,
        category TEXT NOT NULL,
        level TEXT NOT NULL,
        mode TEXT NOT NULL,
        startedAt TEXT NOT NULL,
        endedAt TEXT NOT NULL,
        minutes INTEGER NOT NULL,
        seconds INTEGER NOT NULL
      )
    ''');

    // Mood logs table
    await db.execute('''
      CREATE TABLE mood_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        mood TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to draft_states table
      try {
        await db.execute('''
          ALTER TABLE draft_states ADD COLUMN selectedAffirmations TEXT NOT NULL DEFAULT '[]'
        ''');
      } catch (e) {
        debugPrint('Column selectedAffirmations might already exist: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE draft_states ADD COLUMN customAffirmations TEXT NOT NULL DEFAULT '[]'
        ''');
      } catch (e) {
        debugPrint('Column customAffirmations might already exist: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE draft_states ADD COLUMN currentStep TEXT NOT NULL DEFAULT 'affirmation_selection'
        ''');
      } catch (e) {
        debugPrint('Column currentStep might already exist: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE draft_states ADD COLUMN createdAt TEXT NOT NULL DEFAULT '${DateTime.now().toIso8601String()}'
        ''');
      } catch (e) {
        debugPrint('Column createdAt might already exist: $e');
      }

      try {
        await db.execute('''
          ALTER TABLE draft_states ADD COLUMN updatedAt TEXT NOT NULL DEFAULT '${DateTime.now().toIso8601String()}'
        ''');
      } catch (e) {
        debugPrint('Column updatedAt might already exist: $e');
      }
    }
    if (oldVersion < 3) {
      // For version 3, we need to add recordedTakes column
      // If ALTER TABLE fails, we'll recreate the table
      try {
        await db.execute('''
          ALTER TABLE draft_states ADD COLUMN recordedTakes TEXT NOT NULL DEFAULT '[]'
        ''');
        debugPrint('Successfully added recordedTakes column');
      } catch (e) {
        debugPrint('Failed to add recordedTakes column, recreating table: $e');
        // Recreate the draft_states table with the new schema
        await _recreateDraftStatesTable(db);
      }
    }
    if (oldVersion < 4) {
      // For version 4, we need to add title column
      try {
        await db.execute('''
          ALTER TABLE draft_states ADD COLUMN title TEXT NOT NULL DEFAULT 'Entwurf'
        ''');
        debugPrint('Successfully added title column');
      } catch (e) {
        debugPrint('Failed to add title column, recreating table: $e');
        // Recreate the draft_states table with the new schema
        await _recreateDraftStatesTable(db);
      }
    }
    if (oldVersion < 5) {
      // For version 5, we need to add category column
      try {
        await db.execute('''
          ALTER TABLE draft_states ADD COLUMN category TEXT NOT NULL DEFAULT 'custom'
        ''');
        debugPrint('Successfully added category column');
      } catch (e) {
        debugPrint('Failed to add category column, recreating table: $e');
        // Recreate the draft_states table with the new schema
        await _recreateDraftStatesTable(db);
      }
    }
    if (oldVersion < 6) {
      // For version 6, we need to update listen_logs table with new columns
      debugPrint('Upgrading listen_logs table to version 6...');

      // First, check if the table exists and what columns it has
      final tableInfo = await db.rawQuery("PRAGMA table_info(listen_logs)");
      debugPrint('Current listen_logs table structure: $tableInfo');

      // Drop and recreate the table to ensure clean structure
      await db.execute('DROP TABLE IF EXISTS listen_logs');
      await db.execute('''
        CREATE TABLE listen_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entryId TEXT NOT NULL,
          entryTitle TEXT NOT NULL,
          category TEXT NOT NULL,
          level TEXT NOT NULL,
          mode TEXT NOT NULL,
          startedAt TEXT NOT NULL,
          endedAt TEXT NOT NULL,
          minutes INTEGER NOT NULL,
          seconds INTEGER NOT NULL
        )
      ''');
      debugPrint('Successfully recreated listen_logs table with new schema');
    }
    if (oldVersion < 7) {
      // For version 7, ensure listen_logs table has the correct structure
      debugPrint(
        'Ensuring listen_logs table has correct structure for version 7...',
      );

      // Drop and recreate the table to ensure clean structure
      await db.execute('DROP TABLE IF EXISTS listen_logs');
      await db.execute('''
        CREATE TABLE listen_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entryId TEXT NOT NULL,
          entryTitle TEXT NOT NULL,
          category TEXT NOT NULL,
          level TEXT NOT NULL,
          mode TEXT NOT NULL,
          startedAt TEXT NOT NULL,
          endedAt TEXT NOT NULL,
          minutes INTEGER NOT NULL,
          seconds INTEGER NOT NULL
        )
      ''');
      debugPrint(
        'Successfully ensured listen_logs table structure for version 7',
      );
    }
    if (oldVersion < 8) {
      // For version 8, force recreate listen_logs table with correct structure
      debugPrint('Force recreating listen_logs table for version 8...');

      // Drop and recreate the table to ensure clean structure
      await db.execute('DROP TABLE IF EXISTS listen_logs');
      await db.execute('''
        CREATE TABLE listen_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entryId TEXT NOT NULL,
          entryTitle TEXT NOT NULL,
          category TEXT NOT NULL,
          level TEXT NOT NULL,
          mode TEXT NOT NULL,
          startedAt TEXT NOT NULL,
          endedAt TEXT NOT NULL,
          minutes INTEGER NOT NULL,
          seconds INTEGER NOT NULL
        )
      ''');
      debugPrint('Successfully recreated listen_logs table for version 8');
    }
  }

  Future<void> _recreateDraftStatesTable(Database db) async {
    // Drop the old table
    await db.execute('DROP TABLE IF EXISTS draft_states');

    // Create the new table with all columns
    await db.execute('''
      CREATE TABLE draft_states (
        entryId TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        nextIndex INTEGER NOT NULL,
        perTakeStatus TEXT NOT NULL,
        lastPartialFile TEXT,
        bookmarks TEXT NOT NULL,
        selectedAffirmations TEXT NOT NULL,
        customAffirmations TEXT NOT NULL,
        currentStep TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        recordedTakes TEXT NOT NULL
      )
    ''');

    debugPrint(
      'Successfully recreated draft_states table with recordedTakes column',
    );
  }

  // User Preferences
  Future<UserPrefs> getUserPrefs() async {
    final prefs = _prefs!;
    final userPrefsJson = prefs.getString('user_prefs');

    if (userPrefsJson != null) {
      return UserPrefs.fromJson(jsonDecode(userPrefsJson));
    }

    return UserPrefs();
  }

  Future<void> saveUserPrefs(UserPrefs userPrefs) async {
    final prefs = _prefs!;
    await prefs.setString('user_prefs', jsonEncode(userPrefs.toJson()));
  }

  // Entries
  Future<List<Entry>> getEntries() async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) => Entry.fromJson(maps[i]));
  }

  Future<List<Entry>> getEntriesByCategory(String category) async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) => Entry.fromJson(maps[i]));
  }

  Future<Entry?> getEntry(String id) async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Entry.fromJson(maps.first);
    }
    return null;
  }

  Future<void> saveEntry(Entry entry) async {
    final db = _database!;
    await db.insert(
      'entries',
      entry.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteEntry(String id) async {
    final db = _database!;
    await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  // Draft States
  Future<DraftState?> getDraftState(String entryId) async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'draft_states',
      where: 'entryId = ?',
      whereArgs: [entryId],
    );

    if (maps.isNotEmpty) {
      return DraftState.fromJson(maps.first);
    }
    return null;
  }

  Future<void> saveDraftState(DraftState draftState) async {
    final db = _database!;
    await db.insert(
      'draft_states',
      draftState.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDraftState(String entryId) async {
    final db = _database!;
    await db.delete('draft_states', where: 'entryId = ?', whereArgs: [entryId]);
  }

  Future<List<DraftState>> getAllDraftStates() async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'draft_states',
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) => DraftState.fromJson(maps[i]));
  }

  // Listen Logs
  Future<List<ListenLog>> getListenLogs() async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'listen_logs',
      orderBy: 'startedAt DESC',
    );

    return List.generate(maps.length, (i) => ListenLog.fromJson(maps[i]));
  }

  Future<List<ListenLog>> getListenLogsByEntry(String entryId) async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'listen_logs',
      where: 'entryId = ?',
      whereArgs: [entryId],
      orderBy: 'startedAt DESC',
    );

    return List.generate(maps.length, (i) => ListenLog.fromJson(maps[i]));
  }

  Future<void> saveListenLog(ListenLog listenLog) async {
    final db = _database!;
    await db.insert('listen_logs', listenLog.toJson());
  }

  // Mood Logs
  Future<List<MoodEntry>> getMoodLogs() async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_logs',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => MoodEntry.fromJson(maps[i]));
  }

  Future<MoodEntry?> getMoodForDate(DateTime date) async {
    final db = _database!;
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'mood_logs',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    if (maps.isNotEmpty) {
      return MoodEntry.fromJson(maps.first);
    }
    return null;
  }

  Future<void> saveMoodLog(MoodEntry moodEntry) async {
    final db = _database!;
    await db.insert(
      'mood_logs',
      moodEntry.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Statistics
  Future<int> getTotalListenTime() async {
    final db = _database!;
    final result = await db.rawQuery(
      'SELECT SUM(minutes * 60 + seconds) as total_seconds FROM listen_logs',
    );
    final totalSeconds = result.first['total_seconds'] as int? ?? 0;
    return (totalSeconds / 60).ceil(); // Convert to minutes (always round up)
  }

  Future<int> getListenTimeForDate(DateTime date) async {
    final db = _database!;
    final dateStr = date.toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      'SELECT SUM(minutes * 60 + seconds) as total_seconds FROM listen_logs WHERE DATE(startedAt) = ?',
      [dateStr],
    );
    final totalSeconds = result.first['total_seconds'] as int? ?? 0;
    return (totalSeconds / 60).ceil(); // Convert to minutes (always round up)
  }

  Future<int> getCurrentStreak() async {
    final db = _database!;

    // Prüfe ob heute oder gestern gehört wurde
    final todayResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM listen_logs WHERE DATE(startedAt) = DATE(\'now\')',
    );
    final yesterdayResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM listen_logs WHERE DATE(startedAt) = DATE(\'now\', \'-1 day\')',
    );

    final todayCount = todayResult.first['count'] as int? ?? 0;
    final yesterdayCount = yesterdayResult.first['count'] as int? ?? 0;

    // Wenn weder heute noch gestern gehört wurde, ist die Serie 0
    if (todayCount == 0 && yesterdayCount == 0) {
      return 0;
    }

    // Finde den neuesten Tag mit Aktivität (heute oder gestern)
    final latestDayResult = await db.rawQuery('''
      SELECT DATE(startedAt) as latest_date
      FROM listen_logs
      WHERE DATE(startedAt) IN (DATE('now'), DATE('now', '-1 day'))
      ORDER BY DATE(startedAt) DESC
      LIMIT 1
    ''');

    if (latestDayResult.isEmpty) {
      return 0;
    }

    final latestDate = latestDayResult.first['latest_date'] as String;

    // Berechne die Serie rückwärts vom neuesten Tag
    final result = await db.rawQuery(
      '''
      WITH RECURSIVE streak_days AS (
        SELECT DATE(startedAt) as listen_date, 1 as streak
        FROM listen_logs
        WHERE DATE(startedAt) = ?
        
        UNION ALL
        
        SELECT DATE(l.startedAt), sd.streak + 1
        FROM listen_logs l
        JOIN streak_days sd ON DATE(l.startedAt) = DATE(sd.listen_date, '-1 day')
      )
      SELECT MAX(streak) as max_streak FROM streak_days
    ''',
      [latestDate],
    );

    final streak = result.first['max_streak'] as int? ?? 0;

    return streak;
  }

  // Get listen time for this week (Monday to Sunday)
  Future<int> getListenTimeForWeek() async {
    final db = _database!;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    final startStr = startOfWeek.toIso8601String().split('T')[0];
    final endStr = endOfWeek.toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      'SELECT SUM(minutes * 60 + seconds) as total_seconds FROM listen_logs WHERE DATE(startedAt) BETWEEN ? AND ?',
      [startStr, endStr],
    );
    final totalSeconds = result.first['total_seconds'] as int? ?? 0;
    return (totalSeconds / 60).ceil(); // Convert to minutes (always round up)
  }

  // Get listen time for this month
  Future<int> getListenTimeForMonth() async {
    final db = _database!;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final startStr = startOfMonth.toIso8601String().split('T')[0];
    final endStr = endOfMonth.toIso8601String().split('T')[0];

    final result = await db.rawQuery(
      'SELECT SUM(minutes * 60 + seconds) as total_seconds FROM listen_logs WHERE DATE(startedAt) >= ? AND DATE(startedAt) <= ?',
      [startStr, endStr],
    );
    final totalSeconds = result.first['total_seconds'] as int? ?? 0;
    return (totalSeconds / 60).ceil(); // Convert to minutes (always round up)
  }

  // Get total number of completed affirmations (finished entries)
  Future<int> getTotalAffirmations() async {
    final db = _database!;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM entries');
    return result.first['count'] as int? ?? 0;
  }

  // Get total number of recordings across all affirmations
  Future<int> getTotalRecordings() async {
    // Get all entries
    final entries = await getEntries();

    // Count only non-empty takes across all entries
    int totalTakes = 0;
    for (final entry in entries) {
      // Count only non-empty takes
      totalTakes += entry.takes.where((take) => take.isNotEmpty).length;
    }

    return totalTakes;
  }

  // Get recent listen logs (last 2)
  Future<List<ListenLog>> getRecentListenLogs({int limit = 2}) async {
    final db = _database!;
    final List<Map<String, dynamic>> maps = await db.query(
      'listen_logs',
      orderBy: 'startedAt DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) => ListenLog.fromJson(maps[i]));
  }

  // Get mood statistics
  Future<Map<String, int>> getMoodStatistics() async {
    final userPrefs = await getUserPrefs();
    final Map<String, int> moodCounts = {};

    for (final mood in userPrefs.moods) {
      moodCounts[mood.mood] = (moodCounts[mood.mood] ?? 0) + 1;
    }

    return moodCounts;
  }

  // Get recent activities (last 5 listen logs)
  Future<List<ListenLog>> getRecentActivities({int limit = 5}) async {
    return await getRecentListenLogs(limit: limit);
  }

  // Get total meditation sessions count
  Future<int> getTotalMeditationSessions() async {
    final db = _database!;
    final result = await db.query('listen_logs');
    return result.length;
  }

  // Get endless session count
  Future<int> getEndlessSessionCount() async {
    final db = _database!;
    final result = await db.query(
      'listen_logs',
      where: 'mode = ?',
      whereArgs: ['endless'],
    );
    return result.length;
  }

  // Get all badges (earned and unearned) based on user data
  Future<List<Map<String, dynamic>>> getEarnedBadges() async {
    final badges = <Map<String, dynamic>>[];

    // Get statistics
    final totalListenTime = await getTotalListenTime();
    final currentStreak = await getCurrentStreak();
    final totalAffirmations = await getTotalAffirmations();
    final totalMeditationSessions = await getTotalMeditationSessions();
    final endlessSessionCount = await getEndlessSessionCount();

    // 1. Anmeldung & Erste Schritte
    // Willkommen badge (always earned)
    badges.add({
      'id': 'welcome',
      'name': 'Willkommen',
      'description': 'App-Anmeldung abgeschlossen',
      'icon': 'person',
      'earned': true,
      'color': Colors.blue,
    });

    // Erste Affirmation
    badges.add({
      'id': 'first_affirmation',
      'name': 'Erste Affirmation',
      'description': 'Erste Affirmation aufgenommen',
      'icon': 'mic',
      'earned': totalAffirmations >= 1,
      'color': Colors.purple,
    });

    // Erste Meditation
    badges.add({
      'id': 'first_meditation',
      'name': 'Erste Meditation',
      'description': 'Erste Meditation abgeschlossen',
      'icon': 'play_arrow',
      'earned': totalListenTime > 0,
      'color': Colors.green,
    });

    // Erste Dauerschleife
    badges.add({
      'id': 'first_endless',
      'name': 'Erste Dauerschleife',
      'description': 'Erste Endlos-Session abgeschlossen',
      'icon': 'all_inclusive',
      'earned': endlessSessionCount >= 1,
      'color': Colors.cyan,
    });

    // 2. Streak-Badges (3-Tages-Schritte bis 30) - ALLE anzeigen
    final streakMilestones = [3, 6, 9, 12, 15, 18, 21, 24, 27, 30];
    final streakColors = [
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.teal,
      Colors.amber,
    ];

    for (int i = 0; i < streakMilestones.length; i++) {
      final days = streakMilestones[i];
      badges.add({
        'id': 'streak_$days',
        'name': '$days Tage Serie',
        'description': '$days Tage in Folge meditiert',
        'icon': 'local_fire_department',
        'earned': currentStreak >= days,
        'color': streakColors[i],
      });
    }

    // 3. Meditations-Meisterschaft
    badges.add({
      'id': 'master',
      'name': 'Meister',
      'description': '100 Meditationen abgeschlossen',
      'icon': 'emoji_events',
      'earned': totalMeditationSessions >= 100,
      'color': Colors.amber,
    });

    return badges;
  }

  // Get the highest earned badge
  Future<Map<String, dynamic>> getHighestEarnedBadge() async {
    final badges = await getEarnedBadges();

    // Filter only earned badges
    final earnedBadges = badges
        .where((badge) => badge['earned'] == true)
        .toList();

    // Return the last one (highest in hierarchy)
    if (earnedBadges.isNotEmpty) {
      return earnedBadges.last;
    }

    // Fallback to welcome badge if none earned (should never happen)
    return {
      'id': 'welcome',
      'name': 'Willkommen',
      'description': 'App-Anmeldung abgeschlossen',
      'icon': 'person',
      'earned': true,
      'color': Colors.blue,
    };
  }

  Future<void> clearAllData() async {
    final db = _database!;
    await db.delete('entries');
    await db.delete('draft_states');
    await db.delete('listen_logs');
    await db.delete('mood_logs');

    final prefs = _prefs!;
    await prefs.clear();
  }

  Future<void> close() async {
    await _database?.close();
  }
}
