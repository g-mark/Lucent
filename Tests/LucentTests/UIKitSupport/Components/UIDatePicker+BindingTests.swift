//
//  UIDatePicker+BindingTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation
import Observation
import SwiftUI
import Testing
import UIKit
@testable import Lucent

@Suite("UIDatePicker+Binding")
struct UIDatePickerBindingTests {

    @MainActor
    @Test func bindingMirrorsBindingAndWritesControlChangesBack() async throws {
        let initialDate = Date(timeIntervalSince1970: 1_000)
        let updatedDate = Date(timeIntervalSince1970: 2_000)
        let selectedDate = Date(timeIntervalSince1970: 3_000)
        let model = ObservableValueModel(value: initialDate)
        let bindingReads = LockedRecorder<Date>()
        let control = UIDatePicker(value: binding(to: model) { bindingReads.append($0) })

        try await bindingReads.waitForValue(initialDate)
        #expect(control.date == initialDate)

        model.value = updatedDate
        try await bindingReads.waitForValue(updatedDate)
        #expect(control.date == updatedDate)

        control.date = selectedDate
        control.sendActions(for: .valueChanged)

        #expect(model.value == selectedDate)
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
