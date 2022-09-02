//
// Created by Yury Loshmanov on 01.09.2022.
//

import Foundation
import Network

import Alamofire
import SwiftyJSON
import NWWebSocket

class FTXService: ExchangeService {
    let name: String

    private let socket: NWWebSocket!

    private(set) var dataFetched: Bool
    private var lastUpdateId: UInt64
    private var flag: Bool
    private var buffer: [DepthStream]

    private(set) var bids: [Double: Double] = [:]
    private(set) var asks: [Double: Double] = [:]

    let tradingType: TradingType
    let market: Market
    let matching: Double?

    var pongReceived: Bool = false

    // Markets: https://ftx.com/trade/BTC-PERP
    enum Market: String {
        // Spot
        case BTCUSD = "BTC/USD"     // in BTC
        case BTCUSDT = "BTC/USDT"   // in BTC
        // And five more

        // Futures
        case BTC_PERP = "BTC-PERP"  // in BTC
        case BTC_0930 = "BTC-0930"  // in BTC
        case BTC_1230 = "BTC-1230"  // in BTC
    }


    init(_ tradingType: TradingType, _ market: Market, _ matching: Double? = nil) {
        name = "FTX (\(market.rawValue.uppercased()))"
        self.tradingType = tradingType
        self.market = market
        self.matching = matching

        dataFetched = false
        lastUpdateId = 0
        flag = true
        buffer = .init()

        let serverURL: URL = URL(string: "wss://ftx.com/ws/")!

        socket = NWWebSocket(url: serverURL)
        socket.delegate = self
    }

    func startOrderBook() {
        socket.connect()
        let payload = JSON(
                [
                    "op": "subscribe",
                    "channel": "orderbook",
                    "market": market.rawValue
                ]
        )
        socket.send(data: payload.asData)

        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.pongReceived = false
            self.socket.ping()
        }
    }
}


extension FTXService: WebSocketConnectionDelegate {
    func webSocketDidConnect(connection: WebSocketConnection) {
        // Respond to a WebSocket connection event
        pongReceived = true
    }

    func webSocketDidDisconnect(connection: WebSocketConnection,
                                closeCode: NWProtocolWebSocket.CloseCode, reason: Data?) {
        // Respond to a WebSocket disconnection event
    }

    func webSocketViabilityDidChange(connection: WebSocketConnection, isViable: Bool) {
        // Respond to a WebSocket connection viability change event
    }

    func webSocketDidAttemptBetterPathMigration(result: Result<WebSocketConnection, NWError>) {
        // Respond to when a WebSocket connection migrates to a better network path
        // (e.g. A device moves from a cellular connection to a Wi-Fi connection)
    }

    func webSocketDidReceiveError(connection: WebSocketConnection, error: NWError) {
        // Respond to a WebSocket error event
    }

    func webSocketDidReceivePong(connection: WebSocketConnection) {
        // Respond to a WebSocket connection receiving a Pong from the peer
        pongReceived = true
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        if let jsonString = string.data(using: .utf8) {
            let json = JSON(jsonString)
            if json["type"].string == "partial" {
                let bids = json["data"]["bids"].array!
                let asks = json["data"]["asks"].array!

                for bid in bids {
                    var priceLevel = bid[0].double!
                    let quantity = bid[1].double!

                    if matching != nil {
                        priceLevel += matching!
                    }

                    self.bids[priceLevel] = quantity
                }

                for ask in asks {
                    var priceLevel = ask[0].double!
                    let quantity = ask[1].double!

                    if matching != nil {
                        priceLevel += matching!
                    }

                    self.asks[priceLevel] = quantity
                }
                print(self.bids)
            } else if json["type"].string == "update" {
                let bids = json["data"]["bids"].array!
                let asks = json["data"]["asks"].array!

                for bid in bids {
                    var priceLevel = bid[0].double!
                    let quantity = bid[1].double!

                    if matching != nil {
                        priceLevel += matching!
                    }

                    self.bids[priceLevel] = quantity
                }

                for ask in asks {
                    var priceLevel = ask[0].double!
                    let quantity = ask[1].double!

                    if matching != nil {
                        priceLevel += matching!
                    }

                    self.asks[priceLevel] = quantity
                }

            }
        }

    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        // Respond to a WebSocket connection receiving a binary `Data` message
    }
}
