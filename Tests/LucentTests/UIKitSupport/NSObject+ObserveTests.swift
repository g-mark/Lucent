//
//  NSObject+ObserveTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation
import Observation
import Testing
@testable import LucentCore

@Suite("NSObject+Observe")
struct NSObjectObserveTests {

    @MainActor
    @Test func observeRunsImmediatelyAndTracksChanges() async throws {
        let object = NSObject()
        let model = ObservableIntModel(value: 1)
        let values = LockedRecorder<Int>()

        object.observe(identifier: "value") {
            values.append(model.value)
        }

        try await values.waitForValues([1])

        model.value = 2

        try await values.waitForValues([1, 2])
    }

    @MainActor
    @Test func observeReplacesExistingObservationForIdentifier() async throws {
        let object = NSObject()
        let firstModel = ObservableIntModel(value: 1)
        let secondModel = ObservableIntModel(value: 10)
        let firstValues = LockedRecorder<Int>()
        let secondValues = LockedRecorder<Int>()

        object.observe(identifier: "value") {
            firstValues.append(firstModel.value)
        }

        try await firstValues.waitForValues([1])

        object.observe(identifier: "value") {
            secondValues.append(secondModel.value)
        }

        try await secondValues.waitForValues([10])

        firstModel.value = 2
        secondModel.value = 11

        try await secondValues.waitForValues([10, 11])
        #expect(firstValues.values == [1])
    }
}

@Observable
private final class ObservableIntModel {
    var value: Int

    init(value: Int) {
        self.value = value
    }
}
