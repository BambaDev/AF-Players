import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/native_tts_controller.dart';
import '../../../core/constants/app_colors.dart';

class TtsIndicator extends StatelessWidget {
  const TtsIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final ttsController = Get.find<NativeTtsController>();

    return Obx(() {
      if (!ttsController.isSpeaking.value) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.subtitleBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volume_up, color: AppColors.accent, size: 16),
            const SizedBox(width: 4),
            Text(
              'FR',
              style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    });
  }
}
