import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../services/sync_service.dart';
import '../utils/mood_theme.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = 'Bitte fülle alle Felder aus';
          _isLoading = false;
        });
        return;
      }

      final authService = ref.read(authServiceProvider);
      bool isNewUser = false;

      if (_isSignUp) {
        await authService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        // New account created
        isNewUser = true;
        // Update display name if provided
        if (_displayNameController.text.trim().isNotEmpty) {
          final displayName = _displayNameController.text.trim();
          await authService.updateDisplayName(displayName);
          // Also save to UserPrefs so it gets synced
          await ref.read(userPrefsProvider.notifier).updateDisplayName(displayName);
        }
      } else {
        await authService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Existing user signed in
        isNewUser = false;
      }

      // For existing users, perform cloud sync before navigation
      if (!isNewUser && mounted) {
        setState(() {
          _isSyncing = true;
        });
        
        try {
          debugPrint('AuthScreen: Performing cloud sync after login');
          await ref.read(syncServiceProvider).syncFromCloudDelta();
          debugPrint('AuthScreen: Cloud sync completed');
        } catch (e) {
          debugPrint('AuthScreen: Cloud sync failed: $e');
          // Continue even if sync fails
        } finally {
          if (mounted) {
            setState(() {
              _isSyncing = false;
            });
          }
        }
      }

      if (mounted) {
        // Navigate based on whether user is new or existing
        if (isNewUser) {
          // New user - go to onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } else {
          // Existing user - go to home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final userCredential = await authService.signInWithGoogle();

      if (userCredential == null) {
        // User canceled the sign-in
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check if this is a new user (first time signing in with Google)
      // For Google Sign-In, we need to check additionalUserInfo.isNewUser
      // Since we don't have access to additionalUserInfo here, we'll use a heuristic:
      // If the user was just created (metadata creation time is recent), treat as new
      final user = userCredential.user;
      final isNewUser =
          (user?.metadata.creationTime
                  ?.difference(DateTime.now())
                  .abs()
                  .inSeconds ??
              999) <
          5;

      // For existing users, perform cloud sync before navigation
      if (!isNewUser && mounted) {
        setState(() {
          _isSyncing = true;
        });
        
        try {
          debugPrint('AuthScreen: Performing cloud sync after Google login');
          await ref.read(syncServiceProvider).syncFromCloudDelta();
          debugPrint('AuthScreen: Cloud sync completed');
        } catch (e) {
          debugPrint('AuthScreen: Cloud sync failed: $e');
          // Continue even if sync fails
        } finally {
          if (mounted) {
            setState(() {
              _isSyncing = false;
            });
          }
        }
      }

      if (mounted) {
        // Navigate based on whether user is new or existing
        if (isNewUser) {
          // New user - go to onboarding
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } else {
          // Existing user - go to home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodTheme = MoodTheme.standard; // Neutral theme for auth

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: moodTheme.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo_napolill.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 48),

                  // Title
                  Text(
                    _isSignUp ? 'Konto erstellen' : 'Anmelden',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: 16),

                  // Display name (only for sign up)
                  if (_isSignUp)
                    TextField(
                      controller: _displayNameController,
                      style: GoogleFonts.poppins(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Anzeigename',
                        labelStyle: GoogleFonts.poppins(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: moodTheme.accentColor),
                        ),
                      ),
                    ),
                  if (_isSignUp) const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'E-Mail',
                      labelStyle: GoogleFonts.poppins(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: moodTheme.accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      labelStyle: GoogleFonts.poppins(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: moodTheme.accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign in/up button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: moodTheme.accentColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_isSyncing) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Daten werden synchronisiert...',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Text(
                              _isSignUp ? 'Konto erstellen' : 'Anmelden',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Social sign in
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google
                      IconButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          height: 40,
                          width: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.g_mobiledata, size: 40),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Toggle sign in/sign up
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isSignUp
                          ? 'Bereits ein Konto? Anmelden'
                          : 'Noch kein Konto? Erstellen',
                      style: GoogleFonts.poppins(
                        color: moodTheme.accentColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
