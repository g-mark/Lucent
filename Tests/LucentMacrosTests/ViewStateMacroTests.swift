#if os(macOS) && arch(arm64)
import LucentMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ViewStateMacroTests: XCTestCase {
    func testGeneratesViewStateAndProjectionFromMarkedProperties() {
        assertMacroExpansion(
            """
            @ViewState
            struct State: Equatable, Sendable {
                @ViewFacing let id: Int
                @ViewFacing var name: String
                @ViewFacing(.readOnly) var phase: Phase
                var cacheKey: String
                var retryCount = 0
                var doubledRetryCount: Int { retryCount * 2 }

                enum Phase: Equatable, Sendable {
                    case idle
                }
            }
            """,
            expandedSource: """
            struct State: Equatable, Sendable {
                let id: Int
                var name: String
                var phase: Phase
                var cacheKey: String
                var retryCount = 0
                var doubledRetryCount: Int { retryCount * 2 }

                enum Phase: Equatable, Sendable {
                    case idle
                }
            }

            public nonisolated struct ViewState: Equatable, Sendable {
                let id: Int
                var name: String
                let phase: State.Phase

                public init(
                    id: Int,
                    name: String,
                    phase: State.Phase
                ) {
                    self.id = id
                    self.name = name
                    self.phase = phase
                }
            }

            static var viewStateProjection: StateProjection<State, ViewState> {
                .init(
                    toViewState: { state in
                        ViewState(
                            id: state.id,
                            name: state.name,
                            phase: state.phase
                        )
                    },
                    toState: { viewState, state in
                        State(
                            id: viewState.id,
                            name: viewState.name,
                            phase: viewState.phase,
                            cacheKey: state.cacheKey,
                            retryCount: state.retryCount
                        )
                    }
                )
            }
            """,
            macros: testMacros
        )
    }

    func testGeneratesEmptyViewStateWhenNoPropertiesAreMarked() {
        assertMacroExpansion(
            """
            @ViewState
            struct State: Sendable {
                var name: String
            }
            """,
            expandedSource: """
            struct State: Sendable {
                var name: String
            }

            public nonisolated struct ViewState: Sendable {
                public init() {
                }
            }

            static var viewStateProjection: StateProjection<State, ViewState> {
                .init(
                    toViewState: { state in
                        ViewState()
                    },
                    toState: { viewState, state in
                        State(
                            name: state.name
                        )
                    }
                )
            }
            """,
            macros: testMacros
        )
    }

    func testRejectsNonStructDeclarations() {
        assertMacroExpansion(
            """
            @ViewState
            enum State {
            }
            """,
            expandedSource: """
            enum State {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@ViewState can only be applied to a struct", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }

    func testGeneratedViewStateInitializerRequiresNonDefaultPropertiesAndCarriesDefaults() {
        assertMacroExpansion(
            """
            @ViewState
            struct State: Sendable {
                @ViewFacing(.readOnly) var title: String
                @ViewFacing(.readOnly) var count: Int = 0
                @ViewFacing(.readOnly) var fact: String?
                @ViewFacing(.readOnly) var factIsLoading: Bool = false
            }
            """,
            expandedSource: """
            struct State: Sendable {
                var title: String
                var count: Int = 0
                var fact: String?
                var factIsLoading: Bool = false
            }

            public nonisolated struct ViewState: Sendable {
                let title: String
                let count: Int
                let fact: String?
                let factIsLoading: Bool

                public init(
                    title: String,
                    count: Int = 0,
                    fact: String? = nil,
                    factIsLoading: Bool = false
                ) {
                    self.title = title
                    self.count = count
                    self.fact = fact
                    self.factIsLoading = factIsLoading
                }
            }

            static var viewStateProjection: StateProjection<State, ViewState> {
                .init(
                    toViewState: { state in
                        ViewState(
                            title: state.title,
                            count: state.count,
                            fact: state.fact,
                            factIsLoading: state.factIsLoading
                        )
                    },
                    toState: { viewState, state in
                        State(
                            title: viewState.title,
                            count: viewState.count,
                            fact: viewState.fact,
                            factIsLoading: viewState.factIsLoading
                        )
                    }
                )
            }
            """,
            macros: testMacros
        )
    }

    func testRejectsProjectedPropertiesWithoutExplicitTypes() {
        assertMacroExpansion(
            """
            @ViewState
            struct State {
                @ViewFacing var count = 0
            }
            """,
            expandedSource: """
            struct State {
                var count = 0
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@ViewFacing properties must include an explicit type annotation", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
}

private let testMacros: [String: Macro.Type] = [
    "ViewState": ViewStateMacro.self,
    "ViewFacing": ViewFacingMarkerMacro.self
]
#endif
