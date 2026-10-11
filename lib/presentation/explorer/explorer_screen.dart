import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../controllers/explorer_controller.dart';
import '../../controllers/library_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/video_item.dart';
import '../player/player_screen.dart';
import '../settings/settings_screen.dart';

class ExplorerScreen extends StatelessWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final explorer = Get.find<ExplorerController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (explorer.isAtRoot.value) {
            SystemNavigator.pop();
          } else {
            explorer.goBack();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text(
            'AF Players',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          leading: Obx(() => explorer.isAtRoot.value
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: explorer.goBack,
                )),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: () => explorer.isAtRoot.value
                  ? explorer.loadRootFolders()
                  : explorer.openFolder(explorer.currentPath.value),
              tooltip: 'Actualiser',
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.textSecondary),
              onPressed: () => Get.to(() => const SettingsScreen()),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildBreadcrumb(explorer),
            Expanded(child: _buildContent(explorer, context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumb(ExplorerController explorer) {
    return Obx(() {
      final path = explorer.currentPath.value;
      if (path.isEmpty) return const SizedBox.shrink();

      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.surface.withValues(alpha: 0.5),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            children: [
              InkWell(
                onTap: () => explorer.openFolder('/storage/emulated/0'),
                child: const Icon(Icons.phone_android, size: 16, color: AppColors.accent),
              ),
              for (int i = 0; i < segments.length; i++) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondary),
                ),
                InkWell(
                  onTap: () {
                    final target = '/${segments.sublist(0, i + 1).join('/')}';
                    explorer.openFolder(target);
                  },
                  child: Text(
                    segments[i],
                    style: TextStyle(
                      fontSize: 12,
                      color: i == segments.length - 1 ? AppColors.accent : AppColors.textSecondary,
                      fontWeight: i == segments.length - 1 ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildContent(ExplorerController explorer, BuildContext context) {
    return Obx(() {
      if (explorer.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Analyse des fichiers...', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        );
      }

      final folders = explorer.folders;
      final videos = explorer.videoFiles;

      if (folders.isEmpty && videos.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_library_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const Text(
                'Aucune vidéo trouvée',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                explorer.currentPath.value,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: folders.length + videos.length,
        itemBuilder: (context, index) {
          if (index < folders.length) {
            return _buildFolderTile(folders[index], explorer);
          }
          return _buildVideoTile(videos[index - folders.length], explorer, context);
        },
      );
    });
  }

  Widget _buildFolderTile(dynamic folder, ExplorerController explorer) {
    return InkWell(
      onTap: () => explorer.openFolder(folder.path),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.folder, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                folder.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (folder.videoCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${folder.videoCount}',
                  style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTile(dynamic video, ExplorerController explorer, BuildContext context) {
    return InkWell(
      onTap: () => _onVideoTap(video, explorer, context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.movie, color: AppColors.accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatFileSize(video.size),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(video.lastModified),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 28),
          ],
        ),
      ),
    );
  }

  void _onVideoTap(dynamic video, ExplorerController explorer, BuildContext context) {
    final subtitles = explorer.findSubtitlesForVideo(video.path);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _buildSubtitlePicker(ctx, video, subtitles),
    );
  }

  Widget _buildSubtitlePicker(BuildContext context, dynamic video, List<String> subtitles) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            video.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          const Text(
            'Choisir un fichier de sous-titres',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),

          _subtitleOption(
            icon: Icons.play_arrow,
            color: AppColors.primary,
            title: 'Sans sous-titres',
            onTap: () {
              Navigator.pop(context);
              _launchPlayer(video.path, video.name, null);
            },
          ),

          if (subtitles.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                'Sous-titres trouvés',
                style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            ...subtitles.map((path) => _subtitleOption(
              icon: Icons.subtitles,
              color: AppColors.accent,
              title: path.split('/').last,
              onTap: () {
                Navigator.pop(context);
                _launchPlayer(video.path, video.name, path);
              },
            )),
          ],

          const SizedBox(height: 8),
          _subtitleOption(
            icon: Icons.folder_open,
            color: AppColors.textSecondary,
            title: 'Parcourir...',
            onTap: () async {
              Navigator.pop(context);
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['srt', 'vtt'],
              );
              if (result != null && result.files.single.path != null) {
                _launchPlayer(video.path, video.name, result.files.single.path);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _subtitleOption({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchPlayer(String videoPath, String videoName, String? subtitlePath) {
    final library = Get.find<LibraryController>();
    final video = VideoItem(
      id: const Uuid().v4(),
      title: videoName,
      videoPath: videoPath,
      subtitlePath: subtitlePath,
      sourceType: VideoSourceType.local,
      addedAt: DateTime.now(),
    );
    library.addVideo(
      title: video.title,
      videoPath: video.videoPath,
      subtitlePath: video.subtitlePath,
      sourceType: video.sourceType,
    );
    Get.to(() => PlayerScreen(video: video));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
