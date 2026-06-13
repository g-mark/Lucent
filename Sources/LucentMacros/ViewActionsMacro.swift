import SwiftSyntax
import SwiftSyntaxMacros

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
            generateViewActionEnum(cases: viewCases),
            generateToAction(enumName: enumDecl.name.text, cases: viewCases)
        ]
    }

    private struct CaseInfo {
        let name: String
        let parameters: [EnumCaseParameterSyntax]
    }

    private static func collectViewCases(from enumDecl: EnumDeclSyntax) -> [CaseInfo] {
        enumDecl.memberBlock.members.flatMap { member -> [CaseInfo] in
            guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self),
                  caseDecl.isMarkedAsViewAction
            else {
                return []
            }

            return caseDecl.elements.map { element in
                CaseInfo(
                    name: element.name.text,
                    parameters: element.parameterClause.map { Array($0.parameters) } ?? []
                )
            }
        }
    }

    private static func generateViewActionEnum(cases: [CaseInfo]) -> DeclSyntax {
        let caseLines = cases.map { info -> String in
            guard !info.parameters.isEmpty else {
                return "case \(info.name)"
            }

            let parameterList = info.parameters.map { parameter -> String in
                let type = parameter.type.trimmedDescription
                guard let label = parameter.firstName?.text, label != "_" else {
                    return type
                }
                return "\(label): \(type)"
            }.joined(separator: ", ")

            return "case \(info.name)(\(parameterList))"
        }.joined(separator: "\n    ")

        if caseLines.isEmpty {
            return "enum ViewAction: Sendable { }"
        }

        return """
        enum ViewAction: Sendable {
            \(raw: caseLines)
        }
        """
    }

    private static func generateToAction(enumName: String, cases: [CaseInfo]) -> DeclSyntax {
        let switchCases = cases.map { info -> String in
            guard !info.parameters.isEmpty else {
                return """
                case .\(info.name):
                            .\(info.name)
                """
            }

            let bindings = info.parameters.enumerated().map { index, parameter -> String in
                guard let label = parameter.firstName?.text, label != "_" else {
                    return "let p\(index)"
                }
                return "\(label): let p\(index)"
            }.joined(separator: ", ")

            let arguments = info.parameters.enumerated().map { index, parameter -> String in
                guard let label = parameter.firstName?.text, label != "_" else {
                    return "p\(index)"
                }
                return "\(label): p\(index)"
            }.joined(separator: ", ")

            return """
            case .\(info.name)(\(bindings)):
                        .\(info.name)(\(arguments))
            """
        }.joined(separator: "\n        ")

        return """
        static var toAction: @Sendable (ViewAction) -> \(raw: enumName) {
            {
                switch $0 {
                \(raw: switchCases)
                }
            }
        }
        """
    }
}

public struct ViewActionMarkerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        []
    }
}

private extension EnumCaseDeclSyntax {
    var isMarkedAsViewAction: Bool {
        attributes.contains { attribute in
            guard case .attribute(let attributeSyntax) = attribute else {
                return false
            }

            return attributeSyntax.attributeName.trimmedDescription == "viewAction"
        }
    }
}
