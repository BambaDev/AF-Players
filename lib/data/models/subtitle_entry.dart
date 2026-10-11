class SubtitleEntry {
  final int index;
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleEntry({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
  });

  Duration get duration => end - start;

  bool containsPosition(Duration position) =>
      position >= start && position < end;

  @override
  String toString() => 'SubtitleEntry($index: $start -> $end: "$text")';
}
