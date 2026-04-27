package com.controlbituwb.app_uwb

import com.controlbituwb.app_uwb.uwb.UwbBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private lateinit var uwbBridge: UwbBridge

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        uwbBridge = UwbBridge(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        if (::uwbBridge.isInitialized) uwbBridge.dispose()
        super.onDestroy()
    }
}
