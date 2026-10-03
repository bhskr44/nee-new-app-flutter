package `in`.complit.neep

import android.Manifest
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SubscriptionManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.regex.Pattern

class MainActivity : FlutterFragmentActivity() {

    private val phoneChannel = "com.nee.construction/phone"
    private val otpChannel   = "com.nee.construction/otp"

    private val phonePermCode  = 1001
    private val smsConsentCode = 1002

    private var pendingSimResult: MethodChannel.Result? = null
    private var otpEventSink: EventChannel.EventSink? = null
    private var smsConsentReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, phoneChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSimNumbers"    -> handleGetSimNumbers(result)
                    "startSmsListener" -> { startSmsUserConsent(); result.success(null) }
                    "stopSmsListener"  -> { unregisterSmsConsentReceiver(); result.success(null) }
                    else               -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, otpChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    otpEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    otpEventSink = null
                }
            })
    }

    // ── SIM numbers ────────────────────────────────────────────────────────────
    // Reads phone numbers directly from the telephony subscription info. This is
    // the reliable path — Google Play services' phone-number hint API frequently
    // returns nothing on Indian carriers (Airtel/Jio don't expose the number to
    // it), so this native lookup is tried first and the hint API is only a
    // Dart-side fallback (see phone_number_button.dart).

    private fun handleGetSimNumbers(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE)
            == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(readSimNumbers())
        } else {
            pendingSimResult = result
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.READ_PHONE_STATE),
                phonePermCode
            )
        }
    }

    private fun readSimNumbers(): List<Map<String, Any>> {
        return try {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE)
                != PackageManager.PERMISSION_GRANTED
            ) return emptyList()

            val subManager = getSystemService(SubscriptionManager::class.java) ?: return emptyList()
            val subs = subManager.activeSubscriptionInfoList ?: return emptyList()

            subs.filter { !it.number.isNullOrBlank() }
                .map { sub ->
                    mapOf(
                        "number"  to sub.number,
                        "slot"    to sub.simSlotIndex,
                        "carrier" to (sub.carrierName?.toString() ?: "SIM ${sub.simSlotIndex + 1}")
                    )
                }
        } catch (e: Exception) {
            emptyList()
        }
    }

    // ── OTP via SMS User Consent API ────────────────────────────────────────────
    // No READ_SMS/RECEIVE_SMS permission needed — Play services shows a one-time
    // system prompt ("Allow [app] to read this message?") for the next incoming
    // SMS, and only hands over the message body if the user taps Allow.

    private fun startSmsUserConsent() {
        unregisterSmsConsentReceiver()

        SmsRetriever.getClient(this).startSmsUserConsent(null)

        smsConsentReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action != SmsRetriever.SMS_RETRIEVED_ACTION) return
                val extras = intent.extras ?: return
                val status = extras.get(SmsRetriever.EXTRA_STATUS) as? Status ?: return
                if (status.statusCode == CommonStatusCodes.SUCCESS) {
                    val consentIntent = extras.getParcelable<Intent>(SmsRetriever.EXTRA_CONSENT_INTENT)
                    try {
                        consentIntent?.let { startActivityForResult(it, smsConsentCode) }
                    } catch (e: Exception) {
                        // Consent screen unavailable — user can still type the OTP manually.
                    }
                }
            }
        }
        val filter = IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(smsConsentReceiver, filter, SmsRetriever.SEND_PERMISSION, null, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(smsConsentReceiver, filter, SmsRetriever.SEND_PERMISSION, null)
        }
    }

    private fun unregisterSmsConsentReceiver() {
        smsConsentReceiver?.let {
            try { unregisterReceiver(it) } catch (_: Exception) {}
            smsConsentReceiver = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != smsConsentCode) return

        if (resultCode == Activity.RESULT_OK && data != null) {
            val message = data.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE)
            val otp = message?.let {
                val matcher = Pattern.compile("\\b(\\d{6})\\b").matcher(it)
                if (matcher.find()) matcher.group(1) else null
            }
            otp?.let { otpEventSink?.success(it) }
        }
        // RESULT_CANCELED (user tapped Deny/dismissed) — fall through silently,
        // the user can still type the OTP manually.
        unregisterSmsConsentReceiver()
    }

    // ── Permission results ─────────────────────────────────────────────────────

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == phonePermCode) {
            val result = pendingSimResult.also { pendingSimResult = null }
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            result?.success(if (granted) readSimNumbers() else emptyList<Any>())
        }
    }

    override fun onDestroy() {
        unregisterSmsConsentReceiver()
        super.onDestroy()
    }
}
