import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/library_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/video_item.dart';
import '../../../core/utils/duration_extensions.dart';
import '../../player/player_screen.dart';

class VideoTile extends StatelessWidget {
  final VideoItem video;

  const VideoTile({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => PlayerScreen(video: video)),
      onLongPress: () => _showOptions(context),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Icon(
                    video.sourceType == VideoSourceType.local
                        ? Icons.video_file
                        : Icons.cloud_download,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        video.subtitlePath != null
                            ? Icons.subtitles
                            : Icons.subtitles_off,
                        size: 14,
                        color: video.subtitlePath != null
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        video.subtitlePath != null ? 'Sous-titres' : 'Pas de sous-titres',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (video.lastPositionMs > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Reprise: ${video.lastPosition.toShortTimestamp()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Supprimer'),
              onTap: () {
                Get.find<LibraryController>().deleteVideo(video.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
