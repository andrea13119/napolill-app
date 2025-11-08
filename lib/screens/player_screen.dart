import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/entry.dart';
import '../models/listen_log.dart';
import '../services/audio_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/mood_theme.dart';
import '../providers/app_provider.dart';
import 'completion_screen.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final Entry entry;
  final String mode; // 'meditation' or 'endless'
  final int? durationMinutes; // Only for meditation mode

  const PlayerScreen({
    super.key,
    required this.entry,
    required this.mode,
    this.durationMinutes,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isLocked = false;
  bool _isCompleted = false;
  Timer? _autoLockTimer;
  Timer? _unlockTimer;
  bool _isUnlocking = false;
  double _backgroundVolume = 0.7; // Increased default volume
  String? _selectedBackgroundMusic;
  Duration _currentTime = Duration.zero;
  Duration _totalTime = Duration.zero;
  Duration _remainingTime = Duration.zero;
  Duration _sessionTime = Duration.zero; // Total session time for endless mode
  Timer? _sessionTimer; // Timer for endless mode session
  DateTime? _sessionStartTime; // When the session started

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  // Timer variables
  Timer? _meditationTimer;
  Timer? _progressTimer;
  DateTime? _pauseStartTime;
  Duration _pausedDuration = Duration.zero;

  // Get level-based solfeggio options
  List<Map<String, dynamic>> get _solfeggioOptions {
    final level = widget.entry.level;
    final allowedFrequencies =
        AppConstants.levelSolfeggioFrequencies[level] ?? [];

    // Always include "none" option
    final options = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'none',
        'title': 'Keine Musik',
        'icon': Icons.volume_off,
        'color': Colors.grey,
      },
    ];

    // Add level-appropriate solfeggio frequencies
    for (final frequency in allowedFrequencies) {
      final description = AppConstants.solfeggioDescriptions[frequency];
      if (description != null) {
        options.add(<String, dynamic>{
          'id': 'solfeggio_$frequency',
          'title': description['name']!,
          'subtitle': description['title']!,
          'description': description['description']!,
          'icon': _getSolfeggioIcon(frequency),
          'color': _getSolfeggioColor(frequency),
        });
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
    _initializeAnimations();

    // Initialize background music selection immediately
    _initializeBackgroundMusicSelection();
    _initializePlayer();
    _startAutoLockTimer();
  }

  void _initializeBackgroundMusicSelection() {
    // Get user preferences immediately
    final userPrefs = ref.read(userPrefsProvider);
    final level = widget.entry.level;

    // Try to get level-specific background music first
    final levelMusic = ref
        .read(userPrefsProvider.notifier)
        .getLevelBackgroundMusic(level);
    final lastSelected = userPrefs.lastBackgroundMusic;

    debugPrint('=== INITIAL BACKGROUND MUSIC SELECTION ===');
    debugPrint('Level: $level');
    debugPrint('Level-specific music: $levelMusic');
    debugPrint('Last selected from userPrefs: $lastSelected');

    // Check if level-specific music is available and valid for this level
    if (levelMusic != null && levelMusic.isNotEmpty && levelMusic != 'null') {
      final allowedFrequencies =
          AppConstants.levelSolfeggioFrequencies[level] ?? [];
      final frequency = levelMusic.replaceAll('solfeggio_', '');

      if (allowedFrequencies.contains(frequency)) {
        _selectedBackgroundMusic = levelMusic;
        debugPrint(
          'Initial selection set to level-specific: $_selectedBackgroundMusic',
        );
      } else {
        // Level-specific music is not valid for this level, use default
        _selectedBackgroundMusic = _getDefaultMusicForLevel(level);
        debugPrint(
          'Level-specific music invalid, using default: $_selectedBackgroundMusic',
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
        _selectedBackgroundMusic = lastSelected;
        debugPrint(
          'Initial selection set to last selected: $_selectedBackgroundMusic',
        );
      } else {
        _selectedBackgroundMusic = _getDefaultMusicForLevel(level);
        debugPrint(
          'Last selected invalid for level, using default: $_selectedBackgroundMusic',
        );
      }
    } else {
      _selectedBackgroundMusic = _getDefaultMusicForLevel(level);
      debugPrint('Initial selection defaulted to: $_selectedBackgroundMusic');
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
    // Cancel timers
    _meditationTimer?.cancel();
    _progressTimer?.cancel();
    _sessionTimer?.cancel();
    _autoLockTimer?.cancel();
    _unlockTimer?.cancel();

    _pulseController.dispose();
    _progressController.dispose();
    _stopPlayback();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializePlayer() async {
    try {
      await AudioService().initialize();
      await _loadAudioFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Initialisieren: $e')),
        );
      }
    }
  }

  Future<void> _loadAudioFiles() async {
    try {
      debugPrint('=== LOADING AUDIO FILES ===');
      debugPrint('Entry takes: ${widget.entry.takes}');
      debugPrint('Mode: ${widget.mode}');
      debugPrint('Loop for endless mode: ${widget.mode == 'endless'}');

      // Set up playlist with all takes
      if (widget.entry.takes.isNotEmpty) {
        debugPrint(
          'Setting up playlist with ${widget.entry.takes.length} takes',
        );
        await AudioService().setPlaylist(
          widget.entry.takes,
          loop: widget.mode == 'endless', // Loop for endless mode
        );
        debugPrint('Playlist set up successfully');
      } else {
        debugPrint('WARNING: No takes available for playlist');
      }

      // Set up background music - entry specific or use current selection
      String? bgPath;

      if (widget.entry.bgLoopPath != null &&
          widget.entry.bgLoopPath!.isNotEmpty) {
        // Use entry-specific background music
        bgPath = widget.entry.bgLoopPath;

        // Convert full path to solfeggio ID for UI display
        if (bgPath != null && bgPath.contains('solfeggio_')) {
          final parts = bgPath.split('/');
          final fileName = parts.last;
          _selectedBackgroundMusic = fileName.replaceAll('.mp3', '');
          debugPrint('Extracted solfeggio ID: $_selectedBackgroundMusic');
        } else {
          _selectedBackgroundMusic = widget.entry.bgLoopPath;
        }

        // Save this selection to user preferences
        await ref
            .read(userPrefsProvider.notifier)
            .updateLastBackgroundMusic(_selectedBackgroundMusic!);

        debugPrint('Entry background music: $bgPath');
        debugPrint('Selected music ID: $_selectedBackgroundMusic');
      } else {
        // Use current selection (already set in initState)
        if (_selectedBackgroundMusic != null &&
            _selectedBackgroundMusic != 'none') {
          bgPath = 'assets/audio/$_selectedBackgroundMusic.mp3';
        }

        debugPrint(
          'Using current selection: $_selectedBackgroundMusic -> $bgPath',
        );
      }

      // Load default background volume from UserPrefs
      final userPrefs = ref.read(userPrefsProvider);
      final defaultVolume = userPrefs.defaultBackgroundVolume ?? 0.5;
      _backgroundVolume = defaultVolume;
      await AudioService().loadDefaultBackgroundVolume(userPrefs);
      debugPrint('Default background volume loaded: $defaultVolume');

      // Set up the background music
      await AudioService().setBackgroundMusic(bgPath);
      await AudioService().setBackgroundVolume(_backgroundVolume);

      debugPrint('=== FINAL BACKGROUND MUSIC SETUP ===');
      debugPrint('Selected: $_selectedBackgroundMusic');
      debugPrint('Path: $bgPath');

      // Force UI update
      setState(() {});

      // Calculate total duration for endless mode
      if (widget.mode == 'endless') {
        // For endless mode, set total time to 9 hours (session duration)
        _totalTime = Duration(hours: 9);
        _sessionTime = Duration.zero; // Initialize session time
        _currentTime = Duration.zero; // Initialize current time
        _remainingTime = Duration(hours: 9); // Initialize remaining time
        debugPrint('Endless mode - Total time set to 9 hours');
      } else if (widget.entry.takes.isNotEmpty) {
        // Calculate total duration of all takes for other modes
        Duration totalDuration = Duration.zero;
        for (final take in widget.entry.takes) {
          if (take.isNotEmpty) {
            final duration = await AudioService().getDuration(take);
            if (duration != null) {
              totalDuration += duration;
            }
          }
        }
        _totalTime = totalDuration;
      }

      if (widget.mode == 'meditation' && widget.durationMinutes != null) {
        _remainingTime = Duration(minutes: widget.durationMinutes!);
      } else if (widget.mode != 'endless') {
        _remainingTime = _totalTime;
      }

      setState(() {});

      // Ensure background music is ready for immediate playback
      if (_selectedBackgroundMusic != null &&
          _selectedBackgroundMusic != 'none') {
        debugPrint('Pre-loading background music for immediate playback...');
        String? bgPath;
        if (_selectedBackgroundMusic!.startsWith('solfeggio_')) {
          bgPath = 'assets/audio/$_selectedBackgroundMusic.mp3';
        } else {
          bgPath = _selectedBackgroundMusic;
        }

        await AudioService().setBackgroundMusic(
          bgPath,
          customVolume: defaultVolume,
        );
        debugPrint('Background music pre-loaded: $bgPath');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler beim Laden: $e')));
      }
    }
  }

  void _togglePlayback() {
    debugPrint('=== TOGGLE PLAYBACK ===');
    debugPrint('_isPlaying: $_isPlaying');
    debugPrint('_isPaused: $_isPaused');

    // Reset auto-lock timer on user interaction
    _onUserInteraction();

    if (!_isPlaying) {
      // Start playback if not playing
      debugPrint('Starting playback...');
      _startPlayback();
    } else if (_isPaused) {
      // Resume if paused
      debugPrint('Resuming playback...');

      // Update UI state immediately before calling _resumePlayback
      setState(() {
        _isPaused = false;
      });

      _resumePlayback();
    } else {
      // Pause if playing
      debugPrint('Pausing playback...');
      _pausePlayback();
    }
  }

  Future<void> _startPlayback() async {
    try {
      debugPrint('=== STARTING PLAYBACK ===');
      debugPrint('Entry takes: ${widget.entry.takes}');
      debugPrint('Background music: ${widget.entry.bgLoopPath}');
      debugPrint('Selected background music: $_selectedBackgroundMusic');
      debugPrint('Mode: ${widget.mode}');
      debugPrint('Looping: ${widget.mode == 'endless'}');

      setState(() {
        _isPlaying = true;
        _isPaused = false;
        _isCompleted = false;
      });

      // Record session start time
      _sessionStartTime = DateTime.now();
      debugPrint('Session started at: $_sessionStartTime');

      // Timer will be reset by _onUserInteraction() in _togglePlayback()

      // Enable wake lock to keep screen on
      await WakelockPlus.enable();
      debugPrint('Wake lock enabled');

      // Start playlist playback
      debugPrint('Calling AudioService().playPlaylist()...');
      await AudioService().playPlaylist();
      debugPrint('Playlist playback initiated');

      // Reset timer state before starting
      debugPrint('Resetting timer state...');
      _meditationTimer?.cancel();
      _progressTimer?.cancel();
      _pausedDuration = Duration.zero;
      _pauseStartTime = null;
      _currentTime = Duration.zero; // Reset current time
      debugPrint('Timer state reset complete');

      // Start timers immediately (independent of background music)
      debugPrint('Starting timers...');

      // Start meditation timer
      if (widget.mode == 'meditation' && widget.durationMinutes != null) {
        debugPrint('Creating meditation timer...');
        _meditationTimer?.cancel();
        _meditationTimer = Timer(
          Duration(minutes: widget.durationMinutes!),
          () {
            debugPrint('Meditation timer completed!');
            if (mounted && _isPlaying) {
              _completeMeditation();
            }
          },
        );
        debugPrint('Meditation timer created');
      }

      // Start progress tracking
      debugPrint('Creating progress timer...');
      _progressTimer?.cancel();
      _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isPlaying && !_isPaused) {
          _updateProgress();
        }
      });
      debugPrint('Progress timer created');

      // Start session timer for endless mode
      if (widget.mode == 'endless') {
        _sessionTime = Duration.zero;
        _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && _isPlaying && !_isPaused) {
            setState(() {
              _sessionTime = Duration(seconds: _sessionTime.inSeconds + 1);
            });

            // Auto-stop after 9 hours
            if (_sessionTime.inHours >= 9) {
              _stopPlayback();
            }
          }
        });
        debugPrint('Session timer started for endless mode');
      }

      // Start animations
      _pulseController.repeat(reverse: true);
      _progressController.forward();

      // Start background music (after timers are already running)
      if (_selectedBackgroundMusic != null &&
          _selectedBackgroundMusic != 'none') {
        debugPrint('Calling AudioService().startBackgroundMusic()...');
        await AudioService().startBackgroundMusic();
        debugPrint('Background music started');
      } else {
        debugPrint('No background music selected or "none" selected');
      }

      debugPrint('=== PLAYBACK STARTED SUCCESSFULLY ===');
    } catch (e) {
      debugPrint('=== ERROR STARTING PLAYBACK ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      setState(() {
        _isPlaying = false;
        _isPaused = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Wiedergabefehler: $e')));
      }
    }
  }

  Future<void> _pausePlayback() async {
    try {
      debugPrint('=== PAUSING PLAYBACK ===');
      debugPrint(
        'Current state - _isPlaying: $_isPlaying, _isPaused: $_isPaused',
      );

      // Record pause start time
      _pauseStartTime = DateTime.now();

      // Timer will be reset by _onUserInteraction() in _togglePlayback()

      // Pause audio services
      await AudioService().pause();
      await AudioService().stopBackgroundMusic();

      // Update state immediately
      setState(() {
        _isPaused = true;
        // Keep _isPlaying as true since we're just paused, not stopped
      });

      // Pause animations
      _pulseController.stop();
      _progressController.stop();

      // Pause session timer for endless mode
      if (widget.mode == 'endless') {
        _sessionTimer?.cancel();
      }

      debugPrint('Playback paused at: $_pauseStartTime');
      debugPrint('New state - _isPlaying: $_isPlaying, _isPaused: $_isPaused');
    } catch (e) {
      debugPrint('Error pausing playback: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Pausierungsfehler: $e')));
      }
    }
  }

  Future<void> _resumePlayback() async {
    try {
      debugPrint('=== RESUMING PLAYBACK ===');
      debugPrint(
        'Current state - _isPlaying: $_isPlaying, _isPaused: $_isPaused',
      );

      // Calculate paused duration
      if (_pauseStartTime != null) {
        final pauseDuration = DateTime.now().difference(_pauseStartTime!);
        _pausedDuration += pauseDuration;
        debugPrint('Paused for: ${pauseDuration.inSeconds} seconds');
        debugPrint(
          'Total paused duration: ${_pausedDuration.inSeconds} seconds',
        );
        _pauseStartTime = null;
      }

      // Resume both audio streams simultaneously for synchronization
      await AudioService().resume();
      if (_selectedBackgroundMusic != null &&
          _selectedBackgroundMusic != 'none') {
        await AudioService().startBackgroundMusic();
      }

      debugPrint('New state - _isPlaying: $_isPlaying, _isPaused: $_isPaused');

      // Restart animations properly after a small delay to ensure UI is updated
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _pulseController.stop();
          _pulseController.reset();
          _pulseController.repeat(reverse: true);

          _progressController.stop();
          _progressController.reset();
          _progressController.forward();

          // Restart session timer for endless mode
          if (widget.mode == 'endless') {
            _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (mounted && _isPlaying && !_isPaused) {
                setState(() {
                  _sessionTime = Duration(seconds: _sessionTime.inSeconds + 1);
                });

                // Auto-stop after 9 hours
                if (_sessionTime.inHours >= 9) {
                  _stopPlayback();
                }
              }
            });
            debugPrint('Session timer restarted for endless mode');
          }
        }
      });

      // Restart meditation timer with remaining time
      if (widget.mode == 'meditation' && widget.durationMinutes != null) {
        debugPrint('Restarting meditation timer after resume...');
        _meditationTimer?.cancel();

        // Calculate remaining time including paused duration
        final totalDuration = Duration(minutes: widget.durationMinutes!);
        final remainingDuration = totalDuration - _pausedDuration;

        debugPrint('Remaining time: ${remainingDuration.inMinutes} minutes');

        _meditationTimer = Timer(remainingDuration, () {
          debugPrint('Meditation timer completed after resume!');
          if (mounted && _isPlaying) {
            _completeMeditation();
          }
        });
        debugPrint('Meditation timer restarted after resume');
      }

      debugPrint('Playback resumed successfully');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fortsetzungsfehler: $e')));
      }
    }
  }

  Future<void> _stopPlayback({bool isManualStop = false}) async {
    try {
      debugPrint('=== STOPPING PLAYBACK ===');

      // Cancel timers
      _meditationTimer?.cancel();
      _progressTimer?.cancel();
      if (widget.mode == 'endless') {
        _sessionTimer?.cancel();
      }

      // Reset pause tracking
      _pausedDuration = Duration.zero;
      _pauseStartTime = null;

      await AudioService().stop();
      await AudioService().stopBackgroundMusic();

      // Calculate session duration BEFORE resetting timers
      final sessionDuration = widget.mode == 'endless'
          ? _sessionTime
          : _currentTime;
      debugPrint('Calculated session duration: ${sessionDuration.inSeconds}s');
      debugPrint('Session time: ${_sessionTime.inSeconds}s');
      debugPrint('Current time: ${_currentTime.inSeconds}s');

      setState(() {
        _isPlaying = false;
        _isPaused = false;
        _isCompleted = true;
        _currentTime = Duration.zero;
      });

      // Disable wake lock
      await WakelockPlus.disable();

      // Stop animations
      _pulseController.stop();
      _progressController.reset();

      debugPrint('Playback stopped successfully');

      // Save listen log and show completion screen if session was at least 30 seconds
      if (sessionDuration.inSeconds >= 30 && _sessionStartTime != null) {
        await _saveListenLog(sessionDuration);
        // Show completion screen only if session was at least 30 seconds
        _showCompletionScreen(customDuration: sessionDuration);
      } else {
        // Session too short - go back to home without completion screen
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Stoppfehler: $e')));
      }
    }
  }

  void _updateProgress() {
    debugPrint(
      '_updateProgress called - Current time: ${_currentTime.inSeconds}s',
    );

    setState(() {
      if (widget.mode == 'meditation' && widget.durationMinutes != null) {
        _currentTime = Duration(seconds: _currentTime.inSeconds + 1);
        _remainingTime =
            Duration(minutes: widget.durationMinutes!) - _currentTime;

        if (_remainingTime.isNegative) {
          _remainingTime = Duration.zero;
        }
      } else if (widget.mode == 'endless') {
        // For endless mode, show session time instead of audio loop time
        _currentTime = _sessionTime;
        _remainingTime = Duration(hours: 9) - _sessionTime;

        if (_remainingTime.isNegative) {
          _remainingTime = Duration.zero;
        }

        debugPrint(
          'Endless mode - Session time: ${_sessionTime.inSeconds}s, Current time: ${_currentTime.inSeconds}s, Remaining: ${_remainingTime.inSeconds}s',
        );
      }
    });
  }

  void _completeMeditation() {
    _stopPlayback();
  }

  Future<void> _saveListenLog(Duration sessionDuration) async {
    try {
      debugPrint('=== SAVING LISTEN LOG ===');
      debugPrint('Entry ID: ${widget.entry.id}');
      debugPrint('Entry Title: ${widget.entry.title}');
      debugPrint('Category: ${widget.entry.category}');
      debugPrint('Level: ${widget.entry.level}');
      debugPrint('Mode: ${widget.mode}');
      debugPrint('Session Start: $_sessionStartTime');
      debugPrint('Session Duration: ${sessionDuration.inSeconds}s');

      final endedAt = _sessionStartTime!.add(sessionDuration);
      final minutes = sessionDuration.inMinutes;
      final seconds = sessionDuration.inSeconds % 60;

      final listenLog = ListenLog(
        entryId: widget.entry.id,
        entryTitle: widget.entry.title,
        category: widget.entry.category,
        level: widget.entry.level,
        mode: widget.mode,
        startedAt: _sessionStartTime!,
        endedAt: endedAt,
        minutes: minutes,
        seconds: seconds,
      );

      // Save to database via provider
      await ref.read(listenLogsProvider.notifier).addListenLog(listenLog);

      // Refresh statistics to update the profile screen
      ref.read(statisticsNotifierProvider.notifier).refreshStatistics();

      debugPrint('Listen log saved successfully');
    } catch (e) {
      debugPrint('Error saving listen log: $e');
    }
  }

  void _showCompletionScreen({Duration? customDuration}) {
    // Use custom duration if provided, otherwise calculate based on mode
    final duration =
        customDuration ??
        (widget.mode == 'endless' ? _sessionTime : _currentTime);

    debugPrint('=== SHOWING COMPLETION SCREEN ===');
    debugPrint('Mode: ${widget.mode}');
    debugPrint('Session duration: ${duration.inSeconds}s');
    debugPrint('Session time: ${_sessionTime.inSeconds}s');
    debugPrint('Current time: ${_currentTime.inSeconds}s');

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CompletionScreen(
          mode: widget.mode,
          sessionDuration: duration,
          isEarlyCompletion: false,
        ),
      ),
    );
  }

  void _startAutoLockTimer() {
    _autoLockTimer?.cancel();
    _autoLockTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_isLocked) {
        setState(() {
          _isLocked = true;
        });
        debugPrint('Screen auto-locked after 10 seconds of inactivity');
      }
    });
  }

  void _onUserInteraction() {
    // Reset timer on any user interaction
    if (!_isLocked) {
      _startAutoLockTimer();
    }
  }

  void _toggleLock() {
    // Reset auto-lock timer on user interaction (only if not locked)
    if (!_isLocked) {
      _onUserInteraction();
    }

    if (_isLocked) {
      // Start unlock process - need to hold for 1 second
      _startUnlockProcess();
    } else {
      // Manual lock
      _autoLockTimer?.cancel();
      setState(() {
        _isLocked = true;
      });
    }
  }

  void _startUnlockProcess() {
    if (_isUnlocking) return;

    // Reset auto-lock timer on unlock interaction
    _onUserInteraction();

    setState(() {
      _isUnlocking = true;
    });

    _unlockTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLocked = false;
          _isUnlocking = false;
        });
        _startAutoLockTimer(); // Restart auto-lock timer
        debugPrint('Screen unlocked after 1 second hold');
      }
    });
  }

  void _cancelUnlockProcess() {
    _unlockTimer?.cancel();
    setState(() {
      _isUnlocking = false;
    });
  }

  void _setBackgroundVolume(double volume) {
    // Reset auto-lock timer on user interaction
    _onUserInteraction();

    setState(() {
      _backgroundVolume = volume;
    });
    AudioService().setBackgroundVolume(volume);
  }

  Future<void> _switchBackgroundMusic(String musicId) async {
    try {
      debugPrint('Switching background music to: $musicId');

      // Reset auto-lock timer on user interaction
      _onUserInteraction();

      // Check if the same music is already selected - if so, stop it
      if (_selectedBackgroundMusic == musicId) {
        debugPrint('Same music selected - stopping background music');
        await AudioService().stopBackgroundMusic();
        setState(() {
          _selectedBackgroundMusic = 'none';
        });

        // Save selection to user preferences
        final level = widget.entry.level;
        await ref
            .read(userPrefsProvider.notifier)
            .updateLevelBackgroundMusic(level, 'none');
        await ref
            .read(userPrefsProvider.notifier)
            .updateLastBackgroundMusic('none');

        // No feedback needed - visual selection is enough
        return;
      }

      setState(() {
        _selectedBackgroundMusic = musicId;
      });

      String? bgPath;
      if (musicId != 'none') {
        bgPath = 'assets/audio/$musicId.mp3';
        debugPrint('Background music path: $bgPath');
      } else {
        debugPrint('No background music selected');
      }

      await AudioService().switchBackgroundMusic(bgPath);

      // Save selection to user preferences (both level-specific and legacy)
      final level = widget.entry.level;
      await ref
          .read(userPrefsProvider.notifier)
          .updateLevelBackgroundMusic(level, musicId);
      await ref
          .read(userPrefsProvider.notifier)
          .updateLastBackgroundMusic(musicId);
      debugPrint('Saved background music selection for level $level: $musicId');

      // No feedback needed - visual selection is enough
    } catch (e) {
      debugPrint('Error switching background music: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Wechseln der Musik: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use neutral theme for player screen
    final neutralTheme = MoodTheme.standard;

    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (_) => _onUserInteraction(),
        onTap: () => _onUserInteraction(),
        child: Container(
          decoration: BoxDecoration(gradient: neutralTheme.backgroundGradient),
          child: SafeArea(
            child: _isLocked ? _buildLockedView() : _buildPlayerView(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerView() {
    return Column(
      children: [
        // Header
        _buildHeader(),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Entry info
                _buildEntryInfo(),

                const SizedBox(height: 40),

                // Progress indicator
                _buildProgressIndicator(),

                const SizedBox(height: 40),

                // Play button
                _buildPlayButton(),

                const SizedBox(height: 40),

                // Controls
                _buildControls(),

                const SizedBox(height: 24),

                // Background music volume
                _buildVolumeControl(),

                const SizedBox(height: 24),

                const SizedBox(height: 24), // Extra padding at bottom
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedView() {
    final neutralTheme = MoodTheme.standard;

    return GestureDetector(
      onTapDown: (_) => _startUnlockProcess(),
      onTapUp: (_) => _cancelUnlockProcess(),
      onTapCancel: () => _cancelUnlockProcess(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: neutralTheme.backgroundGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock icon with progress indicator
            Stack(
              alignment: Alignment.center,
              children: [
                // Progress circle
                if (_isUnlocking)
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: 1.0, // Will be animated
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                // Lock icon
                Icon(
                  Icons.lock,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text(
              _isUnlocking
                  ? 'Halte gedrückt...'
                  : 'Halte 1 Sekunde zum Entsperren',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              widget.entry.title,
              style: AppTheme.bodyStyle.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Mini progress indicator
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              child: LinearProgressIndicator(
                value: _getProgressValue(),
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _formatTime(_currentTime),
              style: AppTheme.bodyStyle.copyWith(fontSize: 16),
            ),
          ],
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
            onPressed: () {
              _stopPlayback(isManualStop: true);
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    widget.mode == 'meditation'
                        ? 'Meditation'
                        : 'Dauerschleife',
                    style: AppTheme.headingStyle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Container(width: 100, height: 1, color: Colors.white),
                  const SizedBox(height: 4),
                  Text(
                    widget.entry.title,
                    style: AppTheme.appTaglineStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _toggleLock,
            icon: const Icon(Icons.lock, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryInfo() {
    return Column(
      children: [
        Icon(
          _getCategoryIcon(widget.entry.category),
          color: Colors.white,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          widget.entry.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.entry.takes.where((take) => take.isNotEmpty).length} Affirmationen',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        // Time display
        Text(
          _formatTime(_currentTime),
          style: AppTheme.headingStyle.copyWith(fontSize: 32),
        ),

        const SizedBox(height: 16),

        // Progress bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _getProgressValue(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Mode indicator with readiness status
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.mode == 'meditation'
                  ? 'Meditation • ${widget.durationMinutes} min'
                  : 'Dauerschleife',
              style: AppTheme.bodyStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(width: 8),
            // Readiness indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    _selectedBackgroundMusic != null &&
                        _selectedBackgroundMusic != 'none'
                    ? Colors.green
                    : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              _selectedBackgroundMusic != null &&
                      _selectedBackgroundMusic != 'none'
                  ? 'Bereit'
                  : 'Lädt...',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 10,
                color:
                    _selectedBackgroundMusic != null &&
                        _selectedBackgroundMusic != 'none'
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    // Get current music info for visual indication
    final currentMusicOption = _solfeggioOptions.firstWhere(
      (option) => option['id'] == _selectedBackgroundMusic,
      orElse: () => <String, dynamic>{
        'title': 'Keine Musik',
        'color': Colors.grey,
      },
    );

    final hasBackgroundMusic =
        _selectedBackgroundMusic != null && _selectedBackgroundMusic != 'none';

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: (_isPlaying && !_isPaused) ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _getPlayButtonColor(),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getPlayButtonColor().withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
                // Additional shadow for background music indication
                if (hasBackgroundMusic && !_isPlaying)
                  BoxShadow(
                    color: currentMusicOption['color'].withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Main play button
                Center(
                  child: IconButton(
                    onPressed: _togglePlayback,
                    icon: Icon(
                      _getPlayButtonIcon(),
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
                // Background music indicator in bottom-right corner
                if (hasBackgroundMusic && !_isPlaying)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: currentMusicOption['color'],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop button
        _buildControlButton(
          icon: Icons.stop,
          onPressed: _isPlaying
              ? () => _stopPlayback(isManualStop: true)
              : null,
        ),
      ],
    );
  }

  Widget _buildVolumeControl() {
    final neutralTheme = MoodTheme.standard;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Header in white text
          Text(
            'HINTERGRUNDMUSIK',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          // Music selection in neutral theme container
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  neutralTheme.cardColor,
                  neutralTheme.cardColor.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: neutralTheme.accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: neutralTheme.accentColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Music selection
                  _buildMusicSelection(),

                  const SizedBox(height: 16),

                  // Volume control with current volume indicator
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lautstärke',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(_backgroundVolume * 100).round()}%',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.volume_down, color: Colors.white70),
                          Expanded(
                            child: Slider(
                              value: _backgroundVolume,
                              onChanged: _setBackgroundVolume,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          const Icon(Icons.volume_up, color: Colors.white70),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicSelection() {
    debugPrint('=== BUILDING MUSIC SELECTION ===');
    debugPrint('Current _selectedBackgroundMusic: $_selectedBackgroundMusic');

    return GestureDetector(
      onPanUpdate: (_) => _onUserInteraction(),
      onTap: () => _onUserInteraction(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // List layout for music options with automatic height
            ..._solfeggioOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final isSelected = _selectedBackgroundMusic == option['id'];

              if (isSelected) {
                debugPrint('Option ${option['id']} is SELECTED');
              }

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < _solfeggioOptions.length - 1 ? 12 : 0,
                ),
                child: InkWell(
                  onTap: () => _switchBackgroundMusic(option['id']),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon with background circle
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  option['icon'],
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      option['title'],
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (option['subtitle'] != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        option['subtitle'],
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (option['description'] != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        option['description'],
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w400,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Selection indicator
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: MoodTheme.standard.accentColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final neutralTheme = MoodTheme.standard;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: onPressed != null ? neutralTheme.accentColor : Colors.grey,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Color _getPlayButtonColor() {
    final neutralTheme = MoodTheme.standard;

    if (_isCompleted) return Colors.green;
    if (_isPlaying) return _isPaused ? Colors.orange : Colors.red;
    return neutralTheme.accentColor;
  }

  IconData _getPlayButtonIcon() {
    if (_isCompleted) return Icons.check;
    if (_isPlaying) return _isPaused ? Icons.play_arrow : Icons.pause;
    return Icons.play_arrow;
  }

  double _getProgressValue() {
    if (widget.mode == 'meditation' && widget.durationMinutes != null) {
      final totalSeconds = widget.durationMinutes! * 60;
      if (totalSeconds <= 0) return 0.0;

      final progress = _currentTime.inSeconds / totalSeconds;
      if (!progress.isFinite) return 0.0;

      return progress.clamp(0.0, 1.0).toDouble();
    }

    final totalSeconds = _totalTime.inSeconds;
    if (totalSeconds <= 0) return 0.0;

    final progress = _currentTime.inSeconds / totalSeconds;
    if (!progress.isFinite) return 0.0;

    return progress.clamp(0.0, 1.0).toDouble();
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
}
