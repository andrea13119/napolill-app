import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/intro_screen.dart';
import 'services/storage_service.dart';
import 'services/audio_service.dart';
import 'utils/app_theme.dart';
import 'services/sync_service.dart';
import 'providers/auth_provider.dart';
import 'providers/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize services
  final storageService = StorageService();
  await storageService.initialize();

  // Initialize audio service
  final audioService = AudioService();
  await audioService.initialize();

  // Reset user preferences for testing (remove this line when done testing)
  // await storageService.saveUserPrefs(UserPrefs.reset());

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Napolill',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SyncBootstrapper(child: IntroScreen()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SyncBootstrapper extends ConsumerStatefulWidget {
  final Widget child;
  const SyncBootstrapper({super.key, required this.child});

  @override
  ConsumerState<SyncBootstrapper> createState() => _SyncBootstrapperState();
}

class _SyncBootstrapperState extends ConsumerState<SyncBootstrapper> {
  String? _syncedUserId; // Track which user we've already synced

  @override
  void initState() {
    super.initState();
    // Check initial auth state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null && _syncedUserId != currentUser.uid) {
        debugPrint(
          '_SyncBootstrapper: Initial user detected in initState (uid: ${currentUser.uid})',
        );
        _runInitialSync();
      }
    });
  }

  Future<void> _runInitialSync() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      debugPrint('_runInitialSync: User is null, skipping');
      return;
    }

    // Prevent multiple syncs for same user
    if (_syncedUserId != null && _syncedUserId == user.uid) {
      debugPrint(
        '_runInitialSync: Already synced for this user, skipping (uid: ${user.uid})',
      );
      return;
    }

    debugPrint('_runInitialSync: Starting sync for user ${user.uid}');
    try {
      await ref.read(syncServiceProvider).syncFromCloudDelta();
      final prefs = ref.read(userPrefsProvider);
      debugPrint(
        '_runInitialSync: After pull, syncEnabled=${prefs.syncEnabled}',
      );

      _syncedUserId = user.uid;

      if (prefs.syncEnabled) {
        debugPrint('_runInitialSync: syncEnabled is true, skipping popup');
        return;
      }

      debugPrint('_runInitialSync: syncEnabled is false, checking for popup');
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPrompt());
    } catch (e) {
      debugPrint('Initial sync failed: $e');
      _syncedUserId = user.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPrompt());
    }
  }

  Future<void> _maybeShowPrompt() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final shouldShow = await ref
        .read(syncServiceProvider)
        .shouldShowSyncPrompt();
    if (!shouldShow) return;

    if (!mounted) return;

    final enabled = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Daten synchronisieren?'),
        content: const Text(
          'Möchtest du deine Daten mit Firebase für Gerätewechsel und Mehrgeräte-Nutzung synchronisieren? Du kannst das später in den Einstellungen ändern.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nur lokal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Synchronisieren'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    await ref.read(userPrefsProvider.notifier).setSyncPromptShown();

    if (enabled == true) {
      await ref.read(userPrefsProvider.notifier).updateSyncEnabled(true);
      await ref.read(syncServiceProvider).pushUserPrefsIfEnabled();
      await ref.read(syncServiceProvider).syncFromCloudDelta();
    } else {
      await ref.read(userPrefsProvider.notifier).updateSyncEnabled(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state and trigger sync when user logs in
    ref.listen(authStateProvider, (previous, next) {
      debugPrint(
        '_SyncBootstrapper: listen() called - previous=${previous?.value?.uid}, next.hasValue=${next.hasValue}, next.value=${next.value?.uid}',
      );

      if (!next.hasValue) return;

      final nextUser = next.value;
      final previousUser = (previous?.hasValue == true)
          ? previous!.value
          : null;

      if (nextUser != null && previousUser?.uid != nextUser.uid) {
        debugPrint(
          '_SyncBootstrapper: User changed via listen, triggering sync (previous: ${previousUser?.uid}, next: ${nextUser.uid})',
        );
        _runInitialSync();
      }
    });

    return widget.child;
  }
}
