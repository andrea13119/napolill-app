import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../models/entry.dart';
import '../models/draft_state.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'topic_selection_screen.dart';
import 'entry_player_screen.dart';
import 'affirmation_selection_screen.dart';
import 'recording_screen.dart';
import 'home_screen.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final String categoryKey;
  final String categoryTitle;

  const CategoryDetailScreen({
    super.key,
    required this.categoryKey,
    required this.categoryTitle,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(entriesProvider);
    final drafts = ref.watch(draftStatesProvider);
    final moodTheme = ref.watch(currentMoodThemeProvider);

    // Filter entries by category and sort by creation date
    final categoryEntries =
        entries.where((entry) => entry.category == widget.categoryKey).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Get drafts for current category and sort by updatedAt
    final categoryDrafts = drafts.values.where((draft) {
      return draft.category == widget.categoryKey;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Debug logging
    debugPrint('Category: ${widget.categoryKey}');
    debugPrint('Total drafts: ${drafts.length}');
    debugPrint('Category drafts: ${categoryDrafts.length}');
    for (final draft in categoryDrafts) {
      debugPrint(
        'Draft: ${draft.title}, Category: ${draft.category}, Updated: ${draft.updatedAt}',
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: moodTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Category Section
              _buildCategorySection(),

              // Content
              Expanded(child: _buildContent(categoryEntries, categoryDrafts)),
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

  Widget _buildCategorySection() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: Column(
          children: [
            // Category Icon
            Icon(
              _getCategoryIcon(widget.categoryKey),
              color: moodTheme.accentColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            // Brain Icon and Category Title in one line
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brain Icon with mood themed background
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: moodTheme.accentColor.withValues(alpha: 0.2),
                    boxShadow: [
                      BoxShadow(
                        color: moodTheme.accentColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/images/brain.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Category Title
                Text(
                  widget.categoryTitle,
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                // Info Icon
                GestureDetector(
                  onTap: _showInfoDialog,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: moodTheme.accentColor.withValues(alpha: 0.3),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Entry> entries, List<DraftState> drafts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Neue Affirmation erstellen Button
          _buildCreateNewButton(),

          const SizedBox(height: 32),

          // Level 1
          _buildLevelSection(
            'LEVEL 1',
            entries.where((e) => e.level == AppConstants.levelBeginner).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          ),

          const SizedBox(height: 24),

          // Level 2
          _buildLevelSection(
            'LEVEL 2',
            entries.where((e) => e.level == AppConstants.levelAdvanced).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          ),

          const SizedBox(height: 24),

          // Level 3
          _buildLevelSection(
            'LEVEL 3',
            entries.where((e) => e.level == AppConstants.levelOpen).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
          ),

          const SizedBox(height: 24),

          // Draft Section
          _buildDraftSection(drafts),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCreateNewButton() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _createNewAffirmation,
        style: ElevatedButton.styleFrom(
          backgroundColor: moodTheme.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8,
          shadowColor: moodTheme.accentColor.withValues(alpha: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              'Neue Affirmation erstellen',
              style: AppTheme.buttonStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSection(String levelTitle, List<Entry> entries) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          levelTitle,
          style: AppTheme.headingStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          _buildEmptyLevelState()
        else
          ...entries.map((entry) => _buildEntryCard(entry)),
        const SizedBox(height: 16),
        Container(
          height: 1,
          color: moodTheme.accentColor.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildDraftSection(List<DraftState> drafts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Draft (zum weiter Bearbeiten öffnen)',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (drafts.isEmpty)
          _buildEmptyDraftState()
        else
          ...drafts.map((draft) => _buildDraftCard(draft)),
      ],
    );
  }

  Widget _buildEntryCard(Entry entry) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Löschen',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmationDialog(entry);
      },
      onDismissed: (direction) {
        _deleteEntry(entry);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openEntry(entry),
            onLongPress: () => _handleDeleteRequest(entry),
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    moodTheme.cardColor,
                    moodTheme.cardColor.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: moodTheme.accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: moodTheme.accentColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Entry info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: AppTheme.headingStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.takeCount} Affirmationen • ${_formatDateTime(entry.createdAt)}',
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Icon
                      GestureDetector(
                        onTap: () => _editEntry(entry),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: moodTheme.accentColor.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete Icon
                      GestureDetector(
                        onTap: () => _handleDeleteRequest(entry),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraftCard(DraftState draft) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Dismissible(
      key: Key('draft_${draft.entryId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Löschen',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteDraftConfirmationDialog(draft);
      },
      onDismissed: (direction) {
        _deleteDraft(draft);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _continueDraft(draft),
            onLongPress: () => _handleDeleteDraftRequest(draft),
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    moodTheme.cardColor,
                    moodTheme.cardColor.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: moodTheme.accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: moodTheme.accentColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Title and Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.title,
                          style: AppTheme.headingStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(draft.updatedAt),
                          style: AppTheme.bodyStyle.copyWith(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Icon
                      GestureDetector(
                        onTap: () => _editDraft(draft),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: moodTheme.accentColor.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Delete Icon
                      GestureDetector(
                        onTap: () => _handleDeleteDraftRequest(draft),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyLevelState() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: moodTheme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: moodTheme.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'Noch keine Aufnahmen in diesem Level',
          style: AppTheme.bodyStyle.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDraftState() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: moodTheme.cardColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: moodTheme.accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'Keine Drafts vorhanden',
          style: AppTheme.bodyStyle.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  void _createNewAffirmation() {
    // Navigate to topic selection screen with pre-selected category
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            TopicSelectionScreen(preselectedCategory: widget.categoryKey),
      ),
    );
  }

  void _openEntry(Entry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EntryPlayerScreen(entry: entry)),
    );
  }

  void _continueDraft(DraftState draft) {
    // Navigate to the appropriate screen based on currentStep
    if (draft.currentStep == 'affirmation_selection') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AffirmationSelectionScreen(draftState: draft),
        ),
      );
    } else if (draft.currentStep == 'recording') {
      // Get affirmations from draft state
      final allAffirmations = [
        ...draft.selectedAffirmations,
        ...draft.customAffirmations,
      ];
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              RecordingScreen(affirmations: allAffirmations, draftState: draft),
        ),
      );
    } else {
      // Default to affirmation selection screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AffirmationSelectionScreen(draftState: draft),
        ),
      );
    }
  }

  void _editEntry(Entry entry) {
    _showEditTitleDialog(entry);
  }

  void _handleDeleteRequest(Entry entry) async {
    final shouldDelete = await _showDeleteConfirmationDialog(entry);
    if (shouldDelete) {
      _deleteEntry(entry);
    }
  }

  void _deleteEntry(Entry entry) async {
    try {
      await ref.read(entriesProvider.notifier).deleteEntry(entry.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${entry.title}" wurde gelöscht'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Löschen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog(Entry entry) async {
    final moodTheme = ref.read(currentMoodThemeProvider);

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: moodTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: moodTheme.accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Eintrag löschen?',
                      style: AppTheme.headingStyle.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Möchtest du diesen Eintrag wirklich löschen?',
                    style: AppTheme.bodyStyle.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eintrag:',
                          style: AppTheme.bodyStyle.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.title,
                          style: AppTheme.bodyStyle.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Diese Aktion kann nicht rückgängig gemacht werden.',
                          style: AppTheme.bodyStyle.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Abbrechen',
                    style: AppTheme.bodyStyle.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Löschen'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showEditTitleDialog(Entry entry) {
    final moodTheme = ref.read(currentMoodThemeProvider);
    final TextEditingController titleController = TextEditingController(
      text: entry.title,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: moodTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: moodTheme.accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          title: Text(
            'Titel bearbeiten',
            style: AppTheme.headingStyle.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          content: TextField(
            controller: titleController,
            style: AppTheme.bodyStyle.copyWith(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Neuer Titel eingeben...',
              hintStyle: AppTheme.bodyStyle.copyWith(
                color: Colors.black.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: moodTheme.accentColor, width: 2),
              ),
            ),
            maxLength: 50,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Abbrechen',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newTitle = titleController.text.trim();
                if (newTitle.isNotEmpty && newTitle != entry.title) {
                  _updateEntryTitle(entry, newTitle);
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: moodTheme.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  void _updateEntryTitle(Entry entry, String newTitle) async {
    try {
      final updatedEntry = Entry(
        id: entry.id,
        title: newTitle,
        category: entry.category,
        level: entry.level,
        createdAt: entry.createdAt,
        updatedAt: DateTime.now(),
        takes: entry.takes,
        bgLoopPath: entry.bgLoopPath,
        modeDefault: entry.modeDefault,
      );

      await ref.read(entriesProvider.notifier).updateEntry(updatedEntry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Titel erfolgreich geändert zu: $newTitle'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
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

  void _editDraft(DraftState draft) {
    _showEditDraftTitleDialog(draft);
  }

  void _showEditDraftTitleDialog(DraftState draft) {
    final moodTheme = ref.read(currentMoodThemeProvider);
    final TextEditingController titleController = TextEditingController(
      text: draft.title,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: moodTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: moodTheme.accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          title: Text(
            'Draft-Titel bearbeiten',
            style: AppTheme.headingStyle.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          content: TextField(
            controller: titleController,
            style: AppTheme.bodyStyle.copyWith(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Neuer Titel eingeben...',
              hintStyle: AppTheme.bodyStyle.copyWith(
                color: Colors.black.withValues(alpha: 0.6),
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: moodTheme.accentColor, width: 2),
              ),
            ),
            maxLength: 50,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Abbrechen',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newTitle = titleController.text.trim();
                if (newTitle.isNotEmpty && newTitle != draft.title) {
                  _updateDraftTitle(draft, newTitle);
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: moodTheme.accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  void _updateDraftTitle(DraftState draft, String newTitle) async {
    try {
      final updatedDraft = draft.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );

      await ref
          .read(draftStatesProvider.notifier)
          .saveDraftState(updatedDraft.entryId, updatedDraft);
      // Push drafts to cloud if sync enabled
      await ref.read(syncServiceProvider).pushDraftStates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft-Titel wurde zu "$newTitle" geändert'),
            backgroundColor: AppTheme.secondaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
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

  void _handleDeleteDraftRequest(DraftState draft) async {
    final shouldDelete = await _showDeleteDraftConfirmationDialog(draft);
    if (shouldDelete) {
      _deleteDraft(draft);
    }
  }

  void _deleteDraft(DraftState draft) async {
    try {
      await ref
          .read(draftStatesProvider.notifier)
          .deleteDraftState(draft.entryId);
      // Push drafts to cloud if sync enabled
      await ref.read(syncServiceProvider).pushDraftStates();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Draft vom ${_formatDateTime(DateTime.fromMillisecondsSinceEpoch(int.parse(draft.entryId)))} wurde gelöscht',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Löschen des Drafts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteDraftConfirmationDialog(DraftState draft) async {
    final moodTheme = ref.read(currentMoodThemeProvider);

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: moodTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: moodTheme.accentColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Draft löschen?',
                      style: AppTheme.headingStyle.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Möchtest du diesen Draft wirklich löschen?',
                    style: AppTheme.bodyStyle.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Draft vom:',
                          style: AppTheme.bodyStyle.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDateTime(
                            DateTime.fromMillisecondsSinceEpoch(
                              int.parse(draft.entryId),
                            ),
                          ),
                          style: AppTheme.bodyStyle.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dein Fortschritt geht verloren und kann nicht wiederhergestellt werden.',
                          style: AppTheme.bodyStyle.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Abbrechen',
                    style: AppTheme.bodyStyle.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Löschen'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showInfoDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: moodTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(
              color: moodTheme.accentColor.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: moodTheme.accentColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: moodTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${widget.categoryTitle} Info',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Hier findest du alle deine Aufnahmen für ${widget.categoryTitle}, sortiert nach Schwierigkeitsgraden. Level 1 ist für Anfänger, Level 2 für Fortgeschrittene und Level 3 für alle Inhalte.',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: moodTheme.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Verstanden'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year - $hour:$minute';
  }

  IconData _getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
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
}
