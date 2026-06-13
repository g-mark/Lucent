import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct LucentMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ViewActionsMacro.self,
        ViewActionMarkerMacro.self
    ]
}
