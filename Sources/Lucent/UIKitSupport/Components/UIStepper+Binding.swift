//
//  UIStepper+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import SwiftUI
import UIKit


@available(iOS 17.0, *)
public extension UIStepper {

    convenience init(value binding: Binding<Double>) {
        self.init()
        bind(value: binding)
    }

    func bind(value binding: Binding<Double>) {
        attach(
            binding: binding,
            get: { [weak self] in self?.value ?? 0 },
            set: { [weak self] in self?.value = $0 }
        )
    }
}
