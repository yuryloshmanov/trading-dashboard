//
// Created by Yury Loshmanov on 03.08.2022.
//

import Foundation
import OrderedCollections
import Network
import NWWebSocket


extension DepthView {
    class DepthViewModel: ObservableObject {
        private(set) var aggBids: [Double: Double]
        private(set) var aggAsks: [Double: Double]

//        @Published var grouping: Int = 5
//        @Published var grouping: Int = SettingsPane.orderBookGrouping

        var lastUpdateId: UInt64

        @Published var index: UInt = 0

        @Published var pong: [String: Bool] = [:]

        var timer: Timer?

        static var exchangeServices: [(ExchangeService, Bool)] = []

        deinit {
            timer?.invalidate()
        }

        func refresh() {
            aggAsks = [:]
            aggBids = [:]

            for (exchange, active) in Self.exchangeServices {
                if !active {
                    continue
                }

                for bid in exchange.bids {
                    if bid.1 == 0 {
                        continue
                    }

                    let price: Double = bid.0.rounded() - Double(Int(bid.0.rounded()) % SettingsPane.orderBookGrouping)

                    if aggBids[price] == nil {
                        aggBids[price] = 0
                    }

                    aggBids[price]! += bid.1
                }


                for ask in exchange.asks {
                    if ask.1 == 0 {
                        continue
                    }

                    let price: Double = ask.0.rounded() - Double(Int(ask.0.rounded()) % SettingsPane.orderBookGrouping)

                    if aggAsks[price] == nil {
                        aggAsks[price] = 0
                    }

                    aggAsks[price]! += ask.1
                }
            }

            index += 1
        }

        func start() {
            for (exchange, _) in Self.exchangeServices {
                exchange.startOrderBook()
            }
        }


        init() {
            let exchangeServices = [
                // Binance
                BinanceService(.spot, .BTCUSDT),
                BinanceService(.spot, .BTCBUSD),
                BinanceService(.futures, .BTCUSDT),
                BinanceService(.futures, .BTCBUSD),

                // FTX
//                FTXService(.spot, .BTCUSD),
//                FTXService(.spot, .BTCUSDT, -5),
//                FTXService(.futures, .BTC_PERP, -5),
//                FTXService(.futures, .BTC_0930),
//                FTXService(.futures, .BTC_1230, -70),
            ]

            for ex in exchangeServices {
                Self.exchangeServices.append((ex, true))
            }


            aggAsks = [:]
            aggBids = [:]

            lastUpdateId = 0

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.refresh()
            }

            Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [self] _ in
                for (exchange, isActive) in Self.exchangeServices {
                    pong[exchange.name] = exchange.pongReceived
                }
            }

            let date = DateComponents(calendar: Calendar.current)
            print(date.minute ?? "")
        }

    }
}
