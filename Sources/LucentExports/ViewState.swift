public enum ViewStateProjectedMutability: Sendable {
    case sameAsOriginal
    case readOnly
}

@attached(peer, names: named(ViewState), named(viewStateProjection))
public macro ViewState() = #externalMacro(
    module: "LucentMacros",
    type: "ViewStateMacro"
)

@attached(peer)
public macro ViewFacing(
    _ mutability: ViewStateProjectedMutability = .sameAsOriginal
) = #externalMacro(
    module: "LucentMacros",
    type: "ViewFacingMarkerMacro"
)
