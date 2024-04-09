//
//  EMWeakMapTable.swift
//  AVFoundationQueuePlayer-iOS
//
//  Created by liukun on 2024/4/1.
//

import Foundation

protocol EMWeakArrayValueType: AnyObject {
    static var identifier: String { get }
}

final class EMWeakArray<T: EMWeakArrayValueType> {
    private var factories = [String: () -> T]()

    private var weakCachedArray = NSPointerArray.weakObjects()

    var count: Int {
        weakCachedArray.count
    }

    func get(_ index: Int) -> T? {
        weakCachedArray.compact()
        if index < weakCachedArray.count, let pointer = weakCachedArray.pointer(at: index) {
            return Unmanaged<T>.fromOpaque(pointer).takeUnretainedValue()
        } else {
            return nil
        }
    }

    func append(_ element: T) {
        weakCachedArray.compact()
        weakCachedArray.addPointer(Unmanaged.passUnretained(element).toOpaque())
    }

    func forEach(_ callback: (T) -> ()) {
        weakCachedArray.compact()
        for i in 0 ..< weakCachedArray.count {
            if let element = get(i) {
                callback(element)
            }
        }
    }

    func register(dependencyFactory: @escaping () -> T) {
        let key = T.identifier
        factories[key] = dependencyFactory
    }

    func buildInstance() -> T? {
        weakCachedArray.compact()
        let key = T.identifier
        guard let newInstance = factories[key]?() else { return nil }
        append(newInstance)
        return newInstance
    }
}
