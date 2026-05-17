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
        let bindingReads = LockedRecorder<Bool>()
        let control = UISwitch(isOn: binding(to: model) { bindingReads.append($0) })

        try await bindingReads.waitForValue(true)
        #expect(control.isOn == true)

        model.value = false
        try await bindingReads.waitForValue(false)
        #expect(control.isOn == false)

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
