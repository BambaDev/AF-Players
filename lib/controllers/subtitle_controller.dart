import 'package:get/get.dart';
import '../data/models/subtitle_entry.dart';
import '../data/models/subtitle_file.dart';
import '../data/services/subtitle_parser.dart';

class SubtitleController extends GetxController {
  final SubtitleParser _parser = SubtitleParser();

  final subtitleFile = Rxn<SubtitleFile>();
  final currentEntry = Rxn<SubtitleEntry>();
  final isLoaded = false.obs;

  Future<void> loadFromFile(String filePath) async {
    final file = await _parser.parseFile(filePath);
    subtitleFile.value = file;
    isLoaded.value = file.entries.isNotEmpty;
  }

  void loadFromContent(String content) {
    final file = _parser.parse(content);
    subtitleFile.value = file;
    isLoaded.value = file.entries.isNotEmpty;
  }

  void updatePosition(Duration position) {
    final file = subtitleFile.value;
    if (file == null) return;

    final entry = file.getEntryAtPosition(position);
    if (entry != currentEntry.value) {
      currentEntry.value = entry;
    }
  }

  void clear() {
    subtitleFile.value = null;
    currentEntry.value = null;
    isLoaded.value = false;
  }
}
