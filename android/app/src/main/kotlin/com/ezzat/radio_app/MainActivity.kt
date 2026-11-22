package com.ezzat.radio_app

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// audio_service needs its own Activity base class for background playback.
class MainActivity : AudioServiceActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "radio/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Android 13+: runtime permission for the player notification.
                    "requestNotifications" -> {
                        if (Build.VERSION.SDK_INT >= 33 &&
                            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
                            PackageManager.PERMISSION_GRANTED
                        ) {
                            requestPermissions(
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS), 1001
                            )
                        }
                        result.success(null)
                    }
                    // Our own process's log, for the in-app diagnostics screen.
                    "logcat" -> {
                        Thread {
                            val text = try {
                                val p = Runtime.getRuntime().exec(
                                    arrayOf("logcat", "-d", "-t", "600", "--pid=${android.os.Process.myPid()}")
                                )
                                p.inputStream.bufferedReader().readText()
                            } catch (e: Exception) {
                                "logcat failed: $e"
                            }
                            runOnUiThread { result.success(text) }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
