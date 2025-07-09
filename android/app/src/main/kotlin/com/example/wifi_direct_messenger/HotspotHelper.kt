package com.example.wifi_direct_messenger

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class HotspotHelper(private val context: Context) : MethodCallHandler {
    private val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "createHotspot" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    wifiManager.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                        override fun onStarted(reservation: WifiManager.LocalOnlyHotspotReservation) {
                            super.onStarted(reservation)
                            val config = reservation.wifiConfiguration
                            Handler(Looper.getMainLooper()).post {
                                result.success(mapOf(
                                    "ssid" to (config?.SSID ?: ""),
                                    "password" to (config?.preSharedKey ?: "")
                                ))
                            }
                        }
                        override fun onFailed(reason: Int) {
                            Handler(Looper.getMainLooper()).post {
                                result.error("HOTSPOT_FAILED", "Failed to start hotspot: $reason", null)
                            }
                        }
                    }, Handler(Looper.getMainLooper()))
                } else {
                    result.error("UNSUPPORTED", "Hotspot creation requires Android 8.0+", null)
                }
            }
            else -> result.notImplemented()
        }
    }

    companion object {
        fun registerWith(flutterEngine: FlutterEngine, context: Context) {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "hotspot")
                .setMethodCallHandler(HotspotHelper(context))
        }
    }
} 