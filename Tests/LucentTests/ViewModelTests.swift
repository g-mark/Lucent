//
//  ViewModelTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation
import Testing
@testable import LucentCore

@Suite("ViewModel")
struct ViewModelTests {

    @MainActor
    @Test func exposesInitialStateAndDynamicMemberReads() {
        let viewModel = ViewModel<ViewModelTestScreen>(
            state: .init(count: 3, title: "Initial"),
            sendAction: { _ in },
            sendState: { _ in }
        )

        #expect(viewModel.state == .init(count: 3, title: "Initial"))
        #expect(viewModel.count == 3)
        #expect(viewModel.title == "Initial")
    }

    @MainActor
    @Test func sendsActionsToHandler() async throws {
        let actions = LockedRecorder<ViewModelTestScreen.ViewAction>()
        let viewModel = ViewModel<ViewModelTestScreen>(
            state: .init(count: 0, title: "Initial"),
            sendAction: { action in
                actions.append(action)
            },
            sendState: { _ in }
        )

        viewModel.send(action: .increment)
        viewModel.send(action: .submit("Done"))

        try await eventually {
            actions.values == [.increment, .submit("Done")]
        }
    }

    @MainActor
    @Test func sendsStateChangesToHandler() {
        var states: [ViewModelTestScreen.ViewState] = []
        let viewModel = ViewModel<ViewModelTestScreen>(
            state: .init(count: 0, title: "Initial"),
            sendAction: { _ in },
            sendState: { state in
                states.append(state)
            }
        )

        viewModel.state = .init(count: 4, title: "Updated")

        #expect(states == [.init(count: 4, title: "Updated")])
    }

    @MainActor
    @Test func sendsRapidStateChangesToHandler() {
        var states: [ViewModelTestScreen.ViewState] = []
        let viewModel = ViewModel<ViewModelTestScreen>(
            state: .init(count: 0, title: "Initial"),
            sendAction: { _ in },
            sendState: { state in
                states.append(state)
            }
        )

        viewModel.state = .init(count: 1, title: "Middle")
        viewModel.state = .init(count: 2, title: "Updated")

        #expect(states == [
            .init(count: 1, title: "Middle"),
            .init(count: 2, title: "Updated")
        ])
    }

    @MainActor
    @Test func removedStateObserverDoesNotReceiveStateChanges() {
        var states: [ViewModelTestScreen.ViewState] = []
        let viewModel = ViewModel<ViewModelTestScreen>(
            state: .init(count: 0, title: "Initial"),
            sendAction: { _ in },
            sendState: { _ in }
        )
        let identifier = UUID()

        viewModel.addStateObserver(identifier: identifier) { _, state in
            states.append(state)
        }
        viewModel.removeStateObserver(identifier: identifier)

        viewModel.state = .init(count: 1, title: "Updated")

        #expect(states == [])
    }

    @MainActor
    @Test func previewableUsesProvidedStateAndIgnoresActions() {
        let viewModel = ViewModel<ViewModelTestScreen>.previewable(
            state: .init(count: 9, title: "Preview")
        )

        #expect(viewModel.state == .init(count: 9, title: "Preview"))
        #expect(viewModel.count == 9)

        viewModel.send(action: .increment)

        #expect(viewModel.state == .init(count: 9, title: "Preview"))
    }
}

private enum ViewModelTestScreen: ScreenDefinition {
    struct State: Sendable { }
    enum Action: Sendable {
        case ignored
    }
    enum Output: Sendable { }

    struct ViewState: Equatable, Sendable {
        var count: Int
        var title: String
    }

    enum ViewAction: Equatable, Sendable {
        case increment
        case submit(String)
    }

    static let viewStateProjection = StateProjection<State, ViewState>(
        toViewState: { _ in
            ViewState(count: 0, title: "")
        },
        toState: { _, state in
            state
        }
    )

    static let toAction: @Sendable (ViewAction) -> Action = { _ in
        .ignored
    }

    static func create(initialState: State) -> Screen<Output> {
        fatalError("ViewModelTestScreen does not create a real screen.")
    }
}
