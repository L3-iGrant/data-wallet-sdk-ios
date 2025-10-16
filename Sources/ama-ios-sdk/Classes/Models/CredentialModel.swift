//
//  CredentialModel.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 21/11/20.
//

import Foundation

struct CredentialModel: Codable {
    let type, id: String?
    let thread: CredentialModelThread?
    let credentialPreview: CredentialPreview?
    let offersAttach: [OffersAttach]?
    let comment: String?
    let dataAgreementContext: DataAgreementContext?
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case thread = "~thread"
        case dataAgreementContext = "~data-agreement-context"
        case credentialPreview = "credential_preview"
        case offersAttach = "offers~attach"
        case comment
    }
}

// MARK: - CredentialPreview
struct CredentialPreview: Codable {
    let type: String?
    let attributes: [Attribute]?
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case attributes
    }
}

// MARK: - Attribute
class Attribute: Codable {
    let name, value: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case value
    }
    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        name = try? container.decodeIfPresent(String.self, forKey: .name)
//        value = CodableUtils.decodeAsString(container: container, codingKey: .value)
//    }
//    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//            try container.encodeIfPresent(self.name, forKey: .name)
//            try container.encodeIfPresent(self.value, forKey: .value)
//    }
}

// MARK: - OffersAttach
struct OffersAttach: Codable {
    let id, mimeType: String?
    let data: DataClass?
    
    enum CodingKeys: String, CodingKey {
        case id = "@id"
        case mimeType = "mime-type"
        case data
    }
}

// MARK: - DataClass
struct DataClass: Codable {
    let base64: String?
}

// MARK: - Thread
struct CredentialModelThread: Codable {
}
