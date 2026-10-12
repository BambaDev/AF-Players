import '../models/subtitle_entry.dart';

class Chapter {
  final String title;
  final Duration start;
  final Duration end;
  final int subtitleStartIndex;

  const Chapter({
    required this.title,
    required this.start,
    required this.end,
    required this.subtitleStartIndex,
  });

  Duration get duration => end - start;
}

class ChapterDetector {
  static const _gapThreshold = Duration(seconds: 5);
  static const _segmentDuration = Duration(minutes: 10);

  static List<Chapter> detectChapters(
    List<SubtitleEntry> subtitles,
    Duration videoDuration,
  ) {
    if (subtitles.isEmpty || videoDuration <= Duration.zero) {
      return [
        Chapter(
          title: 'Début',
          start: Duration.zero,
          end: videoDuration,
          subtitleStartIndex: 0,
        ),
      ];
    }

    final breakpoints = <_Breakpoint>[];
    breakpoints.add(_Breakpoint(index: 0, start: Duration.zero));

    for (var i = 1; i < subtitles.length; i++) {
      final prevEnd = subtitles[i - 1].end;
      final currStart = subtitles[i].start;
      final gap = currStart - prevEnd;

      if (gap >= _gapThreshold) {
        breakpoints.add(_Breakpoint(index: i, start: currStart));
      }
    }

    if (breakpoints.length < 2) {
      return _splitByDuration(videoDuration, subtitles);
    }

    final chapters = <Chapter>[];
    for (var i = 0; i < breakpoints.length; i++) {
      final bp = breakpoints[i];
      final end = i + 1 < breakpoints.length
          ? breakpoints[i + 1].start
          : videoDuration;

      final title = _extractTitle(subtitles[bp.index].text, i + 1);

      chapters.add(Chapter(
        title: title,
        start: bp.start,
        end: end,
        subtitleStartIndex: bp.index,
      ));
    }

    return chapters;
  }

  static List<Chapter> _splitByDuration(
    Duration videoDuration,
    List<SubtitleEntry> subtitles,
  ) {
    final chapters = <Chapter>[];
    final segmentMs = _segmentDuration.inMilliseconds;
    final totalMs = videoDuration.inMilliseconds;
    final count = (totalMs / segmentMs).ceil().clamp(1, 100);

    for (var i = 0; i < count; i++) {
      final start = Duration(milliseconds: i * segmentMs);
      final end = Duration(
        milliseconds: ((i + 1) * segmentMs).clamp(0, totalMs),
      );

      final subIdx = subtitles.indexWhere((s) => s.start >= start);
      final title = subIdx >= 0
          ? _extractTitle(subtitles[subIdx].text, i + 1)
          : 'Partie ${i + 1}';

      chapters.add(Chapter(
        title: title,
        start: start,
        end: end,
        subtitleStartIndex: subIdx >= 0 ? subIdx : 0,
      ));
    }

    return chapters;
  }

  static String _extractTitle(String text, int chapterNumber) {
    final cleaned = text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isEmpty) return 'Chapitre $chapterNumber';
    if (cleaned.length <= 60) return cleaned;
    return '${cleaned.substring(0, 57)}...';
  }
}

class _Breakpoint {
  final int index;
  final Duration start;
  const _Breakpoint({required this.index, required this.start});
}
