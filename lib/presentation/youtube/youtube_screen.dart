import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/youtube_controller.dart';
import '../../controllers/library_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/video_item.dart';
import '../player/player_screen.dart';

class YouTubeScreen extends StatefulWidget {
  const YouTubeScreen({super.key});

  @override
  State<YouTubeScreen> createState() => _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen> {
  final _urlController = TextEditingController();
  final _ytController = Get.put(YouTubeController());

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _startDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    final success = await _ytController.download(url);
    if (success && _ytController.lastVideoPath != null) {
      final library = Get.find<LibraryController>();
      final video = VideoItem(
        id: const Uuid().v4(),
        title: _ytController.lastTitle ?? 'YouTube Video',
        videoPath: _ytController.lastVideoPath!,
        subtitlePath: _ytController.lastSubtitlePath,
        sourceType: VideoSourceType.local,
        addedAt: DateTime.now(),
      );
      library.addVideo(
        title: video.title,
        videoPath: video.videoPath,
        subtitlePath: video.subtitlePath,
        sourceType: video.sourceType,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Téléchargement terminé',
                style: TextStyle(color: AppColors.textPrimary)),
            content: Text(
              '${video.title}\n${_ytController.lastSubtitlePath != null ? "Sous-titres FR trouvés" : "Pas de sous-titres FR disponibles"}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Get.to(() => PlayerScreen(video: video));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Lire', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('YouTube', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Coller un lien YouTube',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'La vidéo et les sous-titres français seront téléchargés automatiquement',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'https://www.youtube.com/watch?v=...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.link, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => ElevatedButton.icon(
              onPressed: _ytController.isLoading.value ? null : _startDownload,
              icon: _ytController.isLoading.value
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download),
              label: Text(_ytController.isLoading.value ? 'Téléchargement...' : 'Télécharger'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            )),
            const SizedBox(height: 16),
            Obx(() {
              if (_ytController.isLoading.value && _ytController.progress.value > 0) {
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _ytController.progress.value,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ytController.statusText.value,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                );
              }
              if (_ytController.statusText.value.isNotEmpty && !_ytController.isLoading.value) {
                return Text(
                  _ytController.statusText.value,
                  style: const TextStyle(color: AppColors.accent, fontSize: 13),
                );
              }
              if (_ytController.errorText.value.isNotEmpty) {
                return Text(
                  _ytController.errorText.value,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }
}
