import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_prefs.dart';
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
    if (!_syncEnabled) return;
    final user = _user;
    if (user == null) return;

    try {
      // Sync user prefs first
      await _pullUserPrefs(user.uid);
      // TODO: entries, draft_states, listen_logs, mood_logs and audio files
    } catch (e) {
      debugPrint('Sync from cloud failed: $e');
    }
  }

  /// Push local changes to cloud (can be called after local updates)
  Future<void> pushUserPrefsIfEnabled() async {
    if (!_syncEnabled) return;
    final user = _user;
    if (user == null) return;
    final prefs = ref.read(userPrefsProvider);
    try {
      final doc = _firestore.collection('users').doc(user.uid).collection('meta').doc('user_prefs');
      await doc.set(_prefsToMap(prefs)..['updatedAt'] = FieldValue.serverTimestamp(), SetOptions(merge: true));
      await ref.read(userPrefsProvider.notifier).updateLastSyncAt(DateTime.now());
    } catch (e) {
      debugPrint('Push user prefs failed: $e');
    }
  }

  Map<String, dynamic> _prefsToMap(UserPrefs prefs) => prefs.toJson();

  Future<void> _pullUserPrefs(String uid) async {
    final notifier = ref.read(userPrefsProvider.notifier);
    final local = ref.read(userPrefsProvider);
    final doc = await _firestore.collection('users').doc(uid).collection('meta').doc('user_prefs').get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final cloudPrefs = UserPrefs.fromJson(data);

    final lastSyncAt = local.lastSyncAt;
    // If we never synced or cloud has newer updatedAt → replace/merge
    final cloudUpdatedAt = (data['updatedAt'] is Timestamp)
        ? (data['updatedAt'] as Timestamp).toDate()
        : null;

    final shouldApply = lastSyncAt == null || (cloudUpdatedAt != null && cloudUpdatedAt.isAfter(lastSyncAt));
    if (shouldApply) {
      // Keep local syncEnabled choice, prefer cloud for the rest
      final merged = cloudPrefs.copyWith(syncEnabled: local.syncEnabled);
      await notifier.replaceAll(merged);
      await notifier.updateLastSyncAt(DateTime.now());
    }
  }
}

// Provider for SyncService
final syncServiceProvider = Provider<SyncService>((ref) => SyncService(ref));


