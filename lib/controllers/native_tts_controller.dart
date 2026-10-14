import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../data/models/tts_settings.dart';

class NativeTtsController extends GetxController {
  static const _channel = MethodChannel('com.afplayers/speech');

  final isSpeaking = false.obs;
  final isInitialized = false.obs;
  final currentSpeed = 1.0.obs;
  final availableVoices = <Map<String, dynamic>>[].obs;

  Completer<void>? _speakCompleter;

  @override
  void onInit() {
    super.onInit();
    _channel.setMethodCallHandler(_handleNativeCall);
    _loadVoices();
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onInitStatus':
        isInitialized.value = call.arguments['success'] as bool;
        if (isInitialized.value) _loadVoices();
        break;
      case 'onStart':
        isSpeaking.value = true;
        break;
      case 'onComplete':
        isSpeaking.value = false;
        if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
          _speakCompleter!.complete();
        }
        _speakCompleter = null;
        break;
      case 'onError':
        isSpeaking.value = false;
        if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
          _speakCompleter!.complete();
        }
        _speakCompleter = null;
        break;
    }
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await _channel.invokeMethod<List>('getVoices');
      if (voices != null) {
        availableVoices.assignAll(
          voices.map((v) => Map<String, dynamic>.from(v as Map)).toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    _speakCompleter = Completer<void>();
    await _channel.invokeMethod('speak', {'text': text});
    return _speakCompleter!.future;
  }

  Future<void> stop() async {
    await _channel.invokeMethod('stop');
    isSpeaking.value = false;
    if (_speakCompleter != null && !_speakCompleter!.isCompleted) {
      _speakCompleter!.complete();
    }
    _speakCompleter = null;
  }

  Future<void> setVolume(double volume) async {
    await _channel.invokeMethod('setVolume', {'volume': volume});
  }

  Future<void> setSpeed(double speed) async {
    currentSpeed.value = speed;
    await _channel.invokeMethod('setSpeechRate', {'rate': speed});
  }

  Future<void> setPitch(double pitch) async {
    await _channel.invokeMethod('setPitch', {'pitch': pitch});
  }

  Future<void> setVoice(String voiceName) async {
    await _channel.invokeMethod('setVoice', {'name': voiceName});
  }

  Future<void> applySettings(TtsSettings settings) async {
    currentSpeed.value = settings.speechRate;
    await setSpeed(settings.speechRate);
    await setPitch(settings.pitch);
    if (settings.voiceName != null) {
      await setVoice(settings.voiceName!);
    }
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
