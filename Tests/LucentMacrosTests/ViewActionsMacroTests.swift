#if os(macOS) && arch(arm64)
import LucentMacros
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ViewActionsMacroTests: XCTestCase {
    func testGeneratesViewActionEnumAndActionMapperForMarkedCases() {
        assertMacroExpansion(
            """
            @ViewActions
            enum Action {
                @ViewFacing case viewDidAppear
                case peopleLoaded(Result<[Person], Error>)
                @ViewFacing case setName(name: String, age: Int)
                @ViewFacing case personSelected(Person)
            }
            """,
            expandedSource: """
            enum Action {
                case viewDidAppear
                case peopleLoaded(Result<[Person], Error>)
                case setName(name: String, age: Int)
                case personSelected(Person)
            }

            enum ViewAction: Sendable {
                case viewDidAppear
                case setName(name: String, age: Int)
                case personSelected(Person)
            }

            static var toAction: @Sendable (ViewAction) -> Action {
                {
                    switch $0 {
                    case .viewDidAppear:
                        .viewDidAppear
                    case .setName(name: let p0, age: let p1):
                        .setName(name: p0, age: p1)
                    case .personSelected(let p0):
                        .personSelected(p0)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }

    func testMarksEveryCaseInAMarkedMultiCaseDeclaration() {
        assertMacroExpansion(
            """
            @ViewActions
            enum Action {
                @ViewFacing case started, finished(result: Result<Void, Error>)
            }
            """,
            expandedSource: """
            enum Action {
                case started, finished(result: Result<Void, Error>)
            }

            enum ViewAction: Sendable {
                case started
                case finished(result: Result<Void, Error>)
            }

            static var toAction: @Sendable (ViewAction) -> Action {
                {
                    switch $0 {
                    case .started:
                        .started
                    case .finished(result: let p0):
                        .finished(result: p0)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}

private let testMacros: [String: Macro.Type] = [
    "ViewActions": ViewActionsMacro.self,
    "ViewFacing": ViewFacingMarkerMacro.self
]
#endif
