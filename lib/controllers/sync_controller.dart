import 'dart:async';
import 'dart:collection';
import 'package:get/get.dart';
import 'native_player_controller.dart';
import 'subtitle_controller.dart';
import 'native_tts_controller.dart';
import 'settings_controller.dart';
import '../data/models/subtitle_entry.dart';
import '../data/services/subtitle_merger.dart';

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
  final Queue<String> _queue = Queue();
  bool _loopRunning = false;
  bool _videoPausedForTts = false;
  bool _draining = false;
  bool _isDucked = false;
  double _baseSpeed = 1.0;
  bool _videoSlowedForSync = false;
  double _savedVideoSpeed = 1.0;
  Timer? _restoreTimer;

  List<MergedSubtitleGroup> _mergedGroups = [];
  Map<int, int> _entryToGroupIndex = {};
  int _lastSpokenGroupIndex = -1;
  final Queue<int> _groupIndexQueue = Queue();

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
      if (val != 2 && val != 4) _cancelSyncSpeed();
    });

    ever(_subtitleController.subtitleFile, (_) => _buildMergedGroups());

    ever(_playerController.position, _onPositionChanged);
  }

  void _buildMergedGroups() {
    final file = _subtitleController.subtitleFile.value;
    if (file == null || file.isEmpty) {
      _mergedGroups = [];
      _entryToGroupIndex = {};
      return;
    }
    _mergedGroups = SubtitleMerger.merge(file.entries);
    _entryToGroupIndex = {};
    for (var i = 0; i < _mergedGroups.length; i++) {
      for (final idx in _mergedGroups[i].entryIndices) {
        _entryToGroupIndex[idx] = i;
      }
    }
    _lastSpokenGroupIndex = -1;
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

      if (ttsSyncMode.value == 3 || ttsSyncMode.value == 4) {
        final groupIndex = _entryToGroupIndex[entry.index];
        if (groupIndex != null && groupIndex != _lastSpokenGroupIndex) {
          _lastSpokenGroupIndex = groupIndex;
          _queue.add(_mergedGroups[groupIndex].text);
          _groupIndexQueue.add(groupIndex);
          _onNewEntryQueued();
          if (!_loopRunning) {
            _processLoop();
          }
        }
      } else {
        _queue.add(entry.text);
        _onNewEntryQueued();
        if (!_loopRunning) {
          _processLoop();
        }
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
      case 4:
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
      final text = _queue.removeFirst();

      int? spokenGroupIdx;
      if ((ttsSyncMode.value == 3 || ttsSyncMode.value == 4) && _groupIndexQueue.isNotEmpty) {
        spokenGroupIdx = _groupIndexQueue.removeFirst();
      }

      try {
        if (ttsSyncMode.value == 3 || ttsSyncMode.value == 4) {
          await _speakWithPauses(text);
        } else {
          await _ttsController.speak(text);
        }
      } catch (_) {}

      if (syncStatus.value == SyncStatus.userPaused && !_draining) break;

      if (ttsSyncMode.value == 2) {
        if (_queue.isNotEmpty) {
          _adjustSpeed();
        } else {
          _restoreBaseSpeed();
        }
      }

      if (ttsSyncMode.value == 4) {
        if (_queue.isNotEmpty) {
          _adjustSpeed();
        } else {
          _cancelSyncSpeed();
          if (spokenGroupIdx != null) {
            await _waitForNextGroup(spokenGroupIdx + 1);
            if (_queue.isNotEmpty) continue;
          }
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

    if (ttsSyncMode.value == 2 || ttsSyncMode.value == 4) _restoreBaseSpeed();

    if (syncStatus.value == SyncStatus.speaking) {
      syncStatus.value = SyncStatus.playing;
    }
  }

  void _adjustSpeed() {
    _restoreTimer?.cancel();
    _restoreTimer = null;

    final queueLen = _queue.length;
    if (queueLen == 0) return;

    if (ttsSyncMode.value == 4) {
      final minTts = 1.4;
      final ttsBoost = 0.1 * (queueLen - 1);
      final newTtsSpeed = (minTts + ttsBoost).clamp(1.4, 2.0);
      _ttsController.setSpeed(newTtsSpeed);
    } else {
      final ttsBoost = 0.1 * queueLen;
      final newTtsSpeed = (_baseSpeed + ttsBoost).clamp(0.5, 1.5);
      _ttsController.setSpeed(newTtsSpeed);
    }

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

  Future<void> _waitForNextGroup(int nextIdx) async {
    if (nextIdx >= _mergedGroups.length) return;
    final nextStart = _mergedGroups[nextIdx].start;
    final baseVideoSpeed = _settings.playbackSpeed.value;
    final boosted = (baseVideoSpeed + 0.1).clamp(1.0, 1.3);
    _playerController.setPlaybackSpeed(boosted);

    while (_queue.isEmpty &&
        syncStatus.value != SyncStatus.userPaused &&
        !_draining) {
      final pos = _playerController.position.value;
      if (pos >= nextStart - const Duration(milliseconds: 300)) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _playerController.setPlaybackSpeed(baseVideoSpeed);
  }

  static final _sentenceSplitter = RegExp(r'(?<=[.!?…])\s+');

  Future<void> _speakWithPauses(String text) async {
    final sentences = text.split(_sentenceSplitter);
    for (var i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].trim();
      if (sentence.isEmpty) continue;
      if (syncStatus.value == SyncStatus.userPaused && !_draining) return;
      await _ttsController.speak(sentence);
      if (i < sentences.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
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
      _groupIndexQueue.clear();
      _ttsController.stop();
    }

    if (ttsSyncMode.value == 2 || ttsSyncMode.value == 4) _cancelSyncSpeed();
  }

  void onUserPlay() {
    _draining = false;
    syncStatus.value = SyncStatus.playing;
    _lastSpokenEntry = null;
    _lastSpokenGroupIndex = -1;
    _videoPausedForTts = false;
    _playerController.play();
  }

  void onUserSeek(Duration position) {
    _draining = false;
    _ttsController.stop();
    _queue.clear();
    _groupIndexQueue.clear();
    _lastSpokenEntry = null;
    _lastSpokenGroupIndex = -1;
    _videoPausedForTts = false;
    if (ttsSyncMode.value == 2 || ttsSyncMode.value == 4) _cancelSyncSpeed();
    _playerController.seek(position);
  }

  void toggleTts() {
    isTtsEnabled.toggle();
    if (!isTtsEnabled.value) {
      _draining = false;
      _ttsController.stop();
      _queue.clear();
      _groupIndexQueue.clear();
      if (_videoPausedForTts) {
        _videoPausedForTts = false;
        _playerController.play();
      }
      if (ttsSyncMode.value == 2 || ttsSyncMode.value == 4) _cancelSyncSpeed();
    }
  }

  void cycleSyncMode() {
    final next = (ttsSyncMode.value + 1) % 5;
    _settings.updateTtsSyncMode(next);
  }

  void reset() {
    _unduckVideo();
    _draining = false;
    _ttsController.stop();
    _queue.clear();
    _groupIndexQueue.clear();
    _lastSpokenEntry = null;
    _lastSpokenGroupIndex = -1;
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
    _groupIndexQueue.clear();
    super.onClose();
  }
}
