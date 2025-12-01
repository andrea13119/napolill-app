import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../services/sync_service.dart';
import '../providers/navigation_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/mood_theme.dart';
import '../widgets/mood_check.dart';
import '../widgets/recently_played.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/badge_congratulations_dialog.dart';
import 'media_library_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int? initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isDialogShowing =
      false; // Flag um zu verhindern, dass Dialog mehrfach angezeigt wird

  bool get _isHomeRouteActive {
    final route = ModalRoute.of(context);
    return route?.isCurrent ?? false;
  }

  @override
  void initState() {
    super.initState();
    // Set navigation to specified tab when HomeScreen is initialized
    if (widget.initialTabIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(navigationProvider.notifier)
            .setCurrentIndex(widget.initialTabIndex!);
      });
    }
    // Show sync prompt on first arrival to Home
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowSyncPrompt());

    // Prüfe nach dem ersten Frame, ob bereits ein Badge wartet
    // Dies ist wichtig, wenn man direkt vom completion_screen kommt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForPendingBadge();
    });

    // Zusätzlicher Check nach einer kurzen Verzögerung, falls der Badge später gesetzt wird
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isDialogShowing) {
        _checkForPendingBadge();
      }
    });
  }

  void _checkForPendingBadge() {
    if (_isDialogShowing || !mounted || !_isHomeRouteActive) return;

    final navigationState = ref.read(navigationProvider);
    final currentIndex = navigationState.currentIndex;
    final badge = ref.read(badgeNotificationProvider);

    // Nur anzeigen, wenn wir auf Tab 0 sind und ein Badge wartet
    if (currentIndex == 0 && badge != null) {
      _isDialogShowing = true;
      // Badge sofort löschen
      ref.read(badgeNotificationProvider.notifier).clearBadge();
      // Dialog erst nach dem nächsten Frame anzeigen, um "widget tree locked" Fehler zu vermeiden
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isDialogShowing) {
          _showBadgeCongratulationsDialog(context, badge);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final statistics = ref.watch(statisticsProvider);
    final navigationState = ref.watch(navigationProvider);
    final currentIndex = navigationState.currentIndex;

    // Listen for badge notifications - nur auf Home-Seite (Tab 0) anzeigen
    ref.listen<Map<String, dynamic>?>(badgeNotificationProvider, (
      previous,
      next,
    ) {
      // Nur anzeigen, wenn:
      // 1. Ein Badge vorhanden ist (next != null)
      // 2. Wir auf der Home-Seite sind (currentIndex == 0)
      // 3. Die Home-Route sichtbar ist
      // 4. Der vorherige Wert null war (um mehrfaches Anzeigen zu vermeiden)
      // 5. Kein Dialog bereits angezeigt wird
      if (next != null &&
          currentIndex == 0 &&
          _isHomeRouteActive &&
          previous == null &&
          !_isDialogShowing) {
        _isDialogShowing = true;
        // Badge sofort löschen, damit der Listener nicht erneut feuert
        ref.read(badgeNotificationProvider.notifier).clearBadge();
        // Dialog erst nach dem nächsten Frame anzeigen, um "widget tree locked" Fehler zu vermeiden
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _isDialogShowing) {
            _showBadgeCongratulationsDialog(context, next);
          }
        });
      }
    });

    return Scaffold(
      body: _getCurrentScreen(statistics),
      bottomNavigationBar: BottomNavigation(
        currentIndex: currentIndex,
        onTap: _onNavigationTap,
      ),
    );
  }

  Future<void> _maybeShowSyncPrompt() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Check both local and cloud (via shouldShowSyncPrompt)
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
          'Möchtest du deine Daten (Aufnahmen, Entwürfe, Stimmungen, Aktivitäten, Einstellungen) sicher in der Cloud speichern und auf mehreren Geräten nutzen?\n\n'
          '• Synchronisation setzt eine Anmeldung voraus.\n'
          '• Du kannst die Option jederzeit in Einstellungen → Synchronisation ändern.\n\n'
          'Wenn du „Nur lokal“ wählst, bleiben alle Daten ausschließlich auf diesem Gerät.',
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

    // Set syncPromptShown: true (locally)
    await ref.read(userPrefsProvider.notifier).setSyncPromptShown();

    if (enabled == true) {
      // User chose "Synchronisieren"
      await ref.read(userPrefsProvider.notifier).updateSyncEnabled(true);
      // Push user_prefs immediately so Cloud reflects the decision (including syncPromptShown: true)
      await ref.read(syncServiceProvider).pushUserPrefsIfEnabled();
      // Then pull cloud data (delta sync) to get any missing data
      await ref.read(syncServiceProvider).syncFromCloudDelta();
    } else {
      // User chose "Nur lokal" - set syncEnabled: false locally
      await ref.read(userPrefsProvider.notifier).updateSyncEnabled(false);
      // syncPromptShown is already set locally above
      // Don't push to cloud if sync is disabled (no need to sync when user chose local only)
    }
  }

  Widget _getCurrentScreen(AsyncValue<Map<String, dynamic>> statistics) {
    final navigationState = ref.watch(navigationProvider);
    final currentIndex = navigationState.currentIndex;

    switch (currentIndex) {
      case 0:
        return _buildHomeContent(statistics);
      case 1:
        return const MediaLibraryScreen();
      case 2:
        return const ProfileScreen();
      case 3:
        return const SettingsScreen();
      default:
        return _buildHomeContent(statistics);
    }
  }

  Widget _buildHomeContent(AsyncValue<Map<String, dynamic>> statistics) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Container(
      decoration: BoxDecoration(gradient: moodTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Usage Statistics
                    _buildUsageStatistics(statistics),

                    const SizedBox(height: 24),

                    // Mood Check
                    const MoodCheck(),

                    const SizedBox(height: 24),

                    // Recently Played
                    const RecentlyPlayed(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onNavigationTap(int index) {
    ref.read(navigationProvider.notifier).setCurrentIndex(index);

    // Wenn zur Home-Seite navigiert wird, prüfen ob ein Badge wartet
    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isDialogShowing) return;
        _checkForPendingBadge();
      });
    }
  }

  void _showBadgeCongratulationsDialog(
    BuildContext context,
    Map<String, dynamic> badge,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BadgeCongratulationsDialog(badge: badge),
    ).then((_) {
      // Nach dem Schließen des Dialogs Flag zurücksetzen
      if (mounted) {
        _isDialogShowing = false;
      }
    });
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo_napolill.png',
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatistics(AsyncValue<Map<String, dynamic>> statistics) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return statistics.when(
      data: (data) => Container(
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
                    'DEINE STATISTIKEN',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showStatisticsInfo(context),
                    child: Icon(
                      Icons.info_outline,
                      color: moodTheme.accentColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Links: Kreisdiagramm
                  Expanded(flex: 3, child: _buildCircularProgressCard(data)),
                  const SizedBox(width: 16),
                  // Rechts: Zeitstatistiken
                  Expanded(flex: 2, child: _buildTimeStatsCards(data)),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Fehler beim Laden der Statistiken: $error')),
    );
  }

  Widget _buildCircularProgressCard(Map<String, dynamic> data) {
    final moodTheme = ref.watch(currentMoodThemeProvider);
    // currentStreak kommt direkt aus den gespeicherten Daten (StorageService.getCurrentStreak())
    final currentStreak = data['currentStreak'] ?? 0;
    final totalDays = 30;

    return SizedBox(
      height: 200, // Gleiche Höhe wie Zeitstatistik-Blöcke
      child: Center(
        // Zentriert das Kreisdiagramm vertikal
        child: SizedBox(
          width: 200, // Noch größer für bessere Sichtbarkeit
          height: 200, // Noch größer für bessere Sichtbarkeit
          child: CustomPaint(
            painter: CircularSegmentsPainter(
              progress: (currentStreak / totalDays).clamp(0.0, 1.0),
              totalSegments: totalDays,
              filledSegments:
                  currentStreak, // Echte currentStreak aus den Daten
              accentColor: ref.watch(currentMoodThemeProvider).accentColor,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Days',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20, // Noch größer
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '$currentStreak/$totalDays',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26, // Noch größer
                    ),
                  ),
                  const SizedBox(height: 8), // Noch größer
                  // Höchstes Badge Icon
                  _buildBadgeIcon(moodTheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeStatsCards(Map<String, dynamic> data) {
    return SizedBox(
      height: 200, // Gleiche Höhe wie Kreisdiagramm
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween, // Gleichmäßig verteilen
        children: [
          _buildTimeStatCard(
            'Heute',
            _formatMinutes(data['todayListenMinutes'] ?? 0),
          ),
          _buildTimeStatCard(
            'Gestern',
            _formatMinutes(data['yesterdayListenMinutes'] ?? 0),
          ),
          _buildTimeStatCard(
            'Dieser Monat',
            _formatMinutes(data['monthListenMinutes'] ?? 0),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeStatCard(String label, String time) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style:
                GoogleFonts.poppins(
                  color: moodTheme.accentColor, // Gold
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ).copyWith(
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}Min';
  }

  Widget _buildBadgeIcon(MoodTheme moodTheme) {
    final highestBadge = ref.watch(highestBadgeProvider);

    return highestBadge.when(
      data: (badge) {
        final iconData = _getIconData(badge['icon'] as String);
        return Icon(iconData, color: moodTheme.accentColor, size: 32);
      },
      loading: () =>
          Icon(Icons.emoji_events, color: moodTheme.accentColor, size: 32),
      error: (_, __) =>
          Icon(Icons.emoji_events, color: moodTheme.accentColor, size: 32),
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

  void _showStatisticsInfo(BuildContext context) {
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
            Text(
              'DEINE STATISTIKEN',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Text(
          'Hier siehst du deinen Fortschritt:\n\n'
          '• Das Kreisdiagramm zeigt deine 30-Tage-Streak. Jedes gefüllte Segment steht für einen Tag, an dem du Napolill genutzt hast.\n\n'
          '• Die Zeitstatistiken zeigen dir, wie viele Minuten du heute, gestern und in diesem Monat meditiert hast.\n\n'
          'Bleib dran und erreiche deine Ziele! 🎯',
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
}

class CircularSegmentsPainter extends CustomPainter {
  final double progress;
  final int totalSegments;
  final int filledSegments;
  final Color accentColor;

  CircularSegmentsPainter({
    required this.progress,
    required this.totalSegments,
    required this.filledSegments,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0; // Noch dickere Linien für größeren Kreis

    // Berechne den Radius, um den Strich zu zentrieren
    final radius = size.width / 2 - (paint.strokeWidth / 2);

    // Zeichne alle 30 Segmente mit kleinen Lücken zwischen ihnen
    for (int i = 0; i < totalSegments; i++) {
      final startAngle = -3.14159 / 2 + (2 * 3.14159 / totalSegments) * i;
      final sweepAngle =
          (2 * 3.14159 / totalSegments) -
          0.1; // Kleine Lücke zwischen Segmenten

      // Farbe basierend auf gefüllten Segmenten
      if (i < filledSegments) {
        paint.color = accentColor; // Akzentfarbe für gefüllte Segmente
      } else {
        paint.color = Colors.white.withValues(
          alpha: 0.2,
        ); // Transparentes Weiß für leere Segmente
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is CircularSegmentsPainter &&
        (oldDelegate.progress != progress ||
            oldDelegate.totalSegments != totalSegments ||
            oldDelegate.filledSegments != filledSegments ||
            oldDelegate.accentColor != accentColor);
  }
}
