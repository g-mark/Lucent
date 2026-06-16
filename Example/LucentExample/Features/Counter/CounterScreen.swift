//
//  CounterScreen.swift
//  LucentExample
//
//  Created by Steven Grosmark on 5/7/26.
//

import Lucent

enum CounterScreen: ScreenDefinition {

    @ViewState
    struct State: Equatable, Sendable {
        @ViewFacing(.readOnly) var count: Int = 0
        @ViewFacing(.readOnly) var fact: String?
        @ViewFacing(.readOnly) var factIsLoading: Bool = false
    }

    @ViewActions
    enum Action: Sendable {
        // `@ViewFacing` annotated cases are sendable by the view
        @ViewFacing case decrementButtonTapped
        @ViewFacing case incrementButtonTapped
        @ViewFacing case factButtonTapped

        // The view layer shouldn't be allowed to hijack the fact
        // loading process, so this case isn't `@ViewFacing`.
        case factLoaded(String)
    }

    static func create(initialState: State) -> Screen<Never> {
        create(initialState: initialState, uiStack: .swiftui)
    }

    static func create(initialState: State, uiStack: UIStack) -> Screen<Never> {
        let store = CounterScreenStore(state: initialState)
        return switch uiStack {

        case .uikit:
            Screen(
                viewController: CounterScreenViewController(viewModel: store.viewModel),
                store: store
            )

        case .swiftui:
            Screen(
                view: CounterScreenView(viewModel: store.viewModel),
                store: store
            )
        }
    }

    enum UIStack {
        case uikit, swiftui
    }
}
