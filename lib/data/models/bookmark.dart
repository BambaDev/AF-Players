import 'package:hive/hive.dart';

part 'bookmark.g.dart';

@HiveType(typeId: 3)
class Bookmark extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String videoId;

  @HiveField(2)
  final int positionMs;

  @HiveField(3)
  String note;

  @HiveField(4)
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.videoId,
    required this.positionMs,
    required this.note,
    required this.createdAt,
  });
}
