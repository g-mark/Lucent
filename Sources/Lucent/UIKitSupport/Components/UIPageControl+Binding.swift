//
//  UIPageControl+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import SwiftUI
import UIKit


@available(iOS 17.0, *)
public extension UIPageControl {

    convenience init(currentPage binding: Binding<Int>) {
        self.init()
        bind(currentPage: binding)
    }

    func bind(currentPage binding: Binding<Int>) {
        attach(
            binding: binding,
            get: { [weak self] in self?.currentPage ?? 0 },
            set: { [weak self] in self?.currentPage = $0 }
        )
    }
}
