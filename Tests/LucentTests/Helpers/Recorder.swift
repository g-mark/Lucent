//
//  Recorder.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation
import Testing

final class LockedRecorder<Value: Sendable>: @unchecked Sendable {
    private struct Waiter {
        let predicate: @Sendable ([Value]) -> Bool
        let continuation: CheckedContinuation<Result<[Value], Error>, Never>
    }

    private let lock = NSLock()
    private var recordedValues: [Value] = []
    private var waiters: [UUID: Waiter] = [:]

    var values: [Value] {
        lock.lock()
        defer { lock.unlock() }
        return recordedValues
    }

    func append(_ value: Value) {
        lock.lock()
        recordedValues.append(value)
        let currentValues = recordedValues
        let matchedWaiters = waiters.filter { $0.value.predicate(currentValues) }
        for id in matchedWaiters.keys {
            waiters[id] = nil
        }
        lock.unlock()

        for waiter in matchedWaiters.values {
            waiter.continuation.resume(returning: .success(currentValues))
        }
    }

    func waitForValues(
        _ expectedValues: [Value],
        timeout: TimeInterval = 5,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async throws where Value: Equatable {
        try await waitUntil(timeout: timeout, sourceLocation: sourceLocation) {
            $0 == expectedValues
        }
    }

    func waitForValue(
        _ expectedValue: Value,
        timeout: TimeInterval = 5,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async throws where Value: Equatable {
        try await waitUntil(timeout: timeout, sourceLocation: sourceLocation) {
            $0.contains(expectedValue)
        }
    }

    @discardableResult
    func waitUntil(
        timeout: TimeInterval = 5,
        sourceLocation: SourceLocation = #_sourceLocation,
        predicate: @escaping @Sendable ([Value]) -> Bool
    ) async throws -> [Value] {
        let waiterID = UUID()
        let timeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            self?.resumeWaiter(
                identifiedBy: waiterID,
                with: .failure(EventWaitTimedOut())
            )
        }
        defer { timeoutTask.cancel() }

        let result = await withCheckedContinuation { continuation in
            lock.lock()
            let currentValues = recordedValues
            if predicate(currentValues) {
                lock.unlock()
                continuation.resume(returning: Result<[Value], Error>.success(currentValues))
            } else {
                waiters[waiterID] = Waiter(
                    predicate: predicate,
                    continuation: continuation
                )
                lock.unlock()
            }
        }

        switch result {
        case .success(let values):
            return values
        case .failure(let error):
            Issue.record("timed out waiting for recorded values", sourceLocation: sourceLocation)
            throw error
        }
    }

    private func resumeWaiter(
        identifiedBy waiterID: UUID,
        with result: Result<[Value], Error>
    ) {
        lock.lock()
        let waiter = waiters.removeValue(forKey: waiterID)
        lock.unlock()

        waiter?.continuation.resume(returning: result)
    }
}

struct EventWaitTimedOut: Error { }
