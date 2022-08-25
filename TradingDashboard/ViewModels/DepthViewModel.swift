//
// Created by Yury Loshmanov on 03.08.2022.
//

import Foundation
import OrderedCollections
import Network
import NWWebSocket


extension DepthView {
    class DepthViewModel: ObservableObject {
        private(set) var bids: [Double: Double]
        private(set) var asks: [Double: Double]

        private(set) var aggBids: [Double: Double]
        private(set) var aggAsks: [Double: Double]

        var grouping: Int = 5


        @Published var dataFetched: Bool
        var buffer: [[String: Any]]
        var lastUpdateId: UInt64

        @Published var index: Int = 0
//        @Published var now: Date = Date()

        var timer: Timer?

        deinit {
            timer?.invalidate()
        }

        func refresh() {
            aggAsks = [:]
            aggBids = [:]
            for bid in bids {
                if bid.1 == 0 {
                    continue
                }

                let price: Double = bid.0.rounded() - Double(Int(bid.0.rounded()) % grouping)

                if aggBids[price] == nil {
                    aggBids[price] = 0
                }

                aggBids[price]! += bid.1
            }


            for ask in asks {
                if ask.1 == 0 {
                    continue
                }

                let price: Double = ask.0.rounded() - Double(Int(ask.0.rounded()) % grouping)

                if aggAsks[price] == nil {
                    aggAsks[price] = 0
                }

                aggAsks[price]! += ask.1
            }

            index += 1
//            now = Date()
        }

        var socket: NWWebSocket!


        func start() {
            let serverURL = URL(string: "wss://fstream.binance.com/stream?streams=btcusdt@depth")!
            socket = NWWebSocket(url: serverURL)
            socket.delegate = self

            socket.connect()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                getSnapshot()
            }
        }

        init() {
            bids = [:]
            asks = [:]
            dataFetched = false
            buffer = []
            aggAsks = [:]
            aggBids = [:]

            lastUpdateId = 0

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                self.refresh()
            })
        }

        var flag: Bool = true


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
                        let u: UInt64 = (item["data"] as! [String: Any])["u"] as! UInt64

                        if u < lastUpdateId {
//                            print("<")
                            continue
                        }

                        if let b = (item["data"] as! [String: Any])["b"] as? [[String]],
                           let a = (item["data"] as! [String: Any])["a"] as? [[String]] {

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

                    dataFetched = true
                    buffer = []
                }
            }

        }

        func fetchData(completion: @escaping ([String: Any]?, Error?) -> Void) {
            let url = URL(string: "https://fapi.binance.com/fapi/v1/depth?symbol=BTCUSDT&limit=1000")!

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
}

extension DepthView.DepthViewModel: WebSocketConnectionDelegate {
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
                    if let data = jsonArray["data"] as? [String: Any],
                       let U = data["U"] as? UInt64,
                       let u = data["u"] as? UInt64,
                       let b = data["b"] as? [[String]],
                       let a = data["a"] as? [[String]] {

                        if flag {
                            if !(U <= lastUpdateId && u >= lastUpdateId) {
                                print("Restarting...")
                                start()
                            }
                            flag = false
                        }

                        DispatchQueue.main.async { [self] in
                            for bid in b {
                                let priceLevel: Double = Double(bid[0])!
                                let quantity: Double = Double(bid[1])!

//                                                        if quantity == 0 {
//                                                            if let index = bids.index(forKey: priceLevel) {
//                                                                bids.remove(at: index)
//                                                            }
//                                                        }

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