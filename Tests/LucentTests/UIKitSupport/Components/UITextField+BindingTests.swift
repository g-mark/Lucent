//
//  UITextField+BindingTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Observation
import SwiftUI
import Testing
import UIKit
@testable import Lucent

@Suite("UITextField+Binding")
struct UITextFieldBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesEditingChangesBack() async throws {
        let model = ObservableValueModel(value: "Initial")
        let control = UITextField(text: binding(to: model))

        #expect(control.text == "Initial")

        model.value = "Updated"
        try await eventually {
            control.text == "Updated"
        }

        control.text = "Typed"
        control.sendActions(for: .editingChanged)

        #expect(model.value == "Typed")
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
