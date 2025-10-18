import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../screens/entry_player_screen.dart';

void _showRecentlyPlayedInfo(BuildContext context, WidgetRef ref) {
  final moodTheme = ref.watch(currentMoodThemeProvider);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: moodTheme.cardColor.withValues(alpha: 0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: moodTheme.accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      title: Row(
        children: [
          Icon(Icons.info_outline, color: moodTheme.accentColor, size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'ZULETZT ABGESPIELT',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'Hier findest du deine letzten beiden Meditationssitzungen.\n\n'
        'Du siehst:\n\n'
        '• Welches Level du gewählt hast\n'
        '• Welche Kategorie du bearbeitet hast\n'
        '• Welchen Modus du genutzt hast\n\n'
        'So behältst du einen schnellen Überblick über deine jüngsten Sessions. 🎧',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Verstanden',
            style: GoogleFonts.poppins(
              color: moodTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class RecentlyPlayed extends ConsumerWidget {
  const RecentlyPlayed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentLogs = ref.watch(recentListenLogsProvider);
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodTheme.cardColor.withValues(alpha: 0.75),
            moodTheme.cardColor.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: moodTheme.accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: moodTheme.accentColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.cardPadding + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ZULETZT ABGESPIELT',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showRecentlyPlayedInfo(context, ref),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            recentLogs.when(
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      'Noch keine Einträge',
                      style: AppTheme.bodyStyle.copyWith(color: Colors.white70),
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildRecentEntry(
                        context,
                        logs.isNotEmpty ? logs[0] : null,
                      ),
                    ),
                    if (logs.length > 1) ...[
                      const SizedBox(width: 12),
                      Expanded(child: _buildRecentEntry(context, logs[1])),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Fehler beim Laden',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEntry(BuildContext context, dynamic log) {
    if (log == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'Keine Daten',
            style: AppTheme.captionStyle.copyWith(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _onEntryTap(context, log),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.25),
              Colors.white.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getLevelDisplayName(log.level),
              style: AppTheme.captionStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getCategoryDisplayName(log.category),
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getModeDisplayName(log.mode),
              style: AppTheme.captionStyle.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onEntryTap(BuildContext context, dynamic log) async {
    // Lade die vollständige Entry anhand der entryId
    final storageService = StorageService();
    final entry = await storageService.getEntry(log.entryId);

    if (entry != null) {
      // Navigiere zum EntryPlayerScreen
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EntryPlayerScreen(entry: entry),
          ),
        );
      }
    } else {
      // Zeige Fehlermeldung wenn Entry nicht gefunden wurde
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eintrag konnte nicht gefunden werden'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getLevelDisplayName(String level) {
    switch (level) {
      case 'beginner':
        return 'Anfänger';
      case 'advanced':
        return 'Fortgeschritten';
      case 'open':
        return 'Offen';
      default:
        return level;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'selbstbewusstsein':
        return 'Selbstbewusstsein';
      case 'selbstwert':
        return 'Selbstwert';
      case 'aengste':
        return 'Ängste lösen';
      case 'custom':
        return 'Eigene Ziele';
      default:
        return category;
    }
  }

  String _getModeDisplayName(String mode) {
    switch (mode) {
      case 'meditation':
        return 'Meditation';
      case 'endless':
        return 'Dauerschleife';
      default:
        return mode;
    }
  }
}
