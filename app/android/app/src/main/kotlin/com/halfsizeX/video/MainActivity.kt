package com.halfsizeX.video

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "halfsizex/platform"
    private val prefs by lazy { getSharedPreferences("halfsizex", MODE_PRIVATE) }
    private var pendingDirResult: MethodChannel.Result? = null
    private val outputDirKey = "output_tree_uri"
    private val pickDirRequest = 4102

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ffmpegPaths" -> result.success(ffmpegPaths())
                    "exportToDownloads" -> {
                        val src = call.argument<String>("srcPath")
                        val name = call.argument<String>("displayName") ?: "halfsizeX.mp4"
                        if (src == null) {
                            result.error("bad_args", "srcPath missing", null)
                        } else {
                            try {
                                result.success(exportToDownloads(File(src), name))
                            } catch (e: Exception) {
                                result.error("export_failed", e.message, null)
                            }
                        }
                    }
                    "pickOutputDir" -> {
                        pendingDirResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                            addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                            )
                        }
                        startActivityForResult(intent, pickDirRequest)
                    }
                    "outputDir" -> result.success(outputDirLabel())
                    "clearOutputDir" -> {
                        prefs.edit().remove(outputDirKey).apply()
                        result.success(null)
                    }
                    "openFile" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("bad_args", "path missing", null)
                        } else {
                            try {
                                openFile(path)
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("open_failed", e.message, null)
                            }
                        }
                    }
                    "startCompressService" -> {
                        val title = call.argument<String>("title") ?: "halfsizeX"
                        requestNotificationPermission()
                        val intent = Intent(this, CompressService::class.java)
                            .putExtra("title", title)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }
                    "updateCompressProgress" -> {
                        val progress = call.argument<Int>("progress") ?: 0
                        val text = call.argument<String>("text") ?: "$progress%"
                        CompressService.instance?.update(progress, text)
                        result.success(null)
                    }
                    "stopCompressService" -> {
                        stopService(Intent(this, CompressService::class.java))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickDirRequest) return
        val pending = pendingDirResult
        pendingDirResult = null
        val uri = data?.data
        if (resultCode == RESULT_OK && uri != null) {
            try {
                contentResolver.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
            } catch (_: Exception) {
            }
            prefs.edit().putString(outputDirKey, uri.toString()).apply()
            pending?.success(outputDirLabel(uri))
        } else {
            pending?.success(null)
        }
    }

    private fun outputDirLabel(): String? {
        val raw = prefs.getString(outputDirKey, null) ?: return null
        return outputDirLabel(Uri.parse(raw))
    }

    private fun outputDirLabel(uri: Uri): String {
        return try {
            val id = DocumentsContract.getTreeDocumentId(uri)
            id.substringAfter(':', id).ifEmpty { id }
        } catch (_: Exception) {
            uri.lastPathSegment ?: uri.toString()
        }
    }

    private fun ffmpegPaths(): Map<String, String>? {
        val dir = File(applicationInfo.nativeLibraryDir)
        val ffmpeg = File(dir, "libffmpeg.so")
        val ffprobe = File(dir, "libffprobe.so")
        if (!ffmpeg.exists() || !ffprobe.exists()) return null
        ffmpeg.setExecutable(true)
        ffprobe.setExecutable(true)
        return mapOf("ffmpeg" to ffmpeg.absolutePath, "ffprobe" to ffprobe.absolutePath)
    }

    private fun exportToDownloads(src: File, displayName: String): String {
        val mime = "video/mp4"
        val tree = prefs.getString(outputDirKey, null)
        if (tree != null) {
            try {
                val doc = DocumentsContract.createDocument(
                    contentResolver,
                    Uri.parse(tree),
                    mime,
                    displayName,
                )
                if (doc != null) {
                    contentResolver.openOutputStream(doc)?.use { out ->
                        src.inputStream().use { it.copyTo(out) }
                    } ?: throw IllegalStateException("Cannot open output stream")
                    return doc.toString()
                }
            } catch (_: Exception) {
                // Fall back to MediaStore Downloads if the chosen folder fails.
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
                put(MediaStore.MediaColumns.MIME_TYPE, mime)
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    Environment.DIRECTORY_DOWNLOADS + "/halfsizeX",
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("MediaStore refused the insert")
            try {
                resolver.openOutputStream(uri)?.use { out ->
                    src.inputStream().use { it.copyTo(out) }
                } ?: throw IllegalStateException("Cannot open output stream")
                values.clear()
                values.put(MediaStore.MediaColumns.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
            } catch (e: Exception) {
                resolver.delete(uri, null, null)
                throw e
            }
            return uri.toString()
        }
        val dir = getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: cacheDir
        dir.mkdirs()
        val dest = File(dir, displayName)
        src.copyTo(dest, overwrite = true)
        return dest.absolutePath
    }

    private fun openFile(path: String) {
        val uri = if (path.startsWith("content://")) {
            Uri.parse(path)
        } else {
            FileProvider.getUriForFile(this, "$packageName.fileprovider", File(path))
        }
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "video/mp4")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, null))
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= 33 &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 41)
        }
    }
}
