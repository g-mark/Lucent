//
//  ScreenTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/6/26.
//

import SwiftUI
import Testing
import UIKit
import LucentCore

@Suite("Screen")
struct ScreenTests {

    @MainActor
    @Test func viewControllerInitializerUsesProvidedViewController() {
        let viewController = UIViewController()
        let store = ScreenTestStore(state: .init())

        let screen = Screen(viewController: viewController, store: store)

        #expect(screen.viewController === viewController)
    }

    @MainActor
    @Test func swiftUIViewInitializerWrapsViewInHostingController() {
        let store = ScreenTestStore(state: .init())

        let screen = Screen(view: ScreenTestView(), store: store)

        #expect(screen.viewController is UIHostingController<ScreenTestView>)
    }

    @MainActor
    @Test func observeForwardsStoreOutputs() async throws {
        let store = ScreenTestStore(state: .init())
        let screen = Screen(viewController: UIViewController(), store: store)
        let outputs = LockedRecorder<ScreenTestModule.Output>()

        screen.observe { output in
            outputs.append(output)
        }
        await allowStoreObserversToRegister()

        store.viewModel.send(action: .submit("Done"))

        try await outputs.waitForValues([.message("Done")])
    }

    @MainActor
    @Test func observeReturnsScreen() {
        let viewController = UIViewController()
        let store = ScreenTestStore(state: .init())
        let screen = Screen(viewController: viewController, store: store)

        let returnedScreen = screen.observe { _ in }

        #expect(returnedScreen.viewController === viewController)
    }

    @MainActor
    @Test func captureAssignsViewControllerAndReturnsScreen() {
        let viewController = UIViewController()
        let store = ScreenTestStore(state: .init())
        let screen = Screen(viewController: viewController, store: store)
        var capturedViewController: UIViewController?

        let returnedScreen = screen.capture(&capturedViewController)

        #expect(capturedViewController === viewController)
        #expect(returnedScreen.viewController === viewController)
    }

    @MainActor
    @Test func viewControllerRetainsStoreForItsLifetime() {
        weak var weakStore: ScreenTestStore?
        var retainedViewController: UIViewController?

        do {
            let viewController = UIViewController()
            let store = ScreenTestStore(state: .init())
            weakStore = store

            let screen = Screen(viewController: viewController, store: store)
            retainedViewController = screen.viewController
        }

        #expect(retainedViewController != nil)
        #expect(weakStore != nil)

        retainedViewController = nil

        #expect(weakStore == nil)
    }
}

private enum ScreenTestModule: ScreenDefinition {
    struct State: Sendable { }

    enum Action: Sendable {
        case submit(String)
    }

    enum Output: Equatable, Sendable {
        case message(String)
    }

    enum ViewAction: Sendable {
        case submit(String)
    }

    static let viewStateProjection = StateProjection<State, State>(
        toViewState: { $0 },
        toState: { viewState, _ in viewState }
    )

    static let toAction: @Sendable (ViewAction) -> Action = { viewAction in
        switch viewAction {
        case .submit(let message):
            .submit(message)
        }
    }

    static func create(initialState: State) -> Screen<Output> {
        fatalError("ScreenTestModule does not create a real screen.")
    }
}

@MainActor
private final class ScreenTestStore: Store<ScreenTestModule> {
    override func handleAction(
        action: ScreenTestModule.Action,
        state: inout ScreenTestModule.State,
        store: StoreAccess
    ) {
        switch action {
        case .submit(let message):
            store.sendOutput(.message(message))
        }
    }
}

private struct ScreenTestView: View {
    var body: some View {
        Text("Test")
    }
}
