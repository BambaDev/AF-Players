import 'dart:io';
import '../models/subtitle_entry.dart';
import '../models/subtitle_file.dart';
import '../../core/utils/duration_extensions.dart';
import '../../core/utils/string_extensions.dart';

class SubtitleParser {
  SubtitleFile parse(String content) {
    final cleaned = content.replaceAll('\r\n', '\n').replaceAll('﻿', '');
    final format = _detectFormat(cleaned);

    switch (format) {
      case SubtitleFormat.srt:
        return SubtitleFile(format: format, entries: _parseSrt(cleaned));
      case SubtitleFormat.vtt:
        return SubtitleFile(format: format, entries: _parseVtt(cleaned));
      case SubtitleFormat.unknown:
        return const SubtitleFile(format: SubtitleFormat.unknown, entries: []);
    }
  }

  Future<SubtitleFile> parseFile(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    return parse(content);
  }

  SubtitleFormat _detectFormat(String content) {
    final trimmed = content.trimLeft();
    if (trimmed.startsWith('WEBVTT')) return SubtitleFormat.vtt;
    final firstLine = trimmed.split('\n').first.trim();
    if (int.tryParse(firstLine) != null) return SubtitleFormat.srt;
    if (trimmed.contains(' --> ')) return SubtitleFormat.srt;
    return SubtitleFormat.unknown;
  }

  List<SubtitleEntry> _parseSrt(String content) {
    final entries = <SubtitleEntry>[];
    final blocks = content.split(RegExp(r'\n\n+'));

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;

      int timeLineIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains(' --> ')) {
          timeLineIndex = i;
          break;
        }
      }
      if (timeLineIndex == -1) continue;

      final index = entries.length + 1;
      final times = _parseTimeLine(lines[timeLineIndex]);
      if (times == null) continue;

      final textLines = lines.sublist(timeLineIndex + 1);
      final text = textLines.join(' ').cleanSubtitle();
      if (text.isEmpty) continue;

      entries.add(SubtitleEntry(
        index: index,
        start: times.$1,
        end: times.$2,
        text: text,
      ));
    }

    entries.sort((a, b) => a.start.compareTo(b.start));
    return entries;
  }

  List<SubtitleEntry> _parseVtt(String content) {
    final entries = <SubtitleEntry>[];
    final lines = content.split('\n');

    int i = 0;
    while (i < lines.length && !lines[i].contains(' --> ')) {
      i++;
    }

    while (i < lines.length) {
      if (!lines[i].contains(' --> ')) {
        i++;
        continue;
      }

      final times = _parseTimeLine(lines[i]);
      i++;
      if (times == null) continue;

      final textLines = <String>[];
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        textLines.add(lines[i]);
        i++;
      }

      final text = textLines.join(' ').cleanSubtitle();
      if (text.isEmpty) continue;

      entries.add(SubtitleEntry(
        index: entries.length + 1,
        start: times.$1,
        end: times.$2,
        text: text,
      ));
    }

    entries.sort((a, b) => a.start.compareTo(b.start));
    return entries;
  }

  (Duration, Duration)? _parseTimeLine(String line) {
    final arrowIndex = line.indexOf(' --> ');
    if (arrowIndex == -1) return null;

    final startStr = line.substring(0, arrowIndex).trim();
    var endStr = line.substring(arrowIndex + 5).trim();

    final spaceIndex = endStr.indexOf(' ');
    if (spaceIndex != -1) {
      endStr = endStr.substring(0, spaceIndex);
    }

    final start = startStr.toDuration();
    final end = endStr.toDuration();

    if (end <= start) return null;
    return (start, end);
  }
}
