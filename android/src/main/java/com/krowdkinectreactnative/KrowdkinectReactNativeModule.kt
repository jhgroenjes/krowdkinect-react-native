package com.krowdkinectreactnative

//import android.content.Intent
//import android.content.Context
//import android.util.Log
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap

class KrowdkinectReactNative(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String {
        return "KrowdkinectReactNative"
    }

//data class KKOptions(
//    val apiKey: String, // required
//    val deviceID: Int = 1,
//    val displayName: String? = null,
//    val displayTagline: String? = null,
//    val homeAwayHide: Boolean = true,
//    val seatNumberEditHide: Boolean = true,
//    val homeAwaySelection: String = "All"
//)

    @ReactMethod
    fun launch(options: ReadableMap) {
        val activity = currentActivity
        if (activity != null) {
            try {
                // Convert ReadableMap to KKOptions
              //  val kkOptions = KKOptions(
                
                val apiKey = options.getString("apiKey") ?: throw IllegalArgumentException("API Key is required")
                val deviceIDInt = options.getInt("deviceID")
                val deviceID = deviceIDInt.toUInt() // Convert to UInt
                val displayName = options.getString("displayName") ?: "Default Name"
                val displayTagline = options.getString("displayTagline") ?: "Default Tagline"
                val homeAwayHide = options.getBoolean("homeAwayHide")
                val seatNumberEditHide = options.getBoolean("seatNumberEditHide")
                val homeAwaySelection = options.getString("homeAwaySelection") ?: "All"

               // )

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
