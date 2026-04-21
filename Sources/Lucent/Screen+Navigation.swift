//
//  Screen+Navigation.swift
//  Lucent
//
//  Created by Steven Grosmark on 3/7/26.
//

import UIKit


/// Navigational helpers for placing screens into the view hierarchy: push, present etc.
extension Screen {

    /// Push this screen onto a navigation stack.
    /// If there are no other screens on the stack, this screen will be the root, unanimated.
    @discardableResult
    func push(onto navController: UINavigationController, animated: Bool) -> Self {
        if navController.viewControllers.isEmpty {
            navController.viewControllers = [viewController]
        }
        else {
            navController.pushViewController(viewController, animated: animated)
        }
        return self
    }
}
