import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../data/models/video_item.dart';
import '../data/services/video_storage_service.dart';

class LibraryController extends GetxController {
  final VideoStorageService _storageService = VideoStorageService();
  final videos = <VideoItem>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _storageService.init();
    _loadVideos();
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

  Future<void> updateLastPosition(String id, Duration position) async {
    await _storageService.updateLastPosition(id, position);
    _loadVideos();
  }
}
