import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class NativePlayerController extends GetxController {
  static const _method = MethodChannel('com.afplayers/player');
  static const _events = EventChannel('com.afplayers/player_events');

  final isPlaying = false.obs;
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;
  final isBuffering = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final videoVolume = 0.0.obs;

  int? textureId;
  StreamSubscription? _eventSub;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    try {
      final id = await _method.invokeMethod<int>('init');
      textureId = id;
      update();
      _eventSub = _events.receiveBroadcastStream().listen(
        _handleEvent,
        onError: (e) {
          hasError.value = true;
          errorMessage.value = 'Erreur du flux vidéo: $e';
        },
      );
    } catch (e) {
      hasError.value = true;
      errorMessage.value = 'Impossible d\'initialiser le lecteur: $e';
    }
  }

  void _handleEvent(dynamic event) {
    if (event is! Map) return;
    final map = Map<String, dynamic>.from(event);
    switch (map['event']) {
      case 'position':
        position.value = Duration(milliseconds: (map['position'] as num).toInt());
        break;
      case 'durationChanged':
        duration.value = Duration(milliseconds: (map['duration'] as num).toInt());
        break;
      case 'playingChanged':
        isPlaying.value = map['isPlaying'] as bool;
        break;
      case 'stateChanged':
        final state = map['state'] as String;
        isBuffering.value = state == 'buffering';
        if (state == 'ended') {
          isPlaying.value = false;
        }
        break;
      case 'error':
        hasError.value = true;
        errorMessage.value = map['message'] as String? ?? 'Unknown error';
        break;
    }
  }

  Future<void> open(String pathOrUrl) async {
    hasError.value = false;
    errorMessage.value = '';
    await _method.invokeMethod('open', {'path': pathOrUrl});
    await _method.invokeMethod('setVolume', {'volume': videoVolume.value});
  }

  Future<void> play() async => await _method.invokeMethod('play');

  Future<void> pause() async => await _method.invokeMethod('pause');

  Future<void> togglePlayPause() async {
    if (isPlaying.value) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration pos) async {
    await _method.invokeMethod('seek', {'position': pos.inMilliseconds});
  }

  Future<void> seekForward(int seconds) async {
    final newPos = position.value + Duration(seconds: seconds);
    final maxPos = duration.value;
    await seek(newPos > maxPos ? maxPos : newPos);
  }

  Future<void> seekBackward(int seconds) async {
    final newPos = position.value - Duration(seconds: seconds);
    await seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  Future<void> setVideoVolume(double volume) async {
    videoVolume.value = volume;
    await _method.invokeMethod('setVolume', {'volume': volume});
  }

  @override
  void onClose() {
    _eventSub?.cancel();
    _method.invokeMethod('dispose');
    super.onClose();
  }
}
