import Foundation
import UIKit

@objc(KrowdkinectReactNative)
class KrowdkinectReactNative: NSObject {

    @objc
    func launch(_ options: NSDictionary) {
        guard let apiKey = options["apiKey"] as? String,
              let deviceID = options["deviceID"] as? Int,
              let displayName = options["displayName"] as? String,
              let displayTagline = options["displayTagline"] as? String,
              let homeAwayHide = options["homeAwayHide"] as? Bool,
              let seatNumberEditHide = options["seatNumberEditHide"] as? Bool,
              let homeAwaySelection = options["homeAwaySelection"] as? String else {
            print("Invalid KKOptions received")
            return
        }
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "KKOptions", message: """
                API Key: \(apiKey)
                Device ID: \(deviceID)
                Display Name: \(displayName)
                Display Tagline: \(displayTagline)
                Home Away Hide: \(homeAwayHide)
                Seat Number Edit Hide: \(seatNumberEditHide)
                Home Away Selection: \(homeAwaySelection)
            """, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
                rootVC.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
}
