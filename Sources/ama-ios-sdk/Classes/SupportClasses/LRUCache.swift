//
//  LRUCache.swift
//  ama-ios-sdk
//
//  Created by iGrant on 23/01/25.
//

import Foundation

class LRUCache {
    private let capacity: Int
    private var cache: [String] = [] // Stores the IDs in usage order

    init(capacity: Int) {
        self.capacity = capacity
    }

    // Add a value to the cache
    func add(_ value: String) -> Bool {
        if let index = cache.firstIndex(of: value) {
            // If the value already exists, move it to the end
            cache.remove(at: index)
            cache.append(value)
            return false // Value already existed in the cache
        }

        // If the cache is full, remove the least recently used value
        if cache.count >= capacity {
            cache.removeFirst()
        }

        // Add the new value to the end of the cache
        cache.append(value)
        return true // Value added to the cache
    }

    // Check if a value is in the cache
    func contains(_ value: String) -> Bool {
        return cache.contains(value)
    }

    // Remove a value from the cache
    func remove(_ value: String) {
        if let index = cache.firstIndex(of: value) {
            cache.remove(at: index)
        }
    }

    // Clear all values from the cache
    func clear() {
        cache.removeAll()
    }

    // Get all cached values (for debugging or inspection)
    func allValues() -> [String] {
        return cache
    }
}
