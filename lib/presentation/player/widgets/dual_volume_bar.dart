import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/native_player_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../../core/constants/app_colors.dart';

class DualVolumeBar extends StatefulWidget {
  final NativePlayerController playerController;
  final SettingsController settings;

  const DualVolumeBar({
    super.key,
    required this.playerController,
    required this.settings,
  });

  @override
  State<DualVolumeBar> createState() => _DualVolumeBarState();
}

class _DualVolumeBarState extends State<DualVolumeBar> {
  double _previousEnVolume = 0.0;
  double _previousFrVolume = 1.0;
  bool _enMuted = false;
  bool _frMuted = false;

  void _toggleEnMute() {
    setState(() {
      if (_enMuted) {
        _enMuted = false;
        widget.settings.updateVideoVolume(_previousEnVolume);
        widget.playerController.setVideoVolume(_previousEnVolume);
      } else {
        _previousEnVolume = widget.settings.videoVolume.value;
        _enMuted = true;
        widget.settings.updateVideoVolume(0.0);
        widget.playerController.setVideoVolume(0.0);
      }
    });
  }

  void _toggleFrMute() {
    setState(() {
      if (_frMuted) {
        _frMuted = false;
        widget.settings.updateFrenchVolume(_previousFrVolume);
      } else {
        _previousFrVolume = widget.settings.frenchVolume.value;
        _frMuted = true;
        widget.settings.updateFrenchVolume(0.0);
      }
    });
  }

  void _onEnVolumeChanged(double value) {
    if (_enMuted) {
      setState(() => _enMuted = false);
    }
    widget.settings.updateVideoVolume(value);
    widget.playerController.setVideoVolume(value);
  }

  void _onFrVolumeChanged(double value) {
    if (_frMuted) {
      setState(() => _frMuted = false);
    }
    widget.settings.updateFrenchVolume(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRow(
            icon: Icons.movie,
            isMuted: _enMuted,
            onToggleMute: _toggleEnMute,
            mutedIcon: Icons.volume_off,
            unmutedIcon: Icons.volume_up,
            activeColor: Colors.blueAccent,
            volumeObs: widget.settings.videoVolume,
            onChanged: _onEnVolumeChanged,
          ),
          _buildRow(
            icon: Icons.record_voice_over,
            isMuted: _frMuted,
            onToggleMute: _toggleFrMute,
            mutedIcon: Icons.voice_over_off,
            unmutedIcon: Icons.record_voice_over,
            activeColor: AppColors.accent,
            volumeObs: widget.settings.frenchVolume,
            onChanged: _onFrVolumeChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required bool isMuted,
    required VoidCallback onToggleMute,
    required IconData mutedIcon,
    required IconData unmutedIcon,
    required Color activeColor,
    required RxDouble volumeObs,
    required ValueChanged<double> onChanged,
  }) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onToggleMute,
            child: Icon(
              isMuted ? mutedIcon : unmutedIcon,
              color: isMuted ? Colors.white38 : activeColor.withValues(alpha: 0.8),
              size: 16,
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Obx(() => SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                activeTrackColor: isMuted ? Colors.white24 : activeColor,
                inactiveTrackColor: Colors.white12,
                thumbColor: isMuted ? Colors.white38 : activeColor,
              ),
              child: Slider(
                value: volumeObs.value,
                onChanged: onChanged,
              ),
            )),
          ),
          Obx(() => SizedBox(
            width: 32,
            child: Text(
              '${(volumeObs.value * 100).round()}%',
              style: TextStyle(
                color: isMuted ? Colors.white38 : Colors.white54,
                fontSize: 10,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
