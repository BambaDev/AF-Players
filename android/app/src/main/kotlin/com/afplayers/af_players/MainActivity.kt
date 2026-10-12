package com.afplayers.af_players

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var playerBridge: PlayerBridge? = null
    private var speechBridge: SpeechBridge? = null
    private var audioMixerBridge: AudioMixerBridge? = null
    private var thumbnailBridge: ThumbnailBridge? = null
    private var storageBridge: StorageBridge? = null
    private var pipChannel: MethodChannel? = null
    private var autoPipEnabled = false

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

        storageBridge = StorageBridge(
            context = this,
            channel = MethodChannel(messenger, "com.afplayers/storage")
        )

        pipChannel = MethodChannel(messenger, "com.afplayers/pip").also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "enterPip" -> {
                        result.success(enterPip())
                    }
                    "setAutoPip" -> {
                        autoPipEnabled = call.argument<Boolean>("enabled") ?: false
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun enterPip(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            enterPictureInPictureMode(params)
            true
        } catch (_: Exception) {
            false
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (autoPipEnabled && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            enterPip()
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("onPipChanged", mapOf("isInPip" to isInPictureInPictureMode))
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        playerBridge?.dispose()
        speechBridge?.dispose()
        audioMixerBridge?.dispose()
        thumbnailBridge?.dispose()
        storageBridge?.dispose()
        pipChannel?.setMethodCallHandler(null)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
