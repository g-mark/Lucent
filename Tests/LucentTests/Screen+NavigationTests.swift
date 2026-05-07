//
//  Screen+NavigationTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/6/26.
//

import Testing
import UIKit
@testable import Lucent

@Suite("Screen+Navigation")
struct ScreenNavigationTests {

    @MainActor
    @Test func pushInstallsRootViewControllerWhenNavigationStackIsEmpty() {
        let viewController = UIViewController()
        let navController = UINavigationController()
        let screen = Screen(
            viewController: viewController,
            store: Store<NavigationTestScreen>(state: .init())
        )

        screen.push(onto: navController, animated: true)

        #expect(navController.viewControllers.count == 1)
        #expect(navController.viewControllers.first === viewController)
    }

    @MainActor
    @Test func pushAppendsViewControllerWhenNavigationStackHasRoot() {
        let rootViewController = UIViewController()
        let viewController = UIViewController()
        let navController = UINavigationController(rootViewController: rootViewController)
        let screen = Screen(
            viewController: viewController,
            store: Store<NavigationTestScreen>(state: .init())
        )

        screen.push(onto: navController, animated: false)

        #expect(navController.viewControllers.count == 2)
        #expect(navController.viewControllers.first === rootViewController)
        #expect(navController.viewControllers.last === viewController)
    }
}

private enum NavigationTestScreen: ScreenDefinition {
    struct State: Sendable { }

    static func create(initialState: State) -> Screen<Never> {
        fatalError("NavigationTestScreen does not create a real screen.")
    }
}
