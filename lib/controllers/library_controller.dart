import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/video_item.dart';
import '../data/services/video_storage_service.dart';

class LibraryController extends GetxController {
  final VideoStorageService _storageService = VideoStorageService();
  final videos = <VideoItem>[].obs;
  final recents = <VideoItem>[].obs;
  final favorites = <VideoItem>[].obs;
  final isLoading = true.obs;
  final lastPlayedId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _storageService.init();
    _loadVideos();
    final prefs = await SharedPreferences.getInstance();
    lastPlayedId.value = prefs.getString('last_played_id') ?? '';
    isLoading.value = false;
  }

  void _loadVideos() {
    videos.assignAll(_storageService.getAll());
    recents.assignAll(_storageService.getRecents());
    favorites.assignAll(_storageService.getFavorites());
  }

  Future<void> addVideo({
    required String title,
    required String videoPath,
    String? subtitlePath,
    required VideoSourceType sourceType,
  }) async {
    if (findByPath(videoPath) != null) return;
    final video = VideoItem(
      id: const Uuid().v4(),
      title: title,
      videoPath: videoPath,
      subtitlePath: subtitlePath,
      sourceType: sourceType,
      addedAt: DateTime.now(),
    );
    await _storageService.add(video);
    _loadVideos();
  }

  Future<void> deleteVideo(String id) async {
    await _storageService.delete(id);
    _loadVideos();
  }

  VideoItem? get lastPlayed {
    if (lastPlayedId.value.isEmpty) return null;
    try {
      return videos.firstWhere((v) => v.id == lastPlayedId.value);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateLastPosition(String id, Duration position) async {
    await _storageService.updateLastPosition(id, position);
    lastPlayedId.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_played_id', id);
    _loadVideos();
  }

  Future<void> toggleFavorite(String id) async {
    await _storageService.toggleFavorite(id);
    _loadVideos();
  }

  Future<void> updateDuration(String id, int durationMs) async {
    await _storageService.updateDuration(id, durationMs);
  }

  Future<void> updateSubtitlePath(String videoId, String? subtitlePath) async {
    await _storageService.updateSubtitlePath(videoId, subtitlePath);
    _loadVideos();
  }

  VideoItem? findByPath(String videoPath) {
    try {
      return videos.firstWhere((v) => v.videoPath == videoPath);
    } catch (_) {
      return null;
    }
  }
}
