//
//  DataAgreementQueryResponse.swift
//  ama-ios-sdk
//
//  Created by MOHAMED REBIN K on 18/05/23.
//

import Foundation

struct DataAgreementQueryResponse: Codable {
    let results: [DataAgreement]?
    let pagination: Pagination?
}

struct DataAgreement: Codable {
    let dataAgreementID: String?
    let state: String?
    let methodOfUse: String?
    let dataAgreement: Body?
    let publishFlag: Bool?
    let deleteFlag: Bool?
    let schemaID: String?
    let credDefID: String?
    let presentationRequest: PresentationRequest?
    let isExistingSchema: Bool?
    let createdAt: Int?
    let updatedAt: Int?

    enum CodingKeys: String, CodingKey {
        case dataAgreementID = "data_agreement_id"
        case state
        case methodOfUse = "method_of_use"
        case dataAgreement = "data_agreement"
        case publishFlag = "publish_flag"
        case deleteFlag = "delete_flag"
        case schemaID = "schema_id"
        case credDefID = "cred_def_id"
        case presentationRequest = "presentation_request"
        case isExistingSchema = "is_existing_schema"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Pagination
class Pagination: Codable {

    init() {
    }
}

// MARK: - PresentationRequest
class PresentationRequest: Codable {
    let name, comment, version: String?
    let requestedAttributes: RequestedAttributes?
    let requestedPredicates: Pagination?

    enum CodingKeys: String, CodingKey {
        case name, comment, version
        case requestedAttributes = "requested_attributes"
        case requestedPredicates = "requested_predicates"
    }

    init(name: String?, comment: String?, version: String?, requestedAttributes: RequestedAttributes?, requestedPredicates: Pagination?) {
        self.name = name
        self.comment = comment
        self.version = version
        self.requestedAttributes = requestedAttributes
        self.requestedPredicates = requestedPredicates
    }
}

// MARK: - RequestedAttributes
class RequestedAttributes: Codable {
    let additionalProp1, additionalProp2: AdditionalProp?

    init(additionalProp1: AdditionalProp?, additionalProp2: AdditionalProp?) {
        self.additionalProp1 = additionalProp1
        self.additionalProp2 = additionalProp2
    }
}


