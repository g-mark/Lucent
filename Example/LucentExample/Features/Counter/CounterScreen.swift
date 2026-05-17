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
        @viewAction case decrementButtonTapped
        @viewAction case incrementButtonTapped
        @viewAction case factButtonTapped

        case factLoaded(String)
    }

    static func create(initialState: State) -> Screen<Never> {
        let store = CounterScreenStore(state: initialState)
        return Screen(
            viewController: CounterViewController(viewModel: store.viewModel),
            store: store
        )
    }
}
