import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entry.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../providers/app_provider.dart';
import 'player_screen.dart';

class EntryPlayerScreen extends ConsumerStatefulWidget {
  final Entry entry;

  const EntryPlayerScreen({super.key, required this.entry});

  @override
  ConsumerState<EntryPlayerScreen> createState() => _EntryPlayerScreenState();
}

class _EntryPlayerScreenState extends ConsumerState<EntryPlayerScreen> {
  bool _isPlaying = false;
  bool _isPaused = false;
  String _selectedMode = 'meditation';
  int _selectedDuration = 5; // minutes

  @override
  Widget build(BuildContext context) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Scaffold(
      body: Container(
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
                  child: _buildMainContainer(),
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
          const SizedBox(height: 20),
          // Logo
          Image.asset(
            'assets/images/logo_napolill.png',
            height: 60,
            width: 200,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMainContainer() {
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Entry info
          _buildEntryInfoContent(),

          const SizedBox(height: 32),

          // Mode selection
          _buildModeSelection(),

          const SizedBox(height: 24),

          // Duration selection (for meditation mode)
          if (_selectedMode == 'meditation') _buildDurationSelection(),

          if (_selectedMode == 'meditation') const SizedBox(height: 32),

          if (_selectedMode != 'meditation') const SizedBox(height: 16),

          // Play button
          _buildPlayButton(),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEntryInfoContent() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Column(
      children: [
        // Emoji (Category Icon)
        Icon(
          _getCategoryIcon(widget.entry.category),
          color: moodTheme.accentColor,
          size: 40,
        ),
        const SizedBox(height: 12),
        // Title
        Text(
          widget.entry.title,
          style: AppTheme.headingStyle.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Divider
        Container(
          width: 60,
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                moodTheme.accentColor,
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Affirmations count and level
        Text(
          '${widget.entry.takes.where((take) => take.isNotEmpty).length} Affirmationen • ${_getLevelDisplayName(widget.entry.level)}',
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        // Creation date and time
        Text(
          '${_formatDate(widget.entry.createdAt)} • ${_formatTime(widget.entry.createdAt)}',
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildModeSelection() {
    return Column(
      children: [
        // Meditation Button
        _buildModeButton('meditation', 'Meditation', Icons.info_outline),
        const SizedBox(height: 16),
        // Dauerschleife Button
        _buildModeButton(
          'endless',
          'Dauerschleife',
          Icons.info_outline,
          subtitle: 'max. 9h',
        ),
      ],
    );
  }

  Widget _buildModeButton(
    String mode,
    String title,
    IconData icon, {
    String? subtitle,
  }) {
    final isSelected = _selectedMode == mode;
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? moodTheme.accentColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? moodTheme.accentColor : Colors.white,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showInfoDialog(mode),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: moodTheme.accentColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelection() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Container(
          width: double.infinity,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                moodTheme.accentColor.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Meditationsdauer',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [5, 10, 15, 20].map((duration) {
            final isSelected = _selectedDuration == duration;
            return InkWell(
              onTap: () => setState(() => _selectedDuration = duration),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? moodTheme.accentColor
                      : Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? moodTheme.accentColor
                        : Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${duration}m',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: moodTheme.accentColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: moodTheme.accentColor.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: IconButton(
        onPressed: _togglePlayback,
        icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 48),
      ),
    );
  }

  void _togglePlayback() {
    setState(() {
      if (_isPlaying) {
        _isPaused = !_isPaused;
      } else {
        _isPlaying = true;
        _isPaused = false;
      }
    });

    if (_isPlaying && !_isPaused) {
      _startPlayback();
    } else if (_isPaused) {
      _pausePlayback();
    } else {
      _stopPlayback();
    }
  }

  void _startPlayback() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          entry: widget.entry,
          mode: _selectedMode,
          durationMinutes: _selectedMode == 'meditation'
              ? _selectedDuration
              : null,
        ),
      ),
    );
  }

  void _pausePlayback() {
    // This will be handled in the PlayerScreen
  }

  void _stopPlayback() {
    // This will be handled in the PlayerScreen
  }

  String _getLevelDisplayName(String level) {
    switch (level) {
      case AppConstants.levelBeginner:
        return AppStrings.anfaenger;
      case AppConstants.levelAdvanced:
        return AppStrings.fortgeschritten;
      case AppConstants.levelOpen:
        return AppStrings.offen;
      default:
        return level;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case AppConstants.categorySelbstbewusstsein:
        return Icons.psychology;
      case AppConstants.categorySelbstwert:
        return Icons.favorite;
      case AppConstants.categoryAengste:
        return Icons.visibility_off;
      case AppConstants.categoryCustom:
        return Icons.flag;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showInfoDialog(String mode) {
    final moodTheme = ref.read(currentMoodThemeProvider);
    String title;
    String content;

    if (mode == 'meditation') {
      title = '🧘 Meditation';
      content =
          'Bei der Meditation kannst du eine feste Dauer von 5, 10, 15 oder 20 Minuten wählen.\n\n'
          '• Die Affirmationen werden in der gewählten Zeit abgespielt\n'
          '• Der Timer stoppt automatisch nach Ablauf der Zeit\n'
          '• Perfekt für strukturierte Meditationssitzungen\n'
          '• Ideal für Anfänger und Fortgeschrittene\n\n'
          'Die Meditation hilft dir dabei, gezielt Zeit für deine persönliche Entwicklung zu schaffen.';
    } else {
      title = '♾️ Dauerschleife';
      content =
          'Bei der Dauerschleife werden deine Affirmationen endlos wiederholt.\n\n'
          '• Die Affirmationen laufen kontinuierlich im Hintergrund\n'
          '• Du kannst sie jederzeit manuell stoppen\n'
          '• Maximale Laufzeit: 9 Stunden\n'
          '• Perfekt für längere Meditationssitzungen\n'
          '• Ideal für tiefe Entspannung und Transformation\n\n'
          'Die Dauerschleife ermöglicht es dir, in einen tiefen meditativen Zustand einzutauchen.';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: moodTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: moodTheme.accentColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          title: Text(
            title,
            style: AppTheme.headingStyle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: AppTheme.bodyStyle.copyWith(fontSize: 16, height: 1.5),
              textAlign: TextAlign.left,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: moodTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Verstanden',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
