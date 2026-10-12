import 'package:get/get.dart';
import 'library_controller.dart';

class StatsController extends GetxController {
  LibraryController get _library => Get.find<LibraryController>();

  int get totalVideos => _library.videos.length;

  int get completedVideos =>
      _library.videos.where((v) => v.durationMs > 0 && v.progress > 0.9).length;

  int get totalWatchTimeMinutes =>
      _library.videos.fold<int>(0, (sum, v) => sum + v.lastPositionMs) ~/ 60000;

  int get thisWeekWatchTimeMinutes {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return _library.videos
        .where((v) => v.lastPlayedAt != null && v.lastPlayedAt!.isAfter(startOfWeek))
        .fold<int>(0, (sum, v) => sum + v.lastPositionMs) ~/ 60000;
  }

  int get streakDays {
    final dates = _library.videos
        .where((v) => v.lastPlayedAt != null)
        .map((v) => DateTime(v.lastPlayedAt!.year, v.lastPlayedAt!.month, v.lastPlayedAt!.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));

    if (dates.first != todayDate && dates.first != yesterday) return 0;

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  double get completionRate =>
      totalVideos > 0 ? completedVideos / totalVideos : 0.0;

  List<MapEntry<String, int>> get weeklyActivity {
    final now = DateTime.now();
    final days = <String>['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final result = <MapEntry<String, int>>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final minutes = _library.videos
          .where((v) =>
              v.lastPlayedAt != null &&
              v.lastPlayedAt!.isAfter(dayStart) &&
              v.lastPlayedAt!.isBefore(dayEnd))
          .fold<int>(0, (sum, v) => sum + v.lastPositionMs) ~/ 60000;
      result.add(MapEntry(days[day.weekday - 1], minutes));
    }
    return result;
  }
}
