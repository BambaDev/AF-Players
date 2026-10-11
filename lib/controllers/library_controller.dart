import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/video_item.dart';
import '../data/services/video_storage_service.dart';

class LibraryController extends GetxController {
  final VideoStorageService _storageService = VideoStorageService();
  final videos = <VideoItem>[].obs;
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
  }

  Future<void> addVideo({
    required String title,
    required String videoPath,
    String? subtitlePath,
    required VideoSourceType sourceType,
  }) async {
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
}
