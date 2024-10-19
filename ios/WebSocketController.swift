

import SwiftUI
import os
import CoreMotion
import Foundation
import Network
import Combine
import AVFoundation
import Ably

// setting up the struct that will contain all the var's that the Host app can update
public struct KKOptions {
    public var apiKey: String?
    public var deviceID: UInt32
    public var displayName: String = "Default Name"
    public var displayTagline: String = "Default Tagline"
    public var homeAwayHide: Bool = false
    public var seatNumberEditHide: Bool = false
    public var homeAwaySelection: String = "All"
    
    public init(apiKey: String? = nil,
                deviceID: UInt32 = 1,
                displayName: String = "",
                displayTagline: String = "",
                homeAwayHide: Bool = true,
                seatNumberEditHide: Bool = true,
                homeAwaySelection: String = "All") {
        self.apiKey = apiKey
        self.deviceID = deviceID
        self.displayName = displayName
        self.displayTagline = displayTagline
        self.homeAwayHide = homeAwayHide
        self.seatNumberEditHide = seatNumberEditHide
        self.homeAwaySelection = homeAwaySelection
    }
}


// CUT-PASTE from KrowdKinect start 1 ############################################################
public class WebSocketController: ObservableObject {
    //  ***********  Vars in the pixelArray (9, 16-bit Values)  ************ //
    var seed : UInt16 = 1
    var masterRows : UInt16 = 0
    var masterCols : UInt16 = 0
    var screenRows : UInt16 = 0
    var screenCols : UInt16 = 0
    var calcPacketsRemain : UInt16 = 0
    var startPixel : UInt16 = 1
    var endPixel : UInt16 = 4
    @Published var BPM : UInt16 = 120
    //  ******************************************************************** //

    //  **********  Vars in the featuresArray  (14, 8-bit Values) ********** //
    @Published var surfaceR : UInt8 = 255
    @Published var surfaceG : UInt8 = 0
    @Published var surfaceB : UInt8 = 0
    @Published public var torchBrightness : CGFloat = 1.0
    var flashlightStatus : UInt8 = 0  // 1=Off, 2=On, 3=Strobe 1x, 4=Strobe 2x, ... 27=Strobe 25x
    var white2Flash : UInt8 = 0 //  0..254=Off, 255=On
    var motionTrigger : UInt8 = 0   //  0=disable, 1..255 see protocol documentation
    @Published var homeAwayZone : UInt8 = 0   //  0 = both (ignores this setting)  1 = Home Devices Only   2 = Away Devcies Only
    var randomClientStrobe : UInt8 = 0   //  0..254=Off,  255=On (flash)
    var audioSync : UInt8 = 0   //  future use
    var feature4 : UInt8 = 0   //  future use
    var feature5 : UInt8 = 0   //  future use
    var ablyDisconnect : UInt8 = 0   //  0-254=allows connections, 255=ForceDisconnect
    //  ******************************************************************** //

    // additional vars used by client, but not sent in packets from the first 32 bytes
    @Published public var red : CGFloat = 0.0
    @Published public var green : CGFloat = 0.0
    @Published public var blue : CGFloat = 0.0
    var vDevID : UInt32 = 0  // this is the deviceID used when this device is told to be part of the Screen (not surface)
    let homeAwayChoices = ["All", "Home", "Away"]
    @Published var homeAwaySent = "All"
    var appVersion = "Ver. 0.4.0"
    var pixelArrayBytes = 18  // number of 16-bit values in this array
    var featuresArrayBytes = 14  // number of 8-bit values in this array
    var screenPixel : Bool = false  // tells the device if it is screen or surface
    var viewablecolor : Color = .white  // keeps text readable, regardless of screen color
    var colorsum : Int = 0  //  used to find readable screen text foreground color
    @Published public var online : Bool = false   //initialize to False until Ably confirms connection
    var audioPlayer: AVAudioPlayer?
    @Published public var textIsHidden = false  // state for error text to display when Ably-disconnected
    var timerBright: Timer?
    var timerColor: Timer?
    var timerCandle: Timer?

    // ********************** Setting  up  the  Arrays  *********************//
    var pixelArray : [UInt16] = []
    @Published var featuresArray: [UInt8] = Array(repeating: 0, count: 14)  // initialize all 14 entries to 0
    var colorArray : [[UInt8]] = []
    // **********************************************************************//
    private var channel: ARTRealtimeChannel?
    public var ably : ARTRealtime?
    @Published public var apiKey: String
    @Published public var deviceID: UInt32
    @Published public var displayName: String
    @Published public var displayTagline: String
    @Published public var homeAwayHide: Bool
    @Published public var seatNumberEditHide: Bool
    @Published var homeAwaySelection = "All"

// CUT-PASTE from KrowdKinect End 1 #############################################################

    
//  #############################################################################################
//  #################  Code Unique to the SDK - done differently in KrowdKinect iOS Start #######
//  #############################################################################################

    public init(options: KKOptions) {
            self.apiKey = options.apiKey ?? "Hf3iUg.5U0Azw:vnbLv80uvD3yJjT0Sgwb2ECgFCSXHAXQomrJOvwp-qk"  //Public-use Ably Key for testing
            self.deviceID = options.deviceID
            self.displayName = options.displayName
            self.displayTagline = options.displayTagline
            self.homeAwayHide = options.homeAwayHide
            self.seatNumberEditHide = options.seatNumberEditHide
        self.homeAwaySelection = options.homeAwaySelection
            setupScreenBrightness()
        } // end Init
    
       // Method to update options if needed after initialization
       func updateOptions(with options: KKOptions) {
           self.apiKey = options.apiKey ?? self.apiKey
           self.deviceID = options.deviceID
           self.displayName = options.displayName
           self.displayTagline = options.displayTagline
           self.homeAwayHide = options.homeAwayHide
           self.seatNumberEditHide = options.seatNumberEditHide
           self.homeAwaySelection = options.homeAwaySelection
       }
    
        func stopAllTimers() {
            if let timer = self.timerBright {
                timer.invalidate()
                self.timerBright = nil // Clean up the reference
            }
            if let timer = self.timerColor {
                timer.invalidate()
                self.timerColor = nil // Clean up the reference
            }
            if let timer = self.timerCandle {
                timer.invalidate()
                self.timerCandle = nil // Clean up the reference
            }
            // Add similar logic for other timers if you have more
        }
    
        func resetBrightness() {
            DispatchQueue.main.async {
                UIScreen.main.brightness = CGFloat(0.75)
        }
    }

    deinit {
        disconnectFromAbly()
       
    }
    
    func viewWillDisappear() {
       // print("view will Disappear executed")
        disconnectFromAbly()
    }
    
//  #############################################################################################
//  #################  Code Unique to the SDK - done differently in KrowdKinect iOS End #######
//  #############################################################################################

//  #############################################################################################
//  #############################################################################################
//  #############################################################################################
//   Every function below here should be exactly waht KrowdKinect standalone iOS has too.
    
    // Set the screen brightness to 100% on app launch and disable app timer
    // SAME AS KrowdKinect iOS
    func setupScreenBrightness() {
           UIScreen.main.brightness = 1
           UIApplication.shared.isIdleTimerDisabled = true
    }
    
    // SAME AS KrowdKinect iOS
    func setAPIKey(_ key: String) {
     //   if isValidApiKey(self.apiKey) {
            self.ably = ARTRealtime(key: key)
      //  } else {
      //      print("Invalid API key format initializing Realtime")
      //  }
      }
    
    // SAME AS KrowdKinect iOS
    func connectToAbly() {
        setAPIKey(self.apiKey)  // Set the API key passed from the parent
        guard let ably = ably, channel == nil else {
            print("Already connected to KrowdKinect Service")
            return
        }
        
        // Set up connection handler with error handling inside the callback
        ably.connection.on { [weak self] stateChange in
            guard let self = self else { return }
            switch stateChange.current {
            case .connected:
                self.online = true
                print("Connected to KrowdKinect Cloud Services!")
            case .failed:
                print("Failed to connect to KrowdKinect Service!")
                self.handleConnectionFailure()
            default:
                break
            }
            self.setupReceiveHandler()
        }
    }

    // Specific to SDK - error handling
    func handleConnectionFailure() {
        print("Error in connection.  Check the apiKey format.")
    }
    
    // SAME AS KrowdKinect iOS
    func disconnectFromAbly() {
          channel?.unsubscribe()
          ably?.connection.close()
          channel = nil
          online = false
          print("Disconnected from Ably via Master func.")
    }
    
    
    // SAME AS KrowdKinect iOS
    func setupReceiveHandler() {
        //  Connect to the WebSockets Server
        let channel = ably!.channels.get("KrowdKinect")
        channel.subscribe("kkdata") { message in
            self.handleIncomingMessage(message)
        }
    }
    
    // SAME AS KrowdKinect iOS
    func handleIncomingMessage(_ message: ARTMessage) {
        // +++++++++ C H E C K  Website Demo packet  ++++++++++++++
        //Let's immediately do a check to see if the "extras" channel tag from ably's websocket message is empty.
        //  if it's NOT, that means a website mesage came in, so we just pick a random color for demonstration.
        if (message.extras != nil) {
            print ("DEMO Message received! from www.krowdkinect.com")
            self.red = CGFloat(arc4random_uniform(255)) / 255.0
            self.green = CGFloat(arc4random_uniform(255)) / 255.0
            self.blue = CGFloat(arc4random_uniform(255)) / 255.0
        } else {
            //set a data variable to the unwrapped binary payload from the WS server
            let data = message.data as! Data
            self.processZoneInfo(data)
        }
    }
     
    // SAME AS KrowdKinect iOS
    func processZoneInfo(_ data: Data) {
        //----------------------------------------------------
        //------   Stop any previously-running timers  -------
        //----------------------------------------------------
        self.timerColor?.invalidate()
        self.timerColor = nil
        self.timerBright?.invalidate()
        self.timerBright = nil
        self.timerCandle?.invalidate()
        self.timerCandle = nil
        
        //----------------------------------------------------
        //-------  pixelArray & featuresArray Parsed  --------
        //----------------------------------------------------
        //clean out the arrays first
        if self.pixelArray.isEmpty == false {self.pixelArray.removeAll() }
        if self.featuresArray.isEmpty == false {self.featuresArray.removeAll() }
        
        // parse out pixelArray, which is 9, 16-bit values at the start of the data packet
        for i in stride(from: 0, to: self.pixelArrayBytes, by: 2) {
            let value = data.subdata(in: i..<i+2).withUnsafeBytes { $0.load(as: UInt16.self) }
            self.pixelArray.append(value)
        } // end for
        
        // Now featuresArray, which is the 14, 8-bit bytes that follow in the data packet
        for i in stride(from: 18, to: self.featuresArrayBytes + self.pixelArrayBytes, by: 1) {
            let value = data.subdata(in: i..<i+1).withUnsafeBytes { $0.load(as: UInt8.self) }
            self.featuresArray.append(value)
        }
        print (self.pixelArray)
        print (self.featuresArray)
        
        //----------------------------------------------------
        //------------   Determine Zone First   --------------
        //----------------------------------------------------
        switch self.featuresArray[8] {
        case 0:
            self.homeAwaySent = "All"
        case 1:
            self.homeAwaySent = "Home"
        case 2:
            self.homeAwaySent = "Away"
        default:
            self.homeAwaySent = "All"
        }
        // check to see if this message should continue to be processed based on zone
        if self.homeAwaySent == "All" || self.homeAwaySent == self.homeAwaySelection {
            continueMessageProcessing(data)
        }
    } // end func processZoneInfo
                
    // SAME AS KrowdKinect iOS
    func continueMessageProcessing(_ data: Data) {
                    //----------------------------------------------------
                    //------   Set Screen/Torch Brightness [3]  ----------
                    //----------------------------------------------------
                    let brightnessValue = Int(self.featuresArray[3])
                    let brightness = CGFloat(min(max(brightnessValue, 1), 10)) * 0.1
                    UIScreen.main.brightness = brightness
                    self.torchBrightness = brightness
                    torchIntensity(intensity: self.torchBrightness)
                    
                    //----------------------------------------------------
                    //------  Motion trigger: Rdm color flash [7]=1 ------
                    //----------------------------------------------------
                    if self.featuresArray[7] == 1 {
                        if self.timerColor == nil {
                            let interval = 60.0 / Double(self.pixelArray[8])  //flash at BPM rate
                            // Start a timer that repeats indefinitely
                            self.timerColor = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                                self?.red = CGFloat(Int.random(in: 0...255))/255
                                self?.green = CGFloat(Int.random(in: 0...255))/255
                                self?.blue = CGFloat(Int.random(in: 0...255))/255
                            }
                        }
                    }
                    
                    //----------------------------------------------------
                    //------  Motion trigger: Brightness  [7]=2 ----------
                    //----------------------------------------------------
                    if self.featuresArray[7] == 2 {
                        if self.timerBright == nil {
                            let interval = 60.0 / Double(self.pixelArray[8])  //vary brightness at BPM rate
                            // Start a timer that repeats indefinitely
                            self.timerBright = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                                DispatchQueue.main.async {
                                    UIScreen.main.brightness = CGFloat.random(in: 0.0...1.0)
                                    self.torchBrightness = CGFloat.random(in: 0.0...1.0)
                                    self.torchIntensity(intensity: self.torchBrightness)
                                }
                            }
                        }
                    } // end if featuresArray
                    
                    //----------------------------------------------------
                    //------  Motion trigger: Candle Ficker [7]=4 --------
                    //----------------------------------------------------
                    if self.featuresArray[7] == 4 {
                        if self.timerCandle == nil {
                            let interval = 0.5   // flicker with new target level every 1/2 second
                            // Randomly select a new target intensity level
                            var torchIntensityPrior: Float  = 0.3  // initial chosen intensity
                            // Start a timer that repeats indefinitely - changing the LED every second.
                            self.timerBright = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
                                DispatchQueue.main.async {
                                    let randomTargetIntensity = Float.random(in: 0.03...0.35)
                                    let intensityDelta = randomTargetIntensity - torchIntensityPrior
                                    let step = intensityDelta / 20   // 0.5sec is the duration to reach next intensity
                                    // Start a timer to gradually change the torch intensity
                                    let randomSteps = Double.random(in: 0...20)
                                    self.timerCandle = Timer.scheduledTimer(withTimeInterval: 1.0/randomSteps, repeats: true) { timer in
                                        withAnimation {
                                            torchIntensityPrior += step
                                        }
                                        if abs(torchIntensityPrior - randomTargetIntensity) <= 0.01 {
                                            // Close enough to the target, stop the timer
                                            timer.invalidate()
                                            self.timerCandle?.invalidate()
                                            self.timerCandle = nil
                                        } // end IF
                                        self.torchBrightness = CGFloat(torchIntensityPrior)
                                        self.torchIntensity(intensity: self.torchBrightness)
                                    } // end Timer for Candle incremental changes.
                                } // end DIspatch Queue
                            }  // end TimerBright
                        } // end TimerCandle
                    } // end if featuresArray[7] == 4
                    
                    
                    //----------------------------------------------
                    //------   AUDIO Playback Features [6]  --------
                    //----------------------------------------------
                    // functions below extablish the Sync'ed Audio client Playtback structure
                    func playAudioWhenSecondsDivisibleBy5(audioURL: URL) {
                        // Get the current time
                        let currentDate = Date()
                        // Extract the seconds and milliseconds components
                        let calendar = Calendar.current
                        let currentSeconds = calendar.component(.second, from: currentDate)
                        let currentNanoseconds = calendar.component(.nanosecond, from: currentDate)
                        // Calculate the remaining milliseconds in the current second
                        let millisecondsToNextSecond = (1_000_000_000 - currentNanoseconds) / 1_000_000
                        // Calculate the seconds to wait until the next second divisible by 5
                        let secondsToWait = (5 - (currentSeconds % 5)) % 5
                        // Calculate the total time to wait including milliseconds
                        let totalTimeToWait = TimeInterval(secondsToWait) + TimeInterval(millisecondsToNextSecond) / 1000.0
                        // Delay the audio playback
                        DispatchQueue.main.asyncAfter(deadline: .now() + totalTimeToWait) {
                            playAudio(url: audioURL)
                        }
                    }
                    
                    func playAudio(url: URL) {
                        do {
                            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                            self.audioPlayer!.play()
                            print("SYNCED Audio playback started!")
                        } catch {
                            print("Failed to play audio: \(error.localizedDescription)")
                        }
                    }
                    // process audio playback code if featuresArray[6] is non zero
                    if self.featuresArray[6] != 0 {
                        let audioQueue = DispatchQueue.global(qos: .background)  // sets up a global background queue for playing audio.
                        let soundMapping: [UInt8: (String, Float)] = [
                            // the float var is the volume the audio will be played back at
                            1: ("KK-police", 0.2),
                            2: ("Air-raid-siren", 0.2),
                            3: ("Audience", 0.2),
                            4: ("Rain-37", 0.2),
                            5: ("Wolf", 0.2),
                            6: ("Fire", 0.2),
                            7: ("Wind", 0.2),
                            8: ("metronome", 0.2),
                            84: ("KK-police", 0.5),
                            85: ("Air-raid-siren", 0.5),
                            86: ("Audience", 0.5),
                            87: ("Rain-37", 0.5),
                            88: ("Wolf", 0.5),
                            89: ("Fire", 0.5),
                            90: ("Wind", 0.5),
                            91: ("metronome", 0.5),
                            167: ("KK-police", 1.0),
                            168: ("Air-raid-siren", 1.0),
                            169: ("Audience", 1.0),
                            170: ("Rain-37", 1.0),
                            171: ("Wolf", 1.0),
                            172: ("Fire", 1.0),
                            173: ("Wind", 1.0),
                            174: ("metronome", 1.0)
                        ]
                        
                        func playSound(for feature: UInt8) {
                            if let sound = soundMapping[feature] {
                                let fileExtension = sound.0.contains(".m4a") ? "m4a" : "mp3"
                                let fileName = sound.0.replacingOccurrences(of: ".\(fileExtension)", with: "")
                                let podBundle = Bundle(for: WebSocketController.self)
                                if let url = podBundle.url(forResource: fileName, withExtension: fileExtension) {
                                    print("Playing audio file at: \(url)")
                                    do {
                                        // check to see if this audio playback was to be 5-second sync playback
                                        if self.featuresArray[10] == 255 {
                                            playAudioWhenSecondsDivisibleBy5(audioURL: url)
                                        } else {
                                            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                                            self.audioPlayer!.setVolume(sound.1, fadeDuration: 1.0)
                                            audioQueue.async {
                                                self.audioPlayer!.play()
                                            }
                                        }
                                    } catch {
                                        print("audio player couldn't play: \(error)")
                                    }
                                } else {
                                    print("Audio file \(fileName).\(fileExtension) not found in bundle.")
                                }
                            } else if feature == 254 {
                                self.audioPlayer?.stop()
                            }
                            self.featuresArray[6] = 0
                        } // end func playSound
                        
                        playSound(for: self.featuresArray[6])
                    } // end if featuresArray[6] != 0 check
                    
                    //----------------------------------------------
                    //------   Assign pixelArray Elements ----------
                    //----------------------------------------------
                    self.seed = self.pixelArray[0]
                    self.masterRows = self.pixelArray[1]
                    self.masterCols = self.pixelArray[2]
                    self.screenRows = self.pixelArray[3]
                    self.screenCols = self.pixelArray[4]
                    self.calcPacketsRemain = self.pixelArray[5]
                    self.startPixel = self.pixelArray[6]
                    self.endPixel = self.pixelArray[7]
                    self.BPM = self.pixelArray[8]
                    
                    
                    //----------------------------------------------
                    //------   Assign featuresArray Elements -------
                    //----------------------------------------------
                    self.surfaceR = self.featuresArray[0]
                    self.surfaceG = self.featuresArray[1]
                    self.surfaceB = self.featuresArray[2]
                    // self.brightness = self.featuresArray[3]  brightness parsed out above already
                    self.flashlightStatus = self.featuresArray[4]
                    self.white2Flash = self.featuresArray[5]
                    // self.audioPlayback = self.featuresArray[6]  audio Byte.  parsed out above already
                    self.motionTrigger = self.featuresArray[7]
                    self.homeAwayZone = self.featuresArray[8]
                    self.randomClientStrobe = self.featuresArray[9]
                    self.audioSync = self.featuresArray[10]
                    self.feature4 = self.featuresArray[11]
                    self.feature5 = self.featuresArray[12]
                    self.ablyDisconnect = self.featuresArray[13]
                    
                    print ("PACKETS REMAINING: \(self.pixelArray[5])")
                    print ("Seed: \(self.pixelArray[0])       My DeviceID \(self.deviceID)")
                    print("Master Grid (RxC): \(self.pixelArray[1]) x \(self.pixelArray[2])")
                    print ("Screen Size (RxC): \(self.pixelArray[3]) x \(self.pixelArray[4])")
                    print ("  ")
                    //Need to first figure out it the deviceID of this device is slated to be Screen or Surface.
                    //If Surface, no need to unpack the colorArray
                    
                    //----------------------------------------------
                    //-----  R E S E T  Device ID/vDevID   ---------
                    //----------------------------------------------
                    self.screenPixel = false
                    self.vDevID = 0  //note:  0 is outside the range, which typically starts at 1.
                    
                    //----------------------------------------------
                    //------     Surface or Screen?       ----------
                    //----------------------------------------------
                    for counter in 0..<self.screenRows  {
                        if (self.deviceID >= self.seed) && (self.deviceID <= (self.seed + self.screenCols-1)) {
                            //if above is TRUE, this is a pixel in the Screen, not surface.  Get it's VDevID...
                            let additive = counter * self.screenCols
                            self.vDevID = self.deviceID - UInt32(self.seed) + 1 + UInt32(additive)
                            // print("The received Packet makes this device a Screen Pixel at Virtual Device ID: \(self.vDevID)")
                            self.screenPixel = true
                        } // end if
                        // increment seed for the next loop, which has to be based on MasterCols since the screen can be in the middle of the surface master grid
                        self.seed = self.seed + self.masterCols
                    } //end FOR LOOP
                    
                    
                    //----------------------------------------------
                    //------     colorArray Bits Parsed    ---------
                    //----------------------------------------------
                    if self.screenPixel == true {
                        // Continue parsing the rest of the data, which will ALL BE SCREEN PIXEL colors - in sequential DeviceID order
                        // Screen Pixels will come in multiple packets if total pixels > ??  64K for ably - need to work this out.
                        // clear out the array first, then reload it with the received packet.
                        self.colorArray.removeAll()
                        //get the number of pixels in screen RGB data
                        let numScreenPixels = (data.count - (self.pixelArrayBytes + self.featuresArrayBytes))/3
                        //Load the colorArray
                        self.colorArray = (0..<numScreenPixels).map { i -> [UInt8] in
                            let offset = 32 + (i * 3)
                            let r = data[offset]
                            let g = data[offset + 1]
                            let b = data[offset + 2]
                            return [r, g, b]
                        }
                    } // end if
                    
                    //----------------------------------------------
                    //------ Loop through Screen Packets  ----------
                    //----------------------------------------------
                    for packetCounter in 0...self.calcPacketsRemain {
                        print("PacketCounter loop value is: \(packetCounter)")
                        //check if vDevID is contained in the pixel data in this packet by comparing against surfaceArray[14] and [15] range
                        if self.vDevID >= self.pixelArray[6] && self.vDevID <= self.pixelArray[7]  {
                            //print ("This packet is going to assign Screen data to this device with id:  \(self.vDevID)")
                            //Now process the screen data and device screen updates if this got set as a screenPixel.
                            if self.screenPixel == true {
                                //print("Screen Pixel with vDevID \(self.vDevID)")
                                let arrayindex = UInt16(self.vDevID)  - self.startPixel   //which is also pixelArray[6]
                                self.red = CGFloat(Int(exactly: self.colorArray[Int(arrayindex)][0])!) / 255.0
                                self.green = CGFloat(Int(exactly: self.colorArray[Int(arrayindex)][1])!) / 255.0
                                self.blue = CGFloat(Int(exactly: self.colorArray[Int(arrayindex)][2])!) / 255.0
                                // Check to see if white2Flash toggle is set and light torch instead when color is 255, 255, 255
                                // if set true, the screen will contnue to take on the color as normal, but tourch will turn on too.
                                if self.featuresArray[5] == 255 && self.red == 1.0 && self.green == 1.0 && self.blue == 1.0 {
                                    //print ("White2Flash status: featureArray is \(self.featuresArray[5])   and the color is: \(self.red)  \(self.green)  \(self.blue)")
                                    self.featuresArray[4] = 2
                                    FlashLightOn(intensity: self.torchBrightness)
                                    //print ("FlashLightOn() function was just called.")
                                }
                                
                                //----------------------------------------------------
                                //--Motion trigger: SCREEN Color BPM Flickr [7]=6 ----
                                //----------------------------------------------------
                                // now Check to see if motionTrigger is set to 6 (featuresArray[7] = 6
                                if (self.featuresArray[7] == 6 || self.featuresArray[7] == 7) && self.screenPixel == true {
                                    if self.timerColor == nil {
                                        let interval = 60.0 / Double(self.pixelArray[8])  //flash at BPM rate
                                        // Start a timer that repeats indefinitely
                                        var flip = "screenColor"
                                        self.timerColor = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                                            if flip == "screenColor" {
                                                self?.red = CGFloat(Int(exactly: self?.colorArray[Int(arrayindex)][0] ?? 1)!) / 255.0
                                                self?.green = CGFloat(Int(exactly: self?.colorArray[Int(arrayindex)][1] ?? 1)!) / 255.0
                                                self?.blue = CGFloat(Int(exactly: self?.colorArray[Int(arrayindex)][2] ?? 1)!) / 255.0
                                                flip = "backColor"
                                            } else {
                                                // flicker at BPM between black and the Surface color
                                                self?.red = 0.0
                                                self?.green = 0.0
                                                self?.blue = 0.0
                                                flip = "screenColor"
                                            }
                                        }
                                    }
                                } // end if featuresArray check
                                
                                //set some variables to make the text on the main UIscreen readable all the time
                                self.colorsum = Int((Double(self.colorArray[Int(arrayindex)][0]) * 0.213))
                                self.colorsum = self.colorsum + Int((Double(self.colorArray[Int(arrayindex)][1]) * 0.715))
                                self.colorsum = self.colorsum + Int((Double(self.colorArray[Int(arrayindex)][2]) * 0.072))
                                if self.colorsum >= Int(127.5) { self.viewablecolor = .black} else {self.viewablecolor = .white}
                            } // end if ScreenPixel = True check
                        } // end IF to vDevID check
                    } // end OUTTER for loop that loops on multiple packets
                    
                    
                    //----------------------------------------------
                    //------   Flashlight MODE Features   ----------
                    //----------------------------------------------
                    if self.featuresArray[9] != 255 {   // check to see if randomClientStrobe is on
                        switch self.featuresArray[4] {  // parse through the  flashlight Mode options.
                        case 1:
                            FlashLightOff()
                        case 2:
                            FlashLightOn(intensity: self.torchBrightness)
                        case 3...27:
                            var runCount = 0
                            let flashRate = (30 / Double(self.BPM))
                            Timer.scheduledTimer(withTimeInterval: flashRate, repeats: true) { timer in
                                self.toggleFlashLight(intensity: self.torchBrightness)
                                runCount += 1
                                if runCount == (self.featuresArray[4] - 2) * 2 {
                                    timer.invalidate()
                                }
                            }
                        default:
                            FlashLightOff()
                        } // end Switch
                    } else {
                        let strobeOrNot = Int.random(in:0...3)  // 25% chance to run
                        if strobeOrNot == 3 {
                            switch self.featuresArray[4] {
                            case 1:
                                FlashLightOff()
                            case 2:
                                self.timerBright = nil
                                self.timerCandle?.invalidate()
                                self.timerCandle = nil
                                FlashLightOn(intensity: self.torchBrightness)
                            case 3...27:
                                var runCount = 0
                                let flashRate = (30 / Double(self.BPM))
                                Timer.scheduledTimer(withTimeInterval: flashRate, repeats: true) { timer in
                                    self.toggleFlashLight(intensity: self.torchBrightness)
                                    runCount += 1
                                    if runCount == (self.featuresArray[4] - 2) * 2 {
                                        timer.invalidate()
                                    }
                                }
                            default:
                                FlashLightOff()
                            } // end Switch
                        } // end if
                    } // end else
                    
                    
                    //----------------------------------------------
                    //------   S U R F A C E  Color Set   ----------
                    //----------------------------------------------
                    if self.screenPixel == false {
                        //update the variable to set the text color so that it's readable regardless of surface color
                        self.colorsum = Int((Double(self.featuresArray[0]) * 0.213))
                        self.colorsum = self.colorsum + Int((Double(self.featuresArray[1]) * 0.715))
                        self.colorsum = self.colorsum + Int((Double(self.featuresArray[2]) * 0.072))
                        if self.colorsum >= Int(127.5) { self.viewablecolor = .black} else {self.viewablecolor = .white}
                        // and set the RGB colors for surface
                        self.red = CGFloat(Int(exactly: self.featuresArray[0])!) / 255.0
                        self.green = CGFloat(Int(exactly: self.featuresArray[1])!) / 255.0
                        self.blue = CGFloat(Int(exactly: self.featuresArray[2])!) / 255.0
                        //----------------------------------------------------
                        //--Motion trigger: SURFACE Color BPM Flick [7]=5 ----
                        //----------------------------------------------------
                        if (self.featuresArray[7] == 5 || self.featuresArray[7] == 7) && self.screenPixel == false {
                            if self.timerColor == nil {
                                let interval = 60.0 / Double(self.pixelArray[8])  //flash at BPM rate
                                // Start a timer that repeats indefinitely
                                var flip = "surfaceColor"
                                self.timerColor = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                                    if flip == "surfaceColor" {
                                        self?.red = CGFloat(self?.featuresArray[0] ?? 1) / 255.0
                                        self?.green = CGFloat(self?.featuresArray[1] ?? 1) / 255.0
                                        self?.blue = CGFloat(self?.featuresArray[2] ?? 1) / 255.0
                                        flip = "backColor"
                                    } else {
                                        // flicker at BPM between black and the Surface color
                                        self?.red = 0.0
                                        self?.green = 0.0
                                        self?.blue = 0.0
                                        flip = "surfaceColor"
                                    }
                                }
                            }
                        }  // end if featuresArray[7] check
                    }  // end IF for Surface Pixel set
                    
                    
                    //----------------------------------------------------
                    //------  See if Force-Close-Ably was sent  ----------
                    //----------------------------------------------------
                    if self.featuresArray[13] == 255 {  //  255 is force close websocket connection
                        self.disconnectFromAbly()
                        self.textIsHidden.toggle()
                        print ("Received Command to disconnect from ably - mode 255")
                    } // end if
    } // end func continueMessageProcessing
    
    // SAME AS KrowdKinect iOS
    func toggleFlashLight(intensity : CGFloat) {
            guard let device = AVCaptureDevice.default(for: AVMediaType.video),
                  device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                switch intensity {
                    case 0.00000...0.10000:
                        try device.setTorchModeOn(level: 0.1)
                    case 0.10001...0.20000:
                        try device.setTorchModeOn(level: 0.2)
                    case 0.20001...0.30000:
                        try device.setTorchModeOn(level: 0.3)
                    case 0.30001...0.40000:
                        try device.setTorchModeOn(level: 0.4)
                    case 0.40001...0.50000:
                        try device.setTorchModeOn(level: 0.5)
                    case 0.50001...0.60000:
                        try device.setTorchModeOn(level: 0.6)
                    case 0.60001...0.70000:
                        try device.setTorchModeOn(level: 0.7)
                    case 0.70001...0.80000:
                        try device.setTorchModeOn(level: 0.8)
                    case 0.80001...0.90000:
                        try device.setTorchModeOn(level: 0.9)
                    case 0.90001...1.00000:
                        try device.setTorchModeOn(level: 1.0)
                    default:
                        try device.setTorchModeOn(level: 1.0)
                }  // end Switch
                withAnimation(Animation.linear(duration: 2.0)) {
                    device.torchMode = device.isTorchActive ? .off : .on
                }
                device.unlockForConfiguration()
            } catch {
                assert(false, "error: device flash light \(error)")
            }
    }  //end ToggleFlashLight

    // SAME AS KrowdKinect iOS
    func torchIntensity(intensity : CGFloat) {
            guard let device = AVCaptureDevice.default(for: AVMediaType.video),
                  device.hasTorch else { return }
        do {
                try device.lockForConfiguration()
                if device.isTorchActive == true {
                    switch intensity {
                        case 0.00000...0.10000:
                            try device.setTorchModeOn(level: 0.1)
                        case 0.10001...0.20000:
                            try device.setTorchModeOn(level: 0.2)
                        case 0.20001...0.30000:
                            try device.setTorchModeOn(level: 0.3)
                        case 0.30001...0.40000:
                            try device.setTorchModeOn(level: 0.4)
                        case 0.40001...0.50000:
                            try device.setTorchModeOn(level: 0.5)
                        case 0.50001...0.60000:
                            try device.setTorchModeOn(level: 0.6)
                        case 0.60001...0.70000:
                            try device.setTorchModeOn(level: 0.7)
                        case 0.70001...0.80000:
                            try device.setTorchModeOn(level: 0.8)
                        case 0.80001...0.90000:
                            try device.setTorchModeOn(level: 0.9)
                        case 0.90001...1.00000:
                            try device.setTorchModeOn(level: 1.0)
                        default:
                            try device.setTorchModeOn(level: 1.0)
                    }  // end Switch
                    device.unlockForConfiguration()
                } // end if
            } catch {
                assert(false, "error: device flash light \(error)")
            }
    }  //end func TorchIntensity

    // SAME AS KrowdKinect iOS
    func FlashLightOff() {
            guard let device = AVCaptureDevice.default(for: AVMediaType.video),
                  device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                //try device.setTorchModeOn(level: 1.0)
                    device.torchMode = .off
                device.unlockForConfiguration()
            } catch {
                assert(false, "error: device flash light \(error)")
            }
    }  //end FlashlightOff

    // SAME AS KrowdKinect iOS
    func FlashLightOn(intensity : CGFloat) {
            guard let device = AVCaptureDevice.default(for: AVMediaType.video),
                  device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                switch intensity {
                    case 0.00000...0.10000:
                        try device.setTorchModeOn(level: 0.1)
                    case 0.10001...0.20000:
                        try device.setTorchModeOn(level: 0.2)
                    case 0.20001...0.30000:
                        try device.setTorchModeOn(level: 0.3)
                    case 0.30001...0.40000:
                        try device.setTorchModeOn(level: 0.4)
                    case 0.40001...0.50000:
                        try device.setTorchModeOn(level: 0.5)
                    case 0.50001...0.60000:
                        try device.setTorchModeOn(level: 0.6)
                    case 0.60001...0.70000:
                        try device.setTorchModeOn(level: 0.7)
                    case 0.70001...0.80000:
                        try device.setTorchModeOn(level: 0.8)
                    case 0.80001...0.90000:
                        try device.setTorchModeOn(level: 0.9)
                    case 0.90001...1.00000:
                        try device.setTorchModeOn(level: 1.0)
                    default:
                        try device.setTorchModeOn(level: 1.0)
                }  // end Switch
                    device.torchMode = .on
                    device.unlockForConfiguration()
            } catch {
                assert(false, "error: device flash light \(error)")
            }
    }  //end FlashlightOn
} //end CLASS





