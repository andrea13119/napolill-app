import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../providers/app_provider.dart';
import 'category_detail_screen.dart';

class MediaLibraryScreen extends ConsumerStatefulWidget {
  const MediaLibraryScreen({super.key});

  @override
  ConsumerState<MediaLibraryScreen> createState() => _MediaLibraryScreenState();
}

class _MediaLibraryScreenState extends ConsumerState<MediaLibraryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildMediathekContent());
  }

  Widget _buildMediathekContent() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Container(
      decoration: BoxDecoration(gradient: moodTheme.backgroundGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Mediathek Section
            _buildMediathekSection(),

            // Category Cards
            Expanded(child: _buildCategoryCards()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Image.asset(
          'assets/images/logo_napolill.png',
          height: 80,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildMediathekSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Brain Icon with dark background
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/images/brain.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Mediathek Text
            Text(
              'Mediathek',
              style: AppTheme.headingStyle.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 20),
            // Info Icon
            GestureDetector(
              onTap: _showInfoDialog,
              child: Icon(
                Icons.info_outline,
                color: ref.watch(currentMoodThemeProvider).accentColor,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCards() {
    final categories = [
      {
        'key': AppConstants.categorySelbstbewusstsein,
        'title': AppStrings.selbstbewusstsein,
        'description': 'Selbstvertrauen und innere Stärke aufbauen',
      },
      {
        'key': AppConstants.categorySelbstwert,
        'title': AppStrings.selbstwert,
        'description': 'Deinen eigenen Wert erkennen und schätzen',
      },
      {
        'key': AppConstants.categoryAengste,
        'title': AppStrings.aengsteLoesen,
        'description': 'Ängste überwinden und Blockaden lösen',
      },
      {
        'key': AppConstants.categoryCustom,
        'title': AppStrings.eigeneZiele,
        'description': 'Deine persönlichen Ziele verfolgen',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(
            title: category['title'] as String,
            description: category['description'] as String,
            onTap: () => _navigateToCategory(category['key'] as String),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  moodTheme.cardColor.withValues(alpha: 0.75),
                  moodTheme.cardColor.withValues(alpha: 0.65),
                ],
              ),
              borderRadius: BorderRadius.circular(16.0),
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
            child: Stack(
              children: [
                // Content with icon and text
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Category Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        child: Icon(
                          _getCategoryIcon(title),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Category Title and Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Category Title
                            Text(
                              title,
                              style: AppTheme.headingStyle.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Category Description
                            Text(
                              description,
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrow Icon
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCategory(String categoryKey) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(
          categoryKey: categoryKey,
          categoryTitle: _getCategoryDisplayName(categoryKey),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);

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
            'MEDIATHEK',
            style: AppTheme.headingStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Hier findest du alle deine aufgenommenen Affirmationen:\n\n'
            '• Sortiert nach Kategorien\n'
            '• Organisiert nach Schwierigkeitsgraden\n'
            '• Zugriff auf alle deine persönlichen Aufnahmen\n\n'
            'Wähle eine Kategorie aus, um zu deinen Affirmationen zu gelangen und deine persönliche Entwicklung zu fördern!',
            style: AppTheme.bodyStyle.copyWith(fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Verstanden',
                style: TextStyle(
                  color: moodTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case AppConstants.categorySelbstbewusstsein:
        return AppStrings.selbstbewusstsein;
      case AppConstants.categorySelbstwert:
        return AppStrings.selbstwert;
      case AppConstants.categoryAengste:
        return AppStrings.aengsteLoesen;
      case AppConstants.categoryCustom:
        return AppStrings.eigeneZiele;
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String categoryTitle) {
    switch (categoryTitle) {
      case AppStrings.selbstbewusstsein:
        return Icons.psychology;
      case AppStrings.selbstwert:
        return Icons.favorite;
      case AppStrings.aengsteLoesen:
        return Icons.visibility_off;
      case AppStrings.eigeneZiele:
        return Icons.flag;
      default:
        return Icons.help;
    }
  }
}
