//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 20/08/25.
//

import Foundation

class DraftSuffixProcessor {
    
    func isDraftID(_ id: String) -> Bool? {
        guard id.contains("igrant.io") else { return false }
        let pattern = "/draft-\\d+$"
        return id.range(of: pattern, options: .regularExpression) != nil
    }
    
    func removeDraftSuffix(from id: String) -> String? {
        guard let range = id.range(of: "/draft-\\d+$", options: .regularExpression) else {
            return nil
        }
        return String(id[..<range.lowerBound])
    }
    
}
