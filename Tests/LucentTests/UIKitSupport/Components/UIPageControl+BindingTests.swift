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

    // Note: `currentPage` is zero-based

    @MainActor
    @Test func bindingInitializerMirrorsInitialValue() {
        let model = ObservableValueModel(value: 2)
        let control = UIPageControl(currentPage: binding(to: model))

        #expect(control.numberOfPages == 0)
        #expect(control.currentPage == 0)
    }

    @MainActor
    @Test func bindingInitializerMirrorsInitialValueClamped() {
        let model = ObservableValueModel(value: 2)
        let control = UIPageControl(currentPage: binding(to: model), numberOfPages: 2)

        #expect(control.numberOfPages == 2)
        #expect(control.currentPage == 1)
    }

    @MainActor
    @Test func bindingInitializerConfiguresNumberOfPagesBeforeMirroringInitialValue() {
        let model = ObservableValueModel(value: 2)
        let control = UIPageControl(currentPage: binding(to: model), numberOfPages: 5)

        #expect(control.numberOfPages == 5)
        #expect(control.currentPage == 2)
    }

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
