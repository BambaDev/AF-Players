import 'package:hive_flutter/hive_flutter.dart';
import '../models/video_item.dart';

class VideoStorageService {
  static const String _boxName = 'videos';
  late Box<VideoItem> _box;

  Future<void> init() async {
    _box = await Hive.openBox<VideoItem>(_boxName);
  }

  List<VideoItem> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  Future<void> add(VideoItem video) async {
    await _box.put(video.id, video);
  }

  Future<void> update(VideoItem video) async {
    await video.save();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  VideoItem? getById(String id) {
    return _box.get(id);
  }

  Future<void> updateLastPosition(String id, Duration position) async {
    final video = _box.get(id);
    if (video != null) {
      video.lastPositionMs = position.inMilliseconds;
      video.lastPlayedAt = DateTime.now();
      await video.save();
    }
  }

  Future<void> toggleFavorite(String id) async {
    final video = _box.get(id);
    if (video != null) {
      video.isFavorite = !video.isFavorite;
      await video.save();
    }
  }

  Future<void> updateDuration(String id, int durationMs) async {
    final video = _box.get(id);
    if (video != null && video.durationMs == 0) {
      video.durationMs = durationMs;
      await video.save();
    }
  }

  List<VideoItem> getRecents() {
    return _box.values
        .where((v) => v.lastPlayedAt != null && v.lastPositionMs > 0)
        .toList()
      ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!));
  }

  List<VideoItem> getFavorites() {
    return _box.values.where((v) => v.isFavorite).toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }
}
