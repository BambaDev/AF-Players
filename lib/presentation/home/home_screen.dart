import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../explorer/explorer_screen.dart';
import 'recents_tab.dart';
import 'favorites_tab.dart';
import 'playlists_tab.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/explorer_controller.dart';
import '../settings/settings_screen.dart';
import '../youtube/youtube_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    ExplorerTab(),
    RecentsTab(),
    FavoritesTab(),
    PlaylistsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (_currentIndex != 0) {
            setState(() => _currentIndex = 0);
          } else {
            final explorer = Get.find<ExplorerController>();
            if (explorer.isAtRoot) {
              SystemNavigator.pop();
            } else {
              explorer.goBack();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text(
            'AF Players',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textPrimary),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.smart_display, color: AppColors.primary),
              tooltip: 'YouTube',
              onPressed: () => Get.to(() => const YouTubeScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.settings, color: AppColors.textSecondary),
              onPressed: () => Get.to(() => const SettingsScreen()),
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Explorateur'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Récents'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoris'),
            BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'Playlists'),
          ],
        ),
      ),
    );
  }
}
