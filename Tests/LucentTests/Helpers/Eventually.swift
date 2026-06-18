//
//  Eventually.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation


@concurrent
func allowStoreObserversToRegister() async {
    for _ in 0..<10 {
        try? await Task.sleep(for: .milliseconds(10))
    }
}
