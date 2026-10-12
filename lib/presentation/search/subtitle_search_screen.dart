import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/subtitle_search_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/duration_extensions.dart';
import '../../data/models/video_item.dart';
import '../player/player_screen.dart';

class SubtitleSearchScreen extends StatelessWidget {
  const SubtitleSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(SubtitleSearchController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: TextField(
          autofocus: true,
          onChanged: ctrl.onQueryChanged,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Rechercher dans les sous-titres...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
          ),
        ),
      ),
      body: Obx(() {
        if (ctrl.isSearching.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (ctrl.query.value.trim().length < 2) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text(
                  'Recherchez un mot ou concept',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'La recherche parcourt tous les sous-titres\nde votre bibliothèque',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (ctrl.results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text(
                  'Aucun résultat',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final grouped = <String, List<SubtitleSearchResult>>{};
        for (final r in ctrl.results) {
          grouped.putIfAbsent(r.videoId, () => []).add(r);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final videoId = grouped.keys.elementAt(index);
            final items = grouped[videoId]!;
            final videoTitle = items.first.videoTitle;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.movie, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          videoTitle,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${items.length} résultat${items.length > 1 ? "s" : ""}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ...items.map((r) => _buildResultTile(r, ctrl.query.value)),
                const Divider(color: AppColors.surfaceLight, height: 1),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildResultTile(SubtitleSearchResult result, String query) {
    final timestamp = Duration(milliseconds: result.positionMs).toShortTimestamp();

    return InkWell(
      onTap: () {
        final video = VideoItem(
          id: result.videoId,
          title: result.videoTitle,
          videoPath: result.videoPath,
          subtitlePath: result.subtitlePath,
          sourceType: VideoSourceType.local,
          addedAt: DateTime.now(),
          lastPositionMs: result.positionMs,
        );
        Get.to(() => PlayerScreen(video: video));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                timestamp,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildHighlightedText(result.matchedText, query),
            ),
            const Icon(Icons.play_circle_outline, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    final q = query.trim().toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    final lower = text.toLowerCase();

    while (start < text.length) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(
          text: text.substring(start, idx),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0x336C63FF),
        ),
      ));
      start = idx + q.length;
    }

    return RichText(text: TextSpan(children: spans), maxLines: 3, overflow: TextOverflow.ellipsis);
  }
}
