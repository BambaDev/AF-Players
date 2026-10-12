package com.afplayers.af_players

import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.storage.StorageManager
import android.os.storage.StorageVolume
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class StorageBridge(
    private val context: Context,
    private val channel: MethodChannel
) : MethodChannel.MethodCallHandler {

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getVolumes" -> result.success(getVolumes())
            else -> result.notImplemented()
        }
    }

    private fun getVolumes(): List<Map<String, Any?>> {
        val volumes = mutableListOf<Map<String, Any?>>()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val sm = context.getSystemService(Context.STORAGE_SERVICE) as StorageManager
            val storageVolumes: List<StorageVolume> = sm.storageVolumes

            for (sv in storageVolumes) {
                val path = getVolumePath(sv)
                if (path != null) {
                    val type = when {
                        !sv.isRemovable -> "internal"
                        sv.getDescription(context).lowercase().contains("usb") -> "usb"
                        sv.isRemovable -> "sdCard"
                        else -> "other"
                    }
                    volumes.add(mapOf(
                        "name" to sv.getDescription(context),
                        "path" to path,
                        "type" to type,
                        "isRemovable" to sv.isRemovable
                    ))
                }
            }
        }

        if (volumes.isEmpty()) {
            volumes.add(mapOf(
                "name" to "Stockage interne",
                "path" to Environment.getExternalStorageDirectory()?.absolutePath,
                "type" to "internal",
                "isRemovable" to false
            ))
        }

        val extraDirs = context.getExternalFilesDirs(null)
        for (dir in extraDirs) {
            if (dir == null) continue
            val rootPath = extractVolumeRoot(dir.absolutePath)
            if (rootPath != null && volumes.none { it["path"] == rootPath }) {
                volumes.add(mapOf(
                    "name" to "Stockage (${rootPath.split("/").last()})",
                    "path" to rootPath,
                    "type" to "sdCard",
                    "isRemovable" to true
                ))
            }
        }

        return volumes
    }

    private fun getVolumePath(sv: StorageVolume): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val dir = sv.directory
            return dir?.absolutePath
        }
        return try {
            val getPathMethod = sv.javaClass.getMethod("getPath")
            getPathMethod.invoke(sv) as? String
        } catch (_: Exception) {
            null
        }
    }

    private fun extractVolumeRoot(appFilesPath: String): String? {
        val idx = appFilesPath.indexOf("/Android/")
        if (idx > 0) {
            return appFilesPath.substring(0, idx)
        }
        return null
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }
}
