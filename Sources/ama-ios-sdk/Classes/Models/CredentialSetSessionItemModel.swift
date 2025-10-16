//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 03/10/25.
//

import Foundation

public struct SessionItem: Codable {
    public let credentialIdList: [String]
    public let type: String
    public var selectedCredentialIndex: [Int]
    public var checkedItem:[Int]
    public let options: [[String]]
    public var mandatoryItems: [String]
    // add new item mandatoryItems only for pwa
    
    public init(credentialIdList: [String], type: String, checkedItem: [Int] = [], options: [[String]] = [], mandatoryItems: [String] = []) {
        self.credentialIdList = credentialIdList
        self.type = type
        // Default: fill with 0 for each credentialId
        self.selectedCredentialIndex = Array(repeating: 0, count: credentialIdList.count)
        // Default: empty array
        self.checkedItem = checkedItem
        self.options = options
        self.mandatoryItems = mandatoryItems
    }
}
