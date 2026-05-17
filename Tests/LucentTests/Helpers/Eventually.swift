//
//  Eventually.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation
import Testing


@MainActor
func eventually(
    timeout: TimeInterval = 5,
    sourceLocation: SourceLocation = #_sourceLocation,
    check: @MainActor () async throws -> Bool
) async throws {
    let deadline = Date(timeInterval: timeout, since: Date())
    while Date() < deadline {
        if try await check() {
            return
        }
        try await Task.sleep(for: .milliseconds(10))
    }

    Issue.record("eventually exceeded timeout of \(timeout) seconds", sourceLocation: sourceLocation)
    throw EventuallyTimedOut()
}

struct EventuallyTimedOut: Error { }

@concurrent
func allowStoreObserversToRegister() async {
    for _ in 0..<10 {
        try? await Task.sleep(for: .milliseconds(10))
    }
}
