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
    timeout: TimeInterval = 1,
    sourceLocation: SourceLocation = #_sourceLocation,
    check: @MainActor () async throws -> Bool
) async throws {
    let deadline = Date(timeInterval: timeout, since: Date())
    while Date() < deadline {
        await Task.yield()
        if try await check() {
            return
        }
        await Task.yield()
    }

    Issue.record("eventually exceeded timeout of \(timeout) seconds", sourceLocation: sourceLocation)
    throw EventuallyTimedOut()
}

struct EventuallyTimedOut: Error { }
