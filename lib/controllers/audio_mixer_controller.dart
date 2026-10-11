import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AudioMixerController extends GetxController {
  static const _channel = MethodChannel('com.afplayers/audio_mixer');

  final hasFocus = false.obs;

  @override
  void onInit() {
    super.onInit();
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onAudioFocusChange') {
      final type = call.arguments['type'] as String;
      hasFocus.value = type == 'gain';
    }
  }

  Future<bool> requestFocus() async {
    final result = await _channel.invokeMethod<bool>('requestFocus');
    hasFocus.value = result ?? false;
    return hasFocus.value;
  }

  Future<void> abandonFocus() async {
    await _channel.invokeMethod('abandonFocus');
    hasFocus.value = false;
  }

  @override
  void onClose() {
    abandonFocus();
    super.onClose();
  }
}
