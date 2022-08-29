//
// Created by Yury Loshmanov on 28.08.2022.
//

import Foundation

struct SpotDepth: Depth, Codable {
    let lastUpdateId: UInt64
    let bids: [[String]]
    let asks: [[String]]
}
