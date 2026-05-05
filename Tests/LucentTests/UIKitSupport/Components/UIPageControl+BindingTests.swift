//
//  UIPageControl+BindingTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Observation
import SwiftUI
import Testing
import UIKit
@testable import Lucent

@Suite("UIPageControl+Binding")
struct UIPageControlBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesControlChangesBack() async throws {
        let model = ObservableValueModel(value: 1)
        let control = UIPageControl()
        control.numberOfPages = 4
        control.bind(currentPage: binding(to: model))

        #expect(control.currentPage == 1)

        model.value = 2
        try await eventually {
            control.currentPage == 2
        }

        control.currentPage = 3
        control.sendActions(for: .valueChanged)

        #expect(model.value == 3)
    }
}

@Observable
private final class ObservableValueModel<Value> {
    var value: Value

    init(value: Value) {
        self.value = value
    }
}

@MainActor
private func binding<Value>(to model: ObservableValueModel<Value>) -> Binding<Value> {
    Binding(
        get: { model.value },
        set: { model.value = $0 }
    )
}
