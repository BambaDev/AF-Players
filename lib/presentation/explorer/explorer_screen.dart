import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/explorer_controller.dart';
import '../../controllers/library_controller.dart';
import '../../controllers/thumbnail_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/video_item.dart';
import '../player/player_screen.dart';

class ExplorerTab extends StatelessWidget {
  const ExplorerTab({super.key});

  @override
  Widget build(BuildContext context) {
    final explorer = Get.find<ExplorerController>();

    return Obx(() => Column(
      children: [
        _buildSearchBar(explorer),
        _buildBreadcrumb(explorer),
        _buildResumeBanner(context),
        Expanded(child: _buildContent(explorer, context)),
      ],
    ));
  }

  Widget _buildSearchBar(ExplorerController explorer) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (v) => explorer.searchQuery.value = v,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
            onPressed: () => explorer.openFolder(explorer.currentPath.value),
            tooltip: 'Actualiser',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildResumeBanner(BuildContext context) {
    final library = Get.find<LibraryController>();
    return Obx(() {
      final video = library.lastPlayed;
      if (video == null || video.lastPositionMs <= 0) {
        return const SizedBox.shrink();
      }

      final progress = (video.lastPositionMs / 1000 / 60).toStringAsFixed(0);

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              AppColors.accent.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Get.to(() => PlayerScreen(video: video)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reprendre la lecture',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        video.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Position: ${progress}min',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBreadcrumb(ExplorerController explorer) {
    if (explorer.showingVolumes.value) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.surface.withValues(alpha: 0.5),
        child: const Row(
          children: [
            Icon(Icons.storage, size: 16, color: AppColors.accent),
            SizedBox(width: 4),
            Text('Espaces de stockage', style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final path = explorer.currentPath.value;
    final volumeRoot = explorer.currentVolumeRoot ?? path;
    final volumeName = explorer.currentVolumeName ?? 'Stockage';
    final relative = path.length > volumeRoot.length
        ? path.substring(volumeRoot.length + 1)
        : '';
    final segments = relative.split('/').where((s) => s.isNotEmpty).toList();

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
              onTap: explorer.goBack,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.arrow_back, size: 18, color: AppColors.textSecondary),
              ),
            ),
            if (explorer.storageVolumes.length > 1)
              InkWell(
                onTap: explorer.showVolumeList,
                child: const Row(
                  children: [
                    Icon(Icons.storage, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 2),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            InkWell(
              onTap: () => explorer.openFolder(volumeRoot),
              child: Row(
                children: [
                  Icon(
                    _volumeIcon(explorer),
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(volumeName, style: const TextStyle(fontSize: 12, color: AppColors.accent)),
                ],
              ),
            ),
            for (int i = 0; i < segments.length; i++) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondary),
              ),
              InkWell(
                onTap: () {
                  final target = '$volumeRoot/${segments.sublist(0, i + 1).join('/')}';
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
  }

  IconData _volumeIcon(ExplorerController explorer) {
    final root = explorer.currentVolumeRoot;
    if (root == null) return Icons.phone_android;
    final vol = explorer.storageVolumes.cast<StorageVolume?>().firstWhere(
      (v) => v!.path == root,
      orElse: () => null,
    );
    if (vol == null) return Icons.folder;
    switch (vol.type) {
      case StorageVolumeType.internal:
        return Icons.phone_android;
      case StorageVolumeType.sdCard:
        return Icons.sd_card;
      case StorageVolumeType.usb:
        return Icons.usb;
      case StorageVolumeType.other:
        return Icons.storage;
    }
  }

  Widget _buildContent(ExplorerController explorer, BuildContext context) {
    if (!explorer.hasPermission.value) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Permission requise',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Autorisez l\'accès aux fichiers pour naviguer',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: explorer.retryPermission,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Autoriser', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    if (explorer.showingVolumes.value) {
      return _buildVolumeList(explorer);
    }

    if (explorer.isLoading.value) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final allItems = explorer.filteredItems;
    final visibleItems = allItems.where((e) {
      if (e is Directory) return true;
      return explorer.isVideo(e);
    }).toList();

    if (visibleItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              explorer.searchQuery.value.isNotEmpty ? 'Aucun résultat' : 'Dossier vide',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: visibleItems.length,
      itemBuilder: (context, index) {
        final entity = visibleItems[index];
        if (entity is Directory) {
          return _buildFolderTile(entity, explorer);
        }
        return _buildVideoTile(entity as File, explorer, context);
      },
    );
  }

  Widget _buildVolumeList(ExplorerController explorer) {
    final volumes = explorer.storageVolumes;
    if (volumes.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: volumes.length,
      itemBuilder: (context, index) {
        final vol = volumes[index];
        IconData icon;
        Color iconColor;
        switch (vol.type) {
          case StorageVolumeType.internal:
            icon = Icons.phone_android;
            iconColor = AppColors.primary;
            break;
          case StorageVolumeType.sdCard:
            icon = Icons.sd_card;
            iconColor = AppColors.accent;
            break;
          case StorageVolumeType.usb:
            icon = Icons.usb;
            iconColor = Colors.orangeAccent;
            break;
          case StorageVolumeType.other:
            icon = Icons.storage;
            iconColor = AppColors.textSecondary;
            break;
        }

        String? sizeInfo;
        try {
          final stat = FileStat.statSync(vol.path);
          if (stat.type != FileSystemEntityType.notFound) {
            sizeInfo = vol.path;
          }
        } catch (_) {
          sizeInfo = vol.path;
        }

        return InkWell(
          onTap: () => explorer.openFolder(vol.path),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vol.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (sizeInfo != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          sizeInfo,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFolderTile(Directory folder, ExplorerController explorer) {
    final name = folder.path.split('/').last;
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
                name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTile(File file, ExplorerController explorer, BuildContext context) {
    final name = file.path.split('/').last;
    FileStat? stat;
    try {
      stat = file.statSync();
    } catch (_) {}

    return InkWell(
      onTap: () => _onVideoTap(file, explorer, context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5)),
        ),
        child: Row(
          children: [
            _VideoThumbnail(videoPath: file.path),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (stat != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(stat.size),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 28),
          ],
        ),
      ),
    );
  }

  void _onVideoTap(File file, ExplorerController explorer, BuildContext context) {
    final matchedSubs = explorer.findSubtitlesForVideo(file.path);
    final allSubs = explorer.allSubtitlesInFolder();
    final otherSubs = allSubs.where((s) => !matchedSubs.contains(s)).toList();
    final name = file.path.split('/').last;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _buildSubtitlePicker(ctx, file.path, name, matchedSubs, otherSubs),
    );
  }

  Widget _buildSubtitlePicker(
    BuildContext context,
    String videoPath,
    String videoName,
    List<String> matchedSubs,
    List<String> otherSubs,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              videoName,
              style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
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
                _launchPlayer(videoPath, videoName, null);
              },
            ),

            if (matchedSubs.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  'Correspondants',
                  style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              ...matchedSubs.map((path) => _subtitleOption(
                icon: Icons.subtitles,
                color: AppColors.accent,
                title: path.split('/').last,
                onTap: () {
                  Navigator.pop(context);
                  _launchPlayer(videoPath, videoName, path);
                },
              )),
            ],

            if (otherSubs.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 6),
                child: Text(
                  'Autres sous-titres du dossier',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              ...otherSubs.map((path) => _subtitleOption(
                icon: Icons.subtitles_outlined,
                color: AppColors.textSecondary,
                title: path.split('/').last,
                onTap: () {
                  Navigator.pop(context);
                  _launchPlayer(videoPath, videoName, path);
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
                  _launchPlayer(videoPath, videoName, result.files.single.path);
                }
              },
            ),
          ],
        ),
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
    var video = library.findByPath(videoPath);
    if (video != null) {
      if (subtitlePath != null && video.subtitlePath != subtitlePath) {
        library.updateSubtitlePath(video.id, subtitlePath);
        video = library.findByPath(videoPath)!;
      }
    } else {
      library.addVideo(
        title: videoName,
        videoPath: videoPath,
        subtitlePath: subtitlePath,
        sourceType: VideoSourceType.local,
      );
      video = library.findByPath(videoPath)!;
    }
    Get.to(() => PlayerScreen(video: video!));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String videoPath;
  const _VideoThumbnail({required this.videoPath});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  @override
  void initState() {
    super.initState();
    Get.find<ThumbnailController>().getThumbnail(widget.videoPath);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final thumbs = Get.find<ThumbnailController>().thumbnails;
      final path = thumbs[widget.videoPath];

      return Container(
        width: 56,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: path != null
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.movie, color: AppColors.accent, size: 24),
              )
            : const Icon(Icons.movie, color: AppColors.accent, size: 24),
      );
    });
  }
}
