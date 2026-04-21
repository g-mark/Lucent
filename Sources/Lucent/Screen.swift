//
//  Screen.swift
//  Lucent
//
//  Created by Steven Grosmark on 3/7/26.
//

import UIKit
import SwiftUI


/// Ephemeral type used during screen creation
@MainActor
public struct Screen<Output: Sendable> {

    public let viewController: UIViewController

    fileprivate let _observe: (@escaping @MainActor @Sendable (Output) async -> Void) -> Void

    /// Create a Screen usinf a SwiftUI `View`.
    public init<Content: View, Module: ScreenDefinition>(
        view: Content,
        store: Store<Module>
    ) where Module.Output == Output {
        self.init(
            viewController: UIHostingController(rootView: view),
            store: store
        )
    }

    /// Create a screen with a `UIViewController`.
    public init<Module: ScreenDefinition>(
        viewController: UIViewController,
        store: Store<Module>
    ) where Module.Output == Output {
        self.viewController = viewController
        self._observe = { handler in
            store.observe(outputHandler: handler)
        }

        // The view controller owns the store's lifetime
        viewController.holdReference(to: store)
    }
}

extension Screen {

    /// Observe the screen's `Output` events.
    @discardableResult
    public func observe(handler: @escaping @MainActor @Sendable (Output) async -> Void) -> Self {
        _observe(handler)
        return self
    }
}

extension Screen {

    /// Capture the screen's `UIViewController`.
    @discardableResult
    public func capture(_ controller: inout UIViewController?) -> Self {
        controller = viewController
        return self
    }
}
