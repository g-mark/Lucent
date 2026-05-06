//
//  NSObject+Observe.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import Foundation
import SwiftUI


extension NSObject {

    /// Runs `apply` immediately, then re-runs it whenever any observable
    /// state read inside the closure changes. The observer is retained
    /// for the lifetime of `self`; when `self` is deallocated, tracking
    /// stops automatically.
    ///
    /// You can call this multiple times on the same object to register
    /// multiple independent observations.
    /// If an observation is already registered with the same `identifier`, then
    /// the old observation will stop, and be released.
    @MainActor
    internal func observe(identifier: String, apply: @escaping @MainActor () -> Void) {
        let observer = Observer(apply: apply)
        observations[identifier] = observer
        observer.track()
    }

    @MainActor
    private var observations: Observations {
        if let bag = objc_getAssociatedObject(self, &observationsKey) as? Observations {
            return bag
        }
        let bag = Observations()
        objc_setAssociatedObject(self, &observationsKey, bag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return bag
    }

    @MainActor
    private final class Observations {
        private var observers: [String: AnyObject] = [:]

        subscript(_ identifier: String) -> AnyObject? {
            get { observers[identifier] }
            set { observers[identifier] = newValue }
        }
    }

    @MainActor
    private final class Observer {
        private let apply: @MainActor () -> Void

        init(apply: @escaping @MainActor () -> Void) {
            self.apply = apply
        }

        func track() {
            withObservationTracking {
                apply()
            }
            onChange: { [weak self] in
                // `onChange` fires synchronously *before* the mutation lands.
                // Hop to the next main-actor turn so that `apply` reads the
                // post-change value, and re-arm tracking.
                Task { @MainActor [weak self] in
                    self?.track()
                }
            }
        }
    }
}

private nonisolated(unsafe) var observationsKey: UInt8 = 0
