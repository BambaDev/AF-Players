import 'dart:io';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class FolderItem {
  final String path;
  final String name;
  final int videoCount;
  final DateTime lastModified;

  FolderItem({
    required this.path,
    required this.name,
    required this.videoCount,
    required this.lastModified,
  });
}

class VideoFileItem {
  final String path;
  final String name;
  final int size;
  final DateTime lastModified;

  VideoFileItem({
    required this.path,
    required this.name,
    required this.size,
    required this.lastModified,
  });

  String get sizeLabel {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class ExplorerController extends GetxController {
  static const _videoExtensions = {
    '.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.3gp', '.ts', '.m4v',
  };
  static const _subtitleExtensions = {'.srt', '.vtt'};

  final currentPath = ''.obs;
  final folders = <FolderItem>[].obs;
  final videoFiles = <VideoFileItem>[].obs;
  final subtitleFiles = <String>[].obs;
  final isLoading = true.obs;
  final hasPermission = false.obs;
  final isAtRoot = true.obs;

  final List<String> _navStack = [];

  static const _rootPath = '/storage/emulated/0';
  static const _maxScanDepth = 3;
  static const _ignoredDirs = {
    'Android', '.thumbnails', '.cache', '.trash', '.Trash',
    'node_modules', '.git', 'lost+found',
  };

  @override
  void onInit() {
    super.onInit();
    _requestPermissionAndLoad();
  }

  Future<void> _requestPermissionAndLoad() async {
    hasPermission.value = await _checkAndRequestPermission();
    if (hasPermission.value) {
      await loadRootFolders();
    }
    isLoading.value = false;
  }

  Future<bool> _checkAndRequestPermission() async {
    if (Platform.isAndroid) {
      final sdkInt = int.tryParse(
        await _getAndroidSdkVersion(),
      ) ?? 30;

      if (sdkInt >= 33) {
        final status = await Permission.videos.request();
        return status.isGranted;
      } else if (sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }

  Future<String> _getAndroidSdkVersion() async {
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return (result.stdout as String).trim();
    } catch (_) {
      return '30';
    }
  }

  Future<void> loadRootFolders() async {
    isLoading.value = true;
    currentPath.value = '';
    isAtRoot.value = true;
    _navStack.clear();
    folders.clear();
    videoFiles.clear();
    subtitleFiles.clear();

    final rootDir = Directory(_rootPath);
    if (!await rootDir.exists()) {
      isLoading.value = false;
      return;
    }

    final folderMap = <String, List<FileSystemEntity>>{};

    await _scanForVideos(rootDir, 0, folderMap);

    final result = <FolderItem>[];
    for (final entry in folderMap.entries) {
      final dir = Directory(entry.key);
      DateTime lastMod;
      try {
        lastMod = await dir.stat().then((s) => s.modified);
      } catch (_) {
        lastMod = DateTime(2000);
      }
      result.add(FolderItem(
        path: entry.key,
        name: entry.key.split('/').last,
        videoCount: entry.value.length,
        lastModified: lastMod,
      ));
    }

    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    folders.assignAll(result);
    isLoading.value = false;
  }

  Future<void> _scanForVideos(
    Directory dir,
    int depth,
    Map<String, List<FileSystemEntity>> folderMap,
  ) async {
    if (depth > _maxScanDepth) return;

    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          final ext = _extensionOf(entity.path);
          if (_videoExtensions.contains(ext)) {
            final parent = entity.parent.path;
            folderMap.putIfAbsent(parent, () => []).add(entity);
          }
        } else if (entity is Directory) {
          final dirName = entity.path.split('/').last;
          if (dirName.startsWith('.') || _ignoredDirs.contains(dirName)) {
            continue;
          }
          await _scanForVideos(entity, depth + 1, folderMap);
        }
      }
    } catch (_) {}
  }

  Future<void> openFolder(String path) async {
    isLoading.value = true;

    if (currentPath.value.isNotEmpty) {
      _navStack.add(currentPath.value);
    } else {
      _navStack.add('');
    }

    currentPath.value = path;
    isAtRoot.value = false;

    final dir = Directory(path);
    final subFolders = <FolderItem>[];
    final videos = <VideoFileItem>[];
    final subs = <String>[];

    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          final ext = _extensionOf(entity.path);
          if (_videoExtensions.contains(ext)) {
            final stat = await entity.stat();
            videos.add(VideoFileItem(
              path: entity.path,
              name: entity.path.split('/').last,
              size: stat.size,
              lastModified: stat.modified,
            ));
          } else if (_subtitleExtensions.contains(ext)) {
            subs.add(entity.path);
          }
        } else if (entity is Directory) {
          final dirName = entity.path.split('/').last;
          if (dirName.startsWith('.') || _ignoredDirs.contains(dirName)) {
            continue;
          }
          final count = await _countVideosIn(entity);
          if (count > 0) {
            DateTime lastMod;
            try {
              lastMod = await entity.stat().then((s) => s.modified);
            } catch (_) {
              lastMod = DateTime(2000);
            }
            subFolders.add(FolderItem(
              path: entity.path,
              name: dirName,
              videoCount: count,
              lastModified: lastMod,
            ));
          }
        }
      }
    } catch (_) {}

    subFolders.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    videos.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    folders.assignAll(subFolders);
    videoFiles.assignAll(videos);
    subtitleFiles.assignAll(subs);
    isLoading.value = false;
  }

  Future<int> _countVideosIn(Directory dir) async {
    var count = 0;
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is File) {
          final ext = _extensionOf(entity.path);
          if (_videoExtensions.contains(ext)) count++;
        }
      }
    } catch (_) {}
    return count;
  }

  void goBack() {
    if (_navStack.isEmpty) {
      goToRoot();
      return;
    }
    final prev = _navStack.removeLast();
    if (prev.isEmpty) {
      loadRootFolders();
    } else {
      _navStack.removeLast();
      openFolder(prev);
    }
  }

  void goToRoot() {
    loadRootFolders();
  }

  List<String> findSubtitlesForVideo(String videoPath) {
    final videoName = _nameWithoutExtension(videoPath);
    final videoDir = videoPath.substring(0, videoPath.lastIndexOf('/'));

    return subtitleFiles.where((subPath) {
      final subDir = subPath.substring(0, subPath.lastIndexOf('/'));
      if (subDir != videoDir) return false;
      final subName = _nameWithoutExtension(subPath);
      return subName.toLowerCase().startsWith(videoName.toLowerCase());
    }).toList();
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
      await loadRootFolders();
    }
  }
}
