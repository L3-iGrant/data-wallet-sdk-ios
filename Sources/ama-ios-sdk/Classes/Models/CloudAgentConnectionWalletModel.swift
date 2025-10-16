// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let cloudAgentConnectionWalletModel = try? newJSONDecoder().decode(CloudAgentConnectionWalletModel.self, from: jsonData)

import Foundation

// MARK: - CloudAgentConnectionWalletModel
struct CloudAgentConnectionWalletModel: Codable {
    var type: String?
    var id: String?
    var value: CloudAgentConnectionValue?
    var tags: CloudAgentConnectionTags?
    
    init() { }
}


// MARK: - CloudAgentConnectionTags
struct CloudAgentConnectionTags: Codable {
    let theirDid, invitationKey, requestID, myDid, orgId, myVerKey: String?

    enum CodingKeys: String, CodingKey {
        case theirDid = "their_did"
        case invitationKey = "invitation_key"
        case requestID = "request_id"
        case myDid = "my_did"
        case orgId
        case myVerKey
    }
}

// MARK: - CloudAgentConnectionValue
class CloudAgentConnectionValue: Codable {
    let myDid, updatedAt: String?
    let alias: String?
    let routingState, createdAt: String?
    let theirRole: String?
    let requestID, theirLabel, inboxKey, invitationMode: String?
    let accept, inboxID, invitationKey, state: String?
    let inboundConnectionID: String?
    let initiator: String?
    let errorMsg: String?
    let theirDid: String?
    let imageURL: String?
    let reciepientKey: String?
    let isIgrantAgent: String?
    let routingKey: [String]?
    var orgDetails: OrganisationInfoModel?
    let orgId: String?
    var isThirdPartyShareSupported: String?

    enum CodingKeys: String, CodingKey {
        case myDid = "my_did"
        case updatedAt = "updated_at"
        case alias
        case routingState = "routing_state"
        case createdAt = "created_at"
        case theirRole = "their_role"
        case requestID = "request_id"
        case theirLabel = "their_label"
        case inboxKey = "inbox_Key"
        case invitationMode = "invitation_mode"
        case accept
        case inboxID = "inbox_id"
        case invitationKey = "invitation_key"
        case state
        case inboundConnectionID = "inbound_connection_id"
        case initiator
        case errorMsg = "error_msg"
        case theirDid = "their_did"
        case imageURL
        case reciepientKey
        case isIgrantAgent
        case routingKey = "routing_key"
        case orgDetails
        case orgId
        case isThirdPartyShareSupported
    }
    
    init(myDid: String?, updatedAt: String?, alias: String?, routingState: String?, createdAt: String?, theirRole: String?, requestID: String?, theirLabel: String?, inboxKey: String?, invitationMode: String?, accept: String?, inboxID: String?, invitationKey: String?, state: String?, inboundConnectionID: String?, initiator: String?, errorMsg: String?, theirDid: String?, imageURL: String?, reciepientKey: String?, isIgrantAgent: String?, routingKey: [String]?, orgDetails: OrganisationInfoModel?, orgId: String?, isThirdPartyShareSupported: String?) {
        self.myDid = myDid
        self.updatedAt = updatedAt
        self.alias = alias
        self.routingState = routingState
        self.createdAt = createdAt
        self.theirRole = theirRole
        self.requestID = requestID
        self.theirLabel = theirLabel
        self.inboxKey = inboxKey
        self.invitationMode = invitationMode
        self.accept = accept
        self.inboxID = inboxID
        self.invitationKey = invitationKey
        self.state = state
        self.inboundConnectionID = inboundConnectionID
        self.initiator = initiator
        self.errorMsg = errorMsg
        self.theirDid = theirDid
        self.imageURL = imageURL
        self.reciepientKey = reciepientKey
        self.isIgrantAgent = isIgrantAgent
        self.routingKey = routingKey
        self.orgDetails = orgDetails
        self.orgId = orgId
        self.isThirdPartyShareSupported = isThirdPartyShareSupported
    }
    
}

struct CloudAgentSearchConnectionModel: Codable {
    let totalCount: Int?
    let records: [CloudAgentConnectionWalletModel]?
}
