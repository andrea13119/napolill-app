import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _zoomController;
  late AnimationController _fadeController;
  late Animation<double> _zoomAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _zoomController = AnimationController(
      duration: AppConstants.introAnimationDuration,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _zoomAnimation = Tween<double>(
      begin: 0.9,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _zoomController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 1.0, // Logo sofort sichtbar
      end: 1.0, // Bleibt sichtbar
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _startAnimation();
  }

  void _startAnimation() async {
    // Start both animations simultaneously
    _zoomController.forward();
    _fadeController.forward();

    // Wait for zoom animation to complete
    await _zoomController.forward();

    // Wait a bit before navigating
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    // Warte auf den ersten Auth-State Wert (Firebase Session wird geladen)
    // Dies stellt sicher, dass Firebase die gespeicherte Session geladen hat
    await ref.read(authStateProvider.future);

    if (!mounted) return; // Prüfe ob Widget noch mounted ist

    // Warte darauf, dass die UserPrefs geladen sind
    // Dies stellt sicher, dass die Onboarding-Flags korrekt gelesen werden
    await ref.read(userPrefsLoadedProvider.future);

    if (!mounted) return; // Prüfe nochmal ob Widget noch mounted ist

    // Jetzt kann sicher der Auth-Status und die UserPrefs geprüft werden
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    final userPrefs = ref.read(userPrefsProvider);

    if (!isAuthenticated) {
      // User not authenticated - go to AuthScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    } else if (!userPrefs.consentAccepted ||
        !userPrefs.privacyAccepted ||
        !userPrefs.agbAccepted) {
      // User authenticated but hasn't completed onboarding - go to OnboardingScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else {
      // User authenticated and onboarding completed - go to HomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_zoomAnimation, _fadeAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _zoomAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Center(
                  child: Image.asset(
                    'assets/animations/intro.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
