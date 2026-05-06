//
//  UISwitch+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/3/26.
//

import SwiftUI
import UIKit


extension UISwitch {

    /// Creates a switch whose `isOn` state is bound to a SwiftUI-style binding.
    public convenience init(isOn binding: Binding<Bool>) {
        self.init(frame: .zero)
        bind(isOn: binding)
    }

    public func bind(isOn binding: Binding<Bool>) {
        attach(
            binding: binding,
            get: { [weak self] in self?.isOn ?? false },
            set: { [weak self] in self?.isOn = $0 }
        )
    }
}
