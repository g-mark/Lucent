//
//  ScreenDefinition.swift
//  Lucent
//
//  Created by Steven Grosmark on 3/7/26.
//

import UIKit


/// The set of types that define a screen
@MainActor
public protocol ScreenDefinition: Sendable {

    // MARK: Core types

    /// The data a screen needs to operate.
    associatedtype State: Sendable

    /// Events that occur within a screen.
    associatedtype Action: Sendable

    /// Events that a screen can produce, for external observation
    associatedtype Output: Sendable


    // MARK: ViewModel types

    /// The data a screen's view needs to operate.
    associatedtype ViewState: Sendable = Self.State

    /// Events a screen's view can produce
    associatedtype ViewAction: Sendable = Self.Action

    /// Mapping screen `State` <-> `ViewState`
    static var viewStateProjection: StateProjection<Self.State, ViewState> { get }

    /// Mapping `ViewAction` -> screen `Action`
    static var toAction: @Sendable (ViewAction) -> Self.Action { get }


    // MARK: Screen creation

    static func create(initialState: Self.State) -> Screen<Self.Output>
}

/// Default `State`, `Action`, `Output` types.
extension ScreenDefinition {
    public typealias State = EmptyState
    public typealias Action = Never
    public typealias Output = Never
}

/// Helper for simple screens where `State` is `EmptyState`
extension ScreenDefinition where State == EmptyState {

    @MainActor
    public static func create() -> Screen<Self.Output> {
        create(initialState: EmptyState())
    }
}

/// Helper for simple cases when screen and view states are the same
extension ScreenDefinition where ViewState == State {

    public static var viewStateProjection: StateProjection<Self.State, ViewState> {
        StateProjection(
            toViewState: { $0 },
            toState: { viewState, _ in viewState }
        )
    }
}

/// Helper for simple cases when screen and view actions are the same
extension ScreenDefinition where ViewAction == Action {

    public static var toAction: @Sendable (ViewAction) -> Self.Action {
        { $0 }
    }
}

/// A function pair for transforming `State` <-> `ViewState`
public struct StateProjection<State: Sendable, ViewState: Sendable>: Sendable {
    public let toViewState: @Sendable (State) -> ViewState
    public let toState: @Sendable (ViewState, State) -> State
}

public struct EmptyState: Sendable { }
