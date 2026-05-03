//
//  UIControl+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import UIKit
import SwiftUI


@available(iOS 17.0, *)
extension UIControl {

    /// Binds an `Equatable` property of this control to a SwiftUI
    /// `Binding`.
    ///
    /// - Parameters:
    ///   - binding: The two-way binding to mirror.
    ///   - get: Reads the control's current value.
    ///   - set: Writes a new value into the control.
    ///   - events: The events that should write *back* into the binding.
    ///     Defaults to `.valueChanged`.
    @MainActor
    internal func attach<Value: Equatable>(
        binding: Binding<Value>,
        get: @escaping @MainActor () -> Value,
        set: @escaping @MainActor (Value) -> Void,
        for events: UIControl.Event = .valueChanged,
        identifier: UIAction.Identifier = .init("Lucent.UIControl.binding")
    ) {
        // model -> control
        observe(identifier: identifier.rawValue) {
            let new = binding.wrappedValue
            if get() != new { set(new) }
        }
        
        // control -> model
        removeAction(identifiedBy: identifier, for: events)
        addAction(
            UIAction(identifier: identifier) { _ in
                MainActor.assumeIsolated {
                    let current = get()
                    if binding.wrappedValue != current {
                        binding.wrappedValue = current
                    }
                }
            },
            for: events
        )
    }
}
