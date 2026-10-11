package com.afplayers.af_players

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var playerBridge: PlayerBridge? = null
    private var speechBridge: SpeechBridge? = null
    private var audioMixerBridge: AudioMixerBridge? = null
    private var thumbnailBridge: ThumbnailBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        playerBridge = PlayerBridge(
            context = this,
            textureRegistry = flutterEngine.renderer,
            methodChannel = MethodChannel(messenger, "com.afplayers/player"),
            eventChannel = EventChannel(messenger, "com.afplayers/player_events")
        )

        speechBridge = SpeechBridge(
            context = this,
            channel = MethodChannel(messenger, "com.afplayers/speech")
        )

        audioMixerBridge = AudioMixerBridge(
            context = this,
            channel = MethodChannel(messenger, "com.afplayers/audio_mixer")
        )

        thumbnailBridge = ThumbnailBridge(
            cacheDir = cacheDir,
            channel = MethodChannel(messenger, "com.afplayers/thumbnail")
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        playerBridge?.dispose()
        speechBridge?.dispose()
        audioMixerBridge?.dispose()
        thumbnailBridge?.dispose()
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
