package com.afplayers.af_players

import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID

class SpeechBridge(
    private val context: Context,
    private val channel: MethodChannel
) : MethodChannel.MethodCallHandler, TextToSpeech.OnInitListener {

    private var tts: TextToSpeech? = null
    private var isInitialized = false
    private var pendingResult: MethodChannel.Result? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var volume = 1.0f

    init {
        channel.setMethodCallHandler(this)
        tts = TextToSpeech(context, this)
    }

    override fun onInit(status: Int) {
        isInitialized = status == TextToSpeech.SUCCESS
        if (isInitialized) {
            tts?.language = Locale.FRANCE
            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    mainHandler.post {
                        channel.invokeMethod("onStart", mapOf("utteranceId" to utteranceId))
                    }
                }
                override fun onDone(utteranceId: String?) {
                    mainHandler.post {
                        channel.invokeMethod("onComplete", mapOf("utteranceId" to utteranceId))
                    }
                }
                @Deprecated("Deprecated in API")
                override fun onError(utteranceId: String?) {
                    mainHandler.post {
                        channel.invokeMethod("onError", mapOf("utteranceId" to utteranceId, "error" to "unknown"))
                    }
                }
                override fun onError(utteranceId: String?, errorCode: Int) {
                    mainHandler.post {
                        channel.invokeMethod("onError", mapOf("utteranceId" to utteranceId, "error" to errorCode.toString()))
                    }
                }
            })
        }
        mainHandler.post {
            channel.invokeMethod("onInitStatus", mapOf("success" to isInitialized))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "speak" -> {
                val text = call.argument<String>("text") ?: ""
                if (text.isBlank() || !isInitialized) {
                    result.success(false)
                    return
                }
                val utteranceId = UUID.randomUUID().toString()
                val params = Bundle().apply {
                    putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId)
                    putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, volume)
                }
                val code = tts?.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
                result.success(code == TextToSpeech.SUCCESS)
            }
            "stop" -> {
                tts?.stop()
                result.success(null)
            }
            "setSpeechRate" -> {
                val rate = call.argument<Number>("rate")?.toFloat() ?: 1.0f
                tts?.setSpeechRate(rate)
                result.success(null)
            }
            "setPitch" -> {
                val pitch = call.argument<Number>("pitch")?.toFloat() ?: 1.0f
                tts?.setPitch(pitch)
                result.success(null)
            }
            "setVolume" -> {
                volume = call.argument<Number>("volume")?.toFloat() ?: 1.0f
                result.success(null)
            }
            "getVoices" -> {
                val voices = tts?.voices?.filter { it.locale.language == "fr" }?.map {
                    mapOf("name" to it.name, "locale" to it.locale.toString(), "quality" to it.quality)
                } ?: emptyList()
                result.success(voices)
            }
            "setVoice" -> {
                val voiceName = call.argument<String>("name")
                if (voiceName != null) {
                    val voice = tts?.voices?.find { it.name == voiceName }
                    if (voice != null) tts?.voice = voice
                }
                result.success(null)
            }
            "isInitialized" -> result.success(isInitialized)
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        tts?.stop()
        tts?.shutdown()
        tts = null
    }
}
