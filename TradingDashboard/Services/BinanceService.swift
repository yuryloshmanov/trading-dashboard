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

    enum Market: String {
        case BTCUSDT = "btcusdt"
        case BTCBUSD = "btcbusd"
        case BTCUSD_PERP = "btcusd_perp"
        case BTCUSD_220930 = "btcusd_220930"
        case BTCUSD_221230 = "btcusd_221230"
    }

    // TODO: fix

    var pongReceived: Bool = false
    static let api = Client()
    let matching: Double

    init(_ tradingType: TradingType, _ market: Market, _ matching: Double = 0) {
        self.matching = matching
//        api.getAccountInformation()
//        api.getAccountTradeList()
        if tradingType == .spot {
            name = "Binance (\(market.rawValue.uppercased()))"
        } else {
            name = "Binance Futures (\(market.rawValue.uppercased()))"
        }
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
        case .usds_futures:
            serverURL = URL(string: "wss://fstream.binance.com/stream?streams=\(market.rawValue)@depth")!
        case .coin_futures:
            serverURL = URL(string: "wss://dstream.binance.com/stream?streams=\(market.rawValue)@depth")!
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
            case .usds_futures:
                fallthrough
            case .coin_futures:
                getSnapshot(FuturesDepth.self)
            }
        }

        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            self.pongReceived = false
            self.socket.ping()
        }
    }
}


// MARK: - Client for user information and trading

extension BinanceService {
    class Client {
        private let api: BinanceApi

        init() {
            api = BinanceApi(apiKey: APISettingsPane.apiKey, secretKey: APISettingsPane.apiSecret)
        }

        func newOrder(forPrice price: Double) {
            let req = api.send(BinanceNewOrderRequest(
                    symbol: "BTCUSDT",
                    side: .long,
                    type: .limit,
                    quantity: 1,
                    price: Decimal(price),
                    timeInForce: .GTX
            )) { response in
            }

            req.responseString { response in
                print(response)
            }
        }

        func getAccountTradeList() {
            DispatchQueue.main.async { [self] in
                let req = api.send(BinanceAccountTradeListRequest(symbol: "btcbusd")) { response in
                }
                req.responseString { response in
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
                        print(json)
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
            url = "https://api.binance.com/api/v3/depth?symbol=\(market.rawValue.uppercased())&limit=10000000"
        case .usds_futures:
            url = "https://fapi.binance.com/fapi/v1/depth?symbol=\(market.rawValue.uppercased())&limit=1000"
        case .coin_futures:
            url = "https://dapi.binance.com/dapi/v1/depth?symbol=\(market.rawValue.uppercased())&limit=1000"
        }

        let request = AF.request(url)


        request.responseDecodable(of: T.self) { [self] data in
            if let depth = data.value {
                for bid in depth.bids {
                    var priceLevel = Double(bid[0])!
                    var quantity = Double(bid[1])!

                    priceLevel += matching
                    if tradingType == .spot {
                        priceLevel -= 10
                    } else if tradingType == .coin_futures {
                        quantity *= 100
                        quantity /= priceLevel
                    }

                    bids[priceLevel] = quantity
                }

                for ask in depth.asks {
                    var priceLevel = Double(ask[0])!
                    var quantity = Double(ask[1])!

                    priceLevel += matching
                    if tradingType == .spot {
                        priceLevel -= 10
                    } else if tradingType == .coin_futures {
                        quantity *= 100
                        quantity /= priceLevel
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
                            var quantity = Double(bid[1])!

                            priceLevel += matching
                            if tradingType == .spot {
                                priceLevel -= 10
                            } else if tradingType == .coin_futures {
                                quantity *= 100
                                quantity /= priceLevel
                            }

                            bids[priceLevel] = quantity
                        }

                        for ask in item.a {
                            var priceLevel = Double(ask[0])!
                            var quantity = Double(ask[1])!

                            priceLevel += matching
                            if tradingType == .spot {
                                priceLevel -= 10
                            } else if tradingType == .coin_futures {
                                quantity *= 100
                                quantity /= priceLevel
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
        guard let data = string.data(using: .utf8, allowLossyConversion: false) else {
            return
        }

        let depthStream: DepthStream

        let decoder = JSONDecoder()

        do {
            if tradingType == .spot {
                depthStream = try decoder.decode(DepthStream.self, from: data)
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
                case .usds_futures:
                    fallthrough
                case .coin_futures:
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
                    var quantity: Double = Double(bid[1])!

                    priceLevel += matching
                    if tradingType == .spot {
                        priceLevel -= 10
                    } else if tradingType == .coin_futures {
                        quantity *= 100
                        quantity /= priceLevel
                    }

                    bids[priceLevel] = quantity
                }

                for ask in depthStream.a {
                    var priceLevel: Double = Double(ask[0])!
                    var quantity: Double = Double(ask[1])!

                    priceLevel += matching
                    if tradingType == .spot {
                        priceLevel -= 10
                    } else if tradingType == .coin_futures {
                        quantity *= 100
                        quantity /= priceLevel
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

