package com.lightbeacon.light_beacon

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Reports window focus changes to Dart.
 *
 * Opening the notification shade does not pause the activity: it stays
 * RESUMED and Flutter never sees an AppLifecycleState change. The only signal
 * that the beacon is covered by another window is the window losing focus.
 *
 * The beacon pauses on it because the system posts a notification on every
 * torch state change, so a flashing torch makes the notification shade churn.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "lightbeacon/window_focus",
        )
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        channel?.invokeMethod("windowFocusChanged", hasFocus)
    }

    override fun onDestroy() {
        channel = null
        super.onDestroy()
    }
}
