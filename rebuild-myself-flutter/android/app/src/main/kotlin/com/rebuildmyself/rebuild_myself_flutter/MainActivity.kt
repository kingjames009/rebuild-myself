package com.rebuildmyself.rebuild_myself_flutter

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PHONE_CHANNEL = "com.rebuildmyself/phone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PHONE_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getPhoneNumber") {
                val phone = getPhoneNumber()
                if (phone != null) {
                    result.success(phone)
                } else {
                    result.error("UNAVAILABLE", "Phone number not available", null)
                }
            } else if (call.method == "hasPermission") {
                result.success(hasPhonePermission())
            } else if (call.method == "requestPermission") {
                requestPhonePermission()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun hasPhonePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_NUMBERS) == PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestPhonePermission() {
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Manifest.permission.READ_PHONE_NUMBERS
        } else {
            Manifest.permission.READ_PHONE_STATE
        }
        ActivityCompat.requestPermissions(this, arrayOf(permission), 1001)
    }

    private fun getPhoneNumber(): String? {
        if (!hasPhonePermission()) return null
        return try {
            val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
            val number = tm.line1Number
            if (number.isNullOrEmpty()) null else number
        } catch (e: Exception) {
            null
        }
    }
}
