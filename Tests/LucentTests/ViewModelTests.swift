//
//  ViewModelTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Testing
@testable import Lucent

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
        let actions = Recorder<ViewModelTestScreen.ViewAction>()
        let viewModel = ViewModel<ViewModelTestScreen>(
            state: .init(count: 0, title: "Initial"),
            sendAction: { action in
                Task {
                    await actions.append(action)
                }
            },
            sendState: { _ in }
        )

        viewModel.send(action: .increment)
        viewModel.send(action: .submit("Done"))

        try await eventually {
            await actions.values == [.increment, .submit("Done")]
        }
    }

    @MainActor
    @Test func sendsStateChangesToHandler() async throws {
        let states = Recorder<ViewModelTestScreen.ViewState>()
        let viewModel = ViewModel<ViewModelTestScreen>(
            state: .init(count: 0, title: "Initial"),
            sendAction: { _ in },
            sendState: { state in
                await states.append(state)
            }
        )

        viewModel.state = .init(count: 4, title: "Updated")

        try await eventually {
            await states.values == [.init(count: 4, title: "Updated")]
        }
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
