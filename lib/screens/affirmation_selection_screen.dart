import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../models/draft_state.dart';
import '../models/user_prefs.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/mood_theme.dart';
import '../utils/affirmation_suggestions.dart';
import 'recording_screen.dart';
import 'category_detail_screen.dart';

class AffirmationSelectionScreen extends ConsumerStatefulWidget {
  final DraftState? draftState;
  final String? category;

  const AffirmationSelectionScreen({super.key, this.draftState, this.category});

  @override
  ConsumerState<AffirmationSelectionScreen> createState() =>
      _AffirmationSelectionScreenState();
}

class _AffirmationSelectionScreenState
    extends ConsumerState<AffirmationSelectionScreen> {
  final TextEditingController _customTextController = TextEditingController();
  final List<String> _selectedAffirmations = [];
  final List<String> _customAffirmations = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _loadDraftData();
  }

  void _loadDraftData() {
    if (widget.draftState != null) {
      setState(() {
        _selectedAffirmations.addAll(widget.draftState!.selectedAffirmations);
        _customAffirmations.addAll(widget.draftState!.customAffirmations);
      });
    }
  }

  @override
  void dispose() {
    _customTextController.dispose();
    super.dispose();
  }

  void _loadSuggestions() {
    // Load suggestions based on user's topic and level
    // This will be implemented with actual suggestion data
  }

  List<String> _getSuggestions() {
    final userPrefs = ref.read(userPrefsProvider);
    final topic = userPrefs.selectedTopic;
    final level = userPrefs.level;

    // Return suggestions based on topic and level
    // For now, return some example suggestions
    return _getTopicSuggestions(topic, level);
  }

  List<String> _getTopicSuggestions(String topic, String level) {
    return AffirmationSuggestions.getSuggestions(topic, level);
  }

  void _toggleAffirmation(String affirmation) {
    setState(() {
      if (_selectedAffirmations.contains(affirmation)) {
        _selectedAffirmations.remove(affirmation);
      } else if (_selectedAffirmations.length < 30) {
        _selectedAffirmations.add(affirmation);
      }
    });
  }

  void _addCustomAffirmation() {
    final text = _customTextController.text.trim();
    if (text.isNotEmpty && _selectedAffirmations.length < 30) {
      setState(() {
        _customAffirmations.add(text);
        _selectedAffirmations.add(text);
        _customTextController.clear();
      });
    }
  }

  void _startRecording() {
    if (_selectedAffirmations.isNotEmpty) {
      // Use existing entryId if resuming a draft, otherwise create new one
      final entryId =
          widget.draftState?.entryId ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Get category from widget parameter or user preferences
      final userPrefs = ref.read(userPrefsProvider);
      final category = widget.category ?? userPrefs.selectedTopic;

      // If we have an existing draft, update it instead of creating a new one
      DraftState draftState;
      if (widget.draftState != null) {
        // Update existing draft with new affirmations and step
        draftState = widget.draftState!.copyWith(
          selectedAffirmations: _selectedAffirmations,
          customAffirmations: _customAffirmations,
          currentStep: 'recording',
          updatedAt: DateTime.now(),
        );
      } else {
        // Create new draft state for recording
        draftState = DraftState(
          entryId: entryId,
          title:
              'Entwurf ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
          category: category,
          nextIndex: 0,
          perTakeStatus: List.generate(30, (index) => TakeStatus.todo),
          lastPartialFile: null,
          bookmarks: [],
          selectedAffirmations: _selectedAffirmations,
          customAffirmations: _customAffirmations,
          currentStep: 'recording',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          recordedTakes: [],
        );
      }

      // Debug logging
      debugPrint('Transferring to recording - Title: ${draftState.title}');
      debugPrint('Original draft title: ${widget.draftState?.title}');
      debugPrint('Is updating existing draft: ${widget.draftState != null}');

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RecordingScreen(
            affirmations: _selectedAffirmations,
            draftState: draftState,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use neutral theme for affirmation selection screen
    final neutralTheme = MoodTheme.standard;
    final suggestions = _getSuggestions();

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
                        'Deine Affirmationen',
                        style: AppTheme.headingStyle.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Wähle die Sätze aus, die zu dir passen. Du kannst Vorschläge auswählen oder eigene hinzufügen. (Maximum: 30 Sätze)',
                        style: AppTheme.bodyStyle,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Progress indicator
                      _buildProgressIndicator(),

                      const SizedBox(height: 24),

                      // Custom input
                      _buildCustomInput(),

                      const SizedBox(height: 24),

                      // Suggestions
                      Text(
                        'Vorschläge für dich:',
                        style: AppTheme.headingStyle.copyWith(fontSize: 20),
                      ),

                      const SizedBox(height: 16),

                      // Suggestion chips
                      _buildSuggestionChips(suggestions),

                      const SizedBox(height: 24),

                      // Selected affirmations
                      if (_selectedAffirmations.isNotEmpty) ...[
                        Text(
                          'Ausgewählte Affirmationen:',
                          style: AppTheme.headingStyle.copyWith(fontSize: 20),
                        ),

                        const SizedBox(height: 16),

                        _buildSelectedAffirmations(),

                        const SizedBox(height: 24),
                      ],

                      // Buttons
                      Row(
                        children: [
                          // Pause button
                          Expanded(
                            child: SizedBox(
                              height: AppConstants.buttonHeight,
                              child: ElevatedButton(
                                onPressed: _selectedAffirmations.isNotEmpty
                                    ? _pauseAndSave
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _selectedAffirmations.isNotEmpty
                                      ? Colors.orange
                                      : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.pause,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text('PAUSE', style: AppTheme.buttonStyle),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Start recording button
                          Expanded(
                            child: SizedBox(
                              height: AppConstants.buttonHeight,
                              child: ElevatedButton(
                                onPressed: _selectedAffirmations.isNotEmpty
                                    ? _startRecording
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _selectedAffirmations.isNotEmpty
                                      ? MoodTheme.standard.accentColor
                                      : Colors.grey,
                                ),
                                child: Text(
                                  'AUFNAHME STARTEN',
                                  style: AppTheme.buttonStyle,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: _selectedAffirmations.isNotEmpty
                ? Colors.green
                : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedAffirmations.length} Affirmationen ausgewählt (max. 30)',
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: _selectedAffirmations.length / 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomInput() {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eigene Affirmation hinzufügen:',
              style: AppTheme.headingDarkStyle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customTextController,
              style: AppTheme.bodyDarkStyle, // Schriftfarbe ändern
              decoration: InputDecoration(
                hintText: 'Schreibe deine eigene Affirmation...',
                hintStyle: AppTheme.bodyDarkStyle.copyWith(
                  color: Colors.grey[600], // Hint-Text etwas heller
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  onPressed: _addCustomAffirmation,
                  icon: const Icon(Icons.add),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips(List<String> suggestions) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        final isSelected = _selectedAffirmations.contains(suggestion);
        return FilterChip(
          label: Text(
            suggestion,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textDarkColor,
            ),
          ),
          selected: isSelected,
          onSelected: _selectedAffirmations.length >= 30 && !isSelected
              ? null
              : (_) => _toggleAffirmation(suggestion),
          backgroundColor: AppTheme.cardColor,
          selectedColor: MoodTheme.standard.accentColor,
          checkmarkColor: Colors.white,
        );
      }).toList(),
    );
  }

  Widget _buildSelectedAffirmations() {
    return Column(
      children: _selectedAffirmations.map((affirmation) {
        final isCustom = _customAffirmations.contains(affirmation);
        return Card(
          color: AppTheme.cardColor,
          child: ListTile(
            leading: Icon(
              isCustom ? Icons.edit : Icons.check_circle,
              color: MoodTheme.standard.accentColor,
            ),
            title: Text(affirmation, style: AppTheme.bodyDarkStyle),
            trailing: IconButton(
              onPressed: () => _toggleAffirmation(affirmation),
              icon: const Icon(Icons.remove_circle, color: Colors.red),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _pauseAndSave() async {
    try {
      // Get user preferences
      final userPrefs = ref.read(userPrefsProvider);

      // Use existing entryId if resuming a draft, otherwise create new one
      final entryId =
          widget.draftState?.entryId ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Get category from widget parameter or user preferences
      final category = widget.category ?? userPrefs.selectedTopic;

      // Debug logging
      debugPrint('Creating draft with category: $category');
      debugPrint('Widget category: ${widget.category}');
      debugPrint('UserPrefs selectedTopic: ${userPrefs.selectedTopic}');

      // Create or update draft state
      final draftState = DraftState(
        entryId: entryId,
        title:
            widget.draftState?.title ??
            'Entwurf ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
        category: category,
        selectedAffirmations: _selectedAffirmations,
        customAffirmations: _customAffirmations,
        currentStep: 'affirmation_selection', // Current step
        createdAt: widget.draftState?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save draft (this will update if entryId already exists)
      await ref.read(draftStatesProvider.notifier).addDraft(draftState);

      // Show confirmation dialog
      if (mounted) {
        await _showPauseConfirmationDialog(userPrefs);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPauseConfirmationDialog(UserPrefs userPrefs) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_circle_filled,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Pause gespeichert!',
                style: AppTheme.headingStyle.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Deine Auswahl ist sicher!',
                    style: AppTheme.bodyStyle.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Dein Fortschritt wurde erfolgreich gespeichert.',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.green[300],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildBulletPoint(
                          'Deine Auswahl geht nicht verloren',
                          Colors.blue[300]!,
                        ),
                        _buildBulletPoint(
                          'Zu finden im Entwurfsordner deiner Kategorie',
                          Colors.purple[300]!,
                        ),
                        _buildBulletPoint(
                          'Jederzeit weiter bearbeitbar',
                          Colors.orange[300]!,
                        ),
                        _buildBulletPoint(
                          'Alle ausgewählten Affirmationen bleiben erhalten',
                          Colors.teal[300]!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'ZURÜCK',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.blue[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to category detail screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => CategoryDetailScreen(
                      categoryKey: userPrefs.selectedTopic,
                      categoryTitle: _getCategoryDisplayName(
                        userPrefs.selectedTopic,
                      ),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Zur Kategorie'),
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

  Widget _buildBulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyStyle.copyWith(
                color: color,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
