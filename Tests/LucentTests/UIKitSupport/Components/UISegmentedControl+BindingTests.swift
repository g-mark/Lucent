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
import LucentCore

@Suite("UISegmentedControl+Binding")
struct UISegmentedControlBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesControlChangesBack() async throws {
        let model = ObservableValueModel(value: 1)
        let bindingReads = LockedRecorder<Int>()
        let control = UISegmentedControl(
            items: ["One", "Two", "Three"],
            selectedSegmentIndex: binding(to: model) { bindingReads.append($0) }
        )

        try await bindingReads.waitForValue(1)
        #expect(control.selectedSegmentIndex == 1)

        model.value = 2
        try await bindingReads.waitForValue(2)
        #expect(control.selectedSegmentIndex == 2)

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
