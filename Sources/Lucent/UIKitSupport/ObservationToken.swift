//
//  ObservationToken.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/3/26.
//

import Foundation
import Observation


/// Re-runs an update closure when an observed model value changes.
///
/// The closure is executed immediately. Any `@Observable` properties read by
/// the closure are tracked and will cause the closure to run again when changed.
@MainActor
internal final class ObservationToken<Model: AnyObject>: NSObject {

    private weak var owner: NSObject?
    private let model: Model
    private let apply: @MainActor (Model) -> Void

    init(
        owner: NSObject,
        model: Model,
        apply: @escaping @MainActor (Model) -> Void
    ) {
        self.owner = owner
        self.model = model
        self.apply = apply
        super.init()
        observe()
    }

    private func observe() {
        withObservationTracking {
            apply(model)
        }
        onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.observe()
            }
        }
    }
}
