//
//  UIControl+BindingTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Observation
import SwiftUI
import Testing
import UIKit
@testable import LucentCore

@Suite("UIControl+Binding")
struct UIControlBindingTests {

    @MainActor
    @Test func attachMirrorsBindingAndWritesControlChangesBack() async throws {
        let model = ObservableValueModel(value: 3)
        let control = TestControl()
        let controlValues = LockedRecorder<Int>()

        control.attach(
            binding: binding(to: model),
            get: { control.value },
            set: {
                control.value = $0
                controlValues.append($0)
            }
        )

        try await controlValues.waitForValues([3])
        #expect(control.value == 3)

        model.value = 4
        try await controlValues.waitForValues([3, 4])
        #expect(control.value == 4)

        control.value = 5
        control.sendActions(for: .valueChanged)

        #expect(model.value == 5)
    }

    @MainActor
    @Test func attachReplacesExistingBinding() async throws {
        var oldModel: ObservableValueModel<Int>? = ObservableValueModel(value: 1)
        weak var weakOldModel: ObservableValueModel<Int>?
        weakOldModel = oldModel
        let newModel = ObservableValueModel(value: 10)
        let control = TestControl()
        let controlValues = LockedRecorder<Int>()

        control.attach(
            binding: binding(to: oldModel!),
            get: { control.value },
            set: {
                control.value = $0
                controlValues.append($0)
            }
        )
        try await controlValues.waitForValues([1])
        #expect(control.value == 1)

        control.attach(
            binding: binding(to: newModel),
            get: { control.value },
            set: {
                control.value = $0
                controlValues.append($0)
            }
        )
        try await controlValues.waitForValues([1, 10])
        #expect(control.value == 10)

        oldModel?.value = 2
        await settleObservation()
        #expect(control.value == 10)

        newModel.value = 11
        try await controlValues.waitForValues([1, 10, 11])
        #expect(control.value == 11)

        control.value = 12
        control.sendActions(for: .valueChanged)

        #expect(oldModel?.value == 2)
        #expect(newModel.value == 12)

        oldModel = nil
        await settleObservation()
        #expect(weakOldModel == nil)
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

@MainActor
private final class TestControl: UIControl {
    var value = 0
}
