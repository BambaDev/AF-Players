import '../models/subtitle_entry.dart';

class SmartMergedGroup {
  final Duration start;
  final Duration end;
  final String text;
  final List<int> entryIndices;
  final double suggestedSpeed;

  const SmartMergedGroup({
    required this.start,
    required this.end,
    required this.text,
    required this.entryIndices,
    required this.suggestedSpeed,
  });

  Duration get duration => end - start;
}

class SmartSubtitleMerger {
  static final _bracketTag = RegExp(r'^\[.*\]$');
  static final _sentenceEnd = RegExp(r'[.?!…]\s*$');

  static const _continuationTokens = <String>{
    'de', 'du', 'des', 'au', 'aux', 'à', 'en', 'avec', 'pour', 'par',
    'sur', 'sous', 'entre', 'vers', 'chez',
    'et', 'ou', 'mais', 'que', 'qui', 'quand', 'pendant', 'si',
    'le', 'la', 'les', 'un', 'une',
  };

  static final _endsWithElision = RegExp(
    r"(?:l|d|s|n|j|m|t|c|qu|jusqu|lorsqu|puisqu|quelqu|aujourd)'\s*$",
    caseSensitive: false,
  );

  static final _endsWithOrphan = RegExp(
    r'\b(le|la|les|un|une|des|du|au|aux|de|à|en|par|pour|sur|sous|avec|sans|dans|entre|'
    r'je|tu|il|on|me|te|se|ne|nous|vous|ils|elles|elle|'
    r'ce|cet|cette|ces|mon|ton|son|ma|ta|sa|mes|tes|ses|notre|votre|leur|leurs|'
    r'que|qui|dont|où|et|ou|mais|ni|car|si)\s*$',
    caseSensitive: false,
  );

  static const double _charsPerSec = 13.0;
  static const double _minSpeed = 1.05;
  static const double _maxSpeed = 1.40;
  static const double _minDurationSec = 3.0;
  static const double _maxMergedDurationSec = 20.0;
  static const double _maxGapForMergeSec = 2.0;
  static const double _maxGapForRepairMs = 500.0;
  static const double _tightRatioThreshold = 1.5;

  static List<SmartMergedGroup> merge(List<SubtitleEntry> entries) {
    if (entries.isEmpty) return [];

    // Filter out empty and bracket-tag entries, keep track of original indices
    final filtered = <_WorkEntry>[];
    for (final e in entries) {
      final text = e.text.trim();
      if (text.isEmpty) continue;
      if (_bracketTag.hasMatch(text)) continue;
      filtered.add(_WorkEntry(
        start: e.start,
        end: e.end,
        text: text,
        indices: [e.index],
      ));
    }

    if (filtered.isEmpty) return [];

    // Step 1: repair split sentences
    var groups = _repairSplitSentences(filtered);

    // Step 2: merge short segments
    groups = _mergeShortSegments(groups);

    // Step 3: expand tight slots
    _expandTightSlots(groups);

    // Step 4: compute suggested speed and build final result
    return groups.map((g) {
      final slotSec = g.durationSec;
      final estimatedSec = g.text.length / _charsPerSec;
      final speed = slotSec > 0 ? (estimatedSec / slotSec).clamp(_minSpeed, _maxSpeed) : _minSpeed;

      return SmartMergedGroup(
        start: g.start,
        end: g.end,
        text: g.text,
        entryIndices: List<int>.unmodifiable(g.indices),
        suggestedSpeed: speed,
      );
    }).toList();
  }

  static List<_WorkEntry> _repairSplitSentences(List<_WorkEntry> entries) {
    final result = <_WorkEntry>[];
    var i = 0;

    while (i < entries.length) {
      var current = entries[i];
      i++;

      while (i < entries.length) {
        final next = entries[i];
        final gapMs = (next.start - current.end).inMilliseconds;
        if (gapMs > _maxGapForRepairMs) break;

        final shouldMerge = _shouldRepairMerge(current.text, next.text);
        if (!shouldMerge) break;

        current = _mergeTwo(current, next);
        i++;
      }

      result.add(current);
    }

    return result;
  }

  static bool _shouldRepairMerge(String prevText, String nextText) {
    if (_endsWithElision.hasMatch(prevText)) return true;
    if (_endsWithOrphan.hasMatch(prevText)) return true;

    // Check continuation token at end of previous text
    final lastWord = _lastWordOf(prevText).toLowerCase();
    if (_continuationTokens.contains(lastWord)) {
      // Next entry starts with lowercase → mid-clause cut
      if (nextText.isNotEmpty && nextText[0] == nextText[0].toLowerCase() && nextText[0] != nextText[0].toUpperCase()) {
        return true;
      }
      // Even without lowercase check, continuation token at end is strong signal
      return true;
    }

    // Previous text doesn't end with sentence-ending punctuation
    if (!_sentenceEnd.hasMatch(prevText) && nextText.isNotEmpty &&
        nextText[0] == nextText[0].toLowerCase() && nextText[0] != nextText[0].toUpperCase()) {
      return true;
    }

    return false;
  }

  static String _lastWordOf(String text) {
    final trimmed = text.trimRight();
    if (trimmed.isEmpty) return '';
    // Strip trailing punctuation for word extraction
    final clean = trimmed.replaceAll(RegExp(r'[,;:]+$'), '');
    final parts = clean.split(RegExp(r'\s+'));
    return parts.last;
  }

  static List<_WorkEntry> _mergeShortSegments(List<_WorkEntry> entries) {
    if (entries.length <= 1) return entries;

    var changed = true;
    var groups = List<_WorkEntry>.from(entries);

    // Main pass: merge short segments (< 3s) with neighbors
    while (changed) {
      changed = false;
      final merged = <_WorkEntry>[];

      for (var i = 0; i < groups.length; i++) {
        if (merged.isEmpty) {
          merged.add(groups[i]);
          continue;
        }

        final prev = merged.last;
        final curr = groups[i];
        final gapSec = (curr.start - prev.end).inMilliseconds / 1000.0;
        final mergedDuration = (curr.end - prev.start).inMilliseconds / 1000.0;

        final prevShort = prev.durationSec < _minDurationSec;
        final currShort = curr.durationSec < _minDurationSec;

        if ((prevShort || currShort) &&
            gapSec <= _maxGapForMergeSec &&
            mergedDuration <= _maxMergedDurationSec) {
          merged[merged.length - 1] = _mergeTwo(prev, curr);
          changed = true;
        } else {
          merged.add(curr);
        }
      }

      groups = merged;
    }

    // Orphan pass: merge tiny fragments (≤5 words with terminal punctuation) into previous
    final result = <_WorkEntry>[];
    for (var i = 0; i < groups.length; i++) {
      if (result.isEmpty) {
        result.add(groups[i]);
        continue;
      }

      final curr = groups[i];
      final wordCount = curr.text.split(RegExp(r'\s+')).length;

      if (wordCount <= 5 && _sentenceEnd.hasMatch(curr.text)) {
        final prev = result.last;
        final gapSec = (curr.start - prev.end).inMilliseconds / 1000.0;
        final mergedDuration = (curr.end - prev.start).inMilliseconds / 1000.0;

        if (gapSec <= 3.0 && mergedDuration <= 25.0) {
          result[result.length - 1] = _mergeTwo(prev, curr);
          continue;
        }
      }

      result.add(curr);
    }

    return result;
  }

  static void _expandTightSlots(List<_WorkEntry> groups) {
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      final estimatedSec = g.text.length / _charsPerSec;
      final slotSec = g.durationSec;
      if (slotSec <= 0) continue;

      final ratio = estimatedSec / slotSec;
      if (ratio <= _tightRatioThreshold) continue;

      // Borrow from forward gap
      if (i + 1 < groups.length) {
        final nextStart = groups[i + 1].start;
        final gapMs = (nextStart - g.end).inMilliseconds;
        final gapSec = gapMs / 1000.0;
        if (gapSec > 0.3) {
          final stealSec = (gapSec - 0.15).clamp(0.0, 1.5);
          final stealMs = (stealSec * 1000).round();
          groups[i] = g.withEnd(g.end + Duration(milliseconds: stealMs));
        }
      }

      // Borrow from backward gap
      if (i > 0) {
        final updatedG = groups[i];
        final prevEnd = groups[i - 1].end;
        final gapMs = (updatedG.start - prevEnd).inMilliseconds;
        final gapSec = gapMs / 1000.0;
        if (gapSec > 0.3) {
          final stealSec = (gapSec - 0.15).clamp(0.0, 1.5);
          final stealMs = (stealSec * 1000).round();
          groups[i] = updatedG.withStart(updatedG.start - Duration(milliseconds: stealMs));
        }
      }
    }
  }

  static _WorkEntry _mergeTwo(_WorkEntry a, _WorkEntry b) {
    final aText = a.text;
    final bText = b.text;
    final separator = aText.endsWith("'") ? '' : ' ';

    return _WorkEntry(
      start: a.start < b.start ? a.start : b.start,
      end: a.end > b.end ? a.end : b.end,
      text: '$aText$separator$bText',
      indices: [...a.indices, ...b.indices],
    );
  }
}

class _WorkEntry {
  Duration start;
  Duration end;
  String text;
  List<int> indices;

  _WorkEntry({
    required this.start,
    required this.end,
    required this.text,
    required this.indices,
  });

  double get durationSec => (end - start).inMilliseconds / 1000.0;

  _WorkEntry withEnd(Duration newEnd) =>
      _WorkEntry(start: start, end: newEnd, text: text, indices: indices);

  _WorkEntry withStart(Duration newStart) =>
      _WorkEntry(start: newStart, end: end, text: text, indices: indices);
}
