import '../models/subtitle_entry.dart';

class MergedSubtitleGroup {
  final Duration start;
  final Duration end;
  final String text;
  final List<int> entryIndices;

  const MergedSubtitleGroup({
    required this.start,
    required this.end,
    required this.text,
    required this.entryIndices,
  });
}

class SubtitleMerger {
  static final _bracketTag = RegExp(r'^\[.*\]$');
  static final _sentenceEnd = RegExp(r'[.?!…]\s*$');
  static final _endsWithElision = RegExp(r"(?:l|d|s|n|j|m|t|c|qu|jusqu|lorsqu|puisqu|quelqu|aujourd)'\s*$", caseSensitive: false);
  static final _endsWithOrphan = RegExp(
    r'\b(le|la|les|un|une|des|du|au|aux|de|à|en|par|pour|sur|sous|avec|sans|dans|entre|'
    r'je|tu|il|on|me|te|se|ne|nous|vous|ils|elles|elle|'
    r'ce|cet|cette|ces|mon|ton|son|ma|ta|sa|mes|tes|ses|notre|votre|leur|leurs|'
    r'que|qui|dont|où|et|ou|mais|ni|car|si)\s*$',
    caseSensitive: false,
  );

  static List<MergedSubtitleGroup> merge(
    List<SubtitleEntry> entries, {
    int maxGapMs = 200,
    int maxGroupSize = 8,
  }) {
    if (entries.isEmpty) return [];

    final groups = <MergedSubtitleGroup>[];
    final buffer = StringBuffer();
    final indices = <int>[];
    Duration? groupStart;
    Duration? groupEnd;

    void flushGroup() {
      if (buffer.isEmpty || indices.isEmpty) return;
      groups.add(MergedSubtitleGroup(
        start: groupStart!,
        end: groupEnd!,
        text: buffer.toString().trim(),
        entryIndices: List.unmodifiable(indices),
      ));
      buffer.clear();
      indices.clear();
      groupStart = null;
      groupEnd = null;
    }

    for (final entry in entries) {
      final text = entry.text.trim();
      if (text.isEmpty) continue;

      if (_bracketTag.hasMatch(text)) {
        flushGroup();
        continue;
      }

      final gap = groupEnd != null
          ? (entry.start - groupEnd!).inMilliseconds
          : 0;

      final currentText = buffer.toString().trim();
      final forceJoin = _endsWithElision.hasMatch(currentText) ||
          _endsWithOrphan.hasMatch(currentText);
      final shouldMerge = groupStart != null &&
          indices.length < maxGroupSize &&
          (forceJoin || (gap <= maxGapMs && !_sentenceEnd.hasMatch(currentText)));

      if (shouldMerge) {
        final current = buffer.toString();
        if (!current.endsWith("'")) {
          buffer.write(' ');
        }
        buffer.write(text);
        indices.add(entry.index);
        groupEnd = entry.end;
      } else {
        flushGroup();
        buffer.write(text);
        indices.add(entry.index);
        groupStart = entry.start;
        groupEnd = entry.end;
      }
    }

    flushGroup();
    return groups;
  }
}
