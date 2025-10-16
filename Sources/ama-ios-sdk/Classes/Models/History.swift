//
//  History.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 23/09/21.
//

import Foundation
import eudiWalletOidcIos
//import OrderedDictionary

enum HistoryType: String{
    case issuedCertificate = "issue"
    case exchange = "exchange"
}

struct History: Codable{
    var attributes: [IDCardAttributes]?
    var name: String?
    var date: String?
    var dataAgreementModel: DataAgreementContext?
    var type: String?
    var connectionModel: CloudAgentConnectionWalletModel?
    var certSubType: String?
    var threadID: String?
    var pullDataNotification: PullDataNotificationModel?
    var receipt: ReceiptModel?
    var JWT: String?
    var JWTList: [String]?
    var presentationDefinition: PresentationDefinitionWrapper?
    var display: CredentialDisplay?
    var sectionStruct: [DWSection]?
    var attributesValues: OrderedDictionary<String,DWAttributesModel>?
    var transactionData: TransactionData?
    var credentials: Search_CustomWalletRecordCertModel?
    var fundingSource: FundingSource?
    var receiptData: ReceiptItemModel?

    enum CodingKeys: String, CodingKey {
            case date = "date"
            case attributes = "attributes"
            case connectionModel = "connectionModel"
            case dataAgreementModel = "dataAgreementModel"
            case type = "type"
            case name = "name"
            case certSubType
            case threadID
            case pullDataNotification
            case receipt
            case JWT
            case JWTList
            case presentationDefinition
            case display
            case sectionStruct
            case attributesValues
            case transactionData
            case credentials
            case fundingSource
            case receiptData
    }
    
}

enum PresentationDefinitionWrapper: Codable {
    case presentationDefinition(PresentationDefinitionModel)
    case dcqlQuery(DCQLQuery)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode as DCQLQuery
        if let dcql = try? container.decode(DCQLQuery.self) {
            self = .dcqlQuery(dcql)
            return
        }
        
        // Try to decode as PresentationDefinitionModel first
        if let pd = try? container.decode(PresentationDefinitionModel.self) {
            self = .presentationDefinition(pd)
            return
        }
        
        
        throw DecodingError.typeMismatch(
            PresentationDefinitionWrapper.self,
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected PresentationDefinitionModel or DCQLQuery")
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .presentationDefinition(let pd):
            try container.encode(pd)
        case .dcqlQuery(let dcql):
            try container.encode(dcql)
        }
    }
}

// MARK: - RecordTags
class HistoryWalletTags: Codable {
    let type: String?
    var organisationID: String?
    let threadID: String?
    let instanceID: String?
    let isThirdPartyDataShare: String?

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case organisationID = "organisation_id"
        case threadID = "thread_id"
        case instanceID
        case isThirdPartyDataShare
    }

    init(type: String?, organisationID: String?, threadID: String?, instanceID:String?,isThirdPartyDataShare: String?) {
        self.type = type
        self.organisationID = organisationID
        self.threadID = threadID
        self.instanceID = instanceID
        self.isThirdPartyDataShare = isThirdPartyDataShare
    }
}

struct HistoryRecordValue: Codable{
    var type: String?
    var id: String?
    var value: HistoryWalletValue?
    var tags: HistoryWalletTags?
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case id = "id"
        case value = "value"
        case tags = "tags"
    }
}

// MARK: - RecordValue
class HistoryWalletValue: Codable {
    var history: History?
    let type: String?
    let id: String?

    enum CodingKeys: String, CodingKey {
        case history = "history"
        case type = "@type"
        case id = "@id"
    }

    init(history: History?, type: String?, id: String?) {
        self.history = history
        self.type = type
        self.id = id
    }
}
// MARK: - InboxModelSearchInboxModel
struct SearchHistoryModel: Codable {
    let totalCount: Int?
    let records: [HistoryRecordValue]?

    enum CodingKeys: String, CodingKey {
        case totalCount = "totalCount"
        case records = "records"
    }
}

struct CredentialDisplay: Codable {
    var name: String?
    var location: String?
    var locale: String?
    var description: String?
    var cover, logo: String?
    var backgroundColor, textColor: String?
    
    init(name: String?, location: String?, locale: String?, description:String?,cover: String?, logo: String?, backgroundColor: String?, textColor: String?) {
        self.name = name
        self.location = location
        self.locale = locale
        self.description = description
        self.cover = cover
        self.logo = logo
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
}
