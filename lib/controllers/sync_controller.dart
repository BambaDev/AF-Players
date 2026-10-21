import 'dart:async';
import 'dart:collection';
import 'package:get/get.dart';
import 'native_player_controller.dart';
import 'subtitle_controller.dart';
import 'native_tts_controller.dart';
import 'settings_controller.dart';
import '../data/models/subtitle_entry.dart';
import '../data/services/subtitle_merger.dart';
import '../data/services/smart_subtitle_merger.dart';

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

  // Modes 0 (Fusion) et 1 (Pause)
  List<MergedSubtitleGroup> _mergedGroups = [];
  Map<int, int> _entryToGroupIndex = {};
  int _lastSpokenGroupIndex = -1;

  // Mode 2 (Smart)
  List<SmartMergedGroup> _smartGroups = [];
  Map<int, int> _smartEntryToGroupIndex = {};
  int _lastSpokenSmartGroupIndex = -1;
  final Queue<int> _smartGroupIndexQueue = Queue();

  @override
  void onInit() {
    super.onInit();
    _playerController = Get.find<NativePlayerController>();
    _subtitleController = Get.find<SubtitleController>();
    _ttsController = Get.find<NativeTtsController>();
    _settings = Get.find<SettingsController>();
    ttsSyncMode.value = _settings.ttsSyncMode.value.clamp(0, 2);
    _baseSpeed = _settings.ttsSettings.value.speechRate;

    ever(_settings.ttsSyncMode, (val) {
      ttsSyncMode.value = val.clamp(0, 2);
      if (val != 1 && _videoPausedForTts) {
        _videoPausedForTts = false;
        _playerController.play();
      }
    });

    ever(_subtitleController.subtitleFile, (_) => _buildMergedGroups());

    ever(_playerController.position, _onPositionChanged);
  }

  void _buildMergedGroups() {
    final file = _subtitleController.subtitleFile.value;
    if (file == null || file.isEmpty) {
      _mergedGroups = [];
      _entryToGroupIndex = {};
      _smartGroups = [];
      _smartEntryToGroupIndex = {};
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

    _smartGroups = SmartSubtitleMerger.merge(file.entries);
    _smartEntryToGroupIndex = {};
    for (var i = 0; i < _smartGroups.length; i++) {
      for (final idx in _smartGroups[i].entryIndices) {
        _smartEntryToGroupIndex[idx] = i;
      }
    }
    _lastSpokenSmartGroupIndex = -1;
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

      if (ttsSyncMode.value == 2) {
        final groupIndex = _smartEntryToGroupIndex[entry.index];
        if (groupIndex != null && groupIndex != _lastSpokenSmartGroupIndex) {
          _lastSpokenSmartGroupIndex = groupIndex;
          _queue.add(_smartGroups[groupIndex].text);
          _smartGroupIndexQueue.add(groupIndex);
          _onNewEntryQueued();
          if (!_loopRunning) _processLoop();
        }
      } else {
        final groupIndex = _entryToGroupIndex[entry.index];
        if (groupIndex != null && groupIndex != _lastSpokenGroupIndex) {
          _lastSpokenGroupIndex = groupIndex;
          _queue.add(_mergedGroups[groupIndex].text);
          _onNewEntryQueued();
          if (!_loopRunning) _processLoop();
        }
      }
    }
  }

  void _onNewEntryQueued() {
    if (ttsSyncMode.value == 1 && _loopRunning && !_videoPausedForTts) {
      _videoPausedForTts = true;
      _playerController.pause();
    }
  }

  Future<void> _processLoop() async {
    if (_loopRunning) return;
    _loopRunning = true;
    _duckVideo();

    while (_queue.isNotEmpty) {
      if (!isTtsEnabled.value) break;
      if (syncStatus.value == SyncStatus.userPaused && !_draining) break;

      syncStatus.value = SyncStatus.speaking;
      final text = _queue.removeFirst();

      int? spokenSmartGroupIdx;
      if (ttsSyncMode.value == 2 && _smartGroupIndexQueue.isNotEmpty) {
        spokenSmartGroupIdx = _smartGroupIndexQueue.removeFirst();
      }

      try {
        if (ttsSyncMode.value == 2 && spokenSmartGroupIdx != null &&
            spokenSmartGroupIdx < _smartGroups.length) {
          _ttsController.setSpeed(_smartGroups[spokenSmartGroupIdx].suggestedSpeed);
        }
        await _speakWithPauses(text);
        if (ttsSyncMode.value == 2) {
          _ttsController.setSpeed(_baseSpeed);
        }
      } catch (_) {}

      if (!isTtsEnabled.value) break;
      if (syncStatus.value == SyncStatus.userPaused && !_draining) break;

      if (ttsSyncMode.value == 2 && _queue.isEmpty && spokenSmartGroupIdx != null) {
        await _waitForNextSmartGroup(spokenSmartGroupIdx + 1);
        if (_queue.isNotEmpty) continue;
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
    if (syncStatus.value == SyncStatus.speaking) {
      syncStatus.value = SyncStatus.playing;
    }
  }

  Future<void> _waitForNextSmartGroup(int nextIdx) async {
    if (nextIdx >= _smartGroups.length) return;
    final nextStart = _smartGroups[nextIdx].start;

    while (_queue.isEmpty &&
        isTtsEnabled.value &&
        syncStatus.value != SyncStatus.userPaused &&
        !_draining) {
      final pos = _playerController.position.value;
      if (pos >= nextStart - const Duration(milliseconds: 300)) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  static final _sentenceSplitter = RegExp(r'(?<=[.!?…])\s+');

  Future<void> _speakWithPauses(String text) async {
    final sentences = text.split(_sentenceSplitter);
    for (var i = 0; i < sentences.length; i++) {
      if (!isTtsEnabled.value) return;
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
      _smartGroupIndexQueue.clear();
      _ttsController.stop();
    }
  }

  void onUserPlay() {
    _draining = false;
    syncStatus.value = SyncStatus.playing;
    _lastSpokenEntry = null;
    _lastSpokenGroupIndex = -1;
    _lastSpokenSmartGroupIndex = -1;
    _videoPausedForTts = false;
    _playerController.play();
  }

  void onUserSeek(Duration position) {
    _draining = false;
    _ttsController.stop();
    _queue.clear();
    _smartGroupIndexQueue.clear();
    _lastSpokenEntry = null;
    _lastSpokenGroupIndex = -1;
    _lastSpokenSmartGroupIndex = -1;
    _videoPausedForTts = false;
    _baseSpeed = _settings.ttsSettings.value.speechRate;
    _ttsController.setSpeed(_baseSpeed);
    _playerController.seek(position);
  }

  void toggleTts() {
    isTtsEnabled.toggle();
    if (!isTtsEnabled.value) {
      _draining = false;
      _ttsController.stop();
      _queue.clear();
      _smartGroupIndexQueue.clear();
      if (_videoPausedForTts) {
        _videoPausedForTts = false;
        _playerController.play();
      }
      _baseSpeed = _settings.ttsSettings.value.speechRate;
      _ttsController.setSpeed(_baseSpeed);
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
    _smartGroupIndexQueue.clear();
    _lastSpokenEntry = null;
    _lastSpokenGroupIndex = -1;
    _lastSpokenSmartGroupIndex = -1;
    _videoPausedForTts = false;
    _baseSpeed = _settings.ttsSettings.value.speechRate;
    _ttsController.setSpeed(_baseSpeed);
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

  @override
  void onClose() {
    _ttsController.stop();
    _queue.clear();
    _smartGroupIndexQueue.clear();
    super.onClose();
  }
}
