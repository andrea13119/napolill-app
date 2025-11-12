import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import '../providers/app_provider.dart';
import '../services/audio_service.dart';
import '../models/draft_state.dart';
import '../models/user_prefs.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/mood_theme.dart';
import 'music_selection_screen.dart';
import 'category_detail_screen.dart';

class RecordingScreen extends ConsumerStatefulWidget {
  final List<String> affirmations;
  final DraftState? draftState;

  const RecordingScreen({
    super.key,
    required this.affirmations,
    this.draftState,
  });

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  int _currentIndex = 0;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  double _recordingLevel = 0.0;
  String? _currentRecordingPath;
  final Map<int, String> _recordedTakes = {};
  final Map<int, bool> _takeStatus = {};
  StreamSubscription<just_audio.PlayerState>? _playerStateSubscription;
  bool _isStartingPlayback = false;
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _initializeRecording();
    _loadDraftData();
  }

  void _loadDraftData() {
    if (widget.draftState != null) {
      // Load recorded takes from draft state
      final recordedTakes = widget.draftState!.recordedTakes;
      for (int i = 0; i < recordedTakes.length; i++) {
        if (recordedTakes[i].isNotEmpty) {
          _recordedTakes[i] = recordedTakes[i];
          _takeStatus[i] = true;
        }
      }

      // Set current index to next index from draft, but ensure it's within bounds
      _currentIndex = widget.draftState!.nextIndex;
      if (_currentIndex >= widget.affirmations.length) {
        _currentIndex = widget.affirmations.length - 1;
        debugPrint(
          'Warning: nextIndex ${widget.draftState!.nextIndex} was out of bounds, clamped to $_currentIndex',
        );
      }

      // Set current recording path if available
      if (widget.draftState!.lastPartialFile != null &&
          widget.draftState!.lastPartialFile!.isNotEmpty) {
        _currentRecordingPath = widget.draftState!.lastPartialFile;
      }
    }
  }

  @override
  void dispose() {
    // Cancel player state subscription and timer
    _playerStateSubscription?.cancel();
    _playbackTimer?.cancel();

    // Stop any ongoing recording or playback
    if (_isRecording) {
      _stopRecording();
    }
    if (_isPlaying) {
      AudioService().stop();
    }
    super.dispose();
  }

  Future<void> _initializeRecording() async {
    try {
      // AudioService is already initialized in main.dart
      debugPrint('Recording screen initialized with AudioService');
    } catch (e) {
      debugPrint('Recording initialization error: $e');
    }
  }

  void _startRecording() async {
    try {
      // Use existing entryId if resuming a draft, otherwise create new one
      final entryId =
          widget.draftState?.entryId ??
          DateTime.now().millisecondsSinceEpoch.toString();
      await AudioService().startRecording(entryId, _currentIndex + 1);

      setState(() {
        _isRecording = true;
        _isPaused = false;
      });

      debugPrint('Starting recording for affirmation ${_currentIndex + 1}');

      // Start recording level updates
      _updateRecordingLevel();
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
      debugPrint('Recording error: $e');

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aufnahme-Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _pauseRecording() async {
    try {
      await AudioService().pauseRecording();
      setState(() {
        _isPaused = true;
      });
      debugPrint('Recording paused');
    } catch (e) {
      debugPrint('Pause error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pause-Fehler: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _resumeRecording() async {
    try {
      await AudioService().resumeRecording();
      setState(() {
        _isPaused = false;
      });
      debugPrint('Recording resumed');
    } catch (e) {
      debugPrint('Resume error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resume-Fehler: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _stopRecording() async {
    try {
      // Stop real recording and get file path
      final filePath = await AudioService().stopRecording();

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _currentRecordingPath = filePath ?? '';
        _recordedTakes[_currentIndex] = filePath ?? '';
        _takeStatus[_currentIndex] = true;
      });

      debugPrint('Recording stopped, saved as: $filePath');
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });
      debugPrint('Stop error: $e');
    }
  }

  void _playRecording() async {
    if (_currentRecordingPath == null || _currentRecordingPath!.isEmpty) {
      debugPrint('No recording path available');
      return;
    }

    // Prevent multiple simultaneous playback starts
    if (_isStartingPlayback) {
      debugPrint('Playback already starting, ignoring request');
      return;
    }

    try {
      _isStartingPlayback = true;

      // Clean up any existing playback state first
      _playerStateSubscription?.cancel();
      _playbackTimer?.cancel();

      setState(() {
        _isPlaying = true;
      });

      debugPrint('Attempting to play recording: $_currentRecordingPath');

      // Play real audio file using playAffirmation method
      await AudioService().playAffirmation(_currentRecordingPath!);

      debugPrint('Playback started successfully');

      // Add a small delay before setting up the listener to avoid immediate triggers
      await Future.delayed(const Duration(milliseconds: 500));

      // Listen to player state changes to detect when playback ends
      _playerStateSubscription = AudioService().playerStateStream.listen((
        playerState,
      ) {
        debugPrint(
          'Player state changed: ${playerState.processingState}, playing: ${playerState.playing}',
        );

        // Reset to play button when playback is completed
        if (mounted &&
            playerState.processingState ==
                just_audio.ProcessingState.completed) {
          _resetPlaybackState();
        }
      });

      // Set up a fallback timer in case the stream listener doesn't work
      _playbackTimer?.cancel();
      _playbackTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && _isPlaying) {
          debugPrint('Playback timer fallback triggered');
          _resetPlaybackState();
        }
      });

      _isStartingPlayback = false;
    } catch (e) {
      _isStartingPlayback = false;
      setState(() {
        _isPlaying = false;
      });
      debugPrint('Playback error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wiedergabe-Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetPlaybackState() {
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isStartingPlayback = false;
      });
      debugPrint('Playback state reset to play');
    }
  }

  void _stopPlayback() async {
    try {
      debugPrint('Stopping playback...');

      // Cancel the stream listener and timer
      _playerStateSubscription?.cancel();
      _playbackTimer?.cancel();

      await AudioService().stop();
      _resetPlaybackState();
      debugPrint('Playback stopped successfully');
    } catch (e) {
      debugPrint('Stop playback error: $e');
      // Force reset the state even if stop fails
      _resetPlaybackState();
    }
  }

  void _nextAffirmation() {
    // Check if current affirmation is recorded
    if (_takeStatus[_currentIndex] != true) {
      // Show warning message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Bitte nimm die aktuelle Affirmation auf, bevor du weiterg gehst.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }

    // Reset playback state when switching affirmations
    _resetPlaybackState();
    _playerStateSubscription?.cancel();
    _playbackTimer?.cancel();

    if (_currentIndex < widget.affirmations.length - 1) {
      setState(() {
        _currentIndex++;
        _currentRecordingPath = _recordedTakes[_currentIndex];
      });
    } else {
      _finishRecording();
    }
  }

  void _previousAffirmation() {
    if (_currentIndex > 0) {
      // Reset playback state when switching affirmations
      _resetPlaybackState();
      _playerStateSubscription?.cancel();
      _playbackTimer?.cancel();

      setState(() {
        _currentIndex--;
        _currentRecordingPath = _recordedTakes[_currentIndex];
      });
    }
  }

  bool _hasAnyProgress() {
    // Check if there's any recording progress
    return _takeStatus.values.any((status) => status == true) ||
        _recordedTakes.isNotEmpty ||
        _currentIndex > 0;
  }

  void _pauseAndSave() async {
    try {
      // Get user preferences
      final userPrefs = ref.read(userPrefsProvider);

      // Use existing entryId if resuming a draft, otherwise create new one
      final entryId =
          widget.draftState?.entryId ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Create draft state - use actual affirmations length, not hardcoded 30
      final affirmationsLength = widget.affirmations.length;
      final takeStatusList = List.generate(affirmationsLength, (index) {
        if (_takeStatus[index] == true) {
          return TakeStatus.recorded;
        }
        return TakeStatus.todo;
      });

      // Convert recordedTakes Map to List for storage
      final recordedTakesList = <String>[];
      for (int i = 0; i < affirmationsLength; i++) {
        final takePath = _recordedTakes[i];
        if (takePath != null && takePath.isNotEmpty) {
          recordedTakesList.add(takePath);
        } else {
          recordedTakesList.add(''); // Empty string for missing takes
        }
      }

      // Find the next index that needs recording (not yet recorded)
      int nextUnrecordedIndex = _currentIndex;
      for (int i = _currentIndex; i < affirmationsLength; i++) {
        if (_takeStatus[i] != true) {
          nextUnrecordedIndex = i;
          break;
        }
        // If we reach the end and all are recorded, stay at the last index
        if (i == affirmationsLength - 1) {
          nextUnrecordedIndex = i;
        }
      }

      debugPrint('=== DRAFT SAVE DEBUG ===');
      debugPrint('Current index: $_currentIndex');
      debugPrint('Affirmations length: $affirmationsLength');
      debugPrint('Calculated nextUnrecordedIndex: $nextUnrecordedIndex');
      debugPrint('Take status: ${_takeStatus.entries.where((e) => e.value == true).map((e) => e.key).toList()}');
      debugPrint('Recorded takes count: ${recordedTakesList.where((t) => t.isNotEmpty).length}');

      final draftState = DraftState(
        entryId: entryId,
        title:
            widget.draftState?.title ??
            'Entwurf ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
        category: widget.draftState?.category ?? 'custom',
        nextIndex: nextUnrecordedIndex,
        perTakeStatus: takeStatusList,
        lastPartialFile: _currentRecordingPath,
        bookmarks: [],
        selectedAffirmations: widget.draftState?.selectedAffirmations ?? [],
        customAffirmations: widget.draftState?.customAffirmations ?? [],
        currentStep: 'recording',
        createdAt: widget.draftState?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        recordedTakes: recordedTakesList, // Add recorded takes
      );
      
      debugPrint('DraftState created with nextIndex: ${draftState.nextIndex}');

      // Debug logging
      debugPrint('Saving draft with category: ${draftState.category}');
      debugPrint('Draft entryId: ${draftState.entryId}');
      debugPrint('Draft title: ${draftState.title}');
      debugPrint('Original draft title: ${widget.draftState?.title}');

      // Save draft
      await ref.read(draftStatesProvider.notifier).addDraft(draftState);
      // Push drafts to cloud if sync enabled
      await ref.read(syncServiceProvider).pushDraftStates();

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
                'Aufnahme pausiert!',
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
                    'Deine Aufnahme ist sicher!',
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
                'Dein Aufnahmefortschritt wurde erfolgreich gespeichert.',
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
                          'Deine Aufnahme geht nicht verloren',
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
                          'Alle bisherigen Aufnahmen bleiben erhalten',
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

  void _finishRecording() {
    // Use existing entryId if resuming a draft, otherwise create new one
    final entryId =
        widget.draftState?.entryId ??
        DateTime.now().millisecondsSinceEpoch.toString();

    // Create draft state - use actual affirmations length, not hardcoded 30
    final affirmationsLength = widget.affirmations.length;
    final takeStatusList = List.generate(affirmationsLength, (index) {
      if (_takeStatus[index] == true) {
        return TakeStatus.recorded;
      }
      return TakeStatus.todo;
    });

    // Convert recordedTakes Map to List for storage
    final recordedTakesList = <String>[];
    for (int i = 0; i < affirmationsLength; i++) {
      final takePath = _recordedTakes[i];
      if (takePath != null && takePath.isNotEmpty) {
        recordedTakesList.add(takePath);
      } else {
        recordedTakesList.add(''); // Empty string for missing takes
      }
    }

    // Find the next index that needs recording (not yet recorded)
    int nextUnrecordedIndex = _currentIndex;
    for (int i = _currentIndex; i < affirmationsLength; i++) {
      if (_takeStatus[i] != true) {
        nextUnrecordedIndex = i;
        break;
      }
      // If we reach the end and all are recorded, stay at the last index
      if (i == affirmationsLength - 1) {
        nextUnrecordedIndex = i;
      }
    }

    debugPrint('=== FINISH RECORDING DEBUG ===');
    debugPrint('Current index: $_currentIndex');
    debugPrint('Affirmations length: $affirmationsLength');
    debugPrint('Calculated nextUnrecordedIndex: $nextUnrecordedIndex');
    debugPrint('Take status: ${_takeStatus.entries.where((e) => e.value == true).map((e) => e.key).toList()}');
    debugPrint('Recorded takes count: ${recordedTakesList.where((t) => t.isNotEmpty).length}');

    final draftState = DraftState(
      entryId: entryId,
      title:
          widget.draftState?.title ??
          'Entwurf ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
      category: widget.draftState?.category ?? 'custom',
      nextIndex: nextUnrecordedIndex,
      perTakeStatus: takeStatusList,
      lastPartialFile: _currentRecordingPath,
      bookmarks: [],
      selectedAffirmations: widget.draftState?.selectedAffirmations ?? [],
      customAffirmations: widget.draftState?.customAffirmations ?? [],
      currentStep: 'recording',
      createdAt: widget.draftState?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      recordedTakes: recordedTakesList, // Add recorded takes
    );

    debugPrint('DraftState created for music selection with nextIndex: ${draftState.nextIndex}');

    // Save draft
    ref
        .read(draftStatesProvider.notifier)
        .saveDraftState(draftState.entryId, draftState);

    // Navigate to music selection
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MusicSelectionScreen(
          affirmations: widget.affirmations,
          recordedTakes: _recordedTakes,
          draftState: draftState,
        ),
      ),
    );
  }

  void _updateRecordingLevel() {
    if (_isRecording && !_isPaused && mounted) {
      // Simulate audio level changes
      setState(() {
        _recordingLevel =
            (0.3 + (DateTime.now().millisecondsSinceEpoch % 100) / 100 * 0.7);
      });

      // Only continue if still recording and widget is mounted
      if (_isRecording && !_isPaused && mounted) {
        Future.delayed(
          const Duration(milliseconds: 100),
          _updateRecordingLevel,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use neutral theme for recording screen
    final neutralTheme = MoodTheme.standard;
    final currentAffirmation = widget.affirmations[_currentIndex];
    final progress = (_currentIndex + 1) / widget.affirmations.length;
    final isCompleted = _takeStatus[_currentIndex] == true;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: neutralTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Progress
              _buildProgress(progress),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Helpful guidance text
                      _buildGuidanceText(),

                      const SizedBox(height: 16),

                      // Current affirmation
                      _buildCurrentAffirmation(currentAffirmation),

                      const SizedBox(height: 24),

                      // Recording level indicator
                      if (_isRecording) _buildRecordingLevel(),

                      const SizedBox(height: 24),

                      // Recording controls (Play/Record)
                      _buildRecordingControls(isCompleted),

                      const SizedBox(height: 20),

                      // Navigation (Zurück/Weiter)
                      _buildNavigationButtons(),

                      const SizedBox(height: 16),

                      // Pause & Save button
                      _buildPauseAndSaveButton(),
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
                  Text(
                    'Aufnahme',
                    style: AppTheme.headingStyle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Container(width: 100, height: 1, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    'Satz ${_currentIndex + 1} von ${widget.affirmations.length}',
                    style: AppTheme.appTaglineStyle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_takeStatus.values.where((status) => status == true).length} von ${widget.affirmations.length} aufgenommen',
                    style: AppTheme.appTaglineStyle.copyWith(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
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

  Widget _buildProgress(double progress) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.white.withValues(alpha: 0.3),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
        minHeight: 8,
      ),
    );
  }

  Widget _buildGuidanceText() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.yellow[300],
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'NICHT VERGESSEN!',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow[300],
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTipBullet('Hintergrundgeräusche minimieren'),
              _buildTipBullet('Mikro 10–15 cm vom Mund, leicht seitlich'),
              _buildTipBullet('Körperhaltung: Aufrecht und entspannt'),
              _buildTipBullet('Klar und deutlich sprechen'),
              const SizedBox(height: 4),
              _buildTipBullet(
                'Embodiment: Stell dir vor, du hast dein Ziel bereits erreicht. Halte 1 Szene vor Augen, in der der Satz wahr ist',
                isHighlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentAffirmation(String affirmation) {
    return Card(
      color: AppTheme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              _takeStatus[_currentIndex] == true
                  ? Icons.check_circle
                  : Icons.record_voice_over,
              color: _takeStatus[_currentIndex] == true
                  ? Colors.green
                  : MoodTheme.standard.accentColor,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              affirmation,
              style: AppTheme.headingDarkStyle.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _takeStatus[_currentIndex] == true
                  ? 'Aufgenommen ✓'
                  : 'Aufnahme erforderlich',
              style: AppTheme.bodyDarkStyle.copyWith(
                color: _takeStatus[_currentIndex] == true
                    ? Colors.green
                    : Colors.orange[700],
                fontWeight: _takeStatus[_currentIndex] == true
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingLevel() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic,
            color: _isPaused ? Colors.orange : Colors.red,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _recordingLevel,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isPaused ? Colors.orange : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            _isPaused ? 'PAUSIERT' : 'AUFNAHME',
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: _isPaused ? Colors.orange : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingControls(bool isCompleted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Play button
        if (_currentRecordingPath != null)
          _buildControlButton(
            icon: _isPlaying ? Icons.stop : Icons.play_arrow,
            onPressed: _isPlaying ? _stopPlayback : _playRecording,
            color: Colors.blue,
          ),

        // Record/Pause/Stop button
        _buildControlButton(
          icon: _isRecording
              ? (_isPaused ? Icons.play_arrow : Icons.pause)
              : Icons.mic,
          onPressed: _isRecording
              ? (_isPaused ? _resumeRecording : _pauseRecording)
              : _startRecording,
          color: _isRecording
              ? (_isPaused ? Colors.orange : Colors.red)
              : Colors.green,
          size: 60,
        ),

        // Stop button
        if (_isRecording)
          _buildControlButton(
            icon: Icons.stop,
            onPressed: _stopRecording,
            color: Colors.red,
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    double size = 50,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _currentIndex > 0 ? _previousAffirmation : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Zurück'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentIndex > 0
                  ? MoodTheme.standard.accentColor
                  : Colors.grey,
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Next/Finish button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _takeStatus[_currentIndex] == true
                ? _nextAffirmation
                : null,
            icon: Icon(
              _currentIndex < widget.affirmations.length - 1
                  ? Icons.arrow_forward
                  : Icons.check,
            ),
            label: Text(
              _currentIndex < widget.affirmations.length - 1
                  ? 'Weiter'
                  : 'Fertig',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _takeStatus[_currentIndex] == true
                  ? MoodTheme.standard.accentColor
                  : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPauseAndSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: AppConstants.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: _hasAnyProgress() ? _pauseAndSave : null,
        icon: const Icon(Icons.pause),
        label: const Text('PAUSE & SPEICHERN'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasAnyProgress() ? Colors.orange : Colors.grey,
        ),
      ),
    );
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

  Widget _buildTipBullet(String text, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 14,
              color: isHighlight ? Colors.yellow[300] : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 12,
                color: isHighlight ? Colors.yellow[300] : Colors.white,
                fontFamily: 'Poppins',
                height: 1.3,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
