import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/intro_screen.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
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

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

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
  @override
  void initState() {
    super.initState();
    _runInitialSync();
    // Also run after login changes
    ref.listen(currentUserProvider, (_, __) {
      _runInitialSync();
    });
  }

  Future<void> _runInitialSync() async {
    try {
      await ref.read(syncServiceProvider).syncFromCloudDelta();
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowPrompt());
    } catch (_) {}
  }

  Future<void> _maybeShowPrompt() async {
    final prefs = ref.read(userPrefsProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    if (prefs.syncPromptShown) return;

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

    await ref.read(userPrefsProvider.notifier).setSyncPromptShown();
    if (enabled == true) {
      await ref.read(userPrefsProvider.notifier).updateSyncEnabled(true);
      await ref.read(syncServiceProvider).syncFromCloudDelta();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
