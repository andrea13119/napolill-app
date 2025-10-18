import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../providers/app_provider.dart';

class BadgeCongratulationsDialog extends ConsumerWidget {
  final Map<String, dynamic> badge;

  const BadgeCongratulationsDialog({super.key, required this.badge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              moodTheme.cardColor,
              moodTheme.cardColor.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: moodTheme.accentColor.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: moodTheme.accentColor.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Congratulations Text
            Text(
              'HERZLICHEN GLÜCKWUNSCH!',
              style: AppTheme.headingStyle.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: moodTheme.accentColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Badge Icon with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          moodTheme.accentColor.withValues(alpha: 0.3),
                          moodTheme.accentColor.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: moodTheme.accentColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getIconData(badge['icon'] as String),
                      size: 50,
                      color: moodTheme.accentColor,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Badge Name
            Text(
              badge['name'] as String,
              style: AppTheme.headingStyle.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Badge Description
            Text(
              badge['description'] as String,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Continue Button
            ElevatedButton(
              onPressed: () {
                ref.read(badgeNotificationProvider.notifier).clearBadge();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: moodTheme.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: Text(
                'WEITER',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'mic':
        return Icons.mic;
      case 'play_arrow':
        return Icons.play_arrow;
      case 'all_inclusive':
        return Icons.all_inclusive;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'emoji_events':
        return Icons.emoji_events;
      default:
        return Icons.emoji_events;
    }
  }
}
