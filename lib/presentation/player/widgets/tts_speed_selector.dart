import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/native_tts_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class TtsSpeedSelector extends StatelessWidget {
  const TtsSpeedSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final ttsController = Get.find<NativeTtsController>();
    final settings = Get.find<SettingsController>();

    return Obx(() => PopupMenuButton<double>(
      initialValue: ttsController.currentSpeed.value,
      onSelected: (speed) {
        ttsController.setSpeed(speed);
        settings.updateTtsRate(speed);
      },
      itemBuilder: (context) => AppConstants.ttsSpeedOptions.map((speed) {
        return PopupMenuItem<double>(
          value: speed,
          child: Text(
            'x${speed.toString()}',
            style: TextStyle(
              color: speed == ttsController.currentSpeed.value
                  ? AppColors.primary
                  : null,
              fontWeight: speed == ttsController.currentSpeed.value
                  ? FontWeight.bold
                  : null,
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed, color: AppColors.accent, size: 16),
            const SizedBox(width: 4),
            Text(
              'x${ttsController.currentSpeed.value}',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ));
  }
}
