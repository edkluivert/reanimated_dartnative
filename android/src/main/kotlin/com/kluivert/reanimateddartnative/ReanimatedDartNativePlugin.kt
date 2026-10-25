package com.kluivert.reanimateddartnative

import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Plugin entry point, registered through the pubspec `pluginClass`. Loads
 * libreanimated_dartnative.so (which runs JNI_OnLoad) and gives the bridge
 * the application context it needs for SensorManager and Settings.
 */
class ReanimatedDartNativePlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        try {
            System.loadLibrary("reanimated_dartnative")
        } catch (e: UnsatisfiedLinkError) {
            Log.e("ReanimatedDartNative", "Failed to load libreanimated_dartnative.so: ${e.message}")
        }
        ReanimatedDartNativeBridge.attach(binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        ReanimatedDartNativeBridge.detach()
    }
}
