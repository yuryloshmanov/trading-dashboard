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
                    VStack(spacing: 0) {
                        Spacer()
                        BellCurve((5 + viewModel.selling.reduce(0, +)) / 20 * geometry.size.height / 3)
                            .fill(.red)
                    }

                }
                ZStack {
                    VStack(spacing: 0) {
                        Spacer()
                        BellCurve((5 + viewModel.buying.reduce(0, +)) / 20 * geometry.size.height / 3)
                            .fill(.green)
                    }
                }
            }

                .onAppear {
                    viewModel.listenServer()
                }

        }
    }

    init() {
        viewModel = TradesViewModel()
    }
}
