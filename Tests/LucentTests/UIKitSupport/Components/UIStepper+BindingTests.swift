//
//  UIStepper+BindingTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Observation
import SwiftUI
import Testing
import UIKit
import LucentCore

@Suite("UIStepper+Binding")
struct UIStepperBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesControlChangesBack() async throws {
        let model = ObservableValueModel(value: 1.0)
        let bindingReads = LockedRecorder<Double>()
        let control = UIStepper(value: binding(to: model) { bindingReads.append($0) })

        try await bindingReads.waitForValue(1.0)
        #expect(control.value == 1.0)

        model.value = 2.0
        try await bindingReads.waitForValue(2.0)
        #expect(control.value == 2.0)

        control.value = 3.0
        control.sendActions(for: .valueChanged)

        #expect(model.value == 3.0)
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
