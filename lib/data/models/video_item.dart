import 'package:hive/hive.dart';

part 'video_item.g.dart';

@HiveType(typeId: 0)
enum VideoSourceType {
  @HiveField(0)
  local,
  @HiveField(1)
  remote,
}

@HiveType(typeId: 1)
class VideoItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  final String videoPath;

  @HiveField(3)
  String? subtitlePath;

  @HiveField(4)
  final VideoSourceType sourceType;

  @HiveField(5)
  final DateTime addedAt;

  @HiveField(6)
  int lastPositionMs;

  @HiveField(7)
  bool isFavorite;

  @HiveField(8)
  DateTime? lastPlayedAt;

  @HiveField(9)
  int durationMs;

  VideoItem({
    required this.id,
    required this.title,
    required this.videoPath,
    this.subtitlePath,
    required this.sourceType,
    required this.addedAt,
    this.lastPositionMs = 0,
    this.isFavorite = false,
    this.lastPlayedAt,
    this.durationMs = 0,
  });

  Duration get lastPosition => Duration(milliseconds: lastPositionMs);
  set lastPosition(Duration d) => lastPositionMs = d.inMilliseconds;

  double get progress => durationMs > 0 ? lastPositionMs / durationMs : 0.0;
}
