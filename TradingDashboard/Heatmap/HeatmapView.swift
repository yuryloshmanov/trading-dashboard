//
//  HeatmapView.swift
//  TradingDashboard
//
//  Created by Yury Loshmanov on 30.07.2022.
//

import SwiftUI

struct HeatmapView: View {
    @State var book: [String: [(Int, Double)]] = [:]
    
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    let asks: [(Int, Double)] = book["asks"]?.reversed() ?? []
                    let bids: [(Int, Double)] = book["bids"]?.reversed() ?? []
                    
                    ForEach (0 ..< asks.count, id:\.self) {
                        let k = asks[$0].0
                        let v = asks[$0].1
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
                            Rectangle().fill(Color(red:0/255.0, green:70/255.0, blue:0/255.0, opacity: 1))
                                .frame(width: geometry.size.width, height: nil)
                                .shadow(radius: 15)
                        }
                    }
                    
                    
                    ForEach (0 ..< bids.count, id:\.self) {
                        let k = bids[$0].0
                        let v = bids[$0].1
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
                .padding()
                .frame(width: geometry.size.width)
                .frame(minHeight: geometry.size.height)
            }
            
        }
        
        
        .toolbar {
            HStack {
                Spacer()
                
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
                
                Button(action: {
                    DispatchQueue.global(qos: .background).async {
                        while (true) {
                            fetchData {(dict, error) in
                                if var dict = dict {
                                    dict["bids"]!.sort {
                                        $0.0 < $1.0
                                    }
                                    
                                    dict["asks"]!.sort {
                                        $0.0 < $1.0
                                    }
                                    
                                    book = dict
                                }
                            }
                            
                            sleep(16)
                        }
                    }
                    
                }) {
                    Text("Get Order Book")
                }
                
                Spacer()
            }
        }
        
        
        
    }
}
