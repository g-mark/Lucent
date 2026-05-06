//
//  UISlider+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import SwiftUI
import UIKit


extension UISlider {

    public convenience init(value binding: Binding<Float>) {
        self.init()
        bind(value: binding)
    }

    public func bind(value binding: Binding<Float>) {
        attach(
            binding: binding,
            get: { [weak self] in self?.value ?? 0 },
            set: { [weak self] in self?.value = $0 }
        )
    }
}
