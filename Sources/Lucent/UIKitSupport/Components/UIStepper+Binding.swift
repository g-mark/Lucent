//
//  UIStepper+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import SwiftUI
import UIKit


extension UIStepper {

    public convenience init(value binding: Binding<Double>) {
        self.init()
        bind(value: binding)
    }

    public func bind(value binding: Binding<Double>) {
        attach(
            binding: binding,
            get: { [weak self] in self?.value ?? 0 },
            set: { [weak self] in self?.value = $0 }
        )
    }
}
