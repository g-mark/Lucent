//
//  UIColorWell+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import SwiftUI
import UIKit


@available(iOS 17.0, *)
public extension UIColorWell {

    convenience init(selectedColor binding: Binding<UIColor?>) {
        self.init()
        bind(selectedColor: binding)
    }

    func bind(selectedColor binding: Binding<UIColor?>) {
        attach(
            binding: binding,
            get: { [weak self] in self?.selectedColor },
            set: { [weak self] in self?.selectedColor = $0 }
        )
    }
}
