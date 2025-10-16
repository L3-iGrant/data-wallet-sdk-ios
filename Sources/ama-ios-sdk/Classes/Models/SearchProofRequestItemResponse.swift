//
//  SearchProofRequestItemResponse.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 16/12/20.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let searchProofRequestItemResponse = try? newJSONDecoder().decode(SearchProofRequestItemResponse.self, from: jsonData)

import Foundation

// MARK: - SearchProofRequestItemResponseElement
struct SearchProofRequestItemResponseElement: Codable {
    let credInfo: SearchProofReqCredInfo?
    let interval: JSONNull?

    enum CodingKeys: String, CodingKey {
        case credInfo = "cred_info"
        case interval = "interval"
    }
}

// MARK: - SearchProofReqCredInfo
struct SearchProofReqCredInfo: Codable {
    let referent: String?
    let attrs: [String : String]?
    let schemaID: String?
    let credDefID: String?
    let revRegID: JSONNull?
    let credRevID: JSONNull?

    enum CodingKeys: String, CodingKey {
        case referent = "referent"
        case attrs = "attrs"
        case schemaID = "schema_id"
        case credDefID = "cred_def_id"
        case revRegID = "rev_reg_id"
        case credRevID = "cred_rev_id"
    }
    
//    init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        referent = try? container.decodeIfPresent(String.self, forKey: .referent)
//        schemaID = try? container.decodeIfPresent(String.self, forKey: .schemaID)
//        credDefID = try? container.decodeIfPresent(String.self, forKey: .credDefID)
//        revRegID = try? container.decodeIfPresent(JSONNull.self, forKey: .revRegID)
//        credRevID = try? container.decodeIfPresent(JSONNull.self, forKey: .credRevID)
//        attrs = CodableUtils.decodeAsStringMap(container: container, codingKey: .attrs)
//    }
//    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encodeIfPresent(self.referent, forKey: .referent)
//        try container.encodeIfPresent(self.schemaID, forKey: .schemaID)
//        try container.encodeIfPresent(self.credDefID, forKey: .credDefID)
//        try container.encodeIfPresent(self.revRegID, forKey: .revRegID)
//        try container.encodeIfPresent(self.credRevID, forKey: .credRevID)
//        try container.encodeIfPresent(self.attrs, forKey: .attrs)
//    }
}

struct SearchProofRequestItemResponse:Codable {
    var records: [SearchProofRequestItemResponseElement]?
    
    enum CodingKeys: String, CodingKey {
        case records
    }
}
