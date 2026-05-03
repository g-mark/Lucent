//
//  ViewModel.swift
//  Lucent
//
//  Created by Steven Grosmark on 3/7/26.
//

import SwiftUI
import Evident


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

    public var state: ViewState

    @ObservationIgnored
    private let _sendAction: @Sendable (ViewAction) -> Void

    @ObservationIgnored
    private let _sendState: @MainActor @Sendable (ViewState) async -> Void

    init(
        state: ViewState,
        sendAction: @escaping @Sendable (ViewAction) -> Void,
        sendState: @escaping @MainActor @Sendable (ViewState) async -> Void
    ) {
        self.state = state
        self._sendAction = sendAction
        self._sendState = sendState

        observeViewState()
    }

    public func send(action: ViewAction) {
        _sendAction(action)
    }

    /// Read access to any state property.
    public subscript<Value>(dynamicMember keyPath: KeyPath<ViewState, Value>) -> Value {
        state[keyPath: keyPath]
    }

    /// Monitor changes to `state`, and push those changes out to the owning Store.
    private func observeViewState() {
        withObservationTracking {
            _ = state
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self._sendState(self._state)
                observeViewState()
            }
        }
    }
}

extension ViewModel {

    /// Helper to reduce boilerplate in writing SwiftUI previews.
    public static func previewable(state: Screen.ViewState) -> Self {
        .init(
            state: state,
            sendAction: { _ in },
            sendState: { _ in }
        )
    }
}
