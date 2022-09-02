//
//  ExchangeService.swift
//  TradingDashboard
//
//  Created by Yury Loshmanov on 25.08.2022.
//

import Foundation

protocol ExchangeService {
    var name: String { get }

    var bids: [Double: Double] { get }
    var asks: [Double: Double] { get }

    var pongReceived: Bool { get }

    func startOrderBook()
}
