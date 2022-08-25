//
//  BinanceService.swift
//  TradingDashboard
//
//  Created by Yury Loshmanov on 26.08.2022.
//

import Foundation
import Network
import NWWebSocket

class BinanceService: ExchangeService {
    private let socket: NWWebSocket!

    private(set) var dataFetched: Bool
    private var lastUpdateId: UInt64
    private var flag: Bool
    private var buffer: [[String: Any]]

    private(set) var bids: [Double: Double] = [:]
    private(set) var asks: [Double: Double] = [:]

    let tradingType: TradingType
    let market: String

    init(_ tradingType: TradingType, _ market: String) {
        self.tradingType = tradingType
        self.market = market

        dataFetched = false
        lastUpdateId = 0
        flag = true
        buffer = .init()

        let serverURL: URL

        switch tradingType {
        case .spot:
            serverURL = URL(string: "wss://stream.binance.com:9443/ws/\(market)@depth")!
        case .futures:
            serverURL = URL(string: "wss://fstream.binance.com/stream?streams=\(market)@depth")!
        }

        socket = NWWebSocket(url: serverURL)
        socket.delegate = self
    }

    func startOrderBook() {
        socket.connect()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
            getSnapshot()
        }
    }
}


// MARK: - Extension

extension BinanceService {
    func getSnapshot() -> Void {
        fetchData { [self] (dict, error) in
            if let dict = dict {
                lastUpdateId = dict["lastUpdateId"] as! UInt64
                let b: [[String]] = dict["bids"] as! [[String]]
                let a: [[String]] = dict["asks"] as! [[String]]

                for bid in b {
                    bids[Double(bid[0])!] = Double(bid[1])!
                }

                for ask in a {
                    asks[Double(ask[0])!] = Double(ask[1])!
                }

                for item in buffer {
                    let data = (tradingType == .spot) ? (item) : (item["data"] as! [String: Any])


                    let u: UInt64 = data["u"] as! UInt64

                    if u < lastUpdateId {
                        continue
                    }

                    if let b = data["b"] as? [[String]],
                       let a = data["a"] as? [[String]] {

                        DispatchQueue.main.async { [self] in
                            for bid in b {
                                bids[Double(bid[0])!] = Double(bid[1])!
                            }

                            for ask in a {
                                asks[Double(ask[0])!] = Double(ask[1])!
                            }
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

    func fetchData(completion: @escaping ([String: Any]?, Error?) -> Void) {
        let url: URL

        switch tradingType {
        case .spot:
            url = URL(string: "https://api.binance.com/api/v3/depth?symbol=\(market.uppercased())&limit=1000")!
        case .futures:
            url = URL(string: "https://fapi.binance.com/fapi/v1/depth?symbol=\(market.uppercased())&limit=1000")!
        }

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                return
            }

            do {
                if let array = try JSONSerialization.jsonObject(
                        with: data, options: .allowFragments
                ) as? [String: Any] {
                    completion(array, nil)
                }
            } catch {
                print(error)
                completion(nil, error)
            }
        }
        task.resume()
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
        do {
            if let jsonArray = try JSONSerialization.jsonObject(
                    with: string.data(using: .utf8)!,
                    options: .allowFragments
            ) as? [String: Any] {
                if dataFetched {
                    if let data = (tradingType == .spot) ? (jsonArray) : (jsonArray["data"] as? [String: Any]),

//                    if let data = jsonArray["data"] as? [String: Any],
                        let U = data["U"] as? UInt64,
                        let u = data["u"] as? UInt64,
                        let b = data["b"] as? [[String]],
                        let a = data["a"] as? [[String]] {

                            if flag {
                                switch tradingType {
                                case .spot:
                                    if !(U <= lastUpdateId + 1 && u >= lastUpdateId + 1) {
                                        print("Restarting...")
                                        startOrderBook()
                                    }
                                case .futures:
                                    if !(U <= lastUpdateId && u >= lastUpdateId) {
                                        print("Restarting...")
                                        startOrderBook()
                                    }
                                }
                                flag = false
                            }

                            DispatchQueue.main.async { [self] in
                                for bid in b {
                                    let priceLevel: Double = Double(bid[0])!
                                    let quantity: Double = Double(bid[1])!

                                    bids[priceLevel] = quantity
                                }

                                for ask in a {
                                    asks[Double(ask[0])!] = Double(ask[1])!
                                }
                            }

                        }
                    } else {
                        buffer.append(jsonArray)
                    }
                } else {
                    print("bad json")
                }
            } catch let error as NSError {
                print(error)
            }
        }

        func webSocketDidReceiveMessage(connection: WebSocketConnection, data: Data) {
            // Respond to a WebSocket connection receiving a binary `Data` message
        }
    }

