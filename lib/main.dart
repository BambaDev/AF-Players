import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/video_item.dart';
import 'data/models/playlist.dart';
import 'data/models/bookmark.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(VideoItemAdapter());
  Hive.registerAdapter(VideoSourceTypeAdapter());
  Hive.registerAdapter(PlaylistAdapter());
  Hive.registerAdapter(BookmarkAdapter());

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const AFPlayersApp());
}
