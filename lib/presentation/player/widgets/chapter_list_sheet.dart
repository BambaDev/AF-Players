import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/duration_extensions.dart';
import '../../../data/services/chapter_detector.dart';

class ChapterListSheet extends StatelessWidget {
  final List<Chapter> chapters;
  final Duration currentPosition;
  final void Function(Duration) onSeek;

  const ChapterListSheet({
    super.key,
    required this.chapters,
    required this.currentPosition,
    required this.onSeek,
  });

  int get _currentChapterIndex {
    for (var i = chapters.length - 1; i >= 0; i--) {
      if (currentPosition >= chapters[i].start) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIdx = _currentChapterIndex;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.list, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Chapitres (${chapters.length})',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                final isCurrent = index == currentIdx;

                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    onSeek(chapter.start);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : null,
                      border: const Border(
                        bottom: BorderSide(
                          color: AppColors.surfaceLight,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chapter.title,
                                style: TextStyle(
                                  color: isCurrent
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: isCurrent
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${chapter.start.toShortTimestamp()} — ${chapter.duration.toShortTimestamp()}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          const Icon(
                            Icons.play_arrow,
                            color: AppColors.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
