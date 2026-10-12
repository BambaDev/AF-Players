import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/library_controller.dart';
import '../../controllers/thumbnail_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/video_item.dart';
import '../player/player_screen.dart';

class RecentsTab extends StatelessWidget {
  const RecentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final library = Get.find<LibraryController>();

    return Obx(() {
      final items = library.recents;

      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text('Aucun historique', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Les vidéos lues apparaîtront ici', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        );
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildVideoTile(items[index]),
      );
    });
  }

  Widget _buildVideoTile(VideoItem video) {
    final timeAgo = _formatTimeAgo(video.lastPlayedAt!);

    return InkWell(
      onTap: () => Get.to(() => PlayerScreen(video: video)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5)),
        ),
        child: Row(
          children: [
            _Thumbnail(videoPath: video.videoPath),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(timeAgo, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  if (video.durationMs > 0) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: video.progress.clamp(0.0, 1.0),
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                video.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: video.isFavorite ? Colors.redAccent : AppColors.textSecondary,
                size: 22,
              ),
              onPressed: () => Get.find<LibraryController>().toggleFavorite(video.id),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? "s" : ""}';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _Thumbnail extends StatefulWidget {
  final String videoPath;
  const _Thumbnail({required this.videoPath});

  @override
  State<_Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<_Thumbnail> {
  @override
  void initState() {
    super.initState();
    Get.find<ThumbnailController>().getThumbnail(widget.videoPath);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final path = Get.find<ThumbnailController>().thumbnails[widget.videoPath];
      return Container(
        width: 56,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: path != null
            ? Image.file(File(path), fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.movie, color: AppColors.accent, size: 24))
            : const Icon(Icons.movie, color: AppColors.accent, size: 24),
      );
    });
  }
}
