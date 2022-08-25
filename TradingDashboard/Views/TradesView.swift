//
// Created by Yury Loshmanov on 02.08.2022.
//

import SwiftUI

struct TradesView: View {
    @ObservedObject var viewModel: TradesViewModel

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer()
                ZStack {
                    Rectangle()
                        .fill(.black)
                        .frame(width: 70, height: geometry.size.height)

                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(.red)
                            .frame(width: 70, height: (5 + viewModel.selling.reduce(0, +)) / 20 * geometry.size.height)
                    }

                }
                ZStack {
                    Rectangle()
                        .fill(.black)
                        .frame(width: 70, height: geometry.size.height)

                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(.green)
                            .frame(width: 70, height: (5 + viewModel.buying.reduce(0, +)) / 20 * geometry.size.height)
                    }
                }
//                Spacer()
            }
        }
            .onAppear {
                viewModel.listenServer()
            }
    }

    init() {
        viewModel = TradesViewModel()
    }
}
