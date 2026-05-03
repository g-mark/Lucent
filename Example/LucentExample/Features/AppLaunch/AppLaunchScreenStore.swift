//
//  AppLaunchScreenStore.swift
//  LucentExample
//
//  Created by Steven Grosmark on 4/15/26.
//

import Lucent

final class AppLaunchScreenStore: Store<AppLaunchScreen> {

    override func handleAction(action: Action, state: inout State, store: StoreAccess) {
        switch action {

        case .viewDidLoad:
            store.runSideEffect { [weak self] actions in
                await self?.initializeTheApp(with: actions)
            }

        case .workingOn(let verbing):
            state.status = verbing

        case .finished(let error):
            store.sendOutput(.appLaunchFinished(error))
        }
    }

    private func initializeTheApp(with actions: ActionAccess) async {
        do {
            for step in ["Initializing", "Connecting", "Loading"] {
                await actions.send(.workingOn(step))
                try await Task.sleep(for: .seconds(Double.random(in: 0.2...0.4)))
            }
        }
        catch {
            await actions.send(.finished(error))
        }
        await actions.send(.finished)
    }
}
