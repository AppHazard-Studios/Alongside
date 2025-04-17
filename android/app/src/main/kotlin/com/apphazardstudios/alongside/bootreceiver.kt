package com.apphazardstudios.alongside

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.apphazardstudios.alongside.MainActivity

class bootreceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device boot completed, starting app services")

            try {
                // Start the main activity to initialize the app services
                val launchIntent = Intent(context, MainActivity::class.java)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent.putExtra("boot_completed", true)
                context.startActivity(launchIntent)
            } catch (e: Exception) {
                Log.e("BootReceiver", "Error starting app after boot: ${e.message}")
            }
        }
    }
}