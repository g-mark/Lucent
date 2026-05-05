//
//  StoreTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import Foundation
import Evident
import Testing
@testable import Lucent

@Suite("Store")
struct StoreTests {

    @MainActor
    @Test func viewModelUsesProjectedInitialState() {
        let store = TestStore(state: .init(count: 3, name: "initial"))

        #expect(store.viewModel.state == .init(count: 3))
        #expect(store.viewModel.count == 3)
    }

    @MainActor
    @Test func viewActionIsMappedAndUpdatesViewModelState() async throws {
        let store = TestStore(state: .init(count: 3, name: "initial"))
        await allowStoreObserversToRegister()

        store.viewModel.send(action: .incrementTapped)

        try await eventually {
            store.viewModel.count == 4
        }
    }

    @MainActor
    @Test func outputHandlersReceiveOutputsFromHandledActions() async throws {
        let store = TestStore(state: .init(count: 0, name: "initial"))
        let outputs = Recorder<TestScreen.Output>()

        store.observe { output in
            await outputs.append(output)
        }
        await allowStoreObserversToRegister()

        store.viewModel.send(action: .submit("done"))

        try await eventually {
            await outputs.values == [.message("done")]
        }
    }

    @MainActor
    @Test func viewStateChangesUpdateStoreStateBeforeLaterActions() async throws {
        let store = TestStore(state: .init(count: 1, name: "preserved"))
        let outputs = Recorder<TestScreen.Output>()

        store.observe { output in
            await outputs.append(output)
        }
        await allowStoreObserversToRegister()

        store.viewModel.state = .init(count: 7)
        try await eventually {
            await store.observedViewStates.values.contains(.init(count: 7))
        }

        store.viewModel.send(action: .reportCount)

        try await eventually {
            await outputs.values == [.count(7)]
        }
    }

    @MainActor
    @Test func sideEffectsCanDispatchFollowUpActions() async throws {
        let store = TestStore(state: .init(count: 2, name: "initial"))
        await allowStoreObserversToRegister()

        store.viewModel.send(action: .startSideEffect(amount: 5))

        try await eventually {
            store.viewModel.count == 7
        }
    }
}

private enum TestScreen: ScreenDefinition {
    struct State: Equatable, Sendable {
        var count: Int
        var name: String
    }

    enum Action: Equatable, Sendable {
        case increment
        case submit(String)
        case reportCount
        case startSideEffect(amount: Int)
        case finishSideEffect(amount: Int)
    }

    enum Output: Equatable, Sendable {
        case message(String)
        case count(Int)
    }

    struct ViewState: Equatable, Sendable {
        var count: Int
    }

    enum ViewAction: Equatable, Sendable {
        case incrementTapped
        case submit(String)
        case reportCount
        case startSideEffect(amount: Int)
    }

    static let viewStateProjection = StateProjection<State, ViewState>(
        toViewState: { state in
            ViewState(count: state.count)
        },
        toState: { viewState, state in
            State(count: viewState.count, name: state.name)
        }
    )

    static let toAction: @Sendable (ViewAction) -> Action = { viewAction in
        switch viewAction {
        case .incrementTapped:
            .increment
        case .submit(let message):
            .submit(message)
        case .reportCount:
            .reportCount
        case .startSideEffect(let amount):
            .startSideEffect(amount: amount)
        }
    }

    static func create(initialState: State) -> Screen<Output> {
        fatalError("TestScreen does not create a real screen.")
    }
}

@MainActor
private final class TestStore: Store<TestScreen> {
    let observedViewStates = Recorder<TestScreen.ViewState>()
    private var viewStateObservation: AnyCancellableAsync?

    override func setUpViewStateObservation(viewState: any ObservableValue<TestScreen.ViewState>) {
        viewStateObservation = viewState.observe(\.self) { [observedViewStates] _, viewState in
            await observedViewStates.append(viewState)
        }
    }

    override func handleAction(
        action: TestScreen.Action,
        state: inout TestScreen.State,
        store: StoreAccess
    ) {
        switch action {
        case .increment:
            state.count += 1

        case .submit(let message):
            store.sendOutput(.message(message))

        case .reportCount:
            store.sendOutput(.count(state.count))

        case .startSideEffect(let amount):
            store.runSideEffect { access in
                await access.send(.finishSideEffect(amount: amount))
            }

        case .finishSideEffect(let amount):
            state.count += amount
        }
    }
}

private func allowStoreObserversToRegister() async {
    for _ in 0..<10 {
        await Task.yield()
    }
}
