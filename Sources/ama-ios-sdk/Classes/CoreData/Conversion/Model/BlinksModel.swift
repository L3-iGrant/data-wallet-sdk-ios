//
//  BlinksModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 14/10/22.
//

import Foundation

struct BlinksModel: Codable {
    
    var prefix, url: String
    var infraProviders: [String]
    
    enum CodingKeys: String, CodingKey {
        case prefix
        case url
        case infraProviders
    }
}

