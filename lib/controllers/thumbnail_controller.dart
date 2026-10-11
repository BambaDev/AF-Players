import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ThumbnailController extends GetxController {
  static const _channel = MethodChannel('com.afplayers/thumbnail');
  final Map<String, String?> _cache = {};
  final _loading = <String>{};

  final thumbnails = <String, String?>{}.obs;

  Future<String?> getThumbnail(String videoPath) async {
    if (_cache.containsKey(videoPath)) return _cache[videoPath];
    if (_loading.contains(videoPath)) return null;

    _loading.add(videoPath);
    try {
      final result = await _channel.invokeMethod<String>('getThumbnail', {
        'path': videoPath,
        'width': 160,
        'height': 90,
      });
      _cache[videoPath] = result;
      thumbnails[videoPath] = result;
      return result;
    } catch (_) {
      _cache[videoPath] = null;
      return null;
    } finally {
      _loading.remove(videoPath);
    }
  }
}
