package com.afplayers.af_players

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest

class ThumbnailBridge(
    private val cacheDir: File,
    channel: MethodChannel
) : MethodChannel.MethodCallHandler {

    init {
        channel.setMethodCallHandler(this)
        val thumbDir = File(cacheDir, "thumbnails")
        if (!thumbDir.exists()) thumbDir.mkdirs()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getThumbnail" -> {
                val path = call.argument<String>("path") ?: ""
                val width = call.argument<Int>("width") ?: 160
                val height = call.argument<Int>("height") ?: 90
                Thread {
                    try {
                        val thumbPath = generateThumbnail(path, width, height)
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.success(thumbPath)
                        }
                    } catch (e: Exception) {
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            result.success(null)
                        }
                    }
                }.start()
            }
            else -> result.notImplemented()
        }
    }

    private fun generateThumbnail(videoPath: String, width: Int, height: Int): String? {
        val hash = md5(videoPath)
        val thumbFile = File(cacheDir, "thumbnails/$hash.jpg")
        if (thumbFile.exists()) return thumbFile.absolutePath

        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(videoPath)
            val bitmap = retriever.getFrameAtTime(1000000) ?: return null
            val scaled = Bitmap.createScaledBitmap(bitmap, width, height, true)
            FileOutputStream(thumbFile).use { out ->
                scaled.compress(Bitmap.CompressFormat.JPEG, 75, out)
            }
            if (scaled != bitmap) scaled.recycle()
            bitmap.recycle()
            thumbFile.absolutePath
        } catch (e: Exception) {
            null
        } finally {
            retriever.release()
        }
    }

    private fun md5(input: String): String {
        val digest = MessageDigest.getInstance("MD5")
        return digest.digest(input.toByteArray())
            .joinToString("") { "%02x".format(it) }
    }

    fun dispose() {}
}
