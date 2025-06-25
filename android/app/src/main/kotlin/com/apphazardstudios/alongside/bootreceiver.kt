package com.apphazardstudios.alongside

// android/app/src/main/kotlin/com/your/package/BootReceiver.kt
// Replace com.your.package with your actual package name


import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AlongsideBootReceiver"
        private const val CHANNEL = "alongside/boot"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d(TAG, "Device boot completed - rescheduling notifications")

            context?.let {
                try {
                    // Start the app in background to reschedule notifications
                    val appIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                    appIntent?.let { launchIntent ->
                        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        launchIntent.putExtra("boot_reschedule", true)
                        context.startActivity(launchIntent)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error starting app after boot: ${e.message}")
                }
            }
        }
    }
}