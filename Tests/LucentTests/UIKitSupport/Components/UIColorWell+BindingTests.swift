//
//  UIColorWell+BindingTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Observation
import SwiftUI
import Testing
import UIKit
@testable import Lucent

@Suite("UIColorWell+Binding")
struct UIColorWellBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesControlChangesBack() async throws {
        let model = ObservableValueModel<UIColor?>(value: .red)
        let control = UIColorWell(selectedColor: binding(to: model))

        #expect(control.selectedColor == .red)

        model.value = .blue
        try await eventually {
            control.selectedColor == .blue
        }

        control.selectedColor = .green
        control.sendActions(for: .valueChanged)

        #expect(model.value == .green)
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
