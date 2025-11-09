import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/mood_theme.dart';
import '../providers/app_provider.dart';
import '../models/entry.dart';
import '../models/draft_state.dart';
import 'category_detail_screen.dart';

class MusicSelectionScreen extends ConsumerStatefulWidget {
  final List<String> affirmations;
  final Map<int, String> recordedTakes;
  final DraftState? draftState;

  const MusicSelectionScreen({
    super.key,
    required this.affirmations,
    required this.recordedTakes,
    this.draftState,
  });

  @override
  ConsumerState<MusicSelectionScreen> createState() =>
      _MusicSelectionScreenState();
}

class _MusicSelectionScreenState extends ConsumerState<MusicSelectionScreen> {
  String? _selectedMusic;
  bool _isPreviewing = false;
  just_audio.AudioPlayer? _audioPlayer;
  StreamSubscription<just_audio.PlayerState>? _playerStateSubscription;

  // Get level-based music options
  List<MusicOption> get _musicOptions {
    final userPrefs = ref.read(userPrefsProvider);
    final level = userPrefs.level;
    final allowedFrequencies =
        AppConstants.levelSolfeggioFrequencies[level] ?? [];

    // Always include "none" option
    final options = [
      MusicOption(
        id: 'none',
        title: 'Keine Musik',
        description: 'Nur deine Stimme',
        icon: Icons.volume_off,
        color: Colors.grey,
      ),
    ];

    // Add level-appropriate solfeggio frequencies
    for (final frequency in allowedFrequencies) {
      final description = AppConstants.solfeggioDescriptions[frequency];
      if (description != null) {
        options.add(
          MusicOption(
            id: 'solfeggio_$frequency',
            title: description['name']!,
            description: description['title']!,
            icon: _getSolfeggioIcon(frequency),
            color: _getSolfeggioColor(frequency),
          ),
        );
      }
    }

    return options;
  }

  // Helper methods for solfeggio icons and colors
  IconData _getSolfeggioIcon(String frequency) {
    switch (frequency) {
      case '174':
        return Icons.waves;
      case '284':
        return Icons.auto_awesome;
      case '396':
        return Icons.lock_open;
      case '417':
        return Icons.transform;
      case '528':
        return Icons.favorite;
      case '639':
        return Icons.people;
      case '741':
        return Icons.psychology;
      case '852':
        return Icons.spa;
      case '963':
        return Icons.star;
      default:
        return Icons.music_note;
    }
  }

  Color _getSolfeggioColor(String frequency) {
    switch (frequency) {
      case '174':
        return Colors.brown;
      case '284':
        return Colors.purple;
      case '396':
        return Colors.red;
      case '417':
        return Colors.orange;
      case '528':
        return Colors.green;
      case '639':
        return Colors.blue;
      case '741':
        return Colors.indigo;
      case '852':
        return Colors.teal;
      case '963':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer = just_audio.AudioPlayer();
    _initializeMusicSelection();
  }

  void _initializeMusicSelection() {
    // Get user preferences for level-specific music selection
    final userPrefs = ref.read(userPrefsProvider);
    final level = userPrefs.level;

    // Try to get level-specific background music first
    final levelMusic = ref
        .read(userPrefsProvider.notifier)
        .getLevelBackgroundMusic(level);
    final lastSelected = userPrefs.lastBackgroundMusic;

    debugPrint('=== MUSIC SELECTION INITIALIZATION ===');
    debugPrint('Level: $level');
    debugPrint('Level-specific music: $levelMusic');
    debugPrint('Last selected from userPrefs: $lastSelected');

    // Check if level-specific music is available and valid for this level
    if (levelMusic != null && levelMusic.isNotEmpty && levelMusic != 'null') {
      final allowedFrequencies =
          AppConstants.levelSolfeggioFrequencies[level] ?? [];
      final frequency = levelMusic.replaceAll('solfeggio_', '');

      if (allowedFrequencies.contains(frequency)) {
        _selectedMusic = levelMusic;
        debugPrint('Initial selection set to level-specific: $_selectedMusic');
      } else {
        // Level-specific music is not valid for this level, use default
        _selectedMusic = _getDefaultMusicForLevel(level);
        debugPrint(
          'Level-specific music invalid, using default: $_selectedMusic',
        );
      }
    } else if (lastSelected != null &&
        lastSelected.isNotEmpty &&
        lastSelected != 'null') {
      // Check if last selected is valid for this level
      final allowedFrequencies =
          AppConstants.levelSolfeggioFrequencies[level] ?? [];
      final frequency = lastSelected.replaceAll('solfeggio_', '');

      if (allowedFrequencies.contains(frequency)) {
        _selectedMusic = lastSelected;
        debugPrint('Initial selection set to last selected: $_selectedMusic');
      } else {
        _selectedMusic = _getDefaultMusicForLevel(level);
        debugPrint(
          'Last selected invalid for level, using default: $_selectedMusic',
        );
      }
    } else {
      _selectedMusic = _getDefaultMusicForLevel(level);
      debugPrint('Initial selection defaulted to: $_selectedMusic');
    }

    setState(() {});
  }

  String _getDefaultMusicForLevel(String level) {
    final allowedFrequencies =
        AppConstants.levelSolfeggioFrequencies[level] ?? [];
    if (allowedFrequencies.isNotEmpty) {
      return 'solfeggio_${allowedFrequencies.first}';
    }
    return 'solfeggio_528'; // Fallback
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always use neutral theme for music selection screen
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
                        'Hintergrundmusik wählen',
                        style: AppTheme.headingStyle.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'Wähle optional eine Solfeggio-Frequenz als Hintergrundmusik für deine Affirmationen.\n\n*Du kannst deine Auswahl später jederzeit ändern.*',
                        style: AppTheme.bodyStyle,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Music options
                      ..._musicOptions.map((music) => _buildMusicCard(music)),

                      const SizedBox(height: 16),

                      // Current playing indicator
                      if (_isPreviewing &&
                          _selectedMusic != null &&
                          _selectedMusic != 'none')
                        _buildPlayingIndicator(),

                      const SizedBox(height: 32),

                      // Action buttons
                      _buildActionButtons(),
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

  Widget _buildMusicCard(MusicOption music) {
    final isSelected = _selectedMusic == music.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: isSelected
            ? music.color.withValues(alpha: 0.2)
            : AppTheme.cardColor,
        child: InkWell(
          onTap: () => _selectMusic(music.id),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          child: Container(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        music.color.withValues(alpha: 0.1),
                        music.color.withValues(alpha: 0.3),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? music.color
                          : music.color.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(music.icon, color: Colors.white, size: 24),
                  ),

                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          music.title,
                          style: AppTheme.headingDarkStyle.copyWith(
                            fontSize: 18,
                            color: isSelected
                                ? music.color
                                : AppTheme.textDarkColor,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          music.description,
                          style: AppTheme.bodyDarkStyle.copyWith(
                            fontSize: 14,
                            color: isSelected ? music.color : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),

                  // Selection indicator
                  if (isSelected)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isPreviewing && _selectedMusic == music.id)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: music.color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.volume_up,
                              color: Colors.white,
                              size: 12,
                            ),
                          )
                        else
                          Icon(
                            Icons.check_circle,
                            color: music.color,
                            size: 24,
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

  Widget _buildPlayingIndicator() {
    final currentMusic = _musicOptions.firstWhere(
      (music) => music.id == _selectedMusic,
      orElse: () => _musicOptions.first,
    );

    return Card(
      color: currentMusic.color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: currentMusic.color,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.volume_up, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spielt gerade:',
                    style: AppTheme.bodyDarkStyle.copyWith(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    currentMusic.title,
                    style: AppTheme.headingDarkStyle.copyWith(
                      fontSize: 16,
                      color: currentMusic.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _stopPreview,
              icon: const Icon(Icons.stop, color: Colors.red),
              tooltip: 'Stoppen',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: _proceedToPreview,
        style: ElevatedButton.styleFrom(
          backgroundColor: MoodTheme.standard.accentColor,
        ),
        child: Text(
          'AUSWÄHLEN & FERTIGSTELLEN',
          style: AppTheme.buttonStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _selectMusic(String musicId) async {
    // If clicking the same music that's currently playing, stop it
    if (_selectedMusic == musicId && _isPreviewing) {
      _stopPreview();
      return;
    }

    // Stop any current preview
    if (_isPreviewing) {
      _stopPreview();
    }

    setState(() {
      _selectedMusic = musicId;
    });

    // Auto-play the selected music (except for 'none')
    if (musicId != 'none') {
      _startPreview();
    }
  }

  void _startPreview() async {
    if (_selectedMusic == null || _selectedMusic == 'none') return;

    try {
      setState(() {
        _isPreviewing = true;
      });

      debugPrint('Starting preview for: $_selectedMusic');

      // Stop any current playback
      await _audioPlayer!.stop();

      // Load and play the selected music
      final assetPath = 'assets/audio/$_selectedMusic.m4a';
      debugPrint('Loading asset: $assetPath');

      // Try to load the asset with timeout
      await _audioPlayer!
          .setAsset(assetPath)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout beim Laden der Audio-Datei: $assetPath');
            },
          );
      debugPrint('Asset loaded successfully');

      // Check if the asset was loaded properly
      final duration = _audioPlayer!.duration;
      if (duration == null) {
        throw Exception('Audio-Datei konnte nicht geladen werden: $assetPath');
      }
      debugPrint('Audio duration: $duration');

      await _audioPlayer!.play().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout beim Starten der Wiedergabe');
        },
      );
      debugPrint('Playback started');

      // Listen for playback completion
      _playerStateSubscription?.cancel();
      _playerStateSubscription = _audioPlayer!.playerStateStream.listen((
        playerState,
      ) {
        debugPrint('Player state changed: ${playerState.processingState}');
        if (mounted &&
            playerState.processingState ==
                just_audio.ProcessingState.completed) {
          setState(() {
            _isPreviewing = false;
          });
          debugPrint('Preview completed, button reset');
        }
      });

      debugPrint('Preview setup completed for: $assetPath');
    } catch (e) {
      debugPrint('Preview error: $e');

      // Fallback: Use simulation if audio loading fails
      _startPreviewSimulation();
    }
  }

  void _startPreviewSimulation() {
    debugPrint('Starting preview simulation for: $_selectedMusic');

    // Simulate preview with a timer
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isPreviewing = false;
        });
        debugPrint('Preview simulation completed');
      }
    });
  }

  void _stopPreview() async {
    try {
      debugPrint('Stopping preview...');
      await _audioPlayer!.stop();
      _playerStateSubscription?.cancel();
      setState(() {
        _isPreviewing = false;
      });
      debugPrint('Preview stopped successfully');
    } catch (e) {
      debugPrint('Stop preview error: $e');
      // Force reset the state even if stop fails
      setState(() {
        _isPreviewing = false;
      });
    }
  }

  void _proceedToPreview() async {
    // Stop any current preview music before navigating
    if (_isPreviewing) {
      _stopPreview();
    }

    // Navigate to preview screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreationPreviewScreen(
          affirmations: widget.affirmations,
          recordedTakes: widget.recordedTakes,
          selectedMusic: _selectedMusic,
          draftState: widget.draftState,
        ),
      ),
    );
  }
}

class MusicOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  MusicOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Creation Preview Screen
class CreationPreviewScreen extends ConsumerStatefulWidget {
  final List<String> affirmations;
  final Map<int, String> recordedTakes;
  final String? selectedMusic;
  final DraftState? draftState;

  const CreationPreviewScreen({
    super.key,
    required this.affirmations,
    required this.recordedTakes,
    this.selectedMusic,
    this.draftState,
  });

  @override
  ConsumerState<CreationPreviewScreen> createState() =>
      _CreationPreviewScreenState();
}

class _CreationPreviewScreenState extends ConsumerState<CreationPreviewScreen> {
  bool _isPlaying = false;
  just_audio.AudioPlayer? _affirmationPlayer;
  just_audio.AudioPlayer? _backgroundPlayer;
  StreamSubscription<just_audio.PlayerState>? _affirmationStateSubscription;
  StreamSubscription<just_audio.PlayerState>? _backgroundStateSubscription;
  int _currentAffirmationIndex = 0;

  @override
  void initState() {
    super.initState();
    _affirmationPlayer = just_audio.AudioPlayer();
    _backgroundPlayer = just_audio.AudioPlayer();
  }

  @override
  void dispose() {
    _affirmationStateSubscription?.cancel();
    _backgroundStateSubscription?.cancel();
    _affirmationPlayer?.dispose();
    _backgroundPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Always use neutral theme for preview screen
    final neutralTheme = MoodTheme.standard;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: neutralTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header with Logo
              _buildHeader(),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status indicators
                      _buildStatusIndicators(),

                      const SizedBox(height: 60),

                      // Central play button
                      _buildCentralPlayButton(),

                      const SizedBox(height: 24),

                      // Description text
                      Text(
                        'Höre dir deine Kreation an',
                        style: AppTheme.bodyStyle.copyWith(fontSize: 18),
                      ),

                      const SizedBox(height: 80),

                      // Action button
                      _buildActionButton(),
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
              child: Image.asset(
                'assets/images/logo_napolill.png',
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildStatusIndicators() {
    return Column(
      children: [
        _buildStatusItem('AUFNAHME', true),
        const SizedBox(height: 16),
        _buildStatusItem('SOLFEGGIO HINTERGRUNDMUSIK', true),
      ],
    );
  }

  Widget _buildStatusItem(String text, bool isCompleted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted ? MoodTheme.standard.accentColor : Colors.grey,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCentralPlayButton() {
    return GestureDetector(
      onTap: _isPlaying ? _stopPlayback : _startPlayback,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _isPlaying ? Colors.red : Colors.green,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isPlaying ? Colors.red : Colors.green).withValues(
                alpha: 0.3,
              ),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Icon(
          _isPlaying ? Icons.stop : Icons.play_arrow,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
      child: ElevatedButton(
        onPressed: _goToMediathek,
        style: ElevatedButton.styleFrom(
          backgroundColor: MoodTheme.standard.accentColor,
        ),
        child: Text('ZU DEINER MEDIATHEK', style: AppTheme.buttonStyle),
      ),
    );
  }

  void _startPlayback() async {
    try {
      setState(() {
        _isPlaying = true;
        _currentAffirmationIndex = 0;
      });

      // Prepare both players first
      List<Future> preparationTasks = [];

      // Prepare background music if selected
      if (widget.selectedMusic != null && widget.selectedMusic != 'none') {
        final backgroundPath = 'assets/audio/${widget.selectedMusic}.m4a';
        preparationTasks.add(_backgroundPlayer!.setAsset(backgroundPath));
        preparationTasks.add(
          _backgroundPlayer!.setLoopMode(just_audio.LoopMode.one),
        );
      }

      // Wait for all preparations to complete
      await Future.wait(preparationTasks);

      // Start both players simultaneously
      List<Future> playTasks = [];

      if (widget.selectedMusic != null && widget.selectedMusic != 'none') {
        playTasks.add(_backgroundPlayer!.play());
      }

      // Start playing affirmations
      playTasks.add(_playNextAffirmation());

      // Start both players at the same time
      await Future.wait(playTasks);

      debugPrint('Both players started successfully');
    } catch (e) {
      setState(() {
        _isPlaying = false;
      });
      debugPrint('Playback error: $e');
    }
  }

  void _stopPlayback() async {
    try {
      await _affirmationPlayer!.stop();
      await _backgroundPlayer!.stop();
      setState(() {
        _isPlaying = false;
        _currentAffirmationIndex = 0;
      });
    } catch (e) {
      debugPrint('Stop playback error: $e');
    }
  }

  Future<void> _playNextAffirmation() async {
    if (_currentAffirmationIndex >= widget.recordedTakes.length) {
      // All affirmations played, stop playback
      _stopPlayback();
      return;
    }

    final takePath = widget.recordedTakes[_currentAffirmationIndex];
    if (takePath != null && takePath.isNotEmpty) {
      // Prepare the affirmation
      await _affirmationPlayer!.setFilePath(takePath);

      // Start playing
      await _affirmationPlayer!.play();

      // Listen for completion
      _affirmationStateSubscription?.cancel();
      _affirmationStateSubscription = _affirmationPlayer!.playerStateStream
          .listen((state) {
            if (state.processingState == just_audio.ProcessingState.completed) {
              _currentAffirmationIndex++;
              _playNextAffirmation();
            }
          });
    } else {
      // Skip empty takes
      _currentAffirmationIndex++;
      _playNextAffirmation();
    }
  }

  void _goToMediathek() async {
    try {
      // Get user preferences for category and level
      final userPrefs = ref.read(userPrefsProvider);

      // Use existing entryId if resuming a draft, otherwise create new one
      final entryId =
          widget.draftState?.entryId ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Convert recordedTakes Map to List of file paths
      final takes = <String>[];
      for (int i = 0; i < 30; i++) {
        final takePath = widget.recordedTakes[i];
        if (takePath != null && takePath.isNotEmpty) {
          takes.add(takePath);
        } else {
          takes.add(''); // Empty string for missing takes
        }
      }

      // Create background music path
      String? bgLoopPath;
      if (widget.selectedMusic != null && widget.selectedMusic != 'none') {
        bgLoopPath = 'assets/audio/${widget.selectedMusic}.m4a';
      }

      // Determine the title: use custom title if user renamed the draft, otherwise use standard title
      String entryTitle;
      if (widget.draftState != null &&
          widget.draftState!.title != 'Draft' &&
          !widget.draftState!.title.startsWith('Draft ')) {
        // User has customized the title, use it
        entryTitle = widget.draftState!.title;
        debugPrint('Using custom title: $entryTitle');
      } else {
        // Use standard title format
        entryTitle = _generateEntryTitle(
          userPrefs.selectedTopic,
          userPrefs.level,
        );
        debugPrint('Using standard title: $entryTitle');
        debugPrint('Draft title was: ${widget.draftState?.title}');
      }

      // Create the Entry
      final entry = Entry(
        id: entryId,
        title: entryTitle,
        category: userPrefs.selectedTopic,
        level: userPrefs.level,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        takes: takes,
        bgLoopPath: bgLoopPath,
        modeDefault: 'meditation', // Default mode
      );

      // Save entry to database
      await ref.read(entriesProvider.notifier).addEntry(entry);

      // Trigger cloud push for entries if sync enabled
      await ref.read(syncServiceProvider).pushEntries();

      // Refresh statistics to trigger badge notifications
      await ref.read(statisticsNotifierProvider.notifier).refreshStatistics();

      // Save level-specific background music selection
      if (widget.selectedMusic != null) {
        await ref
            .read(userPrefsProvider.notifier)
            .updateLevelBackgroundMusic(userPrefs.level, widget.selectedMusic!);
        await ref
            .read(userPrefsProvider.notifier)
            .updateLastBackgroundMusic(widget.selectedMusic!);
      }

      // Delete draft if it exists (since entry is now completed)
      if (widget.draftState != null) {
        await ref.read(draftStatesProvider.notifier).deleteDraftState(entryId);
        // Push updated drafts state to cloud
        await ref.read(syncServiceProvider).pushDraftStates();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Affirmation erfolgreich in ${_getCategoryDisplayName(userPrefs.selectedTopic)} gespeichert!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Navigate to the specific category detail screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(
              categoryKey: userPrefs.selectedTopic,
              categoryTitle: _getCategoryDisplayName(userPrefs.selectedTopic),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving entry: $e');
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

  String _generateEntryTitle(String category, String level) {
    final categoryName = _getCategoryDisplayName(category);
    final levelName = _getLevelDisplayName(level);
    final date = DateTime.now();
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    return '$categoryName - $levelName ($dateStr)';
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
}
