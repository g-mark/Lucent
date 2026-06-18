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
import LucentCore

@Suite("UIColorWell+Binding")
struct UIColorWellBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesControlChangesBack() async throws {
        let model = ObservableValueModel<UIColor?>(value: .red)
        let bindingReads = LockedRecorder<String>()
        let control = UIColorWell(selectedColor: binding(to: model) {
            bindingReads.append(colorName($0))
        })

        try await bindingReads.waitForValue("red")
        #expect(control.selectedColor == .red)

        model.value = .blue
        try await bindingReads.waitForValue("blue")
        #expect(control.selectedColor == .blue)

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

private func colorName(_ color: UIColor?) -> String {
    switch color {
    case .red: "red"
    case .blue: "blue"
    case .green: "green"
    default: String(describing: color)
    }
}
