//
//  TradingDashboardApp.swift
//  TradingDashboard
//
//  Created by Yury Loshmanov on 29.07.2022.
//

import SwiftUI
import IOKit
import IOKit.pwr_mgt

struct APISettingsPane: View {
    @AppStorage("api_key") static var apiKey: String = ""
    @AppStorage("api_secret") static var apiSecret: String = ""

    var body: some View {
        Form {
//            TextField("API Key", text: Self.$apiKey)
//            TextField("API Secret", text: Self.$apiSecret)
            SecureField(text: Self.$apiKey, prompt: Text("API Key")) {
                Text("API Key")
            }

            SecureField(text: Self.$apiSecret, prompt: Text("API Secret")) {
                Text("API Secret")
            }
        }
            .padding()
            .frame(maxWidth: 400, maxHeight: 300)
    }
}

struct GeneralSettingsPane: View {
    @AppStorage("order_book_size") static var orderBookSize = 50
    @AppStorage("order_book_grouping") static var orderBookGrouping: Int = 5

    var body: some View {
        Form {
            TextField(value: Self.$orderBookSize, formatter: NumberFormatter()) {
                Text("Order Book Size")
            }

            TextField(value: Self.$orderBookGrouping, formatter: NumberFormatter()) {
                Text("Order Book Grouping")
            }
        }
            .padding()
            .frame(maxWidth: 400, maxHeight: 300)
    }
}

struct AppCommands: Commands {

    func scaleDown() {
        if GeneralSettingsPane.orderBookGrouping == 1 {
            GeneralSettingsPane.orderBookGrouping = 5
        } else {
            GeneralSettingsPane.orderBookGrouping += 5
        }
    }

    func scaleUp() {
        if GeneralSettingsPane.orderBookGrouping > 5 {
            GeneralSettingsPane.orderBookGrouping -= 5
        } else if GeneralSettingsPane.orderBookGrouping == 5 {
            GeneralSettingsPane.orderBookGrouping = 1
        }
    }

    @CommandsBuilder var body: some Commands {
        CommandGroup(after: .toolbar) {
            Button(action: {
                scaleUp()
            }) {
                Text("Zoom In")
            }
                .keyboardShortcut("+", modifiers: .command)

            Button(action: {
                scaleDown()
            }) {
                Text("Zoom Out")
            }
                .keyboardShortcut("-", modifiers: .command)
        }
    }
}

@main
struct TradingDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    LiquidationsView()
                        .rotationEffect(.degrees(180))
                    Spacer()
                    TradesView()
                }
                    .frame(maxWidth: 150)

                DepthView()
            }
                .onAppear {
                    var assertionID: IOPMAssertionID = 0
                    var sleepDisabled = false

                    func disableScreenSleep(reason: String = "Disabling Screen Sleep") {
                        if !sleepDisabled {
                            sleepDisabled = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoDisplaySleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), reason as CFString, &assertionID) == kIOReturnSuccess
                        }
                    }

                    func enableScreenSleep() {
                        if sleepDisabled {
                            IOPMAssertionRelease(assertionID)
                            sleepDisabled = false
                        }
                    }

                    print("sleep Disabled:", sleepDisabled)
                }
        }
            .commands {
                AppCommands()
            }

        #if os(macOS)
        Settings {
            TabView {
//                ProfileSettingsView()
                GeneralSettingsPane()
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }

                APISettingsPane()
                    .tabItem {
                        Label("API", systemImage: "person")
                    }

//                AppearanceSettingsView()
//                    .tabItem {
//                        Label("Appearance", systemImage: "paintpalette")
//                    }
//
//                PrivacySettingsView()
//                    .tabItem {
//                        Label("Privacy", systemImage: "hand.raised")
//                    }
            }
                .frame(width: 450, height: 250)
        }
        #endif
    }
}
