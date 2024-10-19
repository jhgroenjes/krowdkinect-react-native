//
//  SwiftUIView.swift
//
//
//  Created by Jason Groenjes on 8/25/24.
//
// Latest:  0.3.5 (10/7/2024)

import SwiftUI

struct ContentView: View {
    @StateObject var session: WebSocketController
    @State private var isFocused: Bool = false
    @State var homeAwaySelectionVar: String = "All"
    @State private var seatNumber: String = "1"


    init(options: KKOptions) {
        _session = StateObject(wrappedValue: WebSocketController(options: options))
    }

    var body: some View {
        //Background Stack to set color
        ZStack {
            // Background layer
            Color(red: session.red, green: session.green, blue: session.blue)
            .ignoresSafeArea(.all) // Full-screen background

            VStack{
                HStack {
                    // Online status indicator
                    if session.online {
                        Text(".")
                            .foregroundColor(.green)
                            .font(.system(size: 42).bold())
                            .frame(maxWidth: 10, maxHeight: 27, alignment: .bottom)
                            .opacity(session.textIsHidden ? 0 : 1)
                    } else {
                        Text(".")
                            .foregroundColor(.red)
                            .font(.system(size: 42).bold())
                            .frame(maxWidth: 10, maxHeight: 27, alignment: .bottom)
                    }
                    
                    // Seat Number and Zone Selection
                    if session.seatNumberEditHide == false {
                        Button(action: {
                            isFocused = true
                        }) {
                            HStack {
                                Text("Seat")
                                    .frame(width: 40)
                                    .foregroundColor(session.viewablecolor)
                            FocusableTextField(
                                    text: $seatNumber,
                                    isFirstResponder: $isFocused,
                                    placeholder: "Seat",
                                    keyboardType: .numberPad,
                                    onClear: {
                                        seatNumber = ""
                                        session.deviceID = 1
                                    },
                                    onDone: {
                                        DispatchQueue.main.async {
                                            isFocused = false
                                        }
                                        if let number = UInt32(seatNumber.replacingOccurrences(of: ",", with: "")) {
                                            session.deviceID = number
                                            if number == 0 {session.deviceID = 1}
                                        } else {
                                            seatNumber = "1"
                                            session.deviceID = 1
                                        }
                                    },
                                    textColor: UIColor(session.viewablecolor),
                                    font: UIFont.systemFont(ofSize: 23)
                                )
                                .frame(width: 80, height: 40, alignment: .top)
                                .foregroundColor(session.viewablecolor)
                                
                            } // end HStack
                            .onAppear {
                                    // Set initial values from session
                                    seatNumber = String(session.deviceID) // Set seatNumber based on session.deviceID
                                    homeAwaySelectionVar = session.homeAwaySelection // Set homeAwaySelectionVar based on session.homeAwaySelection
                                }
                        } // End Button Action Wrapper
                    } // end ifseatNumberEditHide
                    Spacer()
                    // Zone Selection Picker
                    if session.homeAwayHide == false {
                        Picker("HomeAwayZone", selection: $homeAwaySelectionVar) {
                            ForEach(session.homeAwayChoices, id: \.self) {
                                Text($0)
                                    .foregroundColor(session.viewablecolor)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(session.viewablecolor)
                        .onChange(of: homeAwaySelectionVar) { newZone in
                            session.homeAwaySelection = newZone
                        }
                        
                        Text("Zone")
                            .foregroundColor(session.viewablecolor)
                    } // end If homeAwayHide
                    
                } // end Stack
                .padding([.leading, .top], 15)
                .padding([.trailing], 68)
                
                Spacer() // Pushes the middle content to the center
                
                // Middle Row
                VStack {
                    Text(session.displayName)
                        .font(.system(size: 26).bold())
                        .foregroundColor(session.viewablecolor)
                        .opacity(0.7)
                    Text(session.displayTagline)
                        .foregroundColor(session.viewablecolor)
                        .opacity(0.7)
                } // end VStack Middle section
                
                Spacer() // Pushes the bottom content to the bottom
                
                // Bottom Row
                HStack {
                    Spacer()
                    Text(session.appVersion)
                        .foregroundColor(session.viewablecolor)
                        .opacity(0.4)
                        .padding()
                    Spacer()
                }
            }
        } // end ZStack
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDisappear {
            session.disconnectFromAbly()
            session.stopAllTimers()
            session.resetBrightness()
        }
        .onAppear {
            // This starts the connection as soon as the sdk view loads.
            session.connectToAbly()
            
        }
    } // end Body View
} // end struct



