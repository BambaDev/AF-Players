import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/library_controller.dart';
import '../add_video/add_video_screen.dart';
import '../settings/settings_screen.dart';
import 'widgets/video_tile.dart';
import 'widgets/empty_library.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LibraryController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AF Players'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => const SettingsScreen()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.videos.isEmpty) {
          return const EmptyLibrary();
        }
        return Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: controller.videos.length,
            itemBuilder: (context, index) {
              return VideoTile(video: controller.videos[index]);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddVideoScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
}
