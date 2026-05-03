//
//  UITextField+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/3/26.
//

import SwiftUI
import UIKit


@available(iOS 17.0, *)
extension UITextField {

    public convenience init(text binding: Binding<String>) {
        self.init()
        bind(text: binding)
    }

    public func bind(text binding: Binding<String>) {
        attach(
            binding: binding,
            get: { [weak self] in self?.text ?? "" },
            set: { [weak self] in self?.text = $0 },
            for: .editingChanged
        )
    }
}
