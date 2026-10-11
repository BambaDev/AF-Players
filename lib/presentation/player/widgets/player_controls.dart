import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/native_player_controller.dart';
import '../../../controllers/sync_controller.dart';
import '../../../controllers/settings_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/duration_extensions.dart';
import '../../../data/models/video_item.dart';
import 'dual_volume_bar.dart';
import 'tts_speed_selector.dart';

class PlayerControls extends StatefulWidget {
  final NativePlayerController playerController;
  final SyncController syncController;
  final VideoItem video;
  final VoidCallback? onToggleLock;

  const PlayerControls({
    super.key,
    required this.playerController,
    required this.syncController,
    required this.video,
    this.onToggleLock,
  });

  @override
  State<PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<PlayerControls> {
  bool _volumeExpanded = false;
  bool _isSeeking = false;
  double _seekValue = 0;

  NativePlayerController get _player => widget.playerController;
  SyncController get _sync => widget.syncController;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54, Colors.black87],
          stops: [0.0, 0.3, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSeekBar(settings),
            const SizedBox(height: 4),
            _buildTransportRow(settings),
            if (_volumeExpanded) ...[
              const SizedBox(height: 4),
              DualVolumeBar(
                playerController: _player,
                settings: settings,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeekBar(SettingsController settings) {
    return Obx(() {
      final pos = _player.position.value;
      final dur = _player.duration.value;
      final maxVal = dur.inMilliseconds.toDouble();

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white24,
              thumbColor: AppColors.primary,
            ),
            child: Slider(
              value: _isSeeking
                  ? _seekValue.clamp(0, maxVal > 0 ? maxVal : 1)
                  : (maxVal > 0
                      ? pos.inMilliseconds.toDouble().clamp(0, maxVal)
                      : 0),
              max: maxVal > 0 ? maxVal : 1,
              onChangeStart: (value) {
                setState(() {
                  _isSeeking = true;
                  _seekValue = value;
                });
              },
              onChanged: (value) {
                setState(() {
                  _seekValue = value;
                });
              },
              onChangeEnd: (value) {
                _sync.onUserSeek(Duration(milliseconds: value.toInt()));
                setState(() {
                  _isSeeking = false;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (_isSeeking
                      ? Duration(milliseconds: _seekValue.toInt())
                      : pos)
                    .toShortTimestamp(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  dur.toShortTimestamp(),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildTransportRow(SettingsController settings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const TtsSpeedSelector(),
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 26),
          onPressed: () => _player.seekBackward(settings.seekDuration.value),
          visualDensity: VisualDensity.compact,
        ),
        Obx(() => IconButton(
          icon: Icon(
            _player.isPlaying.value
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            color: Colors.white,
            size: 50,
          ),
          onPressed: () {
            if (_player.isPlaying.value) {
              _sync.onUserPause();
            } else {
              _sync.onUserPlay();
            }
          },
        )),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 26),
          onPressed: () => _player.seekForward(settings.seekDuration.value),
          visualDensity: VisualDensity.compact,
        ),
        Obx(() => IconButton(
          icon: Icon(
            _sync.isTtsEnabled.value
                ? Icons.record_voice_over
                : Icons.voice_over_off,
            color: _sync.isTtsEnabled.value ? AppColors.accent : Colors.white54,
            size: 20,
          ),
          onPressed: _sync.toggleTts,
          visualDensity: VisualDensity.compact,
        )),
        Obx(() {
          final mode = _sync.ttsSyncMode.value;
          final icons = [Icons.queue_music, Icons.pause_circle_outline, Icons.speed];
          final labels = ['File', 'Pause', 'Vitesse'];
          return IconButton(
            icon: Icon(
              icons[mode],
              color: mode == 0 ? Colors.white54 : AppColors.primary,
              size: 20,
            ),
            tooltip: labels[mode],
            onPressed: _sync.cycleSyncMode,
            visualDensity: VisualDensity.compact,
          );
        }),
        IconButton(
          icon: Icon(
            _volumeExpanded ? Icons.audiotrack : Icons.tune,
            color: _volumeExpanded ? AppColors.accent : Colors.white70,
            size: 20,
          ),
          onPressed: () => setState(() => _volumeExpanded = !_volumeExpanded),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
