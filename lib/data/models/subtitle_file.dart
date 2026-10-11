import 'subtitle_entry.dart';

enum SubtitleFormat { srt, vtt, unknown }

class SubtitleFile {
  final SubtitleFormat format;
  final List<SubtitleEntry> entries;

  const SubtitleFile({required this.format, required this.entries});

  SubtitleEntry? getEntryAtPosition(Duration position) {
    if (entries.isEmpty) return null;

    int low = 0;
    int high = entries.length - 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final entry = entries[mid];

      if (entry.containsPosition(position)) return entry;
      if (position < entry.start) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    return null;
  }

  SubtitleEntry? getNextEntry(Duration position) {
    for (final entry in entries) {
      if (entry.start > position) return entry;
    }
    return null;
  }

  bool get isEmpty => entries.isEmpty;
  int get length => entries.length;
}
