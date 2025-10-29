import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/intro_screen.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'services/audio_service.dart';
import 'utils/app_theme.dart';

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
      home: const IntroScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
