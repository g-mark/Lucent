@_exported import LucentCore

@attached(peer, names: named(ViewAction), named(toAction))
public macro ViewActions() = #externalMacro(
    module: "LucentMacros",
    type: "ViewActionsMacro"
)

@attached(peer)
public macro viewAction() = #externalMacro(
    module: "LucentMacros",
    type: "ViewActionMarkerMacro"
)
