package com.example.pata

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.install.InstallState
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class UpdatePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var appUpdateManager: AppUpdateManager

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "update_channel")
        channel.setMethodCallHandler(this)
        appUpdateManager = AppUpdateManagerFactory.create(binding.applicationContext)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkForUpdate" -> {
                appUpdateManager.appUpdateInfo.addOnSuccessListener { info ->
                    val isAvailable = info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
                    result.success(isAvailable)
                }
            }
            "startUpdate" -> {
                appUpdateManager.appUpdateInfo.addOnSuccessListener { info ->
                    if (info.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE) {
                        appUpdateManager.startUpdateFlowForResult(
                            info,
                            AppUpdateType.IMMEDIATE,
                            MainActivity::class.java,
                            1001
                        )
                    }
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}