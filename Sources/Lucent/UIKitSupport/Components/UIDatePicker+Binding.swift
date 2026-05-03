//
//  UIDatePicker+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import SwiftUI
import UIKit


@available(iOS 17.0, *)
public extension UIDatePicker {

    convenience init(value binding: Binding<Date>) {
        self.init()
        bind(value: binding)
    }

    func bind(value binding: Binding<Date>) {
        attach(
            binding: binding,
            get: { [weak self] in self?.date ?? Date() },
            set: { [weak self] in self?.date = $0 }
        )
    }
}
