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

        var grouping: Int = 5

        var lastUpdateId: UInt64

        @Published var index: UInt = 0

        var timer: Timer?

        var exchangeServices: [ExchangeService]

        deinit {
            timer?.invalidate()
        }

        func refresh() {
            aggAsks = [:]
            aggBids = [:]

            for exchange in exchangeServices {
                for bid in exchange.bids {
                    if bid.1 == 0 {
                        continue
                    }

                    let price: Double = bid.0.rounded() - Double(Int(bid.0.rounded()) % grouping)

                    if aggBids[price] == nil {
                        aggBids[price] = 0
                    }

                    aggBids[price]! += bid.1
                }


                for ask in exchange.asks {
                    if ask.1 == 0 {
                        continue
                    }

                    let price: Double = ask.0.rounded() - Double(Int(ask.0.rounded()) % grouping)

                    if aggAsks[price] == nil {
                        aggAsks[price] = 0
                    }

                    aggAsks[price]! += ask.1
                }
            }

            index += 1
        }

        func start() {
            for exchange in exchangeServices {
                exchange.startOrderBook()
            }
        }

        init() {
            exchangeServices = [
//                BinanceService(.spot, .BTCUSDT),
//                BinanceService(.spot, .BTCBUSD),
                BinanceService(.futures, .BTCUSDT),
                BinanceService(.futures, .BTCBUSD)
            ]

            aggAsks = [:]
            aggBids = [:]

            lastUpdateId = 0

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { _ in
                self.refresh()
            })
        }
    }
}
