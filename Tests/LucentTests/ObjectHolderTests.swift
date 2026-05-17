//
//  ObjectHolderTests.swift
//  Lucent
//
//  Created by Steven Grosmark on 5/5/26.
//

import Foundation
import Testing
@testable import LucentCore

@Suite("ObjectHolder")
struct ObjectHolderTests {

    @MainActor
    @Test func holdReferenceKeepsObjectAlive() {
        let owner = NSObject()
        weak var weakObject: NSObject?

        do {
            let object = NSObject()
            weakObject = object

            owner.holdReference(to: object)
        }

        #expect(weakObject != nil)
    }

    @MainActor
    @Test func releaseReferenceAllowsObjectToDeallocate() {
        let owner = NSObject()
        weak var weakObject: NSObject?

        do {
            let object = NSObject()
            weakObject = object

            owner.holdReference(to: object)
            owner.releaseReference(to: object)
        }

        #expect(weakObject == nil)
    }

    @MainActor
    @Test func releaseReferenceOnlyReleasesMatchingObject() {
        let owner = NSObject()
        weak var weakHeldObject: NSObject?
        weak var weakReleasedObject: NSObject?

        do {
            let heldObject = NSObject()
            let releasedObject = NSObject()
            weakHeldObject = heldObject
            weakReleasedObject = releasedObject

            owner.holdReference(to: heldObject)
            owner.holdReference(to: releasedObject)
            owner.releaseReference(to: releasedObject)
        }

        #expect(weakHeldObject != nil)
        #expect(weakReleasedObject == nil)
    }

    @MainActor
    @Test func heldObjectsAreReleasedWhenOwnerDeallocates() {
        weak var weakOwner: NSObject?
        weak var weakObject: NSObject?

        do {
            let owner = NSObject()
            let object = NSObject()
            weakOwner = owner
            weakObject = object

            owner.holdReference(to: object)
        }

        #expect(weakOwner == nil)
        #expect(weakObject == nil)
    }

    @MainActor
    @Test func releasingUnheldObjectDoesNotReleaseHeldObjects() {
        let owner = NSObject()
        weak var weakHeldObject: NSObject?

        do {
            let heldObject = NSObject()
            let unheldObject = NSObject()
            weakHeldObject = heldObject

            owner.holdReference(to: heldObject)
            owner.releaseReference(to: unheldObject)
        }

        #expect(weakHeldObject != nil)
    }
}
