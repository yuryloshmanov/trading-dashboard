//
//  BinanceService.swift
//  TradingDashboard
//
//  Created by Yury Loshmanov on 26.08.2022.
//

import Foundation
import Network

import Alamofire
import SwiftyJSON
import NWWebSocket

class BinanceService: ExchangeService {
    private let socket: NWWebSocket!

    private(set) var dataFetched: Bool
    private var lastUpdateId: UInt64
    private var flag: Bool
    private var buffer: [DepthStream]

    private(set) var bids: [Double: Double] = [:]
    private(set) var asks: [Double: Double] = [:]

    let tradingType: TradingType
    let market: Market

    enum Market: String {
        case BTCUSDT = "btcusdt"
        case BTCBUSD = "btcbusd"
    }

    let api = Client()

    init(_ tradingType: TradingType, _ market: Market) {
//        api.getAccountInformation()
//        api.getAccountTradeList()
        self.tradingType = tradingType
        self.market = market

        dataFetched = false
        lastUpdateId = 0
        flag = true
        buffer = .init()

        let serverURL: URL

        switch tradingType {
        case .spot:
            serverURL = URL(string: "wss://stream.binance.com:9443/ws/\(market.rawValue)@depth")!
        case .futures:
            serverURL = URL(string: "wss://fstream.binance.com/stream?streams=\(market.rawValue)@depth")!
        }

        socket = NWWebSocket(url: serverURL)
        socket.delegate = self
    }

    func startOrderBook() {
        socket.connect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
            switch tradingType {
            case .spot:
                getSnapshot(SpotDepth.self)
            case .futures:
                getSnapshot(FuturesDepth.self)
            }
        }
    }
}


// MARK: - Client for user information and trading

extension BinanceService {
    class Client {
        private let api: BinanceApi

        init() {
            api = BinanceApi(apiKey: SettingsPane.apiKey, secretKey: SettingsPane.apiSecret)
        }

        func getAccountTradeList() {


            DispatchQueue.main.async { [self] in
                let req = api.send(BinanceAccountTradeListRequest(symbol: "btcbusd")) { response in
                }
                req.responseString {
                    response in
                    if let data = response.data {
                        let json = JSON(data)
                        print(json)
                    }
                }
            }

        }

        func getAccountInformation() {
            DispatchQueue.main.async { [self] in
                let req = api.send(BinanceAccountInformationRequest()) { response in
                }
                req.responseString { response in
                    if let data = response.data {
                        let json = JSON(data)
//                        print(json)
                    }
                }
            }
        }

    }
}

// MARK: - Extension

extension BinanceService {
    func getSnapshot<T: Depth>(_ type: T.Type = T.self) -> Void {
        let url: String

        switch tradingType {
        case .spot:
            url = "https://api.binance.com/api/v3/depth?symbol=\(market.rawValue.uppercased())&limit=1000"
        case .futures:
            url = "https://fapi.binance.com/fapi/v1/depth?symbol=\(market.rawValue.uppercased())&limit=1000"
        }

        let request = AF.request(url)


        request.responseDecodable(of: T.self) { [self] data in
            if let depth = data.value {
                for bid in depth.bids {
                    var priceLevel = Double(bid[0])!
                    let quantity = Double(bid[1])!

                    if tradingType == .spot {
                        priceLevel -= 10
                    }

                    bids[priceLevel] = quantity
                }

                for ask in depth.asks {
                    var priceLevel = Double(ask[0])!
                    let quantity = Double(ask[1])!

                    if tradingType == .spot {
                        priceLevel -= 10
                    }

                    asks[priceLevel] = quantity
                }

                for item in buffer {

                    if item.u < lastUpdateId {
                        continue
                    }


                    DispatchQueue.main.async { [self] in
                        for bid in item.b {
                            var priceLevel = Double(bid[0])!
                            let quantity = Double(bid[1])!

                            if tradingType == .spot {
                                priceLevel -= 10
                            }

                            bids[priceLevel] = quantity
                        }

                        for ask in item.a {
                            var priceLevel = Double(ask[0])!
                            let quantity = Double(ask[1])!

                            if tradingType == .spot {
                                priceLevel -= 10
                            }

                            asks[priceLevel] = quantity
                        }
                    }

                }

                DispatchQueue.main.async { [self] in
                    dataFetched = true
                }

                buffer = []
            }
        }
    }
}


extension BinanceService: WebSocketConnectionDelegate {
    func webSocketDidConnect(connection: WebSocketConnection) {
        // Respond to a WebSocket connection event
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
    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, string: String) {
        guard let data = string.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        let depthStream: DepthStream

        let decoder = JSONDecoder()

        do {
            if tradingType == .spot {
                depthStream = try decoder.decode(SpotDepthStream.self, from: data).data
            } else {
                depthStream = try decoder.decode(SpotDepthStream.self, from: data).data
            }
        } catch {
            print(error)
            return
        }

        if dataFetched {
            if flag {
                switch tradingType {
                case .spot:
                    if !(depthStream.U <= lastUpdateId + 1 && depthStream.u >= lastUpdateId + 1) {
                        print("Restarting...")
                        startOrderBook()
                    }
                case .futures:
                    if !(depthStream.U <= lastUpdateId && depthStream.u >= lastUpdateId) {
                        print("Restarting...")
                        startOrderBook()
                    }
                }
                flag = false
            }

            DispatchQueue.main.async { [self] in
                for bid in depthStream.b {
                    var priceLevel: Double = Double(bid[0])!
                    let quantity: Double = Double(bid[1])!

                    if tradingType == .spot {
                        priceLevel -= 10
                    }

                    bids[priceLevel] = quantity
                }

                for ask in depthStream.a {
                    var priceLevel: Double = Double(ask[0])!
                    let quantity: Double = Double(ask[1])!

                    if tradingType == .spot {
                        priceLevel -= 10
                    }

                    asks[priceLevel] = quantity
                }
            }

        } else {
            buffer.append(depthStream)
        }

    }

    func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
        // Respond to a WebSocket connection receiving a binary `Data` message
    }
}

