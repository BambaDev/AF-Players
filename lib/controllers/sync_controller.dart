import 'dart:async';
import 'dart:collection';
import 'package:get/get.dart';
import 'native_player_controller.dart';
import 'subtitle_controller.dart';
import 'native_tts_controller.dart';
import 'settings_controller.dart';
import '../data/models/subtitle_entry.dart';

enum SyncStatus { idle, playing, speaking, paused, userPaused }

class SyncController extends GetxController {
  late final NativePlayerController _playerController;
  late final SubtitleController _subtitleController;
  late final NativeTtsController _ttsController;
  late final SettingsController _settings;

  final syncStatus = SyncStatus.idle.obs;
  final isTtsEnabled = true.obs;
  final ttsSyncMode = 0.obs;

  SubtitleEntry? _lastSpokenEntry;
  final Queue<SubtitleEntry> _queue = Queue();
  bool _loopRunning = false;
  bool _videoPausedForTts = false;
  bool _draining = false;
  bool _isDucked = false;
  double _baseSpeed = 1.0;
  bool _videoSlowedForSync = false;
  double _savedVideoSpeed = 1.0;
  Timer? _restoreTimer;

  @override
  void onInit() {
    super.onInit();
    _playerController = Get.find<NativePlayerController>();
    _subtitleController = Get.find<SubtitleController>();
    _ttsController = Get.find<NativeTtsController>();
    _settings = Get.find<SettingsController>();
    ttsSyncMode.value = _settings.ttsSyncMode.value;
    _baseSpeed = _settings.ttsSettings.value.speechRate;

    ever(_settings.ttsSyncMode, (val) {
      ttsSyncMode.value = val;
      if (val != 1 && _videoPausedForTts) {
        _videoPausedForTts = false;
        _playerController.play();
      }
      if (val != 2) _cancelSyncSpeed();
    });

    ever(_playerController.position, _onPositionChanged);
  }

  void _onPositionChanged(Duration position) {
    if (syncStatus.value == SyncStatus.userPaused) return;
    if (_draining) return;
    if (!isTtsEnabled.value) return;

    _subtitleController.updatePosition(position);
    final entry = _subtitleController.currentEntry.value;
    if (entry == null) return;

    if (entry != _lastSpokenEntry) {
      _lastSpokenEntry = entry;
      _queue.add(entry);
      _onNewEntryQueued();
      if (!_loopRunning) {
        _processLoop();
      }
    }
  }

  void _onNewEntryQueued() {
    switch (ttsSyncMode.value) {
      case 1:
        if (_loopRunning && !_videoPausedForTts) {
          _videoPausedForTts = true;
          _playerController.pause();
        }
        break;
      case 2:
        if (_loopRunning) _adjustSpeed();
        break;
    }
  }

  Future<void> _processLoop() async {
    if (_loopRunning) return;
    _loopRunning = true;
    _duckVideo();

    while (_queue.isNotEmpty) {
      if (syncStatus.value == SyncStatus.userPaused && !_draining) break;

      syncStatus.value = SyncStatus.speaking;
      final entry = _queue.removeFirst();

      try {
        await _ttsController.speak(entry.text);
      } catch (_) {}

      if (syncStatus.value == SyncStatus.userPaused && !_draining) break;

      if (ttsSyncMode.value == 2) {
        if (_queue.isNotEmpty) {
          _adjustSpeed();
        } else {
          _restoreBaseSpeed();
        }
      }
    }

    _loopRunning = false;

    if (_draining) {
      _draining = false;
      _unduckVideo();
      syncStatus.value = SyncStatus.userPaused;
      return;
    }

    if (syncStatus.value != SyncStatus.userPaused) {
      _onAllDone();
    }
  }

  void _onAllDone() {
    _unduckVideo();
    if (ttsSyncMode.value == 1 && _videoPausedForTts) {
      _videoPausedForTts = false;
      _playerController.play();
    }

    if (ttsSyncMode.value == 2) _restoreBaseSpeed();

    if (syncStatus.value == SyncStatus.speaking) {
      syncStatus.value = SyncStatus.playing;
    }
  }

  void _adjustSpeed() {
    _restoreTimer?.cancel();
    _restoreTimer = null;

    final queueLen = _queue.length;
    if (queueLen == 0) return;

    final ttsBoost = 0.1 * queueLen;
    final newTtsSpeed = (_baseSpeed + ttsBoost).clamp(0.5, 1.5);
    _ttsController.setSpeed(newTtsSpeed);

    if (!_videoSlowedForSync) {
      _savedVideoSpeed = _settings.playbackSpeed.value;
      if (_savedVideoSpeed < 0.7) _savedVideoSpeed = 1.0;
      _videoSlowedForSync = true;
    }
    final videoSlow = 0.1 * queueLen;
    final newVideoSpeed = (_savedVideoSpeed - videoSlow).clamp(0.7, _savedVideoSpeed);
    _playerController.setPlaybackSpeed(newVideoSpeed);
  }

  void _restoreBaseSpeed() {
    _baseSpeed = _settings.ttsSettings.value.speechRate;
    _ttsController.setSpeed(_baseSpeed);
    if (_videoSlowedForSync) {
      _progressiveRestore();
    }
  }

  void _progressiveRestore() {
    _restoreTimer?.cancel();
    const steps = 6;
    const intervalMs = 500;
    final target = _savedVideoSpeed;
    final current = _playerController.playbackSpeed.value;
    final stepSize = (target - current) / steps;
    var remaining = steps;

    _restoreTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      remaining--;
      if (remaining <= 0) {
        _playerController.setPlaybackSpeed(target);
        _videoSlowedForSync = false;
        timer.cancel();
        _restoreTimer = null;
        return;
      }
      final next = (_playerController.playbackSpeed.value + stepSize).clamp(0.7, target);
      _playerController.setPlaybackSpeed(next);
    });
  }

  void onUserPause() {
    _unduckVideo();
    _videoPausedForTts = false;
    _playerController.pause();

    if (ttsSyncMode.value == 1 && _loopRunning) {
      _draining = true;
    } else {
      syncStatus.value = SyncStatus.userPaused;
      _queue.clear();
      _ttsController.stop();
    }

    if (ttsSyncMode.value == 2) _cancelSyncSpeed();
  }

  void onUserPlay() {
    _draining = false;
    syncStatus.value = SyncStatus.playing;
    _lastSpokenEntry = null;
    _videoPausedForTts = false;
    _playerController.play();
  }

  void onUserSeek(Duration position) {
    _draining = false;
    _ttsController.stop();
    _queue.clear();
    _lastSpokenEntry = null;
    _videoPausedForTts = false;
    if (ttsSyncMode.value == 2) _cancelSyncSpeed();
    _playerController.seek(position);
  }

  void toggleTts() {
    isTtsEnabled.toggle();
    if (!isTtsEnabled.value) {
      _draining = false;
      _ttsController.stop();
      _queue.clear();
      if (_videoPausedForTts) {
        _videoPausedForTts = false;
        _playerController.play();
      }
      if (ttsSyncMode.value == 2) _cancelSyncSpeed();
    }
  }

  void cycleSyncMode() {
    final next = (ttsSyncMode.value + 1) % 3;
    _settings.updateTtsSyncMode(next);
  }

  void reset() {
    _unduckVideo();
    _draining = false;
    _ttsController.stop();
    _queue.clear();
    _lastSpokenEntry = null;
    _videoPausedForTts = false;
    _cancelSyncSpeed();
    syncStatus.value = SyncStatus.idle;
  }

  void _duckVideo() {
    if (!_settings.isDuckingEnabled.value || _isDucked) return;
    if (_settings.videoVolume.value <= _settings.duckingLevel.value) return;
    _isDucked = true;
    _playerController.setVideoVolume(_settings.duckingLevel.value);
  }

  void _unduckVideo() {
    if (!_isDucked) return;
    _isDucked = false;
    _playerController.setVideoVolume(_settings.videoVolume.value);
  }

  void _cancelSyncSpeed() {
    _restoreTimer?.cancel();
    _restoreTimer = null;
    _baseSpeed = _settings.ttsSettings.value.speechRate;
    _ttsController.setSpeed(_baseSpeed);
    if (_videoSlowedForSync) {
      _playerController.setPlaybackSpeed(_savedVideoSpeed);
      _videoSlowedForSync = false;
    }
  }

  @override
  void onClose() {
    _restoreTimer?.cancel();
    _ttsController.stop();
    _queue.clear();
    super.onClose();
  }
}
