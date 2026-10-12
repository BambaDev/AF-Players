import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/bookmark_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/duration_extensions.dart';
import '../../../data/models/bookmark.dart';

class BookmarkListSheet extends StatelessWidget {
  final String videoId;
  final void Function(Duration position) onSeek;

  const BookmarkListSheet({
    super.key,
    required this.videoId,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<BookmarkController>();

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Signets',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Obx(() {
              final items = ctrl.getBookmarksForVideo(videoId);
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucun signet pour cette vidéo',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (ctx, index) {
                  final bm = items[index];
                  return _buildBookmarkTile(context, bm, ctrl);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarkTile(BuildContext context, Bookmark bm, BookmarkController ctrl) {
    final timestamp = Duration(milliseconds: bm.positionMs).toShortTimestamp();

    return Dismissible(
      key: ValueKey(bm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => ctrl.deleteBookmark(bm.id),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onSeek(Duration(milliseconds: bm.positionMs));
        },
        onLongPress: () => _showEditDialog(context, bm, ctrl),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  timestamp,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bm.note.isEmpty ? '(sans note)' : bm.note,
                  style: TextStyle(
                    color: bm.note.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                    fontSize: 14,
                    fontStyle: bm.note.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Bookmark bm, BookmarkController ctrl) {
    final textCtrl = TextEditingController(text: bm.note);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Modifier la note', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Votre note...',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              ctrl.updateNote(bm.id, textCtrl.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
