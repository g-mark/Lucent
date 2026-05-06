//
//  UISegmentedControl+BindingTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Observation
import SwiftUI
import Testing
import UIKit
@testable import Lucent

@Suite("UISegmentedControl+Binding")
struct UISegmentedControlBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesControlChangesBack() async throws {
        let model = ObservableValueModel(value: 1)
        let control = UISegmentedControl(
            items: ["One", "Two", "Three"],
            selectedSegmentIndex: binding(to: model)
        )

        #expect(control.selectedSegmentIndex == 1)

        model.value = 2
        try await eventually {
            control.selectedSegmentIndex == 2
        }

        control.selectedSegmentIndex = 0
        control.sendActions(for: .valueChanged)

        #expect(model.value == 0)
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
