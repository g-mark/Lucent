//
//  LucentScreen+Observation.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/3/26.
//

import Foundation


@MainActor
extension LucentScreen where Self: NSObject {

    /// Keeps UIKit UI in sync with a single view-state value.
    ///
    /// Example:
    ///
    ///     observe(\.status) { [weak self] status in
    ///         self?.statusLabel.text = status
    ///     }
    ///
    public func observe<Value>(
        _ keyPath: KeyPath<Module.ViewState, Value>,
        apply: @escaping @MainActor (Value) -> Void
    ) {
        observe(viewModel) { viewModel in
            apply(viewModel.state[keyPath: keyPath])
        }
    }

    /// Keeps UIKit UI in sync with a single view-state value.
    ///
    /// Example:
    ///
    ///     observe(\.status) { [weak self] status in
    ///         self?.statusLabel.text = status
    ///     }
    ///
    public func observe<Value: Equatable>(
        _ keyPath: KeyPath<Module.ViewState, Value>,
        apply: @escaping @MainActor (Value) -> Void
    ) {
        observe(viewModel) { viewModel in
            apply(viewModel.state[keyPath: keyPath])
        }
    }

    /// Keeps UIKit UI in sync with any values read from the full view state.
    ///
    /// Example:
    ///
    ///     observe { [weak self] viewState in
    ///         self?.statusLabel.text = viewState.status
    ///     }
    ///
    public func observe(
        apply: @escaping @MainActor (Module.ViewState) -> Void
    ) {
        observe(viewModel) { viewModel in
            apply(viewModel.state)
        }
    }

    /// Keeps UIKit UI in sync with read-only values from an observed model.
    ///
    /// The returned token is retained by the receiver. Store the token only if
    /// you need to cancel observation before the receiver is deallocated.
    private func observe<Model: AnyObject>(
        _ model: Model,
        apply: @escaping @MainActor (Model) -> Void
    ) {
        holdReference(
            to: ObservationToken(model: model, apply: apply)
        )
    }
}
