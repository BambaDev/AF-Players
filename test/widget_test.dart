import 'package:flutter_test/flutter_test.dart';
import 'package:af_players/data/services/subtitle_parser.dart';
import 'package:af_players/data/models/subtitle_file.dart';

void main() {
  group('SubtitleParser', () {
    final parser = SubtitleParser();

    test('parses SRT format correctly', () {
      const srt = '''1
00:00:01,000 --> 00:00:04,000
Bienvenue dans cette formation.

2
00:00:05,500 --> 00:00:08,200
Aujourd'hui, nous allons apprendre les bases.
''';

      final result = parser.parse(srt);
      expect(result.format, SubtitleFormat.srt);
      expect(result.entries.length, 2);
      expect(result.entries[0].text, 'Bienvenue dans cette formation.');
      expect(result.entries[0].start, const Duration(seconds: 1));
      expect(result.entries[0].end, const Duration(seconds: 4));
      expect(result.entries[1].text, "Aujourd'hui, nous allons apprendre les bases.");
    });

    test('parses VTT format correctly', () {
      const vtt = '''WEBVTT

00:00:01.000 --> 00:00:04.000
Bienvenue dans cette formation.

00:00:05.500 --> 00:00:08.200
Aujourd'hui, nous allons apprendre les bases.
''';

      final result = parser.parse(vtt);
      expect(result.format, SubtitleFormat.vtt);
      expect(result.entries.length, 2);
      expect(result.entries[0].text, 'Bienvenue dans cette formation.');
    });

    test('strips HTML tags from subtitles', () {
      const srt = '''1
00:00:01,000 --> 00:00:04,000
<b>Texte en gras</b> et <i>italique</i>
''';

      final result = parser.parse(srt);
      expect(result.entries[0].text, 'Texte en gras et italique');
    });

    test('binary search finds correct entry', () {
      const srt = '''1
00:00:01,000 --> 00:00:04,000
Premier

2
00:00:05,000 --> 00:00:08,000
Deuxième

3
00:00:10,000 --> 00:00:13,000
Troisième
''';

      final result = parser.parse(srt);
      final entry = result.getEntryAtPosition(const Duration(seconds: 6));
      expect(entry?.text, 'Deuxième');

      final noEntry = result.getEntryAtPosition(const Duration(seconds: 9));
      expect(noEntry, isNull);
    });
  });
}
