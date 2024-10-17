package com.krowdkinectreactnative

import android.content.Intent
import android.content.Context
import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap

class KrowdkinectReactNative(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String {
        return "KrowdkinectReactNative"
    }

data class KKOptions(
    val apiKey: String, // required
    val deviceID: Int = 1,
    val displayName: String? = null,
    val displayTagline: String? = null,
    val homeAwayHide: Boolean = true,
    val seatNumberEditHide: Boolean = true,
    val homeAwaySelection: String = "All"
)

    @ReactMethod
    fun launch(options: ReadableMap) {
        val activity = currentActivity
        if (activity != null) {
            try {
                // Convert ReadableMap to KKOptions
                val kkOptions = KKOptions(
                    apiKey = options.getString("apiKey") ?: throw IllegalArgumentException("API Key is required"),
                    deviceID = options.getInt("deviceID"),
                    displayName = if (options.hasKey("displayName")) options.getString("displayName") else null,
                    displayTagline = if (options.hasKey("displayTagline")) options.getString("displayTagline") else null,
                    homeAwayHide = if (options.hasKey("homeAwayHide")) options.getBoolean("homeAwayHide") else true,
                    seatNumberEditHide = if (options.hasKey("seatNumberEditHide")) options.getBoolean("seatNumberEditHide") else true,
                    homeAwaySelection = if (options.hasKey("homeAwaySelection")) options.getString("homeAwaySelection") ?: "All" else "All"
                )

                // Create the Intent to launch KrowdKinectActivity
                val intent = Intent(activity, KrowdKinectActivity::class.java)
                intent.putExtra("apiKey", kkOptions.apiKey)
                intent.putExtra("deviceID", kkOptions.deviceID)
                intent.putExtra("displayName", kkOptions.displayName)
                intent.putExtra("displayTagline", kkOptions.displayTagline)
                intent.putExtra("homeAwayHide", kkOptions.homeAwayHide)
                intent.putExtra("seatNumberEditHide", kkOptions.seatNumberEditHide)
                intent.putExtra("homeAwaySelection", kkOptions.homeAwaySelection)

                activity.startActivity(intent)
            } catch (e: IllegalArgumentException) {
                Log.e("KrowdKinect-react-native", "Error: ${e.message}")
            }
        } else {
            Log.e("KrowdKinect-react-native", "Current activity is null")
        }
    }
}
