package dev.rajath.expense_tracker

import android.content.Intent
import android.net.Uri
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hosts the Flutter UI and owns the OS entry points:
 *
 * - the Android **share target**: an `ACTION_SEND` / `ACTION_SEND_MULTIPLE`
 *   plain-text intent (a payment SMS or UPI message) or a screenshot is handed
 *   to Dart, which parses it offline and opens the intake confirm sheet.
 *   Nothing is ever written to the ledger without that confirmation;
 * - the **home-screen tile** (see QuickAddWidget), which launches straight
 *   into `homewidget://quickadd?action=quickadd` and is handled in Dart.
 *
 * Both are implemented here rather than with plugins because every published
 * plugin version needs either a compileSdk Flutter does not pin or a Gradle
 * override — the dependency policy in PLAN.md is "zero Gradle hacks".
 *
 * Shared images are copied into the app cache first: the share hands over
 * content:// URIs that the ML Kit reader cannot open directly.
 */
class MainActivity : FlutterFragmentActivity() {

    /** Shared before Dart is listening (cold start / locked). */
    private var pending: Map<String, Any?>? = null
    private var events: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        pending = sharePayload(intent)

        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Handed over once: the same intent must not reopen the sheet.
                "initialPayload" -> {
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
        val payload = sharePayload(intent) ?: return
        val sink = events
        if (sink != null) sink.success(payload) else pending = payload
    }

    /** `{text, images}` for a share intent, or null when this is not a share. */
    private fun sharePayload(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        if (intent.action != Intent.ACTION_SEND && intent.action != Intent.ACTION_SEND_MULTIPLE) return null
        val text = when (intent.action) {
            Intent.ACTION_SEND -> intent.getStringExtra(Intent.EXTRA_TEXT)
            else -> intent.getStringArrayListExtra(Intent.EXTRA_TEXT)?.joinToString("\n")
        }?.trim()?.takeIf { it.isNotEmpty() }
        val images = streamUris(intent).mapNotNull { copyToCache(it) }
        if (text == null && images.isEmpty()) return null
        return mapOf("text" to text, "images" to images)
    }

    /** Every image the share carried: EXTRA_STREAM, a list of them, or a clip. */
    private fun streamUris(intent: Intent): List<Uri> {
        val out = mutableListOf<Uri>()
        if (intent.action == Intent.ACTION_SEND) {
            streamUri(intent)?.let { out.add(it) }
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)?.let { out.addAll(it) }
        }
        intent.clipData?.let { clip ->
            for (index in 0 until clip.itemCount) out.add(clip.getItemAt(index).uri)
        }
        return out.distinct()
    }

    @Suppress("DEPRECATION")
    private fun streamUri(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    /** content:// → a plain file path in the app cache, or null if unreadable. */
    private fun copyToCache(uri: Uri): String? = try {
        val resolver = contentResolver
        val extension = when (resolver.getType(uri)) {
            "image/png" -> "png"
            "image/webp" -> "webp"
            else -> "jpg"
        }
        val target = File(cacheDir, "share-${System.currentTimeMillis()}.$extension")
        val copied = resolver.openInputStream(uri)?.use { input ->
            target.outputStream().use { output -> input.copyTo(output) }
        } ?: 0L
        if (copied > 0) target.absolutePath else null
    } catch (error: Exception) {
        null
    }

    companion object {
        private const val METHOD_CHANNEL = "dev.rajath.expense_tracker/share"
        private const val EVENT_CHANNEL = "dev.rajath.expense_tracker/share_events"
    }
}
