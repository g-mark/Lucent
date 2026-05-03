//
//  ObjectHolder.swift
//  Lucent
//
//  Created by Steven Grosmark on 6/5/19.
//

import Foundation


/// Objects that can hold strong references to other objects
protocol ObjectHolder: AnyObject {
    func holdReference(to object: AnyObject)
    func releaseReference(to object: AnyObject)
}

extension NSObject: @MainActor ObjectHolder { }

extension ObjectHolder {

    /// Hold a strong reference to `object`.
    /// The reference will be released when the target `ObjectHolder` is released.
    ///
    /// - Parameter object: The instance to hold a strong reference to.
    @MainActor
    func holdReference(to object: AnyObject) {
        var heldObjects = objc_getAssociatedObject(self, &HeldObjects.associationKey) as? HeldObjects.Dictionary ?? [:]
        heldObjects[ObjectIdentifier(object)] = object
        objc_setAssociatedObject(self, &HeldObjects.associationKey, heldObjects, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// Release a previously held strong reference to `object`
    ///
    /// - Parameter object: The instance to let go of.
    @MainActor
    func releaseReference(to object: AnyObject) {
        guard var heldObjects = objc_getAssociatedObject(self, &HeldObjects.associationKey) as? HeldObjects.Dictionary else { return }
        heldObjects.removeValue(forKey: ObjectIdentifier(object))
        if heldObjects.isEmpty {
            objc_setAssociatedObject(self, &HeldObjects.associationKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        else {
            objc_setAssociatedObject(self, &HeldObjects.associationKey, heldObjects, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

@MainActor
private enum HeldObjects {

    typealias Dictionary = [ObjectIdentifier: AnyObject]

    static var associationKey: Int = 0
}
