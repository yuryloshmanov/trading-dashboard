//
// Created by Yury Loshmanov on 02.08.2022.
//

import SwiftUI

struct LiquidationsView: View {
    @ObservedObject var viewModel: LiquidationsViewModel

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer()
                ZStack {
                    VStack(spacing: 0) {
                        Spacer()
                        BellCurve((5 + viewModel.short.reduce(0, +)) / 20 * geometry.size.height / 3)
                            .fill(.red)
                            .frame(width: 70, height: (5 + viewModel.short.reduce(0, +)) / 20 * geometry.size.height / 3)
                    }

                }
                ZStack {
                    VStack(spacing: 0) {
                        Spacer()
                        BellCurve((5 + viewModel.long.reduce(0, +)) / 20 * geometry.size.height / 3)
                            .fill(.green)
                            .frame(width: 70, height: (5 + viewModel.long.reduce(0, +)) / 20 * geometry.size.height / 3)
                    }
                }
            }
        }
            .onAppear {
                viewModel.listenServer()
            }
    }

    init() {
        viewModel = LiquidationsViewModel()
    }
}
