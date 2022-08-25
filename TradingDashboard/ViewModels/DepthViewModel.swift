//
// Created by Yury Loshmanov on 03.08.2022.
//

import Foundation
import OrderedCollections


extension DepthView {
    class DepthViewModel: ObservableObject {
        private(set) var bids: [Double: Double]
        private(set) var asks: [Double: Double]

        private(set) var bbids: [Double: Double]
        private(set) var aasks: [Double: Double]

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
            aasks = [:]
            bbids = [:]
            for bid in bids {
                if bid.1 == 0 {
                    continue
                }

                let price: Double = bid.0.rounded() - Double(Int(bid.0.rounded()) % grouping)

                if bbids[price] == nil {
                    bbids[price] = 0
                }

                bbids[price]! += bid.1
            }


            for ask in asks {
                if ask.1 == 0 {
                    continue
                }

                let price: Double = ask.0.rounded() - Double(Int(ask.0.rounded()) % grouping)

                if aasks[price] == nil {
                    aasks[price] = 0
                }

                aasks[price]! += ask.1
            }


//            for i in aasks.sorted(by: >).suffix(50) {
//                a[i.key] = i.value
//            }
//
//            for i in bbids.sorted(by: >).prefix(50) {
//                b[i.key] = i.value
//            }


            index += 1
//            now = Date()
        }

        init() {
            bids = [:]
            asks = [:]
            dataFetched = false
            buffer = []
            aasks = [:]
            bbids = [:]

            lastUpdateId = 0
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                self.refresh()
            })

        }

        func listenServer() {
            print("start listening server")
            var flag: Bool = true
            DispatchQueue.global(qos: .background).async {
                let session: URLSession = URLSession(configuration: .default)
                var socket: URLSessionWebSocketTask!

                func listen() {
                    socket.receive { [self] result in
                        switch result {
                        case .success(let message):
                            switch message {
                            case .data(let data):
                                print("Data received \(data)")
                            case .string(let text):
                                do {
                                    if let jsonArray = try JSONSerialization.jsonObject(
                                            with: text.data(using: .utf8)!,
                                            options: .allowFragments
                                    ) as? [String: Any] {
                                        if dataFetched {
                                            if let data = jsonArray["data"] as? [String: Any],
                                               let U = data["U"] as? UInt64,
                                               let u = data["u"] as? UInt64,
                                               let b = data["b"] as? [[String]],
                                               let a = data["a"] as? [[String]] {

//                                                print(lastUpdateId)
//                                                print(U)
//                                                print(u)
                                                if flag {
                                                    if !(U <= lastUpdateId && u >= lastUpdateId) {
                                                        exit(0)
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
                            @unknown default:
                                fatalError()
                            }
                        case .failure(let error):
                            print("Error when receiving \(error)")
                        }

                        listen()
                    }
                }

                socket = session.webSocketTask(
                        with: URL(string: "wss://fstream.binance.com/stream?streams=btcusdt@depth")!
                )
                listen()
                socket.resume()
            }
        }

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
                            print("<")
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
