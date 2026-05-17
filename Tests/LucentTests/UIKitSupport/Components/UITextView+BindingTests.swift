//
//  UITextView+BindingTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation
import Observation
import SwiftUI
import Testing
import UIKit
import LucentCore

@Suite("UITextView+Binding")
struct UITextViewBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesTextChangesBack() async throws {
        let model = ObservableValueModel(value: "Initial")
        let control = UITextView(text: binding(to: model))

        #expect(control.text == "Initial")

        model.value = "Updated"
        try await eventually {
            control.text == "Updated"
        }

        control.text = "Typed"
        NotificationCenter.default.post(
            name: UITextView.textDidChangeNotification,
            object: control
        )

        #expect(model.value == "Typed")
    }

    @MainActor
    @Test func bindReplacesExistingBinding() async throws {
        var oldModel: ObservableValueModel<String>? = ObservableValueModel(value: "Old")
        weak var weakOldModel: ObservableValueModel<String>?
        weakOldModel = oldModel
        let newModel = ObservableValueModel(value: "New")
        let control = UITextView(text: binding(to: oldModel!))

        #expect(control.text == "Old")

        control.bind(text: binding(to: newModel))
        #expect(control.text == "New")

        oldModel?.value = "Old update"
        await settleObservation()
        #expect(control.text == "New")

        newModel.value = "New update"
        try await eventually {
            control.text == "New update"
        }

        control.text = "Typed"
        NotificationCenter.default.post(
            name: UITextView.textDidChangeNotification,
            object: control
        )

        #expect(oldModel?.value == "Old update")
        #expect(newModel.value == "Typed")

        oldModel = nil
        try await eventually {
            weakOldModel == nil
        }
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

@concurrent
private func settleObservation() async {
    for _ in 0..<10 {
        await Task.yield()
    }
}
