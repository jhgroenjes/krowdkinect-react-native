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

    @ReactMethod
    fun launch(options: ReadableMap) {
        val activity = currentActivity
        if (activity != null) {
            try {
                // Convert ReadableMap to KKOptions
                val apiKey = options.getString("apiKey") ?: throw IllegalArgumentException("API Key is required")
                val deviceID = options.getInt("deviceID")
                val displayName = options.getString("displayName") ?: "Default Name"
                val displayTagline = options.getString("displayTagline") ?: "Default Tagline"
                val homeAwayHide = options.getBoolean("homeAwayHide")
                val seatNumberEditHide = options.getBoolean("seatNumberEditHide")
                val homeAwaySelection = options.getString("homeAwaySelection") ?: "All"

         

                // Create the Intent to launch KrowdKinectActivity
                //val intent = Intent(activity, KrowdKinectActivity::class.java)
                //intent.putExtra("apiKey", kkOptions.apiKey)
                //intent.putExtra("deviceID", kkOptions.deviceID)
                //intent.putExtra("displayName", kkOptions.displayName)
                //intent.putExtra("displayTagline", kkOptions.displayTagline)
                //intent.putExtra("homeAwayHide", kkOptions.homeAwayHide)
                //intent.putExtra("seatNumberEditHide", kkOptions.seatNumberEditHide)
                //intent.putExtra("homeAwaySelection", kkOptions.homeAwaySelection)

                //activity.startActivity(intent)

                KrowdKinectActivity.start(activity, apiKey, deviceID, displayName, displayTagline, homeAwayHide, seatNumberEditHide, homeAwaySelection)

            } catch (e: IllegalArgumentException) {
                Log.e("KrowdKinect-react-native", "Error: ${e.message}")
            }
        } else {
            Log.e("KrowdKinect-react-native", "Current activity is null")
        }
    }
}
