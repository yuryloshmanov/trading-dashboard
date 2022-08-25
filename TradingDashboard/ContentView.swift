//
//  ContentView.swift
//  TradingDashboard
//
//  Created by Yury Loshmanov on 29.07.2022.
//

import SwiftUI

import Foundation
import CoreFoundation

typealias OrderBook = [String: [Int: Double]]


func fetchData(completion: @escaping ([String: [(Int, Double)]]?, Error?) -> Void) {
    var dd: [String: [(Int, Double)]] = ["bids": [], "asks": []]
    var ddi: OrderBook = ["bids": [:], "asks": [:]]
    
    let url = URL(string: "http://127.0.0.1:5000/order_book")!
    
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let data = data else { return }
        do {
            if let array = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: [String: Double]] {
                print("____")
                
                for (key, value) in array["bids"]! {
                    ddi["bids"]![Int(key)!] = value
                }
                
                for (key, value) in array["asks"]! {
                    ddi["asks"]![Int(key)!] = value
                }
                
                for (key, value) in ddi["bids"]! {
                    dd["bids"]!.append((key, value))
                }
                
                for (key, value) in ddi["asks"]! {
                    dd["asks"]!.append((key, value))
                }
                
                completion(dd, nil)
            }
        } catch {
            print(error)
            completion(nil, error)
        }
    }
    print("b")
    task.resume()
    print("a")
}


struct ContentView: View {
    @State var book: [String: [(Int, Double)]] = [:]
    
    
    var body: some View {
        NavigationView {
            List {
                Spacer()
                NavigationLink {
                    HeatmapView()
                } label: {
                    Text("HEATMAP")
                        .font(.system(size: 15))
                }
                NavigationLink {
                    LiquidationsView()
                } label: {
                    Text("LIQUIDATIONS")
                        .font(.system(size: 15))
                }
                NavigationLink {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            HeatmapView()
                                .frame(minWidth: 800)
                            VStack(spacing: 0) {
                                TradesView()
                                LiquidationsView()
                            }
                        }
                    }
                } label: {
                    Text("TRADES")
                        .font(.system(size: 15))
                }

                NavigationLink {
                    DepthView()
                } label: {
                    Text("DEPTH")
                        .font(.system(size: 15))
                }
            }
            .listStyle(SidebarListStyle())
        }
        
        
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
