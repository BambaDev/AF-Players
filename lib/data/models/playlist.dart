import 'package:hive/hive.dart';

part 'playlist.g.dart';

@HiveType(typeId: 2)
class Playlist extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> videoPaths;

  @HiveField(3)
  final DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    required this.videoPaths,
    required this.createdAt,
  });

  int get videoCount => videoPaths.length;
}
