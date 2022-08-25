//
// Created by Yury Loshmanov on 03.08.2022.
//

import SwiftUI

struct Price: View {
    @State var checkState: Bool = false

    let k: Double

    var body: some View {
        ZStack {
            if checkState {
                Arrow()
                    .fill(.blue)
            }

            Button {
                print(k)

                if checkState {
                    checkState = false
                } else {
                    checkState = true
                }

            } label: {
                Text(String(format: "%.0f", k))
                    .font(.custom("Menlo-Regular", fixedSize: 12))
            }
                .buttonStyle(PlainButtonStyle())
        }
            .frame(width: 60)
    }

    init(_ k: Double) {
        self.k = k
    }

}

struct Quantity: View {
    @State var checkState: Bool = false
    let v: Double

    var body: some View {
        ZStack {
            if checkState {
                Arrow()
                    .rotation(Angle(degrees: 180))
                    .fill(.blue)
            }

            Button {
                print(v)

                if checkState {
                    checkState = false
                } else {
                    checkState = true
                }

            } label: {
                Text(String(format: "%.0f", v))
                    .font(.custom("Menlo-Regular", fixedSize: 12))
            }
                .buttonStyle(PlainButtonStyle())
        }
            .frame(width: 60)
    }

    init(_ v: Double) {
        self.v = v
    }
}


struct Divider: View {
    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.purple)
                .frame(width: geometry.size.width, height: nil)
                .padding(0)
        }
    }
}

struct Arrow: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height

            path.addLines([
                CGPoint(x: 0, y: 0),
                CGPoint(x: 0, y: height),
                CGPoint(x: width, y: height),
                CGPoint(x: width * 1.2, y: height / 2),
                CGPoint(x: width, y: 0),
            ])

            path.closeSubpath()
        }
    }
}


struct PriceLevel: View {
    var priceLevel: Double
    var quantity: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(getColor(forLiquidity: quantity))
                    .shadow(radius: 0)

                HStack {
                    Price(priceLevel)
                    Spacer()
                    Quantity(quantity)
                }
            }
        }
    }

    init(_ priceLevel: Double, _ quantity: Double) {
        self.priceLevel = priceLevel
        self.quantity = quantity
    }
}

struct DepthView: View {
    @State var isLoading: Bool
    @ObservedObject var viewModel: DepthViewModel

    var size: Int = 50

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if !viewModel.aggAsks.isEmpty {
                    HStack(spacing: 0) {
                        Text("Price")
                            .padding(.leading, 15)
                        Spacer()
                        Text("BTC")
                            .padding(.trailing, 15)
                    }
                }

                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        if viewModel.aggAsks.isEmpty {
                            ProgressView()
                        }

                        ForEach(viewModel.aggAsks.sorted(by: >).suffix(size), id: \.key) { k, v in
                            if v > 0 {
                                PriceLevel(k, v)
                                    .frame(width: geometry.size.width, height: 20)
                            }
                        }

                        if !viewModel.aggAsks.isEmpty {
                            Divider()
                                .frame(width: geometry.size.width, height: 10)
                        }

                        ForEach(viewModel.aggBids.sorted(by: >).prefix(size), id: \.key) { k, v in
                            if v > 0 {
                                PriceLevel(k, v)
                                    .frame(width: geometry.size.width, height: 20)
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
                    viewModel.start()
                }
        }
    }

    init() {
        isLoading = false
        viewModel = DepthViewModel()
    }
}
