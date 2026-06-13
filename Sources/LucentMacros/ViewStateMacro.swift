import SwiftSyntax
import SwiftSyntaxMacros

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
        let allProperties = try collectStoredProperties(
            from: structDecl,
            stateName: stateName,
            nestedTypeNames: nestedTypeNames
        )
        let projectedProperties = allProperties.filter(\.isProjected)
        let inheritance = structDecl.inheritanceClause?.trimmedDescription ?? ""

        return [
            generateViewStateStruct(properties: projectedProperties, inheritance: inheritance),
            generateProjection(stateName: stateName, projected: projectedProperties, all: allProperties)
        ]
    }

    private struct PropInfo {
        let name: String
        let qualifiedType: String?
        let defaultValue: String?
        let isProjected: Bool
        let viewStateIsLet: Bool
    }

    private static func collectNestedTypeNames(from structDecl: StructDeclSyntax) -> Set<String> {
        Set(structDecl.memberBlock.members.compactMap { member -> String? in
            member.decl.as(EnumDeclSyntax.self)?.name.text
                ?? member.decl.as(StructDeclSyntax.self)?.name.text
                ?? member.decl.as(ClassDeclSyntax.self)?.name.text
                ?? member.decl.as(ActorDeclSyntax.self)?.name.text
                ?? member.decl.as(TypeAliasDeclSyntax.self)?.name.text
        })
    }

    private static func collectStoredProperties(
        from structDecl: StructDeclSyntax,
        stateName: String,
        nestedTypeNames: Set<String>
    ) throws -> [PropInfo] {
        var properties: [PropInfo] = []

        for member in structDecl.memberBlock.members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self) else {
                continue
            }
            let attribute = findViewStateAttribute(in: varDecl.attributes)
            let forceReadOnly = attribute.map(isReadOnly(attr:)) ?? false
            let originalIsLet = varDecl.bindingSpecifier.tokenKind == .keyword(.let)

            for binding in varDecl.bindings {
                guard
                    binding.accessorBlock == nil,
                    let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                else {
                    continue
                }

                let isProjected = attribute != nil
                let qualifiedType = binding.typeAnnotation.map {
                    qualifyNestedType($0.type, nestedTypeNames: nestedTypeNames, stateName: stateName)
                }
                let defaultValue: String?
                if let typeAnnotation = binding.typeAnnotation {
                    defaultValue = projectedDefaultValue(from: binding, type: typeAnnotation.type)
                } else {
                    defaultValue = nil
                }

                if isProjected, qualifiedType == nil {
                    throw MacroExpansionErrorMessage("@ViewFacing properties must include an explicit type annotation")
                }

                properties.append(PropInfo(
                    name: name,
                    qualifiedType: qualifiedType,
                    defaultValue: defaultValue,
                    isProjected: isProjected,
                    viewStateIsLet: forceReadOnly || originalIsLet
                ))
            }
        }

        return properties
    }

    private static func findViewStateAttribute(in attributes: AttributeListSyntax) -> AttributeSyntax? {
        attributes.lazy.compactMap { element -> AttributeSyntax? in
            guard
                case .attribute(let attribute) = element,
                attribute.attributeName.trimmedDescription == "ViewFacing"
            else {
                return nil
            }

            return attribute
        }.first
    }

    private static func isReadOnly(attr: AttributeSyntax) -> Bool {
        guard
            case .argumentList(let arguments) = attr.arguments,
            let firstArgument = arguments.first,
            let memberAccess = firstArgument.expression.as(MemberAccessExprSyntax.self)
        else {
            return false
        }

        return memberAccess.declName.baseName.text == "readOnly"
    }

    private static func qualifyNestedType(
        _ type: TypeSyntax,
        nestedTypeNames: Set<String>,
        stateName: String
    ) -> String {
        if let identifier = type.as(IdentifierTypeSyntax.self),
           nestedTypeNames.contains(identifier.name.text) {
            return "\(stateName).\(type.trimmedDescription)"
        }

        return type.trimmedDescription
    }

    private static func projectedDefaultValue(from binding: PatternBindingSyntax, type: TypeSyntax) -> String? {
        if let initializer = binding.initializer {
            return initializer.value.trimmedDescription
        }

        if isOptional(type) {
            return "nil"
        }

        return nil
    }

    private static func isOptional(_ type: TypeSyntax) -> Bool {
        if type.as(OptionalTypeSyntax.self) != nil || type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) != nil {
            return true
        }

        if let identifier = type.as(IdentifierTypeSyntax.self), identifier.name.text == "Optional" {
            return true
        }

        return false
    }

    private static func generateViewStateStruct(
        properties: [PropInfo],
        inheritance: String
    ) -> DeclSyntax {
        guard !properties.isEmpty else {
            return """
            public nonisolated struct ViewState\(raw: inheritance) {
                public init() {
                }
            }
            """
        }

        let propertyLines = properties.map { property in
            "\(property.viewStateIsLet ? "let" : "var") \(property.name): \(property.qualifiedType!)"
        }.joined(separator: "\n    ")
        let initializer = generateViewStateInitializer(properties: properties)

        return """
        public nonisolated struct ViewState\(raw: inheritance) {
            \(raw: propertyLines)

            \(raw: initializer)
        }
        """
    }

    private static func generateViewStateInitializer(properties: [PropInfo]) -> String {
        let parameters = properties.map { property in
            let defaultValue = property.defaultValue.map { " = \($0)" } ?? ""
            return "\(property.name): \(property.qualifiedType!)\(defaultValue)"
        }.joined(separator: ",\n        ")
        let assignments = properties.map { property in
            "self.\(property.name) = \(property.name)"
        }.joined(separator: "\n        ")

        return """
        public init(
            \(parameters)
        ) {
            \(assignments)
        }
        """
    }

    private static func generateProjection(
        stateName: String,
        projected: [PropInfo],
        all: [PropInfo]
    ) -> DeclSyntax {
        let projectedNames = Set(projected.map(\.name))
        let toViewStateArguments = projected.map { property in
            "\(property.name): state.\(property.name)"
        }
        let toStateArguments = all.map { property in
            let source = projectedNames.contains(property.name) ? "viewState" : "state"
            return "\(property.name): \(source).\(property.name)"
        }

        return """
        static var viewStateProjection: StateProjection<\(raw: stateName), ViewState> {
            .init(
                toViewState: { state in
                    \(raw: generateInitializer(name: "ViewState", arguments: toViewStateArguments, indentation: "                "))
                },
                toState: { viewState, state in
                    \(raw: generateInitializer(name: stateName, arguments: toStateArguments, indentation: "                "))
                }
            )
        }
        """
    }

    private static func generateInitializer(
        name: String,
        arguments: [String],
        indentation: String
    ) -> String {
        guard !arguments.isEmpty else {
            return "\(name)()"
        }

        return """
        \(name)(
        \(arguments.map { "\(indentation)    \($0)" }.joined(separator: ",\n"))
        \(indentation))
        """
    }
}

public struct ViewFacingMarkerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}
