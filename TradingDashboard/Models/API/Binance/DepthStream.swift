//
// Created by Yury Loshmanov on 28.08.2022.
//

import Foundation

struct DepthStream: Codable {
    let e: String       // Event type
    let E: UInt64       // Event time
    let T: UInt64 = 0       // Transaction time
    let s: String = ""      // Symbol
    let U: Int          // First update ID in event
    let u: Int          // Final update ID in event
    let pu: Int = 0         // Final update Id in last stream(ie `u` in last stream)
    let b: [[String]]   // Bids to be updated
    let a: [[String]]   // Asks to be updated
}
