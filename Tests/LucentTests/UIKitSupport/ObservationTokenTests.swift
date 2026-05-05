//
//  ObservationTokenTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation
import Observation
import Testing
@testable import Lucent

@Suite("ObservationToken")
struct ObservationTokenTests {

    @MainActor
    @Test func tokenRunsImmediatelyAndTracksChanges() async throws {
        let model = ObservableIntModel(value: 1)
        let values = Recorder<Int>()

        let token = ObservationToken(model: model) { model in
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
        _ = token
    }
}

@Observable
private final class ObservableIntModel {
    var value: Int

    init(value: Int) {
        self.value = value
    }
}
