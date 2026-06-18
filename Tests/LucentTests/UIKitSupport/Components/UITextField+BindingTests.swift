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
import LucentCore

@Suite("UITextField+Binding")
struct UITextFieldBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesEditingChangesBack() async throws {
        let model = ObservableValueModel(value: "Initial")
        let bindingReads = LockedRecorder<String>()
        let control = UITextField(text: binding(to: model) { bindingReads.append($0) })

        try await bindingReads.waitForValue("Initial")
        #expect(control.text == "Initial")

        model.value = "Updated"
        try await bindingReads.waitForValue("Updated")
        #expect(control.text == "Updated")

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
private func binding<Value>(
    to model: ObservableValueModel<Value>,
    onRead: ((Value) -> Void)? = nil
) -> Binding<Value> {
    Binding(
        get: {
            let value = model.value
            onRead?(value)
            return value
        },
        set: { model.value = $0 }
    )
}
