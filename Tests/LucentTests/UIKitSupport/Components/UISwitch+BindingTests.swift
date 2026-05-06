//
//  UISwitch+BindingTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Observation
import SwiftUI
import Testing
import UIKit
@testable import Lucent

@Suite("UISwitch+Binding")
struct UISwitchBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesControlChangesBack() async throws {
        let model = ObservableValueModel(value: true)
        let control = UISwitch(isOn: binding(to: model))

        #expect(control.isOn == true)

        model.value = false
        try await eventually {
            control.isOn == false
        }

        control.isOn = true
        control.sendActions(for: .valueChanged)

        #expect(model.value == true)
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
