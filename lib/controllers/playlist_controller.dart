import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/playlist.dart';

class PlaylistController extends GetxController {
  static const String _boxName = 'playlists';
  late Box<Playlist> _box;
  final playlists = <Playlist>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<Playlist>(_boxName);
    _load();
    isLoading.value = false;
  }

  void _load() {
    playlists.assignAll(
      _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  Future<Playlist> create(String name) async {
    final playlist = Playlist(
      id: const Uuid().v4(),
      name: name,
      videoPaths: [],
      createdAt: DateTime.now(),
    );
    await _box.put(playlist.id, playlist);
    _load();
    return playlist;
  }

  Future<void> rename(String id, String name) async {
    final p = _box.get(id);
    if (p != null) {
      p.name = name;
      await p.save();
      _load();
    }
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _load();
  }

  Future<void> addVideo(String playlistId, String videoPath) async {
    final p = _box.get(playlistId);
    if (p != null && !p.videoPaths.contains(videoPath)) {
      p.videoPaths.add(videoPath);
      await p.save();
      _load();
    }
  }

  Future<void> removeVideo(String playlistId, String videoPath) async {
    final p = _box.get(playlistId);
    if (p != null) {
      p.videoPaths.remove(videoPath);
      await p.save();
      _load();
    }
  }
}
