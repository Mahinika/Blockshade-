package se.cognifox.blockshade

import android.app.Application
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Disables Firebase Analytics collection before any other startup work.
/// Basic consent mode: nothing is sent until Dart turns collection back on
/// after the UMP form. A missing Firebase config must not crash the process.
class BlockshadeApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        try {
            val analyticsClass = Class.forName("com.google.firebase.analytics.FirebaseAnalytics")
            val getInstance = analyticsClass.getMethod("getInstance", Context::class.java)
            val analytics = getInstance.invoke(null, this)
            val setEnabled = analyticsClass.getMethod(
                "setAnalyticsCollectionEnabled",
                Boolean::class.javaPrimitiveType,
            )
            setEnabled.invoke(analytics, false)
        } catch (_: Throwable) {
            // No google-services.json or Firebase classes. The game still starts.
        }
    }
}

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UMP_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "readConsentStorage") {
                    val prefs = getSharedPreferences("${packageName}_preferences", MODE_PRIVATE)
                    result.success(
                        mapOf(
                            "consentModeValues" to (prefs.getString("UMP_consentModeValues", "") ?: ""),
                            "purposeConsents" to (prefs.getString("IABTCF_PurposeConsents", "") ?: ""),
                        ),
                    )
                } else {
                    result.notImplemented()
                }
            }
    }

    companion object {
        private const val UMP_CHANNEL = "se.cognifox.blockshade/ump"
    }
}
