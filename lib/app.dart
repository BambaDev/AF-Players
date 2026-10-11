import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'controllers/settings_controller.dart';
import 'controllers/native_tts_controller.dart';
import 'controllers/audio_mixer_controller.dart';
import 'controllers/library_controller.dart';
import 'controllers/explorer_controller.dart';
import 'controllers/thumbnail_controller.dart';
import 'presentation/explorer/explorer_screen.dart';

class AFPlayersApp extends StatelessWidget {
  const AFPlayersApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.put(SettingsController());
    Get.put(NativeTtsController());
    Get.put(AudioMixerController());
    Get.put(LibraryController());
    Get.put(ExplorerController());
    Get.put(ThumbnailController());

    return Obx(() => GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: settings.isDarkMode.value ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: const ExplorerScreen(),
    ));
  }
}
