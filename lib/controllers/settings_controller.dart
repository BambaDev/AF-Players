import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/tts_settings.dart';

class SettingsController extends GetxController {
  final ttsSettings = const TtsSettings().obs;
  final videoVolume = 0.0.obs;
  final frenchVolume = 1.0.obs;
  final subtitleFontSize = 18.0.obs;
  final seekDuration = 10.obs;
  final isDarkMode = true.obs;
  final ttsSyncMode = 0.obs;
  final isDuckingEnabled = true.obs;
  final duckingLevel = 0.1.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    ttsSettings.value = TtsSettings(
      speechRate: prefs.getDouble('tts_rate') ?? 1.0,
      pitch: prefs.getDouble('tts_pitch') ?? 1.0,
      volume: prefs.getDouble('tts_volume') ?? 1.0,
      voiceName: prefs.getString('tts_voice'),
    );
    videoVolume.value = prefs.getDouble('video_volume') ?? 0.0;
    frenchVolume.value = prefs.getDouble('french_volume') ?? 1.0;
    subtitleFontSize.value = prefs.getDouble('subtitle_font_size') ?? 18.0;
    seekDuration.value = prefs.getInt('seek_duration') ?? 10;
    isDarkMode.value = prefs.getBool('is_dark_mode') ?? true;
    ttsSyncMode.value = prefs.getInt('tts_sync_mode') ?? 0;
    isDuckingEnabled.value = prefs.getBool('is_ducking_enabled') ?? true;
    duckingLevel.value = prefs.getDouble('ducking_level') ?? 0.1;
  }

  Future<void> updateTtsRate(double rate) async {
    ttsSettings.value = ttsSettings.value.copyWith(speechRate: rate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_rate', rate);
  }

  Future<void> updateTtsPitch(double pitch) async {
    ttsSettings.value = ttsSettings.value.copyWith(pitch: pitch);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_pitch', pitch);
  }

  Future<void> updateTtsVolume(double volume) async {
    ttsSettings.value = ttsSettings.value.copyWith(volume: volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tts_volume', volume);
  }

  Future<void> updateTtsVoice(String? voiceName) async {
    ttsSettings.value = ttsSettings.value.copyWith(voiceName: voiceName);
    final prefs = await SharedPreferences.getInstance();
    if (voiceName != null) {
      await prefs.setString('tts_voice', voiceName);
    } else {
      await prefs.remove('tts_voice');
    }
  }

  Future<void> updateVideoVolume(double volume) async {
    videoVolume.value = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('video_volume', volume);
  }

  Future<void> updateFrenchVolume(double volume) async {
    frenchVolume.value = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('french_volume', volume);
  }

  Future<void> updateSubtitleFontSize(double size) async {
    subtitleFontSize.value = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('subtitle_font_size', size);
  }

  Future<void> updateSeekDuration(int seconds) async {
    seekDuration.value = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seek_duration', seconds);
  }

  Future<void> updateDarkMode(bool isDark) async {
    isDarkMode.value = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }

  Future<void> updateTtsSyncMode(int mode) async {
    ttsSyncMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tts_sync_mode', mode);
  }

  Future<void> updateDuckingEnabled(bool enabled) async {
    isDuckingEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_ducking_enabled', enabled);
  }

  Future<void> updateDuckingLevel(double level) async {
    duckingLevel.value = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ducking_level', level);
  }
}
