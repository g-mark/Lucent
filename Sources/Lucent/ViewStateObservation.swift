//
//  ViewStateObservation.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation


/// Store-facing access to view-state observation.
///
/// Observations last the lifetime of the `Store` / `ViewModel`.
@MainActor
public struct ViewStateObservation<Screen: ScreenDefinition> {
    public typealias ViewState = Screen.ViewState

    private let viewModel: ViewModel<Screen>

    internal init(viewModel: ViewModel<Screen>) {
        self.viewModel = viewModel
    }

    /// Observe (non-`Equatable`) view state, receiving both old and new values.
    ///
    /// Calls the handler immediately with current state and `nil` old value,
    /// then every subsequent time the view state is **set**.
    public func observe(
        apply: @escaping @MainActor (ViewState?, ViewState) -> Void
    ) {
        _observe(apply: apply)
    }

    fileprivate func _observe(
        apply: @escaping @MainActor (ViewState?, ViewState) -> Void
    ) {
        viewModel.addStateObserver(identifier: UUID(), onChange: apply)
        apply(nil, viewModel.state)
    }
}

extension ViewStateObservation where ViewState: Equatable {

    /// Observe `Equatable` view state changes, receiving both old and new values.
    ///
    /// Calls the handler immediately with the current state (and `nil` old value),
    /// then on every subsequent value change.
    public func observe(
        apply: @escaping @MainActor (ViewState?, ViewState) -> Void
    ) {
        _observe { oldState, newState in
            if oldState != newState {
                apply(oldState, newState)
            }
        }
    }

    /// Observe `Equatable` view state changes.
    ///
    /// Calls the handler immediately with the current state, then on every subsequent value change.
    public func observe(
        apply: @escaping @MainActor (ViewState) -> Void
    ) {
        observe { _, viewState in
            apply(viewState)
        }
    }
}

extension ViewStateObservation {

    /// Observe (non-`Equatable`) view state.
    ///
    /// Calls the handler immediately with current state (and `nil` old value),
    /// then every subsequent time the view state is **set**.
    public func observe(
        apply: @escaping @MainActor (ViewState) -> Void
    ) {
        observe { _, viewState in
            apply(viewState)
        }
    }

    /// Observe a non-`Equatable` part of the view state, receiving both old and new values.
    ///
    /// Calls the handler immediately with the current value (and `nil` old value),
    /// then every subsequent time the view state is **set**.
    public func observe<Value>(
        _ keyPath: KeyPath<ViewState, Value>,
        apply: @escaping @MainActor (Value?, Value) -> Void
    ) {
        _observe { oldState, viewState in
            apply(oldState?[keyPath: keyPath], viewState[keyPath: keyPath])
        }
    }

    /// Observe an `Equatable` part of the view state, receiving both old and new values.
    ///
    /// Calls the handler immediately with the current value (and `nil` old value),
    /// then every subsequent time the value changes.
    public func observe<Value: Equatable>(
        _ keyPath: KeyPath<ViewState, Value>,
        apply: @escaping @MainActor (Value?, Value) -> Void
    ) {
        _observe { oldState, viewState in
            let oldValue = oldState?[keyPath: keyPath]
            let newValue = viewState[keyPath: keyPath]
            if newValue != oldValue {
                apply(oldValue, newValue)
            }
        }
    }

    /// Observe a non-`Equatable` part of the view state.
    ///
    /// Calls the handler immediately with the current value, then again every time the view state is **set**.
    public func observe<Value>(
        _ keyPath: KeyPath<ViewState, Value>,
        apply: @escaping @MainActor (Value) -> Void
    ) {
        _observe { _, viewState in
            apply(viewState[keyPath: keyPath])
        }
    }

    /// Observe an `Equatable` part of the view state.
    ///
    /// Calls the handler immediately with the current value, then again every time the value changes.
    public func observe<Value: Equatable>(
        _ keyPath: KeyPath<ViewState, Value>,
        apply: @escaping @MainActor (Value) -> Void
    ) {
        _observe { oldState, viewState in
            let oldValue = oldState?[keyPath: keyPath]
            let newValue = viewState[keyPath: keyPath]
            if newValue != oldValue {
                apply(newValue)
            }
        }
    }
}
