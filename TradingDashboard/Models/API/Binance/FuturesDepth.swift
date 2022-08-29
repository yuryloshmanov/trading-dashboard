//
// Created by Yury Loshmanov on 28.08.2022.
//

import Foundation


struct FuturesDepth: Depth, Codable {
    let lastUpdateId: UInt64
    let E: UInt64   // Message output time
    let T: UInt64   // Transaction time
    let bids: [[String]]
    let asks: [[String]]
}
