import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/user_prefs.dart';
import '../models/entry.dart';
import '../models/draft_state.dart';
import '../models/listen_log.dart';
import '../providers/app_provider.dart';

/// Service responsible for syncing local data with Firebase (Firestore + Storage)
class SyncService {
  final Ref ref;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  // Firebase Storage instance (audio sync to be added in subsequent steps)
  // ignore: unused_field
  final _storage = FirebaseStorage.instance;

  SyncService(this.ref);

  bool get _syncEnabled => ref.read(userPrefsProvider).syncEnabled;
  User? get _user => _auth.currentUser;

  /// Perform a delta sync from cloud to local at app start/login
  Future<void> syncFromCloudDelta() async {
    final user = _user;
    if (user == null) return;

    try {
      // Always pull user prefs first (even if sync not yet enabled locally)
      await _pullUserPrefs(user.uid);

      // IMPORTANT: Re-read syncEnabled after _pullUserPrefs to ensure we have the updated state
      // This is crucial for reinstallation scenarios where cloud has syncEnabled: true
      final syncEnabled = ref.read(userPrefsProvider).syncEnabled;

      if (!syncEnabled) return;
      await _pullProfileImage(user.uid);
      await _pullEntriesDelta(user.uid);
      await _pullDraftStatesDelta(user.uid);
      await _pullListenLogsDelta(user.uid);
      await _pullMoodLogsDelta(user.uid);
      await ref
          .read(userPrefsProvider.notifier)
          .updateLastSyncAt(DateTime.now());
    } catch (e) {
      debugPrint('Sync from cloud failed: $e');
    }
  }

  // Full-Pull entfernt – Delta-Sync reicht aus

  /// Push local changes to cloud (can be called after local updates)
  Future<void> pushUserPrefsIfEnabled() async {
    if (!_syncEnabled) return;
    final user = _user;
    if (user == null) return;
    final prefs = ref.read(userPrefsProvider);
    try {
      final doc = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meta')
          .doc('user_prefs');
      await doc.set(
        _prefsToMap(prefs)..['updatedAt'] = FieldValue.serverTimestamp(),
        SetOptions(merge: true),
      );
      await ref
          .read(userPrefsProvider.notifier)
          .updateLastSyncAt(DateTime.now());
    } catch (e) {
      debugPrint('Push user prefs failed: $e');
    }
  }

  /// Push everything from local to cloud (if enabled)
  Future<void> pushAll() async {
    if (!_syncEnabled || _user == null) return;
    await pushUserPrefsIfEnabled();
    await pushProfileImage();
    await pushEntries();
    await pushDraftStates();
    await pushListenLogs();
    await pushMoodLogs();
  }

  Map<String, dynamic> _prefsToMap(UserPrefs prefs) => prefs.toJson();

  /// Check if sync prompt should be shown (checks both local and cloud)
  /// Returns true only if BOTH local and cloud have syncPromptShown: false
  Future<bool> shouldShowSyncPrompt() async {
    final user = _user;
    if (user == null) return false;

    // Check local first
    final local = ref.read(userPrefsProvider);
    if (local.syncPromptShown) {
      debugPrint('shouldShowSyncPrompt: false (local syncPromptShown: true)');
      return false;
    }

    // Check cloud
    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('meta')
          .doc('user_prefs')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final cloudSyncPromptShown = data['syncPromptShown'] as bool? ?? false;
        if (cloudSyncPromptShown) {
          debugPrint(
            'shouldShowSyncPrompt: false (cloud syncPromptShown: true)',
          );
          return false;
        }
      }
      // Cloud document doesn't exist or syncPromptShown: false
      debugPrint(
        'shouldShowSyncPrompt: true (both local and cloud syncPromptShown: false)',
      );
      return true;
    } catch (e) {
      debugPrint(
        'shouldShowSyncPrompt: Error checking cloud, defaulting to local check: $e',
      );
      // If cloud check fails, use local value (already checked above)
      return !local.syncPromptShown;
    }
  }

  Future<void> _pullUserPrefs(String uid) async {
    debugPrint('=== PULL USERPREFS DEBUG ===');
    final notifier = ref.read(userPrefsProvider.notifier);
    final local = ref.read(userPrefsProvider);
    debugPrint('Local syncEnabled: ${local.syncEnabled}');
    debugPrint('Local lastSyncAt: ${local.lastSyncAt}');

    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('meta')
        .doc('user_prefs')
        .get();
    if (!doc.exists) {
      debugPrint('No user_prefs document in cloud');
      return;
    }
    final data = doc.data()!;
    debugPrint('Cloud syncEnabled: ${data['syncEnabled']}');
    debugPrint('Cloud updatedAt: ${data['updatedAt']}');

    final cloudPrefs = UserPrefs.fromJson(data);

    final lastSyncAt = local.lastSyncAt;
    // If we never synced or cloud has newer updatedAt → replace/merge
    final cloudUpdatedAt = (data['updatedAt'] is Timestamp)
        ? (data['updatedAt'] as Timestamp).toDate()
        : null;

    // Special handling for first sync (reinstallation scenario):
    // If lastSyncAt is null AND local syncEnabled is false (default), always use cloud values
    // This ensures that on reinstallation, cloud syncEnabled: true is properly applied
    final isFirstSyncWithDefaults = lastSyncAt == null && !local.syncEnabled;
    final shouldApply =
        isFirstSyncWithDefaults ||
        lastSyncAt == null ||
        (cloudUpdatedAt != null && cloudUpdatedAt.isAfter(lastSyncAt));

    debugPrint(
      'shouldApply: $shouldApply (isFirstSyncWithDefaults=$isFirstSyncWithDefaults, lastSyncAt=$lastSyncAt, cloudUpdatedAt=$cloudUpdatedAt)',
    );
    if (shouldApply) {
      // Cloud is newer or first sync → use cloud values (including syncEnabled)
      // Cloud is source of truth for sync state after initial setup
      debugPrint(
        'Applying cloud data (cloud is newer or first sync), syncEnabled from cloud: ${cloudPrefs.syncEnabled}',
      );
      await notifier.replaceAll(cloudPrefs);
      await notifier.updateLastSyncAt(DateTime.now());
      debugPrint(
        'Merged userPrefs, syncEnabled after merge: ${cloudPrefs.syncEnabled}, syncPromptShown: ${cloudPrefs.syncPromptShown}',
      );
    } else {
      debugPrint('Not applying cloud changes (local is newer or same)');
    }
  }

  // -------- Entries (with audio) --------
  CollectionReference<Map<String, dynamic>> _entriesCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('entries');

  Future<void> pushEntries() async {
    if (!_syncEnabled || _user == null) return;
    final uid = _user!.uid;
    final storage = ref.read(storageServiceProvider);
    final entries = await storage.getEntries();
    for (final entry in entries) {
      final doc = _entriesCol(uid).doc(entry.id);
      final takesHashes = <String>[];
      for (int i = 0; i < entry.takes.length; i++) {
        final p = entry.takes[i];
        if (p.isEmpty) {
          takesHashes.add('');
          continue;
        }
        final file = File(p);
        if (await file.exists()) {
          final hash = await _hashOfFile(file);
          takesHashes.add(hash);
          final refPath = 'users/$uid/audio/${entry.id}/$i.m4a';
          final ref = _storage.ref(refPath);
          try {
            await ref.putFile(file);
          } catch (e) {
            debugPrint('Audio upload failed $refPath: $e');
          }
        } else {
          takesHashes.add('');
        }
      }
      await doc.set({
        ...entry.toJson(),
        'takesHashes': takesHashes,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _pullEntriesDelta(String uid) async {
    final storage = ref.read(storageServiceProvider);
    final lastSyncAt = ref.read(userPrefsProvider).lastSyncAt;
    Query<Map<String, dynamic>> q = _entriesCol(uid);
    if (lastSyncAt != null) {
      q = q.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncAt));
    }
    final snap = await q.get();
    for (final d in snap.docs) {
      final data = Map<String, dynamic>.from(d.data());
      // Normalize Timestamp fields to ISO strings for our local models
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      if (data['updatedAt'] is Timestamp) {
        data['updatedAt'] = (data['updatedAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      try {
        var entry = Entry.fromJson(data);
        debugPrint('Processing entry ${entry.id}');
        // Try to download audio files if hashes present
        final List<dynamic>? hashes = data['takesHashes'] as List<dynamic>?;
        if (hashes != null) {
          debugPrint(
            'Found ${hashes.length} audio hashes for entry ${entry.id}',
          );
          final docsDir = await getApplicationDocumentsDirectory();
          final baseDir = p.join(docsDir.path, 'audio', entry.id);
          final newTakes = List<String>.from(entry.takes);
          for (int i = 0; i < hashes.length; i++) {
            final hash = (hashes[i] ?? '') as String;
            if (hash.isEmpty) {
              if (i < newTakes.length) newTakes[i] = '';
              continue;
            }
            final filePath = p.join(baseDir, '$i.m4a');
            final file = File(filePath);
            bool needDownload = !(await file.exists());
            if (!needDownload) {
              final localHash = await _hashOfFile(file);
              needDownload = localHash != hash;
            }
            if (needDownload) {
              try {
                debugPrint('Downloading audio ${entry.id}#$i from cloud...');
                await file.parent.create(recursive: true);
                final refPath = 'users/$uid/audio/${entry.id}/$i.m4a';
                final audioData = await _storage.ref(refPath).getData();
                if (audioData != null) {
                  await file.writeAsBytes(audioData, flush: true);
                  debugPrint('Successfully downloaded audio ${entry.id}#$i');
                } else {
                  debugPrint('No audio data found for ${entry.id}#$i');
                }
              } catch (e) {
                debugPrint('Audio download failed for ${entry.id}#$i: $e');
              }
            } else {
              debugPrint(
                'Audio ${entry.id}#$i already up to date (hash match)',
              );
            }
            if (i < newTakes.length) {
              newTakes[i] = filePath;
            } else {
              newTakes.add(filePath);
            }
          }
          entry = entry.copyWith(takes: newTakes);
        }
        await storage.saveEntry(entry); // persist possibly updated takes paths
      } catch (e) {
        debugPrint('Skip invalid entry ${d.id}: $e');
      }
    }
  }

  // Full-Pull Entries entfernt

  // -------- Draft States --------
  CollectionReference<Map<String, dynamic>> _draftsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('draft_states');

  Future<void> pushDraftStates() async {
    if (!_syncEnabled || _user == null) {
      debugPrint(
        'Draft states push skipped: syncEnabled=$_syncEnabled, user=${_user != null}',
      );
      return;
    }
    final uid = _user!.uid;
    final storage = ref.read(storageServiceProvider);
    final drafts = await storage.getAllDraftStates();
    debugPrint('Pushing ${drafts.length} draft states to Firebase');
    for (final draft in drafts) {
      debugPrint(
        'Pushing draft ${draft.entryId}: nextIndex=${draft.nextIndex}, title=${draft.title}',
      );
      final draftJson = draft.toJson();
      debugPrint('Draft JSON nextIndex: ${draftJson['nextIndex']}');
      final doc = _draftsCol(uid).doc(draft.entryId);
      await doc.set({
        ...draftJson,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Draft ${draft.entryId} pushed successfully');
    }
  }

  Future<void> _pullDraftStatesDelta(String uid) async {
    final storage = ref.read(storageServiceProvider);
    final lastSyncAt = ref.read(userPrefsProvider).lastSyncAt;
    Query<Map<String, dynamic>> q = _draftsCol(uid);
    if (lastSyncAt != null) {
      q = q.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncAt));
    }
    final snap = await q.get();
    for (final d in snap.docs) {
      final data = Map<String, dynamic>.from(d.data());
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      if (data['updatedAt'] is Timestamp) {
        data['updatedAt'] = (data['updatedAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      try {
        final draft = DraftState.fromJson(data);
        await storage.saveDraftState(draft);
      } catch (e) {
        debugPrint('Skip invalid draft ${d.id}: $e');
      }
    }
  }

  // Full-Pull DraftStates entfernt

  // -------- Listen Logs --------
  CollectionReference<Map<String, dynamic>> _logsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('listen_logs');

  String _logId(ListenLog log) =>
      '${log.entryId}_${log.startedAt.millisecondsSinceEpoch}';

  Future<void> pushListenLogs() async {
    if (!_syncEnabled || _user == null) return;
    final uid = _user!.uid;
    final storage = ref.read(storageServiceProvider);
    final logs = await storage.getListenLogs();
    for (final log in logs) {
      final doc = _logsCol(uid).doc(_logId(log));
      await doc.set({
        ...log.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _pullListenLogsDelta(String uid) async {
    final storage = ref.read(storageServiceProvider);
    final lastSyncAt = ref.read(userPrefsProvider).lastSyncAt;
    Query<Map<String, dynamic>> q = _logsCol(uid);
    if (lastSyncAt != null) {
      q = q.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncAt));
    }
    final snap = await q.get();
    for (final d in snap.docs) {
      try {
        final data = Map<String, dynamic>.from(d.data());
        if (data['startedAt'] is Timestamp) {
          data['startedAt'] = (data['startedAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        if (data['endedAt'] is Timestamp) {
          data['endedAt'] = (data['endedAt'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        final log = ListenLog.fromJson(data);
        await storage.saveListenLog(log);
      } catch (e) {
        debugPrint('Skip invalid log ${d.id}: $e');
      }
    }
  }

  // Full-Pull ListenLogs entfernt

  // -------- Mood Logs --------
  CollectionReference<Map<String, dynamic>> _moodsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('mood_logs');

  String _moodId(MoodEntry m) => m.date.toIso8601String().split('T').first;

  Future<void> pushMoodLogs() async {
    if (!_syncEnabled || _user == null) return;
    final uid = _user!.uid;
    final storage = ref.read(storageServiceProvider);
    final prefs = await storage.getUserPrefs();
    for (final m in prefs.moods) {
      final doc = _moodsCol(uid).doc(_moodId(m));
      await doc.set({
        ...m.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _pullMoodLogsDelta(String uid) async {
    final storage = ref.read(storageServiceProvider);
    final lastSyncAt = ref.read(userPrefsProvider).lastSyncAt;
    Query<Map<String, dynamic>> q = _moodsCol(uid);
    if (lastSyncAt != null) {
      q = q.where('updatedAt', isGreaterThan: Timestamp.fromDate(lastSyncAt));
    }
    final snap = await q.get();
    if (snap.docs.isEmpty) return;
    // merge moods into userPrefs
    final prefs = await storage.getUserPrefs();
    final current = prefs.moods;
    final add = snap.docs
        .map((d) => MoodEntry.fromJson(d.data()))
        .where((m) => current.every((e) => e.date != m.date))
        .toList();
    if (add.isNotEmpty) {
      await ref
          .read(userPrefsProvider.notifier)
          .replaceAll(prefs.copyWith(moods: [...current, ...add]));
    }
  }

  // Full-Pull MoodLogs entfernt

  // -------- Profile Image --------
  Future<void> pushProfileImage() async {
    if (!_syncEnabled || _user == null) {
      debugPrint(
        'Profile image push skipped: syncEnabled=$_syncEnabled, user=${_user != null}',
      );
      return;
    }
    final uid = _user!.uid;
    final prefs = ref.read(userPrefsProvider);

    debugPrint('Pushing profile image for user $uid');
    debugPrint('Local profileImagePath: ${prefs.profileImagePath}');

    try {
      if (prefs.profileImagePath != null &&
          prefs.profileImagePath!.isNotEmpty) {
        final file = File(prefs.profileImagePath!);
        debugPrint('Checking if file exists: ${file.path}');
        if (await file.exists()) {
          debugPrint('File exists, uploading to Firebase Storage...');
          // Upload to Firebase Storage
          final refPath =
              'users/$uid/profile/profile_image${p.extension(prefs.profileImagePath!)}';
          final storageRef = _storage.ref(refPath);
          await storageRef.putFile(file);

          // Get download URL
          final downloadUrl = await storageRef.getDownloadURL();
          debugPrint('Upload successful, download URL: $downloadUrl');

          // Save URL to Firestore (in user_prefs document)
          final doc = _firestore
              .collection('users')
              .doc(uid)
              .collection('meta')
              .doc('user_prefs');
          await doc.set({
            'profileImageUrl': downloadUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          debugPrint(
            'Profile image uploaded successfully and URL saved to Firestore',
          );
        } else {
          debugPrint('Profile image file does not exist at path: ${file.path}');
        }
      } else {
        debugPrint('No profile image path set, removing from cloud if exists');
        // No profile image - remove from cloud if exists
        final doc = _firestore
            .collection('users')
            .doc(uid)
            .collection('meta')
            .doc('user_prefs');
        await doc.set({
          'profileImageUrl': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Push profile image failed: $e');
    }
  }

  Future<void> _pullProfileImage(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('meta')
          .doc('user_prefs')
          .get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final profileImageUrl = data['profileImageUrl'] as String?;

      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        try {
          // Download directly from URL using HTTP
          final httpClient = HttpClient();
          final request = await httpClient.getUrl(Uri.parse(profileImageUrl));
          final response = await request.close();

          if (response.statusCode == 200) {
            final bytes = await response.expand((chunk) => chunk).toList();

            // Save to local file
            final docsDir = await getApplicationDocumentsDirectory();
            final fileName = 'profile_synced.png';
            final localPath = p.join(docsDir.path, fileName);
            final file = File(localPath);
            await file.writeAsBytes(bytes, flush: true);

            // Update local path in UserPrefs
            await ref
                .read(userPrefsProvider.notifier)
                .updateProfileImage(localPath);
            debugPrint('Profile image downloaded successfully: $localPath');
          }
          httpClient.close();
        } catch (e) {
          debugPrint('Profile image download failed: $e');
        }
      } else {
        // No profile image in cloud - clear local if exists
        final currentPrefs = ref.read(userPrefsProvider);
        if (currentPrefs.profileImagePath != null) {
          await ref.read(userPrefsProvider.notifier).updateProfileImage(null);
        }
      }
    } catch (e) {
      debugPrint('Pull profile image failed: $e');
    }
  }

  // -------- Helpers --------
  Future<String> _hashOfFile(File file) async {
    final stat = await file.stat();
    return '${stat.size}_${stat.modified.millisecondsSinceEpoch}';
  }
}

// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));
