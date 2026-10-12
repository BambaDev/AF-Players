import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models/bookmark.dart';

class BookmarkController extends GetxController {
  late Box<Bookmark> _box;
  final bookmarks = <Bookmark>[].obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<Bookmark>('bookmarks');
    bookmarks.assignAll(_box.values.toList());
  }

  Future<Bookmark> addBookmark(String videoId, int positionMs, String note) async {
    final bookmark = Bookmark(
      id: const Uuid().v4(),
      videoId: videoId,
      positionMs: positionMs,
      note: note,
      createdAt: DateTime.now(),
    );
    await _box.put(bookmark.id, bookmark);
    bookmarks.add(bookmark);
    return bookmark;
  }

  Future<void> deleteBookmark(String id) async {
    await _box.delete(id);
    bookmarks.removeWhere((b) => b.id == id);
  }

  Future<void> updateNote(String id, String note) async {
    final bookmark = _box.get(id);
    if (bookmark != null) {
      bookmark.note = note;
      await bookmark.save();
      final index = bookmarks.indexWhere((b) => b.id == id);
      if (index >= 0) {
        bookmarks[index] = bookmark;
        bookmarks.refresh();
      }
    }
  }

  List<Bookmark> getBookmarksForVideo(String videoId) {
    final list = bookmarks.where((b) => b.videoId == videoId).toList();
    list.sort((a, b) => a.positionMs.compareTo(b.positionMs));
    return list;
  }
}
