import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';
import '../models/user_prefs.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  FlutterSoundRecorder? _recorder;
  just_audio.AudioPlayer? _player;
  just_audio.AudioPlayer? _backgroundPlayer;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  // Playlist management
  List<String> _playlist = [];
  int _currentTrackIndex = 0;
  bool _isPlaylistMode = false;
  bool _isLooping = false;
  double _backgroundVolume = 0.5;

  Future<void> initialize() async {
    try {
      // Initialize players (no microphone permission needed for playback)
      _player = just_audio.AudioPlayer();
      _backgroundPlayer = just_audio.AudioPlayer();

      // Set up player state listeners
      _setupPlayerListeners();

      debugPrint(
        'AudioService initialized successfully (without microphone permission)',
      );
    } catch (e) {
      debugPrint('AudioService initialization error: $e');
      throw Exception('Failed to initialize AudioService: $e');
    }
  }

  Future<void> _ensureRecordingPermission() async {
    // Request microphone permission only when needed
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission denied');
    }

    // Initialize recorder only when permission is granted
    if (_recorder == null) {
      _recorder = FlutterSoundRecorder();
      await _recorder!.openRecorder();
    }
  }

  Future<void> startRecording(String entryId, int takeIndex) async {
    if (_isRecording) return;

    try {
      // Request microphone permission only when starting to record
      await _ensureRecordingPermission();

      debugPrint('Start recording for entry: $entryId, take: $takeIndex');

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          '${AppConstants.takePrefix}${takeIndex.toString().padLeft(2, '0')}${AppConstants.recordingFormat}';
      final filePath = '${directory.path}/$fileName';

      _currentRecordingPath = filePath;

      // Start recording with flutter_sound
      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.defaultCodec,
        bitRate: 128000,
        sampleRate: 44100,
      );

      _isRecording = true;
      debugPrint('Recording started successfully: $filePath');
    } catch (e) {
      debugPrint('Recording start error: $e');
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      debugPrint('Stop recording');
      final path = await _recorder!.stopRecorder();
      _isRecording = false;

      // Verify file was created
      if (path != null && _currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          final fileSize = await file.length();
          debugPrint(
            'Recording saved: $_currentRecordingPath, size: $fileSize bytes',
          );
          return _currentRecordingPath;
        } else {
          debugPrint(
            'ERROR: Recording file not found at $_currentRecordingPath',
          );
          return null;
        }
      } else {
        debugPrint('ERROR: Recording path is null');
        return null;
      }
    } catch (e) {
      debugPrint('Stop recording error: $e');
      _isRecording = false;
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<void> pauseRecording() async {
    if (!_isRecording) return;

    try {
      debugPrint('Pause recording');
      await _recorder!.pauseRecorder();
    } catch (e) {
      debugPrint('Pause recording error: $e');
      throw Exception('Failed to pause recording: $e');
    }
  }

  Future<void> resumeRecording() async {
    if (!_isRecording) return;

    try {
      debugPrint('Resume recording');
      await _recorder!.resumeRecorder();
    } catch (e) {
      debugPrint('Resume recording error: $e');
      throw Exception('Failed to resume recording: $e');
    }
  }

  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      debugPrint('Cancel recording');
      await _recorder!.stopRecorder();
      _isRecording = false;
      _currentRecordingPath = null;
    } catch (e) {
      debugPrint('Cancel recording error: $e');
      throw Exception('Failed to cancel recording: $e');
    }
  }

  Future<void> playAffirmation(String filePath) async {
    try {
      debugPrint('Play affirmation: $filePath');

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('ERROR: Audio file not found: $filePath');
        throw Exception('Audio file not found: $filePath');
      }

      final fileSize = await file.length();
      debugPrint('Audio file size: $fileSize bytes');

      if (fileSize == 0) {
        debugPrint('ERROR: Audio file is empty');
        throw Exception('Audio file is empty');
      }

      // Stop any current playback only if not in playlist mode
      if (!_isPlaylistMode) {
        await stop();
      }

      // Play the audio
      await _player!.setFilePath(filePath);
      await _player!.play();

      _isPlaying = true;
      debugPrint('Playback started successfully');
    } catch (e) {
      debugPrint('Play affirmation error: $e');
      _isPlaying = false;
      throw Exception('Failed to play affirmation: $e');
    }
  }

  Future<void> stop() async {
    try {
      debugPrint('Stop playback');
      await _player!.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Stop playback error: $e');
    }
  }

  Future<void> pause() async {
    try {
      debugPrint('Pause playback');
      await _player!.pause();
    } catch (e) {
      debugPrint('Pause playback error: $e');
    }
  }

  Future<void> resume() async {
    try {
      debugPrint('Resume playback');
      await _player!.play();
    } catch (e) {
      debugPrint('Resume playback error: $e');
    }
  }

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  Stream<Duration> get positionStream => _player!.positionStream;
  Stream<Duration?> get durationStream => _player!.durationStream;
  Stream<just_audio.PlayerState> get playerStateStream =>
      _player!.playerStateStream;

  Future<Duration?> getDuration(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      await _player!.setFilePath(filePath);
      return _player!.duration;
    } catch (e) {
      debugPrint('Get duration error: $e');
      return null;
    }
  }

  void _setupPlayerListeners() {
    _player?.playerStateStream.listen((playerState) {
      if (playerState.processingState == just_audio.ProcessingState.completed) {
        if (_isPlaylistMode) {
          _playNextTrackInternal();
        }
      }
    });
  }

  Future<void> _playNextTrackInternal() async {
    _currentTrackIndex++;
    await _playCurrentTrack();
  }

  Future<void> setPlaylist(List<String> takes, {bool loop = false}) async {
    try {
      // Filter out empty takes
      _playlist = takes.where((take) => take.isNotEmpty).toList();
      _currentTrackIndex = 0;
      _isPlaylistMode = true;
      _isLooping = loop;

      debugPrint(
        'Playlist set with ${_playlist.length} tracks, looping: $loop',
      );
    } catch (e) {
      debugPrint('Set playlist error: $e');
      throw Exception('Failed to set playlist: $e');
    }
  }

  Future<void> playPlaylist() async {
    if (_playlist.isEmpty) {
      debugPrint('No playlist to play');
      return;
    }

    try {
      await stop();
      await _playCurrentTrack();
    } catch (e) {
      debugPrint('Play playlist error: $e');
      throw Exception('Failed to play playlist: $e');
    }
  }

  Future<void> _playCurrentTrack() async {
    if (_currentTrackIndex >= _playlist.length) {
      if (_isLooping) {
        _currentTrackIndex = 0;
      } else {
        debugPrint('Playlist completed, restarting from beginning');
        _currentTrackIndex = 0; // Restart from beginning for meditation mode
      }
    }

    final trackPath = _playlist[_currentTrackIndex];
    debugPrint(
      'Playing track ${_currentTrackIndex + 1}/${_playlist.length}: $trackPath',
    );

    // Check if file exists before playing
    final file = File(trackPath);
    if (!await file.exists()) {
      debugPrint('Track file not found: $trackPath, skipping to next');
      _currentTrackIndex++;
      await _playCurrentTrack();
      return;
    }

    await playAffirmation(trackPath);
  }

  Future<void> playNextTrack() async {
    _currentTrackIndex++;
    await _playCurrentTrack();
  }

  Future<void> playPreviousTrack() async {
    if (_currentTrackIndex > 0) {
      _currentTrackIndex--;
      await _playCurrentTrack();
    }
  }

  Future<void> setBackgroundMusic(
    String? bgPath, {
    double? customVolume,
  }) async {
    try {
      if (bgPath == null || bgPath.isEmpty) {
        await _backgroundPlayer?.stop();
        debugPrint('Background music stopped');
        return;
      }

      debugPrint('Setting background music to: $bgPath');

      // Check if it's an asset path
      if (bgPath.startsWith('assets/')) {
        await _backgroundPlayer?.setAsset(bgPath);
        debugPrint('Background music set as asset: $bgPath');
      } else {
        await _backgroundPlayer?.setFilePath(bgPath);
        debugPrint('Background music set as file: $bgPath');
      }

      await _backgroundPlayer?.setLoopMode(just_audio.LoopMode.one);

      // Use custom volume if provided, otherwise use current volume
      final volumeToUse = customVolume ?? _backgroundVolume;
      await _backgroundPlayer?.setVolume(volumeToUse);

      debugPrint('Background music set: $bgPath');
      debugPrint('Background volume: $volumeToUse');
    } catch (e) {
      debugPrint('Set background music error: $e');
    }
  }

  Future<void> switchBackgroundMusic(String? newBgPath) async {
    try {
      if (newBgPath == null || newBgPath.isEmpty) {
        await _backgroundPlayer?.stop();
        debugPrint('Background music stopped');
        return;
      }

      // Check if we're currently playing background music
      final isCurrentlyPlaying = _backgroundPlayer?.playing ?? false;
      debugPrint('Currently playing background music: $isCurrentlyPlaying');

      // Set new background music
      if (newBgPath.startsWith('assets/')) {
        await _backgroundPlayer?.setAsset(newBgPath);
        debugPrint('Background music switched to asset: $newBgPath');
      } else {
        await _backgroundPlayer?.setFilePath(newBgPath);
        debugPrint('Background music switched to file: $newBgPath');
      }
      await _backgroundPlayer?.setLoopMode(just_audio.LoopMode.one);
      await _backgroundPlayer?.setVolume(_backgroundVolume);

      debugPrint('Background music file set: $newBgPath');
      debugPrint('Background volume: $_backgroundVolume');

      // Always start the new music if we're in playback mode
      await _backgroundPlayer?.play();
      debugPrint('Background music started after switch');
    } catch (e) {
      debugPrint('Switch background music error: $e');
    }
  }

  Future<void> startBackgroundMusic() async {
    try {
      final playerState = _backgroundPlayer?.playerState;
      debugPrint('Background player state before start: $playerState');

      // Check if we have a valid audio source
      final duration = _backgroundPlayer?.duration;
      debugPrint('Background music duration: $duration');

      if (duration == null || duration == Duration.zero) {
        debugPrint('ERROR: No valid audio source for background music');
        return;
      }

      await _backgroundPlayer?.play();
      debugPrint('Background music started');

      // Verify it's actually playing
      Future.delayed(const Duration(milliseconds: 1000), () {
        final newState = _backgroundPlayer?.playerState;
        final isPlaying = _backgroundPlayer?.playing;
        debugPrint('Background player state after start: $newState');
        debugPrint('Background player is playing: $isPlaying');
      });
    } catch (e) {
      debugPrint('Start background music error: $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer?.stop();
      debugPrint('Background music stopped');
    } catch (e) {
      debugPrint('Stop background music error: $e');
    }
  }

  Future<void> setBackgroundVolume(double volume) async {
    _backgroundVolume = volume;
    await _backgroundPlayer?.setVolume(volume);
    debugPrint('Background volume set to: $volume');
  }

  /// Load default background volume from UserPrefs
  Future<void> loadDefaultBackgroundVolume(UserPrefs userPrefs) async {
    final defaultVolume = userPrefs.defaultBackgroundVolume ?? 0.5;
    _backgroundVolume = defaultVolume;
    debugPrint('Default background volume loaded: $defaultVolume');
  }

  /// Get current background volume
  double get currentBackgroundVolume => _backgroundVolume;

  // Getters
  int get currentTrackIndex => _currentTrackIndex;
  int get totalTracks => _playlist.length;
  bool get isPlaylistMode => _isPlaylistMode;
  bool get isLooping => _isLooping;

  Future<void> dispose() async {
    try {
      debugPrint('Dispose AudioService');
      await _recorder?.closeRecorder();
      await _player?.dispose();
      await _backgroundPlayer?.dispose();
      _recorder = null;
      _player = null;
      _backgroundPlayer = null;
    } catch (e) {
      debugPrint('Dispose error: $e');
    }
  }
}
