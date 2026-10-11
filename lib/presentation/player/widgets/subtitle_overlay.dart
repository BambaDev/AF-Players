import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/subtitle_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../../core/constants/app_colors.dart';

class SubtitleOverlay extends StatelessWidget {
  final SubtitleController subtitleController;

  const SubtitleOverlay({super.key, required this.subtitleController});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return Obx(() {
      final entry = subtitleController.currentEntry.value;
      if (entry == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.subtitleBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Obx(() => Text(
          entry.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: settings.subtitleFontSize.value,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        )),
      );
    });
  }
}
