//
//  NSObject+ObserveTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation
import Observation
import Testing
@testable import Lucent

@Suite("NSObject+Observe")
struct NSObjectObserveTests {

    @MainActor
    @Test func observeRunsImmediatelyAndTracksChanges() async throws {
        let object = NSObject()
        let model = ObservableIntModel(value: 1)
        let values = Recorder<Int>()

        object.observe(identifier: "value") {
            let value = model.value
            Task {
                await values.append(value)
            }
        }

        try await eventually {
            await values.values == [1]
        }

        model.value = 2

        try await eventually {
            await values.values == [1, 2]
        }
    }

    @MainActor
    @Test func observeReplacesExistingObservationForIdentifier() async throws {
        let object = NSObject()
        let firstModel = ObservableIntModel(value: 1)
        let secondModel = ObservableIntModel(value: 10)
        let firstValues = Recorder<Int>()
        let secondValues = Recorder<Int>()

        object.observe(identifier: "value") {
            let value = firstModel.value
            Task {
                await firstValues.append(value)
            }
        }

        try await eventually {
            await firstValues.values == [1]
        }

        object.observe(identifier: "value") {
            let value = secondModel.value
            Task {
                await secondValues.append(value)
            }
        }

        try await eventually {
            await secondValues.values == [10]
        }

        firstModel.value = 2
        secondModel.value = 11

        try await eventually {
            await secondValues.values == [10, 11]
        }
        #expect(await firstValues.values == [1])
    }
}

@Observable
private final class ObservableIntModel {
    var value: Int

    init(value: Int) {
        self.value = value
    }
}
