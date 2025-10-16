//
//  MediatorDidDocModel.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 24/11/20.
//

import Foundation

// MARK: - MediatorDidDocModel
struct SearchDidDocModel: Codable {
    let totalCount: Int?
    let records: [DidDocModel]?
}

// MARK: - DidDocModel
struct DidDocModel: Codable {
    let type: JSONNull?
    let id: String?
    let value: Value?
    let tags: Tags?
}

// MARK: - Tags
struct Tags: Codable {
    let did: String?
}

// MARK: - Value
struct Value: Codable {
    let context: String?
    let service: [Service]?
    let authentication: [Authentication]?
    let id: String?
    let publicKey: [PublicKey]?

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case service, authentication, id, publicKey
    }
}

// MARK: - Authentication
struct Authentication: Codable {
    let type, publicKey: String?
}

// MARK: - PublicKey
struct PublicKey: Codable {
    let controller, id, type, publicKeyBase58: String?
}

// MARK: - Service
struct Service: Codable {
    let routingKeys: [String]?
    let type: String?
    let serviceEndpoint: String?
    let priority: Int?
    let id: String?
    let recipientKeys: [String]?
}

// MARK: - Localise
struct Connections: Codable {
    let records: [RecordNew]
    let totalCount: Int
}

// MARK: - Record
struct RecordNew: Codable {
    let type: JSONNull?
    let value: ValueNew
    let tags: TagsNew
    let id: String
}

// MARK: - Tags
struct TagsNew: Codable {
    let myDid, isIgrantAgent, myVerKey, orgID: String
    let requestID, reciepientKey, theirDid, routingKey: String
    let state, invitationKey: String

    enum CodingKeys: String, CodingKey {
        case myDid = "my_did"
        case isIgrantAgent, myVerKey, orgID
        case requestID = "request_id"
        case reciepientKey
        case theirDid = "their_did"
        case routingKey = "routing_key"
        case state
        case invitationKey = "invitation_key"
    }
}

// MARK: - Value
struct ValueNew: Codable {
    let routingState, invitationMode: String
    let errorMsg: JSONNull?
    let theirLabel, inboxKey, initiator, isIgrantAgent: String
    let invitationKey, inboxID, theirDid, orgID: String
    let createdAt: String
    let inboundConnectionID, alias: JSONNull?
    let accept: String
    let orgDetails: OrgDetailsNew
    let reciepientKey: String
    let routingKey: JSONNull?
    let imageURL: String
    let isThirdPartyShareSupported, requestID, state, myDid: String
    let updatedAt: String
    let theirRole: JSONNull?

    enum CodingKeys: String, CodingKey {
        case routingState = "routing_state"
        case invitationMode = "invitation_mode"
        case errorMsg = "error_msg"
        case theirLabel = "their_label"
        case inboxKey = "inbox_Key"
        case initiator, isIgrantAgent
        case invitationKey = "invitation_key"
        case inboxID = "inbox_id"
        case theirDid = "their_did"
        case orgID
        case createdAt = "created_at"
        case inboundConnectionID = "inbound_connection_id"
        case alias, accept, orgDetails, reciepientKey
        case routingKey = "routing_key"
        case imageURL, isThirdPartyShareSupported
        case requestID = "request_id"
        case state
        case myDid = "my_did"
        case updatedAt = "updated_at"
        case theirRole = "their_role"
    }
}

// MARK: - OrgDetails
struct OrgDetailsNew: Codable {
    let coverImageURL: String?
    let logoImageURL: String?
    let orgID, description, location, name: String?
    var isValidOrganization: Bool?

    enum CodingKeys: String, CodingKey {
        case coverImageURL = "cover_image_url"
        case logoImageURL = "logo_image_url"
        case orgID = "org_id"
        case description, location, name
        case isValidOrganization
    }
}
