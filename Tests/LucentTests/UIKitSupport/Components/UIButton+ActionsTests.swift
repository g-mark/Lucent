//
//  UIButton+ActionsTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 6/7/26.
//

import Testing
import UIKit
@testable import LucentCore


@Suite("UIButton+Actions")
struct UIButtonActionsTests {

    @MainActor
    @Test func onTapSendsViewAction() async throws {
        let actions = LockedRecorder<ButtonActionScreen.ViewAction>()
        let viewModel = ViewModel<ButtonActionScreen>(
            state: EmptyState(),
            sendAction: { action in
                actions.append(action)
            },
            sendState: { _ in }
        )
        let button = UIButton(type: .system)

        button.onTap(send: .incrementTapped, to: viewModel)
        button.sendActions(for: .touchUpInside)

        try await eventually {
            actions.values == [.incrementTapped]
        }
    }
}

private enum ButtonActionScreen: ScreenDefinition {
    enum Action: Equatable, Sendable {
        case incrementTapped
    }

    static func create(initialState: EmptyState) -> Screen<Never> {
        fatalError("ButtonActionScreen does not create a real screen.")
    }
}
