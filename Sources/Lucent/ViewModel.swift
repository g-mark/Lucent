//
//  ViewModel.swift
//  Lucent
//
//  Created by Steven Grosmark on 3/7/26.
//

import Foundation
import SwiftUI


/// Access to screen state and actions specifically for a view.
///
/// These are generally only created by a screen's `Store`.
///
/// - read/write access to some state
/// - actions can be sent
///
@MainActor
@Observable
@dynamicMemberLookup
public final class ViewModel<Screen: ScreenDefinition> {
    public typealias ViewState = Screen.ViewState
    public typealias ViewAction = Screen.ViewAction

    public var state: ViewState {
        didSet {
            handleStateChange(from: oldValue, to: state)
        }
    }

    /// The `ViewModel` holds all observation closures:
    /// - The internal one to send implicit state changes (view Bindings) back to the store; and
    /// - any observations registered in a `Store` subclass' `setUpViewStateObservation`.
    @ObservationIgnored
    private var stateObservers: [UUID: @MainActor (ViewState, ViewState) -> Void] = [:]

    @ObservationIgnored
    private let _sendAction: @Sendable (ViewAction) -> Void

    @ObservationIgnored
    private let _sendState: @MainActor @Sendable (ViewState) -> Void

    init(
        state: ViewState,
        sendAction: @escaping @Sendable (ViewAction) -> Void,
        sendState: @escaping @MainActor @Sendable (ViewState) -> Void
    ) {
        self.state = state
        self._sendAction = sendAction
        self._sendState = sendState
    }

    public func send(action: ViewAction) {
        _sendAction(action)
    }

    /// Read access to any state property.
    public subscript<Value>(dynamicMember keyPath: KeyPath<ViewState, Value>) -> Value {
        state[keyPath: keyPath]
    }

    private func handleStateChange(from oldState: ViewState, to newState: ViewState) {
        _sendState(newState)
        notifyStateObservers(oldState: oldState, newState: newState)
    }

    private func notifyStateObservers(oldState: ViewState, newState: ViewState) {
        let observers = Array(stateObservers.values)
        for observer in observers {
            observer(oldState, newState)
        }
    }

    internal func addStateObserver(
        identifier: UUID,
        onChange: @escaping @MainActor (ViewState, ViewState) -> Void
    ) {
        stateObservers[identifier] = onChange
    }

    internal func removeStateObserver(identifier: UUID) {
        stateObservers[identifier] = nil
    }
}

extension ViewModel {

    /// Helper to reduce boilerplate in previews when starting from full screen state.
    public static func previewable(screenState: Screen.State) -> Self {
        mock(
            viewState: Screen.viewStateProjection.toViewState(screenState)
        )
    }

    /// Creates a detached view model from already-projected view state.
    ///
    /// This is useful in tests. For SwiftUI previews backed by `@ViewState`,
    /// prefer `previewable(screenState:)` so the preview body does not construct
    /// macro-generated `ViewState` directly.
    public static func mock(viewState: Screen.ViewState) -> Self {
        .init(
            state: viewState,
            sendAction: { _ in },
            sendState: { _ in }
        )
    }
}
