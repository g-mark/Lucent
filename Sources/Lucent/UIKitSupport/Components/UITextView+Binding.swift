//
//  UITextView+Binding.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/4/26.
//

import UIKit
import SwiftUI


@available(iOS 17.0, *)
public extension UITextView {

    convenience init(text binding: Binding<String>) {
        self.init()
        bind(text: binding)
    }

    func bind(text binding: Binding<String>) {
        // model -> view
        observe(identifier: "Lucent.UITextView.binding") { [weak self] in
            guard let self else { return }
            let new = binding.wrappedValue
            if self.text != new { self.text = new }
        }

        // view -> model (via NotificationCenter; UITextView isn't UIControl)
        let token = NotificationCenter.default.addObserver(
            forName: UITextView.textDidChangeNotification,
            object: self,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                let current = self.text ?? ""
                if binding.wrappedValue != current {
                    binding.wrappedValue = current
                }
            }
        }
        objc_setAssociatedObject(
            self, &textViewObserverKey,
            NotificationToken(token: token),
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}

private nonisolated(unsafe) var textViewObserverKey: UInt8 = 0

private final class NotificationToken {
    let token: any NSObjectProtocol
    init(token: any NSObjectProtocol) { self.token = token }
    deinit { NotificationCenter.default.removeObserver(token) }
}
