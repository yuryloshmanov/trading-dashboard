//
//  LiquidationView.swift
//  TradingDashboard
//
//  Created by Yury Loshmanov on 30.07.2022.
//

import SwiftUI

struct LiquidationView: View {
    @State var book: [String: [(Int, Double)]] = [:]
    
    
    var body: some View {
        Text("Hello")
        .toolbar {
                HStack {
                    Spacer()
                    
                    Picker(selection: .constant(1), label: Text("Coin:")) {
                        Text("BTC").tag(1)
                        Text("ETH").tag(2)
                    }
                    .frame(width:150, height: nil)
                    
                    Spacer()
                    
                    Picker(selection: .constant(1), label: Text("Pair:")) {
                        Text("All").tag(1)
                        Text("USDT").tag(2)
                        Text("BUSD").tag(3)
                    }
                    .frame(width:150, height: nil)
                    
                    Spacer()
                    
                    Picker(selection: .constant(2), label: Text("Price:")) {
                        Text("USD").tag(1)
                        Text("USDT").tag(2)
                        Text("BUSD").tag(3)
                    }
                    .frame(width:150, height: nil)
                    
                    Spacer()
                }
        
        }
        
    }
    
}
