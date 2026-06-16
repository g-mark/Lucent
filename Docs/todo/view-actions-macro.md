# `@ViewActions` Macro Design

A Swift macro that eliminates the boilerplate of declaring a `ViewAction` enum and `toAction` mapping in a `ScreenDefinition`.

## Motivation

When a `ScreenDefinition` has an `Action` enum with some cases that should be view-facing, you currently have to write three things manually:

1. The `Action` enum with all cases
2. A `ViewAction` enum with the subset of view-facing cases
3. A `toAction` function mapping `ViewAction` → `Action`

```swift
enum Action {
    case viewDidAppear
    case peopleLoaded(Result<[Person], Error>)
    case personSelected(Person)
}

enum ViewAction {
    case viewDidAppear
    case personSelected(Person)
}

static var toAction: @Sendable (ViewAction) -> Action {{
    switch $0 {
    case .viewDidAppear: .viewDidAppear
    case .personSelected(let person): .personSelected(person)
    }
}}
```

The `ViewAction` and `toAction` are pure boilerplate derived directly from the marked cases in `Action`.

## Design

Two macros work together:

- **`@ViewFacing`** — marks a case in `Action` as view-facing (marker only, generates nothing)
- **`@ViewActions`** — applied to the `Action` enum, generates `ViewAction` and `toAction` as siblings

```swift
@ViewActions
enum Action {
    @ViewFacing case viewDidAppear
    case peopleLoaded(Result<[Person], Error>)
    @ViewFacing case personSelected(Person)
}
```

Because `@ViewActions` is `@attached(peer)`, it generates declarations at the same level as `Action` — i.e., as members of the `ScreenDefinition` — which is exactly where `ViewAction` and `toAction` need to live to satisfy the `ScreenDefinition` protocol.

### Expansion

The macro expands to:

```swift
enum ViewAction {
    case viewDidAppear
    case personSelected(Person)
}

static var toAction: @Sendable (ViewAction) -> Action {{
    switch $0 {
    case .viewDidAppear: .viewDidAppear
    case .personSelected(let p0): .personSelected(p0)
    }
}}
```

## Macro Declarations

Place these in the `Lucent` module:

```swift
@attached(peer, names: named(ViewAction), named(toAction))
macro ViewActions() = #externalMacro(module: "LucentMacros", type: "ViewActionsMacro")

@attached(peer)
macro ViewFacing(
    _ mutability: ViewStateProjectedMutability = .sameAsOriginal
) = #externalMacro(module: "LucentMacros", type: "ViewFacingMarkerMacro")
```

Action cases use `@ViewFacing` without arguments. The optional mutability argument is used by `@ViewState` when the same marker is attached to stored state properties.

The `names:` argument on `@ViewActions` is required — Xcode needs to know the introduced names at parse time to support code completion and incremental builds.

## Macro Implementation

Place this in a separate `LucentMacros` target (Swift macros must be compiled as a separate plugin):

```swift
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - @ViewActions

public struct ViewActionsMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@ViewActions can only be applied to an enum")
        }
        let viewCases = collectViewCases(from: enumDecl)
        return [
            try generateViewActionEnum(cases: viewCases),
            try generateToAction(enumName: enumDecl.name.text, cases: viewCases)
        ]
    }

    private struct CaseInfo {
        let name: String
        let params: [EnumCaseParameterSyntax]
    }

    private static func collectViewCases(from enumDecl: EnumDeclSyntax) -> [CaseInfo] {
        enumDecl.memberBlock.members.compactMap { member in
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { return nil }
            let isMarked = caseDecl.attributes.contains {
                guard case .attribute(let attr) = $0 else { return false }
                return attr.attributeName.trimmedDescription == "ViewFacing"
            }
            guard isMarked, let element = caseDecl.elements.first else { return nil }
            return CaseInfo(
                name: element.name.text,
                params: element.parameterClause.map { Array($0.parameters) } ?? []
            )
        }
    }

    private static func generateViewActionEnum(cases: [CaseInfo]) throws -> DeclSyntax {
        let caseLines = cases.map { info -> String in
            guard !info.params.isEmpty else { return "case \(info.name)" }
            let paramStr = info.params.map { param -> String in
                let type = param.type.trimmedDescription
                guard let label = param.firstName?.text, label != "_" else { return type }
                return "\(label): \(type)"
            }.joined(separator: ", ")
            return "case \(info.name)(\(paramStr))"
        }.joined(separator: "\n    ")

        return "enum ViewAction {\n    \(raw: caseLines)\n}"
    }

    private static func generateToAction(enumName: String, cases: [CaseInfo]) throws -> DeclSyntax {
        let switchCases = cases.map { info -> String in
            guard !info.params.isEmpty else {
                return "case .\(info.name): .\(info.name)"
            }
            let bindings = info.params.enumerated().map { i, param -> String in
                guard let label = param.firstName?.text, label != "_" else { return "let p\(i)" }
                return "\(label): let p\(i)"
            }.joined(separator: ", ")
            let args = info.params.enumerated().map { i, param -> String in
                guard let label = param.firstName?.text, label != "_" else { return "p\(i)" }
                return "\(label): p\(i)"
            }.joined(separator: ", ")
            return "case .\(info.name)(\(bindings)): .\(info.name)(\(args))"
        }.joined(separator: "\n        ")

        return """
        static var toAction: @Sendable (ViewAction) -> \(raw: enumName) {{
            switch $0 {
            \(raw: switchCases)
            }
        }}
        """
    }
}

// MARK: - @ViewFacing (marker only)

public struct ViewFacingMarkerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] { [] }
}
```

## Notes

- **Macro interaction**: `@ViewActions` reads `@ViewFacing` from the *pre-expansion* syntax tree, so the two macros don't interfere with each other.
- **`@ViewFacing` as peer macro**: Declaring it as `@attached(peer)` causes the compiler to recognize and consume the attribute. Returning `[]` makes it a pure marker with no side effects.
- **Associated value labels**: Labeled params (e.g., `case foo(bar: Baz)`) are preserved correctly in both the `ViewAction` enum and the switch bindings.
- **Setup**: Add a `LucentMacros` macro target to `Package.swift`. This requires `swift-syntax` as a package dependency:

  ```swift
  // Package.swift

  // 1. Add swift-syntax to the package dependencies:
  .package(url: "https://github.com/swiftlang/swift-syntax", from: "600.0.0"),

  // 2. Add a macro target:
  .macro(
      name: "LucentMacros",
      dependencies: [
          .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
          .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
  ),

  // 3. Add LucentMacros as a dependency of the Lucent target:
  .target(
      name: "Lucent",
      dependencies: [
          .product(name: "Evident", package: "Evident"),
          "LucentMacros",
      ]
  ),
  ```

  Place macro implementations in `Sources/LucentMacros/`. The plugin entry point in that directory must register all provided macros:

  ```swift
  import SwiftCompilerPlugin
  import SwiftSyntaxMacros

  @main
  struct LucentMacrosPlugin: CompilerPlugin {
      let providingMacros: [Macro.Type] = [
          ViewActionsMacro.self,
          ViewFacingMarkerMacro.self,
      ]
  }
  ```
