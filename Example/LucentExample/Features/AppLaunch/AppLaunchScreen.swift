//
//  AppLaunchScreen.swift
//  LucentExample
//
//  Created by Steven Grosmark on 4/15/26.
//

import Lucent

enum AppLaunchScreen: ScreenDefinition {

    struct State: Equatable {
        var status: String = ""
    }

    enum Action {
        case viewDidLoad
        case workingOn(String)
        case finished(Error?)
        static var finished: Action { .finished(nil) }
    }

    enum Output {
        case appLaunchFinished(Error?)
    }

    static func create() -> Screen<Output> {
        create(initialState: State())
    }

    static func create(initialState: State) -> Screen<Output> {
        let store = AppLaunchScreenStore(state: initialState)
        return Screen(
            viewController: AppLaunchViewController(viewModel: store.viewModel),
            store: store
        )
    }
}
