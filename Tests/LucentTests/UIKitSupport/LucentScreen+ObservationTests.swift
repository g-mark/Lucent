//
//  LucentScreen+ObservationTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation
import Testing
@testable import LucentCore

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
        var values: [UIKitObservationScreen.ViewState] = []

        screen.observe { viewState in
            values.append(viewState)
        }

        try await eventually {
            values == [.init(count: 1, title: "Initial")]
        }

        screen.viewModel.state = .init(count: 2, title: "Updated")

        try await eventually {
            values == [
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
        var values: [String] = []

        screen.observe(\.title) { title in
            values.append(title)
        }

        try await eventually {
            values == ["Initial"]
        }

        screen.viewModel.state = .init(count: 2, title: "Updated")

        try await eventually {
            values == ["Initial", "Updated"]
        }
    }

    @MainActor
    @Test func observesFullViewStateOldAndNewValues() {
        let screen = UIKitObservationScreenController(
            viewModel: .init(
                state: .init(count: 1, title: "Initial"),
                sendAction: { _ in },
                sendState: { _ in }
            )
        )
        var values: [String] = []

        screen.observe { oldState, viewState in
            values.append("\(oldState?.count ?? -1):\(oldState?.title ?? "nil")->\(viewState.count):\(viewState.title)")
        }

        screen.viewModel.state = .init(count: 2, title: "Middle")
        screen.viewModel.state = .init(count: 3, title: "Updated")

        #expect(values == [
            "-1:nil->1:Initial",
            "1:Initial->2:Middle",
            "2:Middle->3:Updated"
        ])
    }

    @MainActor
    @Test func equatableFullViewStateObservationIgnoresUnchangedValues() {
        let screen = UIKitObservationScreenController(
            viewModel: .init(
                state: .init(count: 1, title: "Initial"),
                sendAction: { _ in },
                sendState: { _ in }
            )
        )
        var values: [String] = []

        screen.observe { oldState, viewState in
            values.append("\(oldState?.count ?? -1):\(oldState?.title ?? "nil")->\(viewState.count):\(viewState.title)")
        }

        screen.viewModel.state = .init(count: 1, title: "Initial")
        screen.viewModel.state = .init(count: 2, title: "Updated")

        #expect(values == [
            "-1:nil->1:Initial",
            "1:Initial->2:Updated"
        ])
    }

    @MainActor
    @Test func equatableKeyPathObservationIgnoresUnchangedValues() {
        let screen = UIKitObservationScreenController(
            viewModel: .init(
                state: .init(count: 1, title: "Initial"),
                sendAction: { _ in },
                sendState: { _ in }
            )
        )
        var values: [String] = []

        screen.observe(\.title) { oldTitle, title in
            values.append("\(oldTitle ?? "nil")->\(title)")
        }

        screen.viewModel.state = .init(count: 2, title: "Initial")
        screen.viewModel.state = .init(count: 3, title: "Updated")

        #expect(values == [
            "nil->Initial",
            "Initial->Updated"
        ])
    }

    @MainActor
    @Test func equatableKeyPathObservationDeliversRapidBackToBackChanges() {
        let screen = UIKitObservationScreenController(
            viewModel: .init(
                state: .init(count: 1, title: "Initial"),
                sendAction: { _ in },
                sendState: { _ in }
            )
        )
        var values: [String] = []

        screen.observe(\.title) { oldTitle, title in
            values.append("\(oldTitle ?? "nil")->\(title)")
        }

        screen.viewModel.state = .init(count: 2, title: "Middle")
        screen.viewModel.state = .init(count: 3, title: "Initial")

        #expect(values == [
            "nil->Initial",
            "Initial->Middle",
            "Middle->Initial"
        ])
    }

    @MainActor
    @Test func nonEquatableKeyPathObservationDeliversEverySetValue() {
        let screen = NonEquatableObservationScreenController(
            viewModel: .init(
                state: .init(status: .init(identifier: 1)),
                sendAction: { _ in },
                sendState: { _ in }
            )
        )
        var values: [Int] = []

        screen.observe(\.status) { status in
            values.append(status.identifier)
        }

        screen.viewModel.state = .init(status: .init(identifier: 1))
        screen.viewModel.state = .init(status: .init(identifier: 2))

        #expect(values == [1, 1, 2])
    }

    @MainActor
    @Test func nonEquatableKeyPathObservationDeliversOldAndNewValues() {
        let screen = NonEquatableObservationScreenController(
            viewModel: .init(
                state: .init(status: .init(identifier: 1)),
                sendAction: { _ in },
                sendState: { _ in }
            )
        )
        var values: [String] = []

        screen.observe(\.status) { oldStatus, status in
            values.append("\(oldStatus?.identifier ?? -1)->\(status.identifier)")
        }

        screen.viewModel.state = .init(status: .init(identifier: 1))
        screen.viewModel.state = .init(status: .init(identifier: 2))

        #expect(values == [
            "-1->1",
            "1->1",
            "1->2"
        ])
    }

    @MainActor
    @Test func keyPathObservationDoesNotUseFullViewStateEquatableFiltering() {
        let screen = CustomEquatableObservationScreenController(
            viewModel: .init(
                state: .init(ignored: 1, title: "Initial"),
                sendAction: { _ in },
                sendState: { _ in }
            )
        )
        var values: [String] = []

        screen.observe(\.title) { oldTitle, title in
            values.append("\(oldTitle ?? "nil")->\(title)")
        }

        screen.viewModel.state = .init(ignored: 1, title: "Updated")

        #expect(values == [
            "nil->Initial",
            "Initial->Updated"
        ])
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

private enum NonEquatableObservationScreen: ScreenDefinition {
    struct State: Sendable { }
    enum Action: Sendable { case ignored }
    enum Output: Sendable { }

    struct ViewState: Sendable {
        var status: NonEquatableStatus
    }

    enum ViewAction: Sendable { case ignored }

    static let viewStateProjection = StateProjection<State, ViewState>(
        toViewState: { _ in .init(status: .init(identifier: 0)) },
        toState: { _, state in state }
    )

    static let toAction: @Sendable (ViewAction) -> Action = { _ in .ignored }

    static func create(initialState: State) -> Screen<Output> {
        fatalError("NonEquatableObservationScreen does not create a real screen.")
    }
}

private struct NonEquatableStatus: Sendable {
    var identifier: Int
}

@MainActor
private final class NonEquatableObservationScreenController: NSObject, LucentScreen {
    typealias Module = NonEquatableObservationScreen

    let viewModel: ViewModel<NonEquatableObservationScreen>

    init(viewModel: ViewModel<NonEquatableObservationScreen>) {
        self.viewModel = viewModel
    }
}

private enum CustomEquatableObservationScreen: ScreenDefinition {
    struct State: Sendable { }
    enum Action: Sendable { case ignored }
    enum Output: Sendable { }

    struct ViewState: Equatable, Sendable {
        var ignored: Int
        var title: String

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.ignored == rhs.ignored
        }
    }

    enum ViewAction: Sendable { case ignored }

    static let viewStateProjection = StateProjection<State, ViewState>(
        toViewState: { _ in .init(ignored: 0, title: "") },
        toState: { _, state in state }
    )

    static let toAction: @Sendable (ViewAction) -> Action = { _ in .ignored }

    static func create(initialState: State) -> Screen<Output> {
        fatalError("CustomEquatableObservationScreen does not create a real screen.")
    }
}

@MainActor
private final class CustomEquatableObservationScreenController: NSObject, LucentScreen {
    typealias Module = CustomEquatableObservationScreen

    let viewModel: ViewModel<CustomEquatableObservationScreen>

    init(viewModel: ViewModel<CustomEquatableObservationScreen>) {
        self.viewModel = viewModel
    }
}
