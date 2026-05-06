//
//  Recorder.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation

actor Recorder<Value: Sendable> {
    private var recordedValues: [Value] = []

    var values: [Value] {
        recordedValues
    }

    func append(_ value: Value) {
        recordedValues.append(value)
    }
}

final class LockedRecorder<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedValues: [Value] = []

    var values: [Value] {
        lock.lock()
        defer { lock.unlock() }
        return recordedValues
    }

    func append(_ value: Value) {
        lock.lock()
        defer { lock.unlock() }
        recordedValues.append(value)
    }
}
