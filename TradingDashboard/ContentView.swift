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

var dd: [String: [(Int, Double)]] = ["bids": [], "asks": []]
var ddi: OrderBook = ["bids": [:], "asks": [:]]

func fetchData(completion: @escaping (OrderBook?, Error?) -> Void) {
    ddi = ["bids": [:], "asks": [:]]
    let url = URL(string: "http://127.0.0.1:5000/order_book")!
    
//    let task = URLSession(configuration: .default).dataTask(with: url) { (data, response, error) in
//
//    }
    
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
                
                completion(ddi, nil)
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

func getColor(forLiquidity liquidity: Double) -> Color {
    let opacity = 0.5
    
    if liquidity < 200 {
        return Color(.displayP3, red: 0/255, green: 0/255, blue: 0/255, opacity: opacity)
    } else if liquidity < 500 {
        return Color(.displayP3, red: 0/255, green: 0/255, blue: 255/255, opacity: opacity)
    } else if liquidity < 1000 {
        return Color(.displayP3, red: 0/255, green: 255/255, blue: 255/255, opacity: opacity)
    } else if liquidity < 2000 {
        return Color(.displayP3, red: 255/255, green: 255/255, blue: 255/255, opacity: opacity)
    } else if liquidity < 10000 {
        return Color(.displayP3, red: 255/255, green: 255/255, blue: 0/255, opacity: opacity)
    } else {
        return Color(.displayP3, red: 255/255, green: 0/255, blue: 0/255, opacity: opacity)
    }
}

//class Depth {
//    @Published var book: [String: [(Int, Double)]]
//
//    init() {
//        book = [:]
//        DispatchQueue.global(qos: .background).async {
//            while (true) {
//                fetchData {(dict, error) in
//
//                }
//
//                if dd.isEmpty {
//                    return
//                }
//
//                dd["bids"]!.sort {
//                    $0.0 < $1.0
//                }
//                dd["asks"]!.sort {
//                    $0.0 < $1.0
//                }
//                self.book = dd
//
//                dd = ["bids": [], "asks": []]
//                ddi = ["bids": [:], "asks": [:]]
//                sleep(8)
//            }
//        }
//    }
//}

struct ContentView: View {
//    @State var depth: Depth = Depth()
    @State var book: [String: [(Int, Double)]] = [:]
    
    func update() {
        DispatchQueue.main.async {
            fetchData {(dict, error) in
                if dict != nil {
                    self.book = ["bids": [], "asks": []]
                    for (key, value) in ddi["bids"]! {
                        self.book["bids"]!.append((key, value))
                    }
                    
                    for (key, value) in ddi["asks"]! {
                        book["asks"]!.append((key, value))
                    }
                    book["bids"]!.sort {
                        $0.0 < $1.0
                    }
                    book["asks"]!.sort {
                        $0.0 < $1.0
                    }
                    
                    self.book = dd
//                    print(dd)
                    dd = ["bids": [], "asks": []]
                    ddi = ["bids": [:], "asks": [:]]
                }
            }
        }
    }
//    init() {
//        self.book = ["bids": [], "asks": []]
//        update()
//    }
    var body: some View {
        Button(action: {
            DispatchQueue.global(qos: .background).async {
                while (true) {
                    fetchData {(dict, error) in

                    }

                    if dd.isEmpty {
                        return
                    }

                    dd["bids"]!.sort {
                        $0.0 < $1.0
                    }
                    dd["asks"]!.sort {
                        $0.0 < $1.0
                    }
                    book = dd

                    dd = ["bids": [], "asks": []]
                    ddi = ["bids": [:], "asks": [:]]
                    sleep(16)
                }
            }
            
        }) {
            Text("Get Order Book")
        }
        
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
//                    let book = depth.book
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
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
