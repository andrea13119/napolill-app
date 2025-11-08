import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';

// Custom euphorisch theme colors for completion screen
class CompletionTheme {
  static const Color primaryGold = Color(0xFFFFD700); // Warmes Gold
  static const Color accentOrange = Color(0xFFFF6B35); // Leuchtendes Orange
  static const Color deepPurple = Color(0xFF6A0DAD); // Warmes Lila
  static const Color lightPurple = Color(0xFF9D4EDD); // Helles Lila

  static const RadialGradient backgroundGradient = RadialGradient(
    center: Alignment.topCenter,
    radius: 1.2,
    colors: [deepPurple, accentOrange],
    stops: [0.0, 1.0],
  );
}

class CompletionScreen extends ConsumerWidget {
  final String mode; // 'meditation' or 'endless'
  final Duration sessionDuration;
  final bool isEarlyCompletion;

  const CompletionScreen({
    super.key,
    required this.mode,
    required this.sessionDuration,
    this.isEarlyCompletion = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: CompletionTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with logo
              _buildHeader(),

              // Main content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Sparkle icon
                        _buildSparkleIcon(),

                        const SizedBox(height: 30),

                        // Congratulatory message
                        _buildCongratulatoryMessage(),

                        const SizedBox(height: 40),

                        // Completed stamp
                        _buildCompletedStamp(),

                        const SizedBox(height: 50),

                        // Motivational message
                        _buildMotivationalMessage(),

                        const SizedBox(height: 60),

                        // Action buttons
                        _buildActionButtons(context, ref),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Image.asset(
          'assets/images/logo_napolill.png',
          height: 80,
          width: 200,
        ),
      ),
    );
  }

  Widget _buildSparkleIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CompletionTheme.primaryGold, CompletionTheme.accentOrange],
        ),
        boxShadow: [
          BoxShadow(
            color: CompletionTheme.primaryGold.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: const Icon(Icons.star, size: 60, color: Colors.white),
    );
  }

  Widget _buildCongratulatoryMessage() {
    return Column(
      children: [
        Text(
          'HERZLICHEN',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: CompletionTheme.primaryGold,
            fontFamily: 'Poppins',
            shadows: [
              Shadow(
                color: CompletionTheme.primaryGold.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        Text(
          'GLÜCKWUNSCH!',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: CompletionTheme.primaryGold,
            fontFamily: 'Poppins',
            shadows: [
              Shadow(
                color: CompletionTheme.primaryGold.withValues(alpha: 0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedStamp() {
    return Transform.rotate(
      angle: 0.1, // Slight rotation like in the image
      child: Image.asset(
        'assets/images/completion_button.png',
        width: 300,
        height: 150,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildMotivationalMessage() {
    return Column(
      children: [
        Text(
          'NOCH EIN SCHRITT',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          'NÄHER ZU DEINEM',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          'NEUEN ICH',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Session info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: CompletionTheme.primaryGold.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Text(
              _getSessionInfo(),
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 30),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Refresh statistics before navigating
                ref
                    .read(statisticsNotifierProvider.notifier)
                    .refreshStatistics();

                // Navigate directly to home screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(initialTabIndex: 0),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CompletionTheme.primaryGold,
                foregroundColor: CompletionTheme.deepPurple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 12,
                shadowColor: CompletionTheme.primaryGold.withValues(alpha: 0.6),
              ),
              child: Text(
                'WEITER',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSessionInfo() {
    debugPrint('=== COMPLETION SCREEN SESSION INFO ===');
    debugPrint('Mode: $mode');
    debugPrint('Session duration: ${sessionDuration.inSeconds}s');
    debugPrint('Formatted duration: ${_formatDuration(sessionDuration)}');

    if (mode == 'meditation') {
      return 'Meditation abgeschlossen • ${_formatDuration(sessionDuration)}';
    } else {
      return 'Dauerschleife beendet • ${_formatDuration(sessionDuration)}';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
