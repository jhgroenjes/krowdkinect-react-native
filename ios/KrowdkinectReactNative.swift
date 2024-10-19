import Foundation
import SwiftUI
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
      
         // Convert to KKOptions Object
        let kkOptions = KKOptions(apiKey: apiKey, deviceID: deviceID, displayName: displayName,
                                  displayTagline: displayTagline, homeAwayHide: homeAwayHide,
                                  seatNumberEditHide: seatNumberEditHide, homeAwaySelection: homeAwaySelection)
        
        //DispatchQueue.main.async {
        //    let alert = UIAlertController(title: "KKOptions", message: """
        //        API Key: \(apiKey)
        //        Device ID: \(deviceID)
        //        Display Name: \(displayName)
        //        Display Tagline: \(displayTagline)
        //        Home Away Hide: \(homeAwayHide)
        //        Seat Number Edit Hide: \(seatNumberEditHide)
        //        Home Away Selection: \(homeAwaySelection)
        //    """, preferredStyle: .alert)
        //    
         //   alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
         //   
         //   if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
         //       rootVC.present(alert, animated: true, completion: nil)
        //    }
       // }

        // Get the current root view controller
        DispatchQueue.main.async {
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                KrowdKinectSDK.launch(from: rootViewController, with: kkOptions)
            } else {
                print("Root view controller not found.")
            }
        }
    }
    
    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
}


public class FullScreenViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    var options: KKOptions?
   
    
    public init(options: KKOptions) {
        self.options = options
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        guard let options = self.options else { return }
        let contentView = ContentView(options: options)  // Pass host app options to ContentView
        let hostingController = UIHostingController(rootView: contentView)

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Create and add the close button (X) in the upper-right corner
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("X", for: .normal)
        closeButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
        closeButton.setTitleColor(.black, for: .normal)  // Set the color of "X"
        
        // Set up circular white background
        closeButton.backgroundColor = .white
        closeButton.layer.cornerRadius = 20
        closeButton.layer.masksToBounds = true
        
        // Adjust size to create padding around the "X"
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        // Position the close button in the upper-right corner
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),  // Width for the circular button
            closeButton.heightAnchor.constraint(equalToConstant: 40)  // Height for the circular button
        ])
        
        // Add action to close button
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        // Set the presentation controller delegate
        self.presentationController?.delegate = self
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override public var shouldAutorotate: Bool {
        return false
    }
    
    // Close button action
    @objc private func closeButtonTapped() {
        presentExitConfirmation()
    }
    
    private func presentExitConfirmation() {
        let alertController = UIAlertController(title: "Confirm Exit", message: "Do you really want to exit?", preferredStyle: .alert)
        
        // Cancel Action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        // Exit Action
        let exitAction = UIAlertAction(title: "Exit", style: .destructive) { _ in
            self.dismiss(animated: true, completion: nil)
            //self.session.disconnectFromAbly()
            //print ("Ably connection closed via Exit button action")
        }
        
        
        
        alertController.addAction(cancelAction)
        alertController.addAction(exitAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Disable the down-swipe gesture to dismiss the view
    public func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
   
    
}



public class KrowdKinectSDK {
   
    public static func launch(from viewController: UIViewController, with options: KKOptions) {
        let fullScreenVC = FullScreenViewController(options: options)
        fullScreenVC.modalPresentationStyle = .fullScreen
        viewController.present(fullScreenVC, animated: true, completion: nil)
    }
}

