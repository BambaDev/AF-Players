import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../controllers/native_player_controller.dart';
import '../../controllers/subtitle_controller.dart';
import '../../controllers/sync_controller.dart';
import '../../controllers/native_tts_controller.dart';
import '../../controllers/audio_mixer_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/library_controller.dart';
import '../../controllers/explorer_controller.dart';
import '../../data/models/video_item.dart';
import 'widgets/subtitle_overlay.dart';
import 'widgets/player_controls.dart';
import 'widgets/gesture_overlay.dart';
import 'widgets/lock_overlay.dart';

class PlayerScreen extends StatefulWidget {
  final VideoItem video;

  const PlayerScreen({super.key, required this.video});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late final NativePlayerController _playerController;
  late final SubtitleController _subtitleController;
  late final SyncController _syncController;
  late final SettingsController _settings;

  late final AnimationController _controlsFade;
  bool _isLocked = false;
  Timer? _hideTimer;
  Timer? _saveTimer;
  late final Worker _playingWorker;

  List<VideoItem> _playlist = [];
  int _currentIndex = -1;

  static const _autoHideDuration = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    WakelockPlus.enable();

    _playerController = Get.put(NativePlayerController());
    _subtitleController = Get.put(SubtitleController());
    _syncController = Get.put(SyncController());
    _settings = Get.find<SettingsController>();

    _playerController.setVideoVolume(_settings.videoVolume.value);

    final ttsController = Get.find<NativeTtsController>();
    ttsController.applySettings(_settings.ttsSettings.value);

    Get.find<AudioMixerController>().requestFocus();

    _controlsFade = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0,
    );
    _openVideo();
    _startHideTimer();

    _playingWorker = ever(_playerController.isPlaying, (bool playing) {
      if (!mounted) return;
      if (playing) {
        _startHideTimer();
      } else {
        _cancelHideTimer();
        _showControls();
      }
    });

    ever(_playerController.duration, (Duration dur) {
      if (dur.inMilliseconds > 0) {
        Get.find<LibraryController>().updateDuration(
          widget.video.id,
          dur.inMilliseconds,
        );
      }
    });

    _buildPlaylist();
  }

  void _buildPlaylist() {
    try {
      final explorer = Get.find<ExplorerController>();
      final videoFiles = explorer.items
          .whereType<File>()
          .where((f) => explorer.isVideo(f))
          .toList();

      _playlist = videoFiles
          .map((f) => VideoItem(
                id: '',
                title: f.path.split('/').last,
                videoPath: f.path,
                sourceType: VideoSourceType.local,
                addedAt: DateTime.now(),
              ))
          .toList();

      _currentIndex =
          _playlist.indexWhere((v) => v.videoPath == widget.video.videoPath);
    } catch (_) {}
  }

  void _playNextVideo() {
    if (_playlist.isEmpty || _currentIndex < 0) return;
    if (_currentIndex >= _playlist.length - 1) return;
    _savePosition();
    final next = _playlist[_currentIndex + 1];
    Get.off(() => PlayerScreen(video: next));
  }

  void _playPreviousVideo() {
    if (_playlist.isEmpty || _currentIndex <= 0) return;
    _savePosition();
    final prev = _playlist[_currentIndex - 1];
    Get.off(() => PlayerScreen(video: prev));
  }

  Future<void> _openVideo() async {
    try {
      await _playerController.open(widget.video.videoPath);
    } catch (e) {
      _playerController.hasError.value = true;
      _playerController.errorMessage.value = 'Impossible d\'ouvrir la vidéo: $e';
      return;
    }

    if (widget.video.subtitlePath != null) {
      try {
        await _subtitleController.loadFromFile(widget.video.subtitlePath!);
      } catch (_) {}
    }

    if (widget.video.lastPositionMs > 0) {
      await _playerController.seek(widget.video.lastPosition);
    }

    _startPeriodicSave();
  }

  void _startPeriodicSave() {
    _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _savePosition();
    });
  }

  @override
  void dispose() {
    _playingWorker.dispose();
    _cancelHideTimer();
    _saveTimer?.cancel();
    _controlsFade.dispose();
    _savePosition();
    WakelockPlus.disable();
    _syncController.reset();
    Get.find<AudioMixerController>().abandonFocus();
    Get.delete<SyncController>();
    Get.delete<SubtitleController>();
    Get.delete<NativePlayerController>();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _savePosition() {
    final pos = _playerController.position.value;
    if (pos > Duration.zero) {
      Get.find<LibraryController>().updateLastPosition(widget.video.id, pos);
    }
  }

  void _showControls() {
    _controlsFade.forward();
    _startHideTimer();
  }

  void _hideControls() {
    _cancelHideTimer();
    _controlsFade.reverse();
  }

  void _toggleControls() {
    if (_controlsFade.isAnimating) return;
    if (_controlsFade.isDismissed) {
      _showControls();
    } else {
      _hideControls();
    }
  }

  void _startHideTimer() {
    _cancelHideTimer();
    if (_playerController.isPlaying.value) {
      _hideTimer = Timer(_autoHideDuration, () {
        if (mounted && _playerController.isPlaying.value) {
          _hideControls();
        }
      });
    }
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (_isLocked) {
        _hideControls();
      } else {
        _showControls();
      }
    });
  }

  void _onVolumeChange(double volume) {
    _settings.updateVideoVolume(volume);
    _playerController.setVideoVolume(volume);
  }

  void _seekForward() {
    _playerController.seekForward(_settings.seekDuration.value);
  }

  void _seekBackward() {
    _playerController.seekBackward(_settings.seekDuration.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideoLayer(),
          _buildSubtitleLayer(),
          _buildGestureLayer(),
          _buildTopBar(),
          _buildBottomControls(),
          LockOverlay(isLocked: _isLocked, onToggleLock: _toggleLock),
          _buildBufferingIndicator(),
          _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    return Center(
      child: GetBuilder<NativePlayerController>(
        builder: (ctrl) {
          if (ctrl.textureId == null) {
            return const CircularProgressIndicator(color: Colors.white);
          }
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Texture(textureId: ctrl.textureId!),
          );
        },
      ),
    );
  }

  Widget _buildSubtitleLayer() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SubtitleOverlay(subtitleController: _subtitleController),
    );
  }

  Widget _buildGestureLayer() {
    return Obx(() => GestureOverlay(
      onTap: _toggleControls,
      onDoubleTapLeft: _seekBackward,
      onDoubleTapRight: _seekForward,
      onVolumeChange: _onVolumeChange,
      onBrightnessChange: (_) {},
      currentVolume: _settings.videoVolume.value,
      isLocked: _isLocked,
      seekSeconds: _settings.seekDuration.value,
      onSwipeLeft: _playNextVideo,
      onSwipeRight: _playPreviousVideo,
    ));
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _controlsFade,
        builder: (context, child) => IgnorePointer(
          ignoring: _controlsFade.isDismissed || _isLocked,
          child: Opacity(
            opacity: _isLocked ? 0.0 : _controlsFade.value,
            child: child,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(4, 8, 8, 24),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Get.back(),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lock_outline, color: Colors.white, size: 22),
                onPressed: _toggleLock,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedBuilder(
        animation: _controlsFade,
        builder: (context, child) => IgnorePointer(
          ignoring: _controlsFade.isDismissed || _isLocked,
          child: Opacity(
            opacity: _isLocked ? 0.0 : _controlsFade.value,
            child: child,
          ),
        ),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _startHideTimer(),
          child: PlayerControls(
            playerController: _playerController,
            syncController: _syncController,
            video: widget.video,
            onToggleLock: _toggleLock,
          ),
        ),
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return Obx(() {
      if (_playerController.isBuffering.value) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      return const SizedBox.shrink();
    });
  }

  Widget _buildErrorOverlay() {
    return Obx(() {
      if (!_playerController.hasError.value) return const SizedBox.shrink();
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Erreur de lecture',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _playerController.errorMessage.value,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    });
  }
}
