//
//  UIButton+Actions.swift
//  Lucent
//
//  Created by Steven Grosmark on 6/7/26.
//

import UIKit


extension UIButton {

    /// Sends a Lucent view action when the button is tapped.
    public func onTap<Module: ScreenDefinition>(
        send action: Module.ViewAction,
        to viewModel: ViewModel<Module>
    ) {
        addAction(
            UIAction { [weak viewModel] _ in
                Task { @MainActor in
                    viewModel?.send(action: action)
                }
            },
            for: .touchUpInside
        )
    }
}
