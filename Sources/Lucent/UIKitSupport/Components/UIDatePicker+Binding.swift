//
//  UIDatePicker+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import SwiftUI
import UIKit


extension UIDatePicker {

    public convenience init(value binding: Binding<Date>) {
        self.init()
        bind(value: binding)
    }

    public func bind(value binding: Binding<Date>) {
        attach(
            binding: binding,
            get: { [weak self] in self?.date ?? Date() },
            set: { [weak self] in self?.date = $0 }
        )
    }
}
