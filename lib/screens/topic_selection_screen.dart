import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/mood_theme.dart';
import 'level_selection_screen.dart';
import 'home_screen.dart';

class TopicSelectionScreen extends ConsumerStatefulWidget {
  final String? preselectedCategory;

  const TopicSelectionScreen({super.key, this.preselectedCategory});

  @override
  ConsumerState<TopicSelectionScreen> createState() =>
      _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends ConsumerState<TopicSelectionScreen> {
  String? _selectedTopic;

  final List<TopicOption> _topics = [
    TopicOption(
      id: AppConstants.categorySelbstbewusstsein,
      title: AppStrings.selbstbewusstsein,
      description: 'Selbstvertrauen und innere Stärke aufbauen',
      icon: Icons.psychology,
      color: Colors.green,
    ),
    TopicOption(
      id: AppConstants.categorySelbstwert,
      title: AppStrings.selbstwert,
      description: 'Deinen eigenen Wert erkennen und schätzen',
      icon: Icons.favorite,
      color: Colors.pink,
    ),
    TopicOption(
      id: AppConstants.categoryAengste,
      title: AppStrings.aengsteLoesen,
      description: 'Ängste überwinden und Blockaden lösen',
      icon: Icons.visibility_off,
      color: Colors.orange,
    ),
    TopicOption(
      id: AppConstants.categoryCustom,
      title: AppStrings.eigeneZiele,
      description: 'Deine persönlichen Ziele verfolgen',
      icon: Icons.flag,
      color: Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedTopic();
  }

  void _loadSelectedTopic() {
    // If a preselected category is provided, use it; otherwise use saved preference
    if (widget.preselectedCategory != null) {
      setState(() {
        _selectedTopic = widget.preselectedCategory;
      });
    } else {
      final userPrefs = ref.read(userPrefsProvider);
      setState(() {
        _selectedTopic = userPrefs.selectedTopic;
      });
    }
  }

  void _selectTopic(String topicId) {
    setState(() {
      _selectedTopic = topicId;
    });
  }

  void _next() {
    if (_selectedTopic != null) {
      ref.read(userPrefsProvider.notifier).updateSelectedTopic(_selectedTopic!);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const LevelSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use neutral theme for topic selection screen
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
                        'Wähle dein Startthema',
                        style: AppTheme.headingStyle.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Damit deine Affirmationen möglichst gut zu dir passen, kannst du hier dein aktuelles Thema auswählen:',
                        style: AppTheme.bodyStyle,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Topic Options
                      ..._topics.map((topic) => _buildTopicCard(topic)),

                      const SizedBox(height: 32),

                      // Next Button
                      SizedBox(
                        width: double.infinity,
                        height: AppConstants.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _selectedTopic != null ? _next : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedTopic != null
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
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(initialTabIndex: 1),
              ),
            ),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/logo_napolill.png',
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildTopicCard(TopicOption topic) {
    final isSelected = _selectedTopic == topic.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: isSelected
            ? topic.color.withValues(alpha: 0.2)
            : AppTheme.cardColor,
        child: InkWell(
          onTap: () => _selectTopic(topic.id),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? topic.color
                        : topic.color.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(topic.icon, color: Colors.white, size: 30),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        style: AppTheme.headingDarkStyle.copyWith(
                          fontSize: 18,
                          color: isSelected
                              ? topic.color
                              : AppTheme.textDarkColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topic.description,
                        style: AppTheme.bodyDarkStyle.copyWith(
                          fontSize: 14,
                          color: isSelected ? topic.color : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  Icon(Icons.check_circle, color: topic.color, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TopicOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  TopicOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
