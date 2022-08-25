//
// Created by Yury Loshmanov on 02.08.2022.
//

import Foundation

extension LiquidationsView {
    class LiquidationsViewModel: ObservableObject {
        @Published private(set) var short: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        @Published private(set) var long: [Double] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

        @Published private(set) var si = 0
        @Published private(set) var li = 0

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
                                print(text)
                                do {
                                    if let jsonArray = try JSONSerialization.jsonObject(with: text.data(using: .utf8)!, options: .allowFragments) as? [String: Any] {
                                        DispatchQueue.main.async { [self] in
                                            if let o = jsonArray["o"] as? [String: Any],
                                               let S = o["S"] as? String, let q = Double((o["q"] as? String)!) {
                                                if S == "SELL" {
                                                    if li == 10 {
                                                        li = 0
                                                    }

                                                    long[li] = q
                                                    li += 1
                                                } else {
                                                    if si == 10 {
                                                        si = 0
                                                    }

                                                    short[si] = q
                                                    si += 1
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

                socket = session.webSocketTask(with: URL(string: "wss://fstream.binance.com/ws/btcusdt@forceOrder")!)
                listen()
                socket.resume()
            }
        }
    }
}
