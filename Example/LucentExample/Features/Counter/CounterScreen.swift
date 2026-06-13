//
//  CounterScreen.swift
//  LucentExample
//
//  Created by Steven Grosmark on 5/7/26.
//

import Lucent

enum CounterScreen: ScreenDefinition {

    struct State: Equatable, Sendable {
        var count = 0
        var fact: String?
        var factIsLoading = false
    }

    @ViewActions
    enum Action: Sendable {
        // `@ViewAction` annotated cases are sendable by the view
        @viewAction case decrementButtonTapped
        @viewAction case incrementButtonTapped
        @viewAction case factButtonTapped

        // The view layer shouldn't be allowed to hijack the fact
        // loading process, so this case isn't `@ViewAction`.
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
