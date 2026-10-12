import 'dart:async';
import 'package:get/get.dart';
import '../data/services/subtitle_parser.dart';
import 'library_controller.dart';

class SubtitleSearchResult {
  final String videoId;
  final String videoTitle;
  final String videoPath;
  final String? subtitlePath;
  final String matchedText;
  final int positionMs;

  SubtitleSearchResult({
    required this.videoId,
    required this.videoTitle,
    required this.videoPath,
    this.subtitlePath,
    required this.matchedText,
    required this.positionMs,
  });
}

class SubtitleSearchController extends GetxController {
  final query = ''.obs;
  final results = <SubtitleSearchResult>[].obs;
  final isSearching = false.obs;

  final _parser = SubtitleParser();
  Timer? _debounce;

  void onQueryChanged(String value) {
    query.value = value;
    _debounce?.cancel();
    if (value.trim().length < 2) {
      results.clear();
      isSearching.value = false;
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => search(value));
  }

  Future<void> search(String searchQuery) async {
    final q = searchQuery.trim().toLowerCase();
    if (q.length < 2) {
      results.clear();
      return;
    }

    isSearching.value = true;
    final library = Get.find<LibraryController>();
    final found = <SubtitleSearchResult>[];

    final videosWithSubs = library.videos
        .where((v) => v.subtitlePath != null && v.subtitlePath!.isNotEmpty);

    for (final video in videosWithSubs) {
      try {
        final subFile = await _parser.parseFile(video.subtitlePath!);
        for (final entry in subFile.entries) {
          if (entry.text.toLowerCase().contains(q)) {
            found.add(SubtitleSearchResult(
              videoId: video.id,
              videoTitle: video.title,
              videoPath: video.videoPath,
              subtitlePath: video.subtitlePath,
              matchedText: entry.text,
              positionMs: entry.start.inMilliseconds,
            ));
          }
        }
      } catch (_) {}
    }

    results.assignAll(found);
    isSearching.value = false;
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
