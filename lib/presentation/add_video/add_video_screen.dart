import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/library_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/video_item.dart';
import '../../data/services/file_picker_service.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _filePickerService = FilePickerService();

  String? _localVideoPath;
  String? _localSubtitlePath;
  final _localTitleController = TextEditingController();

  final _urlVideoController = TextEditingController();
  final _urlSubtitleController = TextEditingController();
  final _urlTitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _localTitleController.dispose();
    _urlVideoController.dispose();
    _urlSubtitleController.dispose();
    _urlTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une vidéo'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.folder), text: 'Fichier local'),
            Tab(icon: Icon(Icons.link), text: 'URL distante'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLocalTab(),
          _buildUrlTab(),
        ],
      ),
    );
  }

  Widget _buildLocalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPickerButton(
            icon: Icons.video_file,
            label: _localVideoPath != null
                ? _localVideoPath!.split(RegExp(r'[/\\]')).last
                : 'Sélectionner la vidéo',
            onTap: () async {
              final path = await _filePickerService.pickVideoFile();
              if (path != null) {
                setState(() {
                  _localVideoPath = path;
                  if (_localTitleController.text.isEmpty) {
                    _localTitleController.text =
                        path.split(RegExp(r'[/\\]')).last.replaceAll(RegExp(r'\.[^.]+$'), '');
                  }
                });
              }
            },
            isSelected: _localVideoPath != null,
          ),
          const SizedBox(height: 16),
          _buildPickerButton(
            icon: Icons.subtitles,
            label: _localSubtitlePath != null
                ? _localSubtitlePath!.split(RegExp(r'[/\\]')).last
                : 'Sélectionner les sous-titres',
            onTap: () async {
              final path = await _filePickerService.pickSubtitleFile();
              if (path != null) setState(() => _localSubtitlePath = path);
            },
            isSelected: _localSubtitlePath != null,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _localTitleController,
            decoration: InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surfaceLight,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _localVideoPath != null ? _saveLocal : null,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _urlVideoController,
            decoration: InputDecoration(
              labelText: 'URL de la vidéo',
              hintText: 'https://...',
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surfaceLight,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlSubtitleController,
            decoration: InputDecoration(
              labelText: 'URL des sous-titres (optionnel)',
              hintText: 'https://... ou vide',
              prefixIcon: const Icon(Icons.subtitles),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surfaceLight,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () async {
              final path = await _filePickerService.pickSubtitleFile();
              if (path != null) {
                _urlSubtitleController.text = path;
              }
            },
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('Ou choisir un fichier local'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlTitleController,
            decoration: InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppColors.surfaceLight,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _urlVideoController.text.isNotEmpty ? _saveUrl : null,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceLight,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          ],
        ),
      ),
    );
  }

  void _saveLocal() {
    final title = _localTitleController.text.trim().isEmpty
        ? _localVideoPath!.split(RegExp(r'[/\\]')).last
        : _localTitleController.text.trim();

    Get.find<LibraryController>().addVideo(
      title: title,
      videoPath: _localVideoPath!,
      subtitlePath: _localSubtitlePath,
      sourceType: VideoSourceType.local,
    );
    Get.back();
    Get.snackbar('Ajoutée', '$title a été ajoutée à la bibliothèque',
        snackPosition: SnackPosition.BOTTOM);
  }

  void _saveUrl() {
    final title = _urlTitleController.text.trim().isEmpty
        ? 'Vidéo en ligne'
        : _urlTitleController.text.trim();

    final subtitlePath = _urlSubtitleController.text.trim().isEmpty
        ? null
        : _urlSubtitleController.text.trim();

    Get.find<LibraryController>().addVideo(
      title: title,
      videoPath: _urlVideoController.text.trim(),
      subtitlePath: subtitlePath,
      sourceType: VideoSourceType.remote,
    );
    Get.back();
    Get.snackbar('Ajoutée', '$title a été ajoutée à la bibliothèque',
        snackPosition: SnackPosition.BOTTOM);
  }
}
