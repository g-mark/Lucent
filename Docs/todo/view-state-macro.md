# `@ViewState` Macro Design

A Swift macro that eliminates the boilerplate of declaring a `ViewState` struct and `viewStateProjection` mapping in a `ScreenDefinition`.

## Motivation

When a `ScreenDefinition` has a `State` struct where only a subset of properties should be visible to the view, you currently write three things manually:

1. The `State` struct with all properties
2. A `ViewState` struct with the projected subset
3. A `viewStateProjection` mapping both directions: `State → ViewState` and `ViewState → State`

```swift
struct State: Equatable {
    let personId: Int
    var personName: String
    var phase: Phase

    enum Phase: Equatable { ... }
}

public nonisolated struct ViewState: Equatable {
    let personId: Int
    let phase: State.Phase

    public init(
        personId: Int,
        phase: State.Phase
    ) {
        self.personId = personId
        self.phase = phase
    }
}

static var viewStateProjection: StateProjection<State, ViewState> {
    .init(
        toViewState: { state in
            ViewState(personId: state.personId, phase: state.phase)
        },
        toState: { viewState, state in
            State(
                personId: viewState.personId,
                personName: state.personName,  // not in ViewState — use state's value
                phase: viewState.phase
            )
        }
    )
}
```

`ViewState` and `viewStateProjection` are entirely derivable from which properties are marked on `State`.

## Design

Two macros and one supporting enum work together:

- **`ViewStateProjectedMutability`** — declared in the `Lucent` module, used as a macro argument
- **`@ViewFacing`** — marks a stored property in `State` for projection into `ViewState`, with optional mutability override
- **`@ViewState`** — applied to the `State` struct, generates `ViewState` and `viewStateProjection` as siblings

```swift
@ViewState
struct State: Equatable {
    @ViewFacing let personId: Int
    var personName: String
    @ViewFacing(.readOnly) var phase: Phase

    enum Phase: Equatable { ... }
}
```

Because `@ViewState` is `@attached(peer)`, it generates declarations at the same level as `State` — i.e., as members of the screen definition type — which is exactly where `ViewState` and `viewStateProjection` need to live.

### Mutability rules for `ViewState` properties

| `State` declaration | `@ViewFacing` argument | `ViewState` declaration |
|---|---|---|
| `let x: T` | (any) | `let x: T` |
| `var x: T` | _(none)_ or `.sameAsOriginal` | `var x: T` |
| `var x: T` | `.readOnly` | `let x: T` |

### Nested type qualification

Types defined inside `State` (e.g., `enum Phase`) are referenced as bare names within `State` but must be qualified as `State.Phase` inside `ViewState`. The macro detects all nested type declarations in `State` and qualifies their names automatically.

### Expansion

For the example above, the macro generates:

```swift
struct ViewState: Equatable {
    let personId: Int
    let phase: State.Phase
}

static var viewStateProjection: StateProjection<State, ViewState> {
    .init(
        toViewState: { state in
            ViewState(
                personId: state.personId,
                phase: state.phase
            )
        },
        toState: { viewState, state in
            State(
                personId: viewState.personId,
                personName: state.personName,
                phase: viewState.phase
            )
        }
    )
}
```

`toState` uses `viewState.x` for every `@ViewFacing`-marked property and `state.x` for every unmarked property, in declaration order to match the synthesized memberwise initializer.

The generated `ViewState` has an explicit initializer. Parameters mirror the projected property list; a parameter receives a default only when the source property has a default value, or when the source property is optional and therefore defaults to `nil`. Non-default `State` properties remain required.

## Macro and Type Declarations

Place these in the `Lucent` module:

```swift
/// Controls the mutability of a property in the generated `ViewState`.
public enum ViewStateProjectedMutability: Sendable {
    /// Preserve the original `let`/`var` from `State`.
    case sameAsOriginal
    /// Force `let` in `ViewState` regardless of `var` in `State`.
    case readOnly
}

@attached(peer, names: named(ViewState), named(viewStateProjection))
public macro ViewState() = #externalMacro(module: "LucentMacros", type: "ViewStateMacro")

@attached(peer)
public macro ViewFacing(
    _ mutability: ViewStateProjectedMutability = .sameAsOriginal
) = #externalMacro(module: "LucentMacros", type: "ViewFacingMarkerMacro")
```

`ViewStateProjectedMutability` must live in `Lucent` (not the macro plugin) so that users can write `@ViewFacing(.readOnly)` as a normal Swift expression with auto-complete. The macro reads it as syntax, not as a runtime value.

## Macro Implementation

Place this in a separate `LucentMacros` target:

```swift
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - @ViewState

public struct ViewStateMacro: PeerMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@ViewState can only be applied to a struct")
        }

        let stateName = structDecl.name.text
        let nestedTypeNames = collectNestedTypeNames(from: structDecl)
        let allProperties = collectStoredProperties(
            from: structDecl,
            stateName: stateName,
            nestedTypeNames: nestedTypeNames
        )
        let projectedProperties = allProperties.filter { $0.isProjected }

        let inheritanceStr = structDecl.inheritanceClause?.trimmedDescription ?? ""

        return [
            generateViewStateStruct(properties: projectedProperties, inheritanceStr: inheritanceStr),
            generateProjection(stateName: stateName, projected: projectedProperties, all: allProperties)
        ]
    }

    // MARK: - Property collection

    struct PropInfo {
        let name: String
        let qualifiedType: String   // type as it should appear in ViewState
        let isProjected: Bool       // included in ViewState?
        let viewStateIsLet: Bool    // let vs var in ViewState
    }

    private static func collectNestedTypeNames(from structDecl: StructDeclSyntax) -> Set<String> {
        Set(structDecl.memberBlock.members.compactMap { member -> String? in
            member.decl.as(EnumDeclSyntax.self)?.name.text
                ?? member.decl.as(StructDeclSyntax.self)?.name.text
                ?? member.decl.as(ClassDeclSyntax.self)?.name.text
                ?? member.decl.as(TypeAliasDeclSyntax.self)?.name.text
        })
    }

    private static func collectStoredProperties(
        from structDecl: StructDeclSyntax,
        stateName: String,
        nestedTypeNames: Set<String>
    ) -> [PropInfo] {
        structDecl.memberBlock.members.compactMap { member -> PropInfo? in
            guard
                let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.first,
                binding.accessorBlock == nil,   // exclude computed properties
                let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                let typeAnnotation = binding.typeAnnotation?.type
            else { return nil }

            let originalIsLet = varDecl.bindingSpecifier.tokenKind == .keyword(.let)
            let qualifiedType = qualifyNestedType(typeAnnotation, nestedTypeNames: nestedTypeNames, stateName: stateName)

            if let attr = findViewStateAttribute(in: varDecl.attributes) {
                let forceReadOnly = isReadOnly(attr: attr)
                return PropInfo(
                    name: name,
                    qualifiedType: qualifiedType,
                    isProjected: true,
                    viewStateIsLet: forceReadOnly || originalIsLet
                )
            } else {
                return PropInfo(
                    name: name,
                    qualifiedType: qualifiedType,
                    isProjected: false,
                    viewStateIsLet: originalIsLet
                )
            }
        }
    }

    private static func findViewStateAttribute(in attributes: AttributeListSyntax) -> AttributeSyntax? {
        attributes.lazy.compactMap {
            guard case .attribute(let attr) = $0,
                  attr.attributeName.trimmedDescription == "ViewFacing"
            else { return nil }
            return attr
        }.first
    }

    private static func isReadOnly(attr: AttributeSyntax) -> Bool {
        guard
            case .argumentList(let args) = attr.arguments,
            let firstArg = args.first,
            let memberAccess = firstArg.expression.as(MemberAccessExprSyntax.self)
        else { return false }
        return memberAccess.declName.baseName.text == "readOnly"
    }

    /// For bare identifier types that name a nested type in `State`,
    /// qualify them as `State.TypeName`. Other types (Int, String, etc.) pass through.
    private static func qualifyNestedType(
        _ type: TypeSyntax,
        nestedTypeNames: Set<String>,
        stateName: String
    ) -> String {
        if let identType = type.as(IdentifierTypeSyntax.self),
           nestedTypeNames.contains(identType.name.text) {
            return "\(stateName).\(type.trimmedDescription)"
        }
        return type.trimmedDescription
    }

    // MARK: - Code generation

    private static func generateViewStateStruct(
        properties: [PropInfo],
        inheritanceStr: String
    ) -> DeclSyntax {
        let propLines = properties.map { prop in
            "\(prop.viewStateIsLet ? "let" : "var") \(prop.name): \(prop.qualifiedType)"
        }.joined(separator: "\n    ")

        return "struct ViewState\(raw: inheritanceStr) {\n    \(raw: propLines)\n}"
    }

    private static func generateProjection(
        stateName: String,
        projected: [PropInfo],
        all: [PropInfo]
    ) -> DeclSyntax {
        let projectedNames = Set(projected.map { $0.name })

        let toViewStateArgs = projected.map { prop in
            "\(prop.name): state.\(prop.name)"
        }.joined(separator: ",\n                ")

        let toStateArgs = all.map { prop in
            let source = projectedNames.contains(prop.name) ? "viewState" : "state"
            return "\(prop.name): \(source).\(prop.name)"
        }.joined(separator: ",\n                ")

        return """
        static var viewStateProjection: StateProjection<\(raw: stateName), ViewState> {
            .init(
                toViewState: { state in
                    ViewState(
                        \(raw: toViewStateArgs)
                    )
                },
                toState: { viewState, state in
                    \(raw: stateName)(
                        \(raw: toStateArgs)
                    )
                }
            )
        }
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

- **`ViewStateProjectedMutability` is read as syntax, not evaluated.** The macro checks the AST for `.readOnly` / `.sameAsOriginal`. The enum is still declared as a real Swift type so users get auto-complete and type-checking.

- **Nested type qualification is shallow.** Only bare identifier types (e.g., `Phase`) that match a nested type declaration in `State` are qualified. Generic types that embed nested types (e.g., `Result<Phase, Error>`) are not currently walked — they would need to be declared at the screen level or qualified manually.

- **Computed properties are excluded.** Properties with an accessor block (`get`, `set`) are skipped. Stored properties with `willSet`/`didSet` observers are also currently skipped (their `accessorBlock` is non-nil); this is a known limitation.

- **`toState` assumes the synthesized memberwise initializer.** All stored properties must appear in the memberwise init in declaration order. Custom `init` declarations on `State` are not considered.

- **Conformances are mirrored.** The generated `ViewState` copies the inheritance clause from `State` (e.g., `: Equatable`). Since `ViewState` is a strict subset of `State`'s properties, if `State`'s properties satisfy a conformance, so will `ViewState`'s.

- **Relationship to `@ViewActions`.** Both outer macros use `@attached(peer)` — applied to a type nested inside the screen definition, generating siblings at the screen level. The shared `@ViewFacing` marker is a no-op `@attached(peer)` expansion read as syntax by each outer macro.

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
          ViewStateMacro.self,
          ViewFacingMarkerMacro.self,
      ]
  }
  ```

  If both `@ViewState` and `@ViewActions` are implemented together, combine all types in a single `providingMacros` array in the shared plugin entry point.
