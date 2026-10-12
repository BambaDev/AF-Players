import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/stats_controller.dart';
import '../../controllers/library_controller.dart';
import '../../core/constants/app_colors.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = Get.find<StatsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Statistiques', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Obx(() {
        Get.find<LibraryController>().videos.length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCards(stats),
            const SizedBox(height: 24),
            _buildCompletionRing(stats),
            const SizedBox(height: 24),
            _buildWeeklyChart(stats),
          ],
        );
      }),
    );
  }

  Widget _buildStatCards(StatsController stats) {
    return Row(
      children: [
        Expanded(child: _statCard(
          icon: Icons.timer,
          value: _formatTime(stats.totalWatchTimeMinutes),
          label: 'Temps total',
          color: AppColors.primary,
        )),
        const SizedBox(width: 12),
        Expanded(child: _statCard(
          icon: Icons.check_circle,
          value: '${stats.completedVideos}',
          label: 'Terminées',
          color: AppColors.accent,
        )),
        const SizedBox(width: 12),
        Expanded(child: _statCard(
          icon: Icons.local_fire_department,
          value: '${stats.streakDays}j',
          label: 'Streak',
          color: Colors.orangeAccent,
        )),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRing(StatsController stats) {
    final rate = stats.completionRate;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'Taux de complétion',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: rate,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
                Text(
                  '${(rate * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${stats.completedVideos} / ${stats.totalVideos} vidéos',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Cette semaine: ${_formatTime(stats.thisWeekWatchTimeMinutes)}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(StatsController stats) {
    final activity = stats.weeklyActivity;
    final maxMinutes = activity.fold<int>(0, (m, e) => max(m, e.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activité des 7 derniers jours',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: activity.map((entry) {
                final fraction = maxMinutes > 0 ? entry.value / maxMinutes : 0.0;
                final barHeight = max(4.0, fraction * 100);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (entry.value > 0)
                          Text(
                            '${entry.value}m',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: entry.value > 0
                                ? AppColors.primary
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h${m.toString().padLeft(2, '0')}' : '${h}h';
  }
}
