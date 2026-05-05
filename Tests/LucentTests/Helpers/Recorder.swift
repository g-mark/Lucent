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
