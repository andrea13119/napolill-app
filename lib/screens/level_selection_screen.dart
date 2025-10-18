import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/mood_theme.dart';
import 'final_notice_screen.dart';

class LevelSelectionScreen extends ConsumerStatefulWidget {
  const LevelSelectionScreen({super.key});

  @override
  ConsumerState<LevelSelectionScreen> createState() =>
      _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends ConsumerState<LevelSelectionScreen> {
  String? _selectedLevel;

  final List<LevelOption> _levels = [
    LevelOption(
      id: AppConstants.levelBeginner,
      title: AppStrings.anfaenger,
      description: 'Lieber ruhig & klar geführt',
      color: Colors.green,
      icon: Icons.school,
    ),
    LevelOption(
      id: AppConstants.levelAdvanced,
      title: AppStrings.fortgeschritten,
      description: 'Mit mehr Tiefe',
      color: Colors.orange,
      icon: Icons.trending_up,
    ),
    LevelOption(
      id: AppConstants.levelOpen,
      title: AppStrings.offen,
      description: 'Alle Inhalte freigeschaltet',
      color: Colors.blue,
      icon: Icons.all_inclusive,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedLevel();
  }

  void _loadSelectedLevel() {
    final userPrefs = ref.read(userPrefsProvider);
    setState(() {
      _selectedLevel = userPrefs.level;
    });
  }

  void _selectLevel(String levelId) {
    setState(() {
      _selectedLevel = levelId;
    });
  }

  void _next() {
    if (_selectedLevel != null) {
      ref.read(userPrefsProvider.notifier).updateLevel(_selectedLevel!);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const FinalNoticeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use neutral theme for level selection screen
    final neutralTheme = MoodTheme.standard;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: neutralTheme.backgroundGradient),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Level auswählen',
                        style: AppTheme.headingStyle.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Question
                      Text(
                        'Wie vertraut bist du bereits mit Affirmationen?',
                        style: AppTheme.bodyStyle.copyWith(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Level Options
                      ..._levels.map((level) => _buildLevelCard(level)),

                      const SizedBox(height: 24),

                      // Explanation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Dein Level hilft dabei, passende Vorschläge für deine ersten Aufnahmen zu machen. Du kannst es jederzeit anpassen.',
                          style: AppTheme.bodyStyle.copyWith(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Next Button
                      SizedBox(
                        width: double.infinity,
                        height: AppConstants.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _selectedLevel != null ? _next : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedLevel != null
                                ? MoodTheme.standard.accentColor
                                : Colors.grey,
                          ),
                          child: Text(
                            AppStrings.weiter,
                            style: AppTheme.buttonStyle,
                          ),
                        ),
                      ),
                    ],
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
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo_napolill.png',
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildLevelCard(LevelOption level) {
    final isSelected = _selectedLevel == level.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: isSelected
            ? level.color.withValues(alpha: 0.2)
            : AppTheme.cardColor,
        child: InkWell(
          onTap: () => _selectLevel(level.id),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        level.color.withValues(alpha: 0.1),
                        level.color.withValues(alpha: 0.3),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? level.color
                          : level.color.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(level.icon, color: Colors.white, size: 24),
                  ),

                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.title,
                          style: AppTheme.headingDarkStyle.copyWith(
                            fontSize: 20,
                            color: isSelected
                                ? level.color
                                : AppTheme.textDarkColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          level.description,
                          style: AppTheme.bodyDarkStyle.copyWith(
                            fontSize: 16,
                            color: isSelected ? level.color : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  if (isSelected)
                    Icon(Icons.check_circle, color: level.color, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LevelOption {
  final String id;
  final String title;
  final String description;
  final Color color;
  final IconData icon;

  LevelOption({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
  });
}
