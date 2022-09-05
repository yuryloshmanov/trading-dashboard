//
// Created by Yury Loshmanov on 02.08.2022.
//

import SwiftUI

extension TradesView {
    class TradesViewModel: ObservableObject {
        @Published private(set) var buying: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        @Published private(set) var selling: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

        @Published private(set) var bi = 0
        @Published private(set) var si = 0

        init() {
        }

        func listenServer() {
            print("start listening server")
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
                                    if let jsonArray = try JSONSerialization.jsonObject(with: text.data(using: .utf8)!, options: .allowFragments) as? [String: Any] {
                                        DispatchQueue.main.async { [self] in
                                            if let m = jsonArray["m"] as? Bool, let q = Double((jsonArray["q"] as? String)!) {
                                                if q > 10 {
                                                    if m {
                                                        print("MM sells \(q) BTC")
                                                    } else {
                                                        print("MM buys \(q) BTC")
                                                    }
                                                }
                                                if m {
                                                    if si == 10 {
                                                        si = 0
                                                    }

//                                                    let oldQ = selling[si]
//                                                    let diff = (q - oldQ) / 100
//
//                                                    for _ in 0..<100 {
//                                                        selling[si] += diff
//                                                    }
                                                    selling[si] = q
                                                    si += 1
                                                } else {
                                                    if bi == 10 {
                                                        bi = 0
                                                    }

//                                                    let oldQ = buying[bi]
//                                                    let diff = (q - oldQ) / 100
//
//                                                    for _ in 0..<100 {
//                                                        buying[bi] += diff
//                                                    }
                                                    buying[bi] = q

                                                    bi += 1
                                                }
                                            }
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

//                    socket = session.webSocketTask(with: URL(string: "wss://stream.binance.com:9443/ws/btcusdt@aggTrade")!)

                socket = session.webSocketTask(with: URL(string: "wss://fstream.binance.com/ws/btcusdt@aggTrade")!)
                listen()
                socket.resume()
            }
        }
    }
}
