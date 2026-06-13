//
//  UISlider+BindingTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Observation
import SwiftUI
import Testing
import UIKit
import LucentCore

@Suite("UISlider+Binding")
struct UISliderBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesControlChangesBack() async throws {
        let model = ObservableValueModel(value: Float(0.25))
        let control = UISlider(value: binding(to: model))

        #expect(control.value == 0.25)

        model.value = 0.5
        try await eventually {
            control.value == 0.5
        }

        control.value = 0.75
        control.sendActions(for: .valueChanged)

        #expect(model.value == 0.75)
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
