//
// Created by Yury Loshmanov on 28.08.2022.
//

import Foundation

protocol Depth: Codable {
    var bids: [[String]] { get }
    var asks: [[String]] { get }
}
