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
      await video.save();
    }
  }
}
