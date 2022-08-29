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

    var body: some View {
        Form {
            TextField("API Key", text: Self.$apiKey)
            TextField("API Secret", text: Self.$apiSecret)
        }
            .padding()
            .frame(maxWidth: 400)
    }
}


@main
struct TradingDashboardApp: App {
    var body: some Scene {
        WindowGroup {
            DepthView()
//            ContentView()
        }

        #if os(macOS)
        Settings {
            SettingsPane()
        }
        #endif
    }
}
