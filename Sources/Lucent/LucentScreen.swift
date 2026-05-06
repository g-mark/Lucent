//
//  LucentScreen.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/3/26.
//

import Foundation

/// A `LucentScreen` owns a Lucent view model.
///
@MainActor
public protocol LucentScreen {
    associatedtype Module: ScreenDefinition

    var viewModel: ViewModel<Module> { get }
}
