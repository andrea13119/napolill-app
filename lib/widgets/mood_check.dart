import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../models/user_prefs.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

class MoodCheck extends ConsumerStatefulWidget {
  const MoodCheck({super.key});

  @override
  ConsumerState<MoodCheck> createState() => _MoodCheckState();
}

class _MoodCheckState extends ConsumerState<MoodCheck> {
  String? _selectedMood;

  final List<MoodOption> _moodOptions = [
    MoodOption(mood: AppConstants.moodWuetend, emoji: '😠', color: Colors.red),
    MoodOption(mood: AppConstants.moodTraurig, emoji: '😢', color: Colors.blue),
    MoodOption(
      mood: AppConstants.moodPassiv,
      emoji: '😐',
      color: Colors.orange,
    ),
    MoodOption(
      mood: AppConstants.moodFroehlich,
      emoji: '😊',
      color: Colors.green,
    ),
    MoodOption(
      mood: AppConstants.moodEuphorisch,
      emoji: '🤩',
      color: Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayMood();
  }

  void _loadTodayMood() {
    final userPrefs = ref.read(userPrefsProvider);
    final today = DateTime.now();

    final todayMood = userPrefs.moods.firstWhere(
      (mood) =>
          mood.date.year == today.year &&
          mood.date.month == today.month &&
          mood.date.day == today.day,
      orElse: () => MoodEntry(date: today, mood: ''),
    );

    if (todayMood.mood.isNotEmpty) {
      setState(() {
        _selectedMood = todayMood.mood;
      });
    }
  }

  void _selectMood(String mood) {
    setState(() {
      // Toggle: Wenn das gleiche Mood nochmal angeklickt wird, deselektieren
      if (_selectedMood == mood) {
        _selectedMood = null;
      } else {
        _selectedMood = mood;
      }
    });

    // Save mood (leerer String wenn deselektiert)
    final today = DateTime.now();
    ref
        .read(userPrefsProvider.notifier)
        .addMood(MoodEntry(date: today, mood: _selectedMood ?? ''));

    // Invalidate mood statistics to refresh the mood overview immediately
    ref.invalidate(moodStatisticsProvider);
  }

  void _showMoodCheckInfo(BuildContext context) {
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
                'ICH FÜHLE MICH HEUTE',
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Wähle deine aktuelle Stimmung aus, um deine emotionale Entwicklung zu tracken.\n\n'
          'Dein täglicher Mood Check hilft dir dabei:\n\n'
          '• Bewusster mit deinen Gefühlen umzugehen\n'
          '• Muster in deiner Stimmung zu erkennen\n'
          '• Deinen Fortschritt im Laufe der Zeit zu sehen\n\n'
          'Sei ehrlich zu dir selbst – es gibt keine falschen Antworten! 💙',
          style: AppTheme.bodyStyle.copyWith(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Verstanden',
              style: AppTheme.buttonStyle.copyWith(
                color: moodTheme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'ICH FÜHLE MICH HEUTE',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showMoodCheckInfo(context),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _moodOptions.map((option) {
                final isSelected = _selectedMood == option.mood;
                return GestureDetector(
                  onTap: () => _selectMood(option.mood),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isSelected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    option.color.withValues(alpha: 0.9),
                                    option.color.withValues(alpha: 0.7),
                                  ],
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withValues(alpha: 0.2),
                          border: isSelected
                              ? Border.all(color: option.color, width: 2.5)
                              : Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: option.color.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            option.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option.mood.toUpperCase(),
                        style: AppTheme.captionStyle.copyWith(
                          fontSize: 10,
                          color: isSelected ? option.color : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class MoodOption {
  final String mood;
  final String emoji;
  final Color color;

  MoodOption({required this.mood, required this.emoji, required this.color});
}
