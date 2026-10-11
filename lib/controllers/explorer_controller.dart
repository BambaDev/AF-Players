import 'dart:io';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class ExplorerController extends GetxController {
  static const _videoExtensions = {
    '.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.3gp', '.ts', '.m4v',
  };
  static const _subtitleExtensions = {'.srt', '.vtt'};
  static const _rootPath = '/storage/emulated/0';

  final currentPath = _rootPath.obs;
  final items = <FileSystemEntity>[].obs;
  final isLoading = false.obs;
  final hasPermission = false.obs;

  final List<String> _navStack = [];

  bool get isAtRoot => currentPath.value == _rootPath;

  @override
  void onInit() {
    super.onInit();
    _requestPermissionAndLoad();
  }

  Future<void> _requestPermissionAndLoad() async {
    hasPermission.value = await _checkAndRequestPermission();
    if (hasPermission.value) {
      openFolder(_rootPath);
    }
  }

  Future<bool> _checkAndRequestPermission() async {
    if (!Platform.isAndroid) return true;
    final sdkInt = int.tryParse(await _getAndroidSdkVersion()) ?? 30;
    if (sdkInt >= 33) {
      return (await Permission.videos.request()).isGranted;
    } else if (sdkInt >= 30) {
      return (await Permission.manageExternalStorage.request()).isGranted;
    } else {
      return (await Permission.storage.request()).isGranted;
    }
  }

  Future<String> _getAndroidSdkVersion() async {
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return (result.stdout as String).trim();
    } catch (_) {
      return '30';
    }
  }

  Future<void> openFolder(String path) async {
    isLoading.value = true;

    if (currentPath.value != path) {
      _navStack.add(currentPath.value);
    }
    currentPath.value = path;

    final dir = Directory(path);
    final folders = <Directory>[];
    final files = <File>[];

    try {
      await for (final entity in dir.list(followLinks: false)) {
        final name = entity.path.split('/').last;
        if (name.startsWith('.')) continue;

        if (entity is Directory) {
          folders.add(entity);
        } else if (entity is File) {
          final ext = _extensionOf(entity.path);
          if (_videoExtensions.contains(ext) || _subtitleExtensions.contains(ext)) {
            files.add(entity);
          }
        }
      }
    } catch (_) {}

    folders.sort((a, b) => a.path.split('/').last.toLowerCase()
        .compareTo(b.path.split('/').last.toLowerCase()));
    files.sort((a, b) => a.path.split('/').last.toLowerCase()
        .compareTo(b.path.split('/').last.toLowerCase()));

    items.assignAll([...folders, ...files]);
    isLoading.value = false;
  }

  void goBack() {
    if (_navStack.isEmpty) return;
    final prev = _navStack.removeLast();
    currentPath.value = prev;
    openFolder(prev);
  }

  List<String> findSubtitlesForVideo(String videoPath) {
    final videoName = _nameWithoutExtension(videoPath);
    return items
        .whereType<File>()
        .where((f) => _subtitleExtensions.contains(_extensionOf(f.path)))
        .where((f) => _nameWithoutExtension(f.path)
            .toLowerCase()
            .startsWith(videoName.toLowerCase()))
        .map((f) => f.path)
        .toList();
  }

  List<String> allSubtitlesInFolder() {
    return items
        .whereType<File>()
        .where((f) => _subtitleExtensions.contains(_extensionOf(f.path)))
        .map((f) => f.path)
        .toList();
  }

  bool isVideo(FileSystemEntity entity) {
    return entity is File && _videoExtensions.contains(_extensionOf(entity.path));
  }

  bool isSubtitle(FileSystemEntity entity) {
    return entity is File && _subtitleExtensions.contains(_extensionOf(entity.path));
  }

  String _extensionOf(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot < 0) return '';
    return path.substring(lastDot).toLowerCase();
  }

  String _nameWithoutExtension(String path) {
    final name = path.split('/').last;
    final lastDot = name.lastIndexOf('.');
    if (lastDot < 0) return name;
    return name.substring(0, lastDot);
  }

  Future<void> retryPermission() async {
    hasPermission.value = await _checkAndRequestPermission();
    if (hasPermission.value) {
      openFolder(_rootPath);
    }
  }
}
