//
//  UIPageControl+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import SwiftUI
import UIKit


extension UIPageControl {

    public convenience init(currentPage binding: Binding<Int>, numberOfPages: Int = 0) {
        self.init()
        self.numberOfPages = numberOfPages
        bind(currentPage: binding)
    }

    public func bind(currentPage binding: Binding<Int>) {
        attach(
            binding: binding,
            get: { [weak self] in self?.currentPage ?? 0 },
            set: { [weak self] in self?.currentPage = $0 }
        )
    }
}
