//
//  HeatmapView.swift
//  TradingDashboard
//
//  Created by Yury Loshmanov on 30.07.2022.
//

import SwiftUI

struct HeatmapView: View {
    @State var book: [String: [(Int, Double)]] = [:]
    @State var isLoading = false
    
    var colors = ["Red", "Green", "Blue", "Tartan"]
    @State var selected = "Red"
    
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    if isLoading {
                        ProgressView()
                    }
                    
                    let asks: [(Int, Double)] = book["asks"]?.reversed() ?? []
                    let bids: [(Int, Double)] = book["bids"]?.reversed() ?? []
                    
                    let askSum = asks.map({$0.0 < asks[asks.count - 1].0 + 1000 ? $0.1 : 0}).reduce(0, +)
                    let bidSum = bids.map({$0.0 > bids[0].0 - 1000 ? $0.1 : 0}).reduce(0, +)
                    
                    ForEach (0 ..< asks.count, id:\.self) {
                        let k: Int = asks[$0].0
                        let v: Double = asks[$0].1
                        
                        if k <= asks[asks.count - 1].0 + 500 {
                            ZStack {
                                Rectangle()
                                    .fill(getColor(forLiquidity: v))
                                    .frame(width: geometry.size.width, height: nil)
                                    .shadow(radius: 0)
                                
                                HStack {
                                    Text("\(k)")
                                    Spacer()
                                    Text("\(Int(v))")
                                }
                            }
                            
                            if $0 == asks.count - 1{
                                ZStack {
                                    Rectangle()
                                        .fill(Color(red:0/255.0, green:70/255.0, blue:0/255.0, opacity: 1))
                                        .frame(width: geometry.size.width, height: nil)
                                        .shadow(radius: 15)
                                    
                                    HStack {
                                        Spacer()
                                        Text("Bids: \(bidSum)")
                                        Spacer()
                                        Text("Asks: \(askSum)")
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    
                    
                    ForEach (0 ..< bids.count, id:\.self) {
                        let k: Int = bids[$0].0
                        let v: Double = bids[$0].1
                        
                        if k >= bids[0].0 - 500 {
                            ZStack {
                                Rectangle()
                                    .fill(getColor(forLiquidity: v))
                                    .frame(width: geometry.size.width, height: nil)
                                    .shadow(radius: 0)
                                
                                HStack {
                                    Text("\(k)")
                                    Spacer()
                                    Text("\(Int(v))")
                                }
                            }
                        }
                        
                        
                    }
                }
                .padding()
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
            
        }
        .onAppear {
            isLoading = true
            DispatchQueue.global(qos: .background).async {
                while (true) {
                    print("_-----------------------------")
                    fetchData {(dict, error) in
                        if var dict = dict {
                            dict["bids"]!.sort {
                                $0.0 < $1.0
                            }
                            
                            dict["asks"]!.sort {
                                $0.0 < $1.0
                            }
                            
                            isLoading = false
                            book = dict
                        }
                    }
                    sleep(16)
                }
            }
        }
        
        
        .toolbar {
            HStack {
                Spacer()
                Picker(selection: $selected, label: Text("Coin:")) {
                    ForEach(colors, id: \.self) {
                        Text($0)
                    }
                }
                .frame(width:150, height: nil)
                
                Picker(selection: .constant(1), label: Text("Coin:")) {
                    Text("BTC").tag(1)
                    Text("ETH").tag(2)
                }
                .frame(width:150, height: nil)
                
                Spacer()
                
                Picker(selection: .constant(1), label: Text("Pair:")) {
                    Text("All").tag(1)
                    Text("USDT").tag(2)
                    Text("BUSD").tag(3)
                }
                .frame(width:150, height: nil)
                
                Spacer()
                
                Picker(selection: .constant(2), label: Text("Price:")) {
                    Text("USD").tag(1)
                    Text("USDT").tag(2)
                    Text("BUSD").tag(3)
                }
                .frame(width:150, height: nil)
                
                Spacer()
            }
        }
        
        
        
    }
    
}
