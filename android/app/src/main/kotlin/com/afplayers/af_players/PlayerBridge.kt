package com.afplayers.af_players

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.Surface
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.PlaybackParameters
import androidx.media3.common.Player
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry

class PlayerBridge(
    private val context: Context,
    private val textureRegistry: TextureRegistry,
    methodChannel: MethodChannel,
    private val eventChannel: EventChannel
) : MethodChannel.MethodCallHandler {

    private var player: ExoPlayer? = null
    private var mediaSession: MediaSession? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var surface: Surface? = null
    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    private var positionRunnable: Runnable? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "init" -> {
                initPlayer()
                result.success(textureEntry?.id())
            }
            "open" -> {
                val path = call.argument<String>("path") ?: ""
                open(path)
                result.success(null)
            }
            "play" -> { player?.play(); result.success(null) }
            "pause" -> { player?.pause(); result.success(null) }
            "seek" -> {
                val posMs = call.argument<Number>("position")?.toLong() ?: 0L
                player?.seekTo(posMs)
                result.success(null)
            }
            "setVolume" -> {
                val vol = call.argument<Number>("volume")?.toFloat() ?: 1.0f
                player?.volume = vol
                result.success(null)
            }
            "setSpeed" -> {
                val speed = call.argument<Number>("speed")?.toFloat() ?: 1.0f
                player?.playbackParameters = PlaybackParameters(speed)
                result.success(null)
            }
            "getPosition" -> result.success(player?.currentPosition ?: 0L)
            "getDuration" -> result.success(player?.duration ?: 0L)
            "isPlaying" -> result.success(player?.isPlaying ?: false)
            "dispose" -> { dispose(); result.success(null) }
            else -> result.notImplemented()
        }
    }

    private fun initPlayer() {
        dispose()
        textureEntry = textureRegistry.createSurfaceTexture()
        surface = Surface(textureEntry!!.surfaceTexture())

        player = ExoPlayer.Builder(context).build().apply {
            setVideoSurface(surface)
            addListener(object : Player.Listener {
                override fun onPlaybackStateChanged(state: Int) {
                    val stateStr = when (state) {
                        Player.STATE_IDLE -> "idle"
                        Player.STATE_BUFFERING -> "buffering"
                        Player.STATE_READY -> "ready"
                        Player.STATE_ENDED -> "ended"
                        else -> "unknown"
                    }
                    sendEvent(mapOf("event" to "stateChanged", "state" to stateStr))
                    if (state == Player.STATE_READY) {
                        sendEvent(mapOf(
                            "event" to "durationChanged",
                            "duration" to (duration.takeIf { it > 0 } ?: 0L)
                        ))
                    }
                }

                override fun onIsPlayingChanged(isPlaying: Boolean) {
                    sendEvent(mapOf("event" to "playingChanged", "isPlaying" to isPlaying))
                    if (isPlaying) startPositionUpdates() else stopPositionUpdates()
                }

                override fun onPlayerError(error: PlaybackException) {
                    sendEvent(mapOf("event" to "error", "message" to (error.message ?: "Unknown error")))
                }
            })
        }

        mediaSession = MediaSession.Builder(context, player!!).build()
    }

    private fun open(path: String) {
        val mediaItem = if (path.startsWith("http://") || path.startsWith("https://")) {
            MediaItem.fromUri(path)
        } else {
            MediaItem.fromUri("file://$path")
        }
        player?.setMediaItem(mediaItem)
        player?.prepare()
        player?.playWhenReady = true
    }

    private fun startPositionUpdates() {
        stopPositionUpdates()
        positionRunnable = object : Runnable {
            override fun run() {
                player?.let {
                    sendEvent(mapOf("event" to "position", "position" to it.currentPosition))
                }
                handler.postDelayed(this, 200)
            }
        }
        handler.post(positionRunnable!!)
    }

    private fun stopPositionUpdates() {
        positionRunnable?.let { handler.removeCallbacks(it) }
        positionRunnable = null
    }

    private fun sendEvent(data: Map<String, Any>) {
        handler.post { eventSink?.success(data) }
    }

    fun dispose() {
        stopPositionUpdates()
        mediaSession?.release()
        mediaSession = null
        player?.release()
        player = null
        surface?.release()
        surface = null
        textureEntry?.release()
        textureEntry = null
    }
}
