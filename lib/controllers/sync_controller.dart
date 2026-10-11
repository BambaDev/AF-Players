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
  double _baseSpeed = 1.0;

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
      if (val != 2) _restoreBaseSpeed();
    });

    ever(_playerController.position, _onPositionChanged);
  }

  void _onPositionChanged(Duration position) {
    if (syncStatus.value == SyncStatus.userPaused) return;
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
        if (_queue.length > 1 && !_videoPausedForTts) {
          _videoPausedForTts = true;
          _playerController.pause();
        }
        break;
      case 2:
        if (_queue.length > 1) _adjustSpeed();
        break;
    }
  }

  Future<void> _processLoop() async {
    if (_loopRunning) return;
    _loopRunning = true;

    while (_queue.isNotEmpty) {
      if (syncStatus.value == SyncStatus.userPaused) break;

      syncStatus.value = SyncStatus.speaking;
      final entry = _queue.removeFirst();

      try {
        await _ttsController.speak(entry.text);
      } catch (_) {}

      if (syncStatus.value == SyncStatus.userPaused) break;
    }

    _loopRunning = false;

    if (syncStatus.value != SyncStatus.userPaused) {
      _onAllDone();
    }
  }

  void _onAllDone() {
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
    final boost = 0.15 * _queue.length;
    final newSpeed = (_baseSpeed + boost).clamp(0.5, 3.0);
    _ttsController.setSpeed(newSpeed);
  }

  void _restoreBaseSpeed() {
    _baseSpeed = _settings.ttsSettings.value.speechRate;
    _ttsController.setSpeed(_baseSpeed);
  }

  void onUserPause() {
    syncStatus.value = SyncStatus.userPaused;
    _queue.clear();
    _videoPausedForTts = false;
    _ttsController.stop();
    _playerController.pause();
    if (ttsSyncMode.value == 2) _restoreBaseSpeed();
  }

  void onUserPlay() {
    syncStatus.value = SyncStatus.playing;
    _lastSpokenEntry = null;
    _videoPausedForTts = false;
    _playerController.play();
  }

  void onUserSeek(Duration position) {
    _ttsController.stop();
    _queue.clear();
    _lastSpokenEntry = null;
    _videoPausedForTts = false;
    if (ttsSyncMode.value == 2) _restoreBaseSpeed();
    _playerController.seek(position);
  }

  void toggleTts() {
    isTtsEnabled.toggle();
    if (!isTtsEnabled.value) {
      _ttsController.stop();
      _queue.clear();
      if (_videoPausedForTts) {
        _videoPausedForTts = false;
        _playerController.play();
      }
      if (ttsSyncMode.value == 2) _restoreBaseSpeed();
    }
  }

  void cycleSyncMode() {
    final next = (ttsSyncMode.value + 1) % 3;
    _settings.updateTtsSyncMode(next);
  }

  void reset() {
    _ttsController.stop();
    _queue.clear();
    _lastSpokenEntry = null;
    _videoPausedForTts = false;
    if (ttsSyncMode.value == 2) _restoreBaseSpeed();
    syncStatus.value = SyncStatus.idle;
  }

  @override
  void onClose() {
    _ttsController.stop();
    _queue.clear();
    super.onClose();
  }
}
