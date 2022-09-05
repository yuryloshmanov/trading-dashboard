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
                BinanceService.api.newOrder(forPrice: k)

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
                if Int(priceLevel) % 10 == 0 && GeneralSettingsPane.orderBookGrouping == 1 {
                    Rectangle()
                        .fill(getColor(forLiquidity: quantity))
                        .shadow(radius: 0)
                        .border(.pink, width: 2)
                } else {
                    Rectangle()
                        .fill(getColor(forLiquidity: quantity))
                        .shadow(radius: 0)
                }


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

struct BellCurve: Shape {
    var height: CGFloat

    func path(in rect: CGRect) -> Path {
        Path { path in
            let y: CGFloat = rect.height
            let x: CGFloat = rect.width

            path.move(to: CGPoint(x: 0, y: y))
            path.addCurve(
                    to: CGPoint(x: x / 2, y: y - height),
                    control1: CGPoint(x: x / 4, y: y),
                    control2: CGPoint(x: x / 4, y: y - height)
            )
            path.addCurve(
                    to: CGPoint(x: x, y: y),
                    control1: CGPoint(x: x * 3 / 4, y: y - height),
                    control2: CGPoint(x: x * 3 / 4, y: y)
            )
            path.addLine(to: CGPoint(x: 0, y: y))
            path.closeSubpath()
        }
    }

    init() {
        height = 100
    }

    init(_ height: CGFloat) {
        self.height = height
    }
}


struct DepthView: View {
    @State var isLoading: Bool
    @ObservedObject var viewModel: DepthViewModel

//    var size: Int = 100

    var body: some View {

        HStack(spacing: 0) {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    if !viewModel.aggAsks.isEmpty {
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {

                                Text("Price")
                                    .padding(.leading, 15)
                                Spacer()
                                Text("BTC")
                                    .padding(.trailing, 15)
                            }
                        }
                    }

                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            if viewModel.aggAsks.isEmpty {
                                ProgressView()
                            }

                            ForEach(viewModel.aggAsks.sorted(by: >).suffix(GeneralSettingsPane.orderBookSize), id: \.key) { k, v in
                                if v > 0 {
                                    PriceLevel(k, v)
                                        .frame(width: geometry.size.width, height: 20)
                                }
                            }

                            if !viewModel.aggAsks.isEmpty {
                                Divider()
                                    .frame(width: geometry.size.width, height: 10)
                            }

                            ForEach(viewModel.aggBids.sorted(by: >).prefix(GeneralSettingsPane.orderBookSize), id: \.key) { k, v in
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
            }
                .onAppear {
                    isLoading = true
                    viewModel.start()
                }
            VStack(spacing: 0) {
                ForEach(viewModel.pong.keys.sorted(), id: \.self) { key in
                    Ex(key, viewModel.pong[key]!)
                }

                Spacer()
            }
                .frame(maxWidth: 230)
        }
    }

    init() {
        isLoading = false
        viewModel = DepthViewModel()
    }
}

extension DepthView {
    struct Ex: View {
        var name: String = ""
        @State var color: Color = .green
        @State var isActive: Bool

        var body: some View {

            HStack(spacing: 0) {
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                    .shadow(color: color, radius: 2)
                    .padding(.leading, 7)
                    .padding(.trailing, 7)
                Text(name)
                    .font(.system(size: 10))

                Spacer()
                Toggle(isOn: $isActive) {
                    Text("")
                }
                    .padding(.leading, 10)
                    .onChange(of: isActive) { value in
                        for i in 0..<DepthViewModel.exchangeServices.count {
                            if DepthViewModel.exchangeServices[i].0.name == name {
                                DepthViewModel.exchangeServices[i].1 = value
                            }
                        }
                    }
            }
        }

        init(_ name: String, _ pongReceived: Bool) {
            self.name = name
            color = pongReceived ? Color.green : Color.red
            isActive = true
        }
    }
}
