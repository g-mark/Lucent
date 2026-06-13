//
//  CounterScreenView.swift
//  LucentExample
//
//  Created by Steven Grosmark on 6/11/26.
//

import SwiftUI
import Lucent


struct CounterScreenView: View {

    @Bindable var viewModel: ViewModel<CounterScreen>

    @State private var countButtonsWidth: CGFloat = 1

    var body: some View {
        inputs
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottom) {
                outputs
                    .alignmentGuide(
                        .bottom,
                        computeValue: { $0[.top]}
                    )
            }
    }

    @ViewBuilder
    private var inputs: some View {
        VStack {
            VStack {
                Text(String(viewModel.count))
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
                HStack {
                    Button("Decrement") {
                        viewModel.send(action: .decrementButtonTapped)
                    }
                    Button("Increment") {
                        viewModel.send(action: .incrementButtonTapped)
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .onGeometryChange(
                    for: CGFloat.self,
                    of: { g in g.size.width },
                    action: { countButtonsWidth = $0 }
                )

                Button {
                    viewModel.send(action: .factButtonTapped)
                } label: {
                    Text("Get fact")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BorderedButtonStyle())
                .frame(width: countButtonsWidth)
            }
            .disabled(viewModel.factIsLoading)
        }
    }

    @ViewBuilder
    private var outputs: some View {
        VStack {
            if viewModel.factIsLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding()
            }
            if let fact = viewModel.fact, !fact.isEmpty {
                Text(fact)
                    .padding()
            }
        }
    }
}

// MARK: - Previews

#Preview {
    @Previewable @State var store = CounterScreenStore(
        state: .init()
    )
    CounterScreenView(
        viewModel: .previewable(
            state: .init()
        )
    )
}

#Preview("Loading") {
    @Previewable @State var store = CounterScreenStore(
        state: .init(
            count: 42,
            fact: nil,
            factIsLoading: true
        )
    )
    CounterScreenView(viewModel: store.viewModel)
}

#Preview("Fact-based") {
    @Previewable @State var store = CounterScreenStore(
        state: .init(
            count: 42,
            fact: "The meaning of life",
            factIsLoading: false
        )
    )
    CounterScreenView(viewModel: store.viewModel)
}
