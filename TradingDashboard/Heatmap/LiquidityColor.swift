//
//  LiquidityColor.swift
//  TradingDashboard
//
//  Created by Yury Loshmanov on 30.07.2022.
//

import SwiftUI

func getColor(forLiquidity liquidity: Double) -> Color {
    let opacity = 0.5
    
    if liquidity < 100 {
        return Color(.displayP3, red: 0/255, green: 0/255, blue: 0/255, opacity: opacity)
    } else if liquidity < 200 {
        return Color(.displayP3, red: 0/255, green: 0/255, blue: 255/255, opacity: opacity)
    } else if liquidity < 300 {
        return Color(.displayP3, red: 0/255, green: 255/255, blue: 255/255, opacity: opacity)
    } else if liquidity < 500 {
        return Color(.displayP3, red: 255/255, green: 255/255, blue: 255/255, opacity: opacity)
    } else if liquidity < 1000 {
        return Color(.displayP3, red: 255/255, green: 255/255, blue: 0/255, opacity: opacity)
    } else {
        return Color(.displayP3, red: 255/255, green: 0/255, blue: 0/255, opacity: opacity)
    }
}
