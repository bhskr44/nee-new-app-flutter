package in.complit.neep

import android.content.Intent
import com.truecaller.android.sdk.ITrueCallback
import com.truecaller.android.sdk.TrueError
import com.truecaller.android.sdk.TrueProfile
import com.truecaller.android.sdk.TruecallerSDK
import com.truecaller.android.sdk.TruecallerSdkScope
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), ITrueCallback {

    private val CHANNEL = "com.nee.construction/truecaller"
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize TrueCaller SDK — app key is read from AndroidManifest meta-data
        val scope = TruecallerSdkScope.Builder(this, this)
            .sdkOptions(TruecallerSdkScope.SDK_OPTION_WITHOUT_OTP)
            .consentMode(TruecallerSdkScope.CONSENT_MODE_BOTTOMSHEET)
            .loginTextPrefix(TruecallerSdkScope.LOGIN_TEXT_PREFIX_TO_GET_STARTED)
            .loginTextSuffix(TruecallerSdkScope.LOGIN_TEXT_SUFFIX_PLEASE_VERIFY)
            .ctaTextPrefix(TruecallerSdkScope.CTA_TEXT_PREFIX_USE)
            .buttonShapeOptions(TruecallerSdkScope.BUTTON_SHAPE_ROUNDED)
            .footerType(TruecallerSdkScope.FOOTER_TYPE_SKIP)
            .consentTitleOption(TruecallerSdkScope.SDK_CONSENT_TITLE_LOG_IN)
            .build()
        TruecallerSDK.init(scope)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(TruecallerSDK.getInstance().isUsable)
                    "getProfile"  -> {
                        if (!TruecallerSDK.getInstance().isUsable) {
                            result.error("NOT_USABLE", "TrueCaller not available", null)
                            return@setMethodCallHandler
                        }
                        pendingResult = result
                        TruecallerSDK.getInstance().getUserProfile(this)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── ITrueCallback ──────────────────────────────────────────────────────────

    override fun onSuccessProfileShared(profile: TrueProfile) {
        pendingResult?.success(
            mapOf(
                "phone"        to (profile.phoneNumber ?: ""),
                "name"         to ("${profile.firstName.orEmpty()} ${profile.lastName.orEmpty()}".trim()),
                "email"        to (profile.email ?: ""),
                "access_token" to (profile.accessToken ?: ""),
            )
        )
        pendingResult = null
    }

    override fun onFailureProfileShared(error: TrueError) {
        val code = when (error.errorType) {
            TrueError.ERROR_TYPE_USER_CANCELLED -> "USER_CANCELLED"
            else -> "TC_ERROR_${error.errorType}"
        }
        pendingResult?.error(code, "TrueCaller error: ${error.errorType}", null)
        pendingResult = null
    }

    override fun onVerificationRequired(error: TrueError?) {
        pendingResult?.error("VERIFICATION_REQUIRED", "Manual OTP verification needed", null)
        pendingResult = null
    }

    // ── Activity result (required by TrueCaller SDK) ───────────────────────────

    @Suppress("OVERRIDE_DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (TruecallerSDK.getInstance().isUsable) {
            TruecallerSDK.getInstance().onActivityResultObtained(this, requestCode, resultCode, data)
        }
    }
}
