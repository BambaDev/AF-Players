import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/native_tts_controller.dart';
import '../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final ttsController = Get.find<NativeTtsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Parametres')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Voix francaise'),
          const SizedBox(height: 8),

          Obx(() {
            final voices = ttsController.availableVoices;
            if (voices.isEmpty) {
              return const Card(
                child: ListTile(
                  leading: Icon(Icons.voice_over_off),
                  title: Text('Aucune voix francaise trouvee'),
                  subtitle: Text('Installez Google TTS depuis le Play Store'),
                ),
              );
            }
            return Card(
              child: ListTile(
                leading: const Icon(Icons.record_voice_over, color: AppColors.accent),
                title: const Text('Voix'),
                subtitle: Text(settings.ttsSettings.value.voiceName ?? 'Par defaut'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showVoicePicker(context, ttsController, settings),
              ),
            );
          }),

          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vitesse de la voix', style: TextStyle(fontWeight: FontWeight.w600)),
                  Obx(() => Row(
                    children: [
                      const Text('x0.5', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Expanded(
                        child: Slider(
                          value: settings.ttsSettings.value.speechRate,
                          min: 0.5,
                          max: 2.0,
                          divisions: 6,
                          label: 'x${settings.ttsSettings.value.speechRate.toStringAsFixed(2)}',
                          onChanged: (value) {
                            settings.updateTtsRate(value);
                            ttsController.setSpeed(value);
                          },
                        ),
                      ),
                      const Text('x2.0', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tonalite', style: TextStyle(fontWeight: FontWeight.w600)),
                  Obx(() => Slider(
                    value: settings.ttsSettings.value.pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: settings.ttsSettings.value.pitch.toStringAsFixed(2),
                    onChanged: (value) {
                      settings.updateTtsPitch(value);
                      ttsController.setPitch(value);
                    },
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          ElevatedButton.icon(
            onPressed: () => ttsController.speak('Bienvenue dans cette formation. Aujourd\'hui nous allons apprendre les bases.'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Tester la voix'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Sous-titres'),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Taille du texte', style: TextStyle(fontWeight: FontWeight.w600)),
                  Obx(() => Slider(
                    value: settings.subtitleFontSize.value,
                    min: 12,
                    max: 32,
                    divisions: 10,
                    label: '${settings.subtitleFontSize.value.round()}',
                    onChanged: settings.updateSubtitleFontSize,
                  )),
                  Obx(() => Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(settings.subtitleBgColor.value),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Apercu du sous-titre',
                        style: TextStyle(
                          color: Color(settings.subtitleColor.value),
                          fontSize: settings.subtitleFontSize.value,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Couleur du texte', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Obx(() => Row(
                    children: [
                      _colorCircle(settings, 0xFFFFFFFF, 'Blanc', isText: true),
                      const SizedBox(width: 12),
                      _colorCircle(settings, 0xFFFFFF00, 'Jaune', isText: true),
                      const SizedBox(width: 12),
                      _colorCircle(settings, 0xFF00FF00, 'Vert', isText: true),
                      const SizedBox(width: 12),
                      _colorCircle(settings, 0xFF00FFFF, 'Cyan', isText: true),
                    ],
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fond des sous-titres', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Obx(() => Row(
                    children: [
                      _colorCircle(settings, 0x00000000, 'Transparent', isText: false),
                      const SizedBox(width: 12),
                      _colorCircle(settings, 0x80000000, 'Léger', isText: false),
                      const SizedBox(width: 12),
                      _colorCircle(settings, 0xCC000000, 'Normal', isText: false),
                      const SizedBox(width: 12),
                      _colorCircle(settings, 0xFF000000, 'Opaque', isText: false),
                    ],
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Card(
            child: Obx(() => ListTile(
              leading: Icon(
                settings.subtitlePosition.value == 0 ? Icons.vertical_align_bottom : Icons.vertical_align_top,
                color: AppColors.primary,
              ),
              title: const Text('Position des sous-titres'),
              subtitle: Text(settings.subtitlePosition.value == 0 ? 'En bas' : 'En haut'),
              trailing: ToggleButtons(
                isSelected: [
                  settings.subtitlePosition.value == 0,
                  settings.subtitlePosition.value == 1,
                ],
                onPressed: (index) => settings.updateSubtitlePosition(index),
                borderRadius: BorderRadius.circular(8),
                selectedColor: AppColors.primary,
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Bas')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Haut')),
                ],
              ),
            )),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Lecture'),
          const SizedBox(height: 8),

          Card(
            child: Obx(() => ListTile(
              leading: const Icon(Icons.fast_forward, color: AppColors.primary),
              title: const Text('Avance/Recul rapide'),
              subtitle: Text('${settings.seekDuration.value} secondes'),
              trailing: ToggleButtons(
                isSelected: [
                  settings.seekDuration.value == 5,
                  settings.seekDuration.value == 10,
                  settings.seekDuration.value == 15,
                ],
                onPressed: (index) {
                  final values = [5, 10, 15];
                  settings.updateSeekDuration(values[index]);
                },
                borderRadius: BorderRadius.circular(8),
                selectedColor: AppColors.primary,
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('5s')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('10s')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('15s')),
                ],
              ),
            )),
          ),

          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mode de lecture vocale', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Obx(() => Column(
                    children: [
                      _syncModeOption(
                        settings,
                        mode: 0,
                        icon: Icons.queue_music,
                        title: 'File d\'attente',
                        subtitle: 'Termine chaque phrase, enchaîne la suivante. La vidéo continue normalement.',
                      ),
                      const SizedBox(height: 8),
                      _syncModeOption(
                        settings,
                        mode: 1,
                        icon: Icons.pause_circle_outline,
                        title: 'File + pause auto',
                        subtitle: 'Termine la phrase, pause la vidéo si retard, reprend automatiquement.',
                      ),
                      const SizedBox(height: 8),
                      _syncModeOption(
                        settings,
                        mode: 2,
                        icon: Icons.speed,
                        title: 'File + vitesse auto',
                        subtitle: 'Termine la phrase, accélère la voix si retard, revient à la normale.',
                      ),
                    ],
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _sectionTitle('Apparence'),
          const SizedBox(height: 8),

          Card(
            child: Obx(() => SwitchListTile(
              secondary: Icon(
                settings.isDarkMode.value ? Icons.dark_mode : Icons.light_mode,
                color: AppColors.primary,
              ),
              title: const Text('Thème sombre'),
              value: settings.isDarkMode.value,
              onChanged: (value) => settings.updateDarkMode(value),
              activeTrackColor: AppColors.primary,
            )),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _syncModeOption(
    SettingsController settings, {
    required int mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = settings.ttsSyncMode.value == mode;
    return InkWell(
      onTap: () => settings.updateTtsSyncMode(mode),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
          color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.accent : AppColors.textSecondary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.accent : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.accent, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _colorCircle(SettingsController settings, int colorValue, String label, {required bool isText}) {
    final isSelected = isText
        ? settings.subtitleColor.value == colorValue
        : settings.subtitleBgColor.value == colorValue;
    final color = Color(colorValue);

    return GestureDetector(
      onTap: () => isText
          ? settings.updateSubtitleColor(colorValue)
          : settings.updateSubtitleBgColor(colorValue),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: colorValue == 0x00000000
                ? Icon(Icons.block, color: AppColors.textSecondary.withValues(alpha: 0.5), size: 18)
                : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _showVoicePicker(BuildContext context, NativeTtsController ttsController, SettingsController settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => ListView.builder(
        itemCount: ttsController.availableVoices.length,
        itemBuilder: (context, index) {
          final voice = ttsController.availableVoices[index];
          final name = voice['name'] as String? ?? 'Voix ${index + 1}';
          final isSelected = name == settings.ttsSettings.value.voiceName;

          return ListTile(
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            title: Text(name),
            subtitle: Text(voice['locale'] as String? ?? ''),
            onTap: () {
              settings.updateTtsVoice(name);
              ttsController.setVoice(name);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
