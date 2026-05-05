//
//  LucentScreen+ObservationTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation
import Testing
@testable import Lucent

@Suite("LucentScreen+Observation")
struct LucentScreenObservationTests {

    @MainActor
    @Test func observesFullViewState() async throws {
        let screen = UIKitObservationScreenController(
            viewModel: .init(
                state: .init(count: 1, title: "Initial"),
                sendAction: { _ in },
                sendState: { _ in }
            )
        )
        let values = Recorder<UIKitObservationScreen.ViewState>()

        screen.observe { viewState in
            Task {
                await values.append(viewState)
            }
        }

        try await eventually {
            await values.values == [.init(count: 1, title: "Initial")]
        }

        screen.viewModel.state = .init(count: 2, title: "Updated")

        try await eventually {
            await values.values == [
                .init(count: 1, title: "Initial"),
                .init(count: 2, title: "Updated")
            ]
        }
    }

    @MainActor
    @Test func observesViewStateKeyPath() async throws {
        let screen = UIKitObservationScreenController(
            viewModel: .init(
                state: .init(count: 1, title: "Initial"),
                sendAction: { _ in },
                sendState: { _ in }
            )
        )
        let values = Recorder<String>()

        screen.observe(\.title) { title in
            Task {
                await values.append(title)
            }
        }

        try await eventually {
            await values.values == ["Initial"]
        }

        screen.viewModel.state = .init(count: 2, title: "Updated")

        try await eventually {
            await values.values == ["Initial", "Updated"]
        }
    }
}

private enum UIKitObservationScreen: ScreenDefinition {
    struct State: Sendable { }
    enum Action: Sendable { case ignored }
    enum Output: Sendable { }

    struct ViewState: Equatable, Sendable {
        var count: Int
        var title: String
    }

    enum ViewAction: Sendable { case ignored }

    static let viewStateProjection = StateProjection<State, ViewState>(
        toViewState: { _ in .init(count: 0, title: "") },
        toState: { _, state in state }
    )

    static let toAction: @Sendable (ViewAction) -> Action = { _ in .ignored }

    static func create(initialState: State) -> Screen<Output> {
        fatalError("UIKitObservationScreen does not create a real screen.")
    }
}

@MainActor
private final class UIKitObservationScreenController: NSObject, LucentScreen {
    typealias Module = UIKitObservationScreen

    let viewModel: ViewModel<UIKitObservationScreen>

    init(viewModel: ViewModel<UIKitObservationScreen>) {
        self.viewModel = viewModel
    }
}
