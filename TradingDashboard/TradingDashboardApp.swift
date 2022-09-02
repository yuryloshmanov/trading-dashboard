//
//  TradingDashboardApp.swift
//  TradingDashboard
//
//  Created by Yury Loshmanov on 29.07.2022.
//

import SwiftUI


struct SettingsPane: View {
    @AppStorage("api_key") static var apiKey: String = ""
    @AppStorage("api_secret") static var apiSecret: String = ""
    @AppStorage("order_book_size") static var orderBookSize = 50
    @AppStorage("order_book_grouping") static var orderBookGrouping: Int = 5

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
        if SettingsPane.orderBookGrouping == 1 {
            SettingsPane.orderBookGrouping = 5
        } else {
            SettingsPane.orderBookGrouping += 5
        }
    }

    func scaleUp() {
        if SettingsPane.orderBookGrouping > 5 {
            SettingsPane.orderBookGrouping -= 5
        } else if SettingsPane.orderBookGrouping == 5 {
            SettingsPane.orderBookGrouping = 1
        }
    }

    @CommandsBuilder var body: some Commands {
        CommandMenu("Menu") {
            Button(action: {
                scaleUp()
            }) {
                Text("ScaleUp")
            }
                .keyboardShortcut("=", modifiers: .command)
            Button(action: {
                scaleDown()
            }) {
                Text("ScaleDown")
            }
                .keyboardShortcut("-", modifiers: .command)
//                .disabled(SettingsPane.orderBookGrouping != 1)
        }
    }
}

@main
struct TradingDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DepthView()
//            ContentView()
        }
            .commands {
                AppCommands()
            }

        #if os(macOS)
        Settings {
            SettingsPane()
        }
        #endif
    }
}
