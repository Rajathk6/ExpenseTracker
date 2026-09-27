package dev.rajath.expense_tracker

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and owns two OS entry points:
 *
 * - the Android **share target**: an `ACTION_SEND` / `ACTION_SEND_MULTIPLE`
 *   plain-text intent (a payment SMS or UPI message) is handed to Dart, which
 *   parses it offline and opens the intake confirm sheet. Nothing is ever
 *   written to the ledger without that confirmation;
 * - the **home-screen tile** (see QuickAddWidget), which launches straight
 *   into `homewidget://quickadd?action=quickadd` and is handled in Dart.
 *
 * Both are implemented here rather than with plugins because every published
 * plugin version needs either a compileSdk Flutter does not pin or a Gradle
 * override — the dependency policy in PLAN.md is "zero Gradle hacks".
 */
class MainActivity : FlutterFragmentActivity() {

    /** Shared before Dart is listening (cold start / locked). */
    private var pending: String? = null
    private var events: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        pending = sharedText(intent)

        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Handed over once: the same intent must not reopen the sheet.
                "initialText" -> {
                    result.success(pending)
                    pending = null
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                events = sink
            }

            override fun onCancel(arguments: Any?) {
                events = null
            }
        })
    }

    /** `launchMode="singleTop"`, so a share while the app is open lands here. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val text = sharedText(intent) ?: return
        val sink = events
        if (sink != null) sink.success(text) else pending = text
    }

    /** The plain-text payload of a share intent, or null when this is not one. */
    private fun sharedText(intent: Intent?): String? {
        if (intent == null) return null
        val raw = when (intent.action) {
            Intent.ACTION_SEND -> intent.getStringExtra(Intent.EXTRA_TEXT)
            Intent.ACTION_SEND_MULTIPLE ->
                intent.getStringArrayListExtra(Intent.EXTRA_TEXT)?.joinToString("\n")
            else -> null
        }
        return raw?.trim()?.takeIf { it.isNotEmpty() }
    }

    companion object {
        private const val METHOD_CHANNEL = "dev.rajath.expense_tracker/share"
        private const val EVENT_CHANNEL = "dev.rajath.expense_tracker/share_events"
    }
}
