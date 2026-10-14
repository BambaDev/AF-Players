import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/playlist_controller.dart';
import '../../controllers/library_controller.dart';
import '../../controllers/thumbnail_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/playlist.dart';
import '../../data/models/video_item.dart';
import '../player/player_screen.dart';

class PlaylistScreen extends StatelessWidget {
  final Playlist playlist;
  const PlaylistScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    final playlistCtrl = Get.find<PlaylistController>();
    final library = Get.find<LibraryController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Obx(() {
          final p = playlistCtrl.playlists.firstWhereOrNull((e) => e.id == playlist.id);
          return Text(
            p?.name ?? playlist.name,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
          );
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.textSecondary, size: 20),
            onPressed: () => _showRenameDialog(context, playlistCtrl),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            onPressed: () => _confirmDelete(context, playlistCtrl),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _addVideos(playlistCtrl),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        final p = playlistCtrl.playlists.firstWhereOrNull((e) => e.id == playlist.id);
        if (p == null) return const SizedBox.shrink();

        if (p.videoPaths.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.playlist_add, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text('Playlist vide', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Ajoutez des vidéos avec le bouton +', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          );
        }

        final completed = p.videoPaths.where((path) {
          final v = library.findByPath(path);
          return v != null && v.durationMs > 0 && v.progress > 0.9;
        }).length;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.playlist_play, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${p.videoCount} vidéo${p.videoCount > 1 ? "s" : ""}',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: p.videoCount > 0 ? completed / p.videoCount : 0,
                            backgroundColor: AppColors.surfaceLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$completed/${p.videoCount}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: p.videoPaths.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final item = p.videoPaths.removeAt(oldIndex);
                  p.videoPaths.insert(newIndex, item);
                  p.save();
                  playlistCtrl.playlists.refresh();
                },
                itemBuilder: (context, index) {
                  final path = p.videoPaths[index];
                  final name = path.split('/').last;
                  final video = library.findByPath(path);

                  return _buildVideoTile(
                    key: ValueKey(path),
                    path: path,
                    name: name,
                    video: video,
                    playlistCtrl: playlistCtrl,
                    library: library,
                    index: index,
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildVideoTile({
    required Key key,
    required String path,
    required String name,
    required VideoItem? video,
    required PlaylistController playlistCtrl,
    required LibraryController library,
    required int index,
  }) {
    return Dismissible(
      key: key,
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => playlistCtrl.removeVideo(playlist.id, path),
      child: InkWell(
        onTap: () {
          if (video != null) {
            Get.to(() => PlayerScreen(video: video));
          } else {
            library.addVideo(
              title: name,
              videoPath: path,
              sourceType: VideoSourceType.local,
            );
            final created = library.findByPath(path);
            if (created != null) {
              Get.to(() => PlayerScreen(video: created));
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              _Thumbnail(videoPath: path),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video != null && video.durationMs > 0) ...[
                      const SizedBox(height: 4),
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
              if (video != null && video.durationMs > 0 && video.progress > 0.9)
                const Icon(Icons.check_circle, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Icon(Icons.drag_handle, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _addVideos(PlaylistController ctrl) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'webm', 'mov', 'flv', '3gp'],
      allowMultiple: true,
    );
    if (result != null) {
      for (final file in result.files) {
        if (file.path != null) {
          await ctrl.addVideo(playlist.id, file.path!);
        }
      }
    }
  }

  void _showRenameDialog(BuildContext context, PlaylistController ctrl) {
    final textCtrl = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Renommer', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final name = textCtrl.text.trim();
              if (name.isNotEmpty) {
                ctrl.rename(playlist.id, name);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, PlaylistController ctrl) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Supprimer la playlist?', style: TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              ctrl.delete(playlist.id);
              Navigator.pop(ctx);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
