//
//  UISegmentedControl+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import SwiftUI
import UIKit


extension UISegmentedControl {

    public convenience init(items: [Any], selectedSegmentIndex binding: Binding<Int>) {
        self.init(items: items)
        bind(selectedSegmentIndex: binding)
    }

    public func bind(selectedSegmentIndex binding: Binding<Int>) {
        attach(
            binding: binding,
            get: { [weak self] in self?.selectedSegmentIndex ?? UISegmentedControl.noSegment },
            set: { [weak self] in self?.selectedSegmentIndex = $0 }
        )
    }
}
