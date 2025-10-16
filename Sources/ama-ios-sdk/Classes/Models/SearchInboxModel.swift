//
//  SearchInboxModel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 18/01/21.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let inboxModelSearchInboxModel = try? newJSONDecoder().decode(InboxModelSearchInboxModel.self, from: jsonData)

import Foundation

// MARK: - InboxModelSearchInboxModel
struct SearchInboxModel: Codable {
    let totalCount: Int?
    let records: [InboxModelRecord]?

    enum CodingKeys: String, CodingKey {
        case totalCount = "totalCount"
        case records = "records"
    }
}

// MARK: - InboxModelRecord
class InboxModelRecord: Codable {
    let type: String?
    let id: String?
    let value: InboxModelRecordValue?
    let tags: InboxModelRecordTags?

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case id = "id"
        case value = "value"
        case tags = "tags"
    }
    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.type = try container.decodeIfPresent(String.self, forKey: .type)
//        self.id = try container.decodeIfPresent(String.self, forKey: .id)
//        self.tags = try container.decodeIfPresent(InboxModelRecordTags.self, forKey: .tags)
//        if let str = try? container.decodeIfPresent(String.self, forKey: .value), let dict = UIApplicationUtils.shared.convertStringToDictionary(text: str){
//            self.value = InboxModelRecordValue.decode(withDictionary: dict as NSDictionary? ?? NSDictionary()) as? InboxModelRecordValue
//        }else{
//            self.value = try container.decodeIfPresent(InboxModelRecordValue.self, forKey: .value)
//        }
//
//    }
}

// MARK: - InboxModelRecordTags
struct InboxModelRecordTags: Codable {
    let threadID: String?
    let type: String?
    let requestID: String?
    let state: String?

    enum CodingKeys: String, CodingKey {
        case threadID = "thread_id"
        case type = "type"
        case requestID = "request_id"
        case state = "state"
    }
}

// MARK: - InboxModelRecordValue
class InboxModelRecordValue: Codable {
    let connectionModel: CloudAgentConnectionWalletModel?
    let presentationRequest: SearchPresentationExchangeValueModel?
    let offerCredential:SearchCertificateRecord?
    var dataAgreement: DataAgreementContext?
    var walletRecordCertModel: CustomWalletRecordCertModel?
    let type: String?
    let orgRecordId: String?

    init(connectionModel: CloudAgentConnectionWalletModel?, presentationRequest: SearchPresentationExchangeValueModel?, offerCredential: SearchCertificateRecord?, dataAgreement: DataAgreementContext?, type: String?, orgRecordId: String?, walletRecordCertModel: CustomWalletRecordCertModel? = nil){
        self.connectionModel = connectionModel
        self.presentationRequest = presentationRequest
        self.offerCredential = offerCredential
        self.dataAgreement = dataAgreement
        self.type = type
        self.orgRecordId = orgRecordId
        self.walletRecordCertModel = walletRecordCertModel
    }
    
    enum CodingKeys: String, CodingKey {
        case connectionModel = "connectionModel"
        case presentationRequest = "presentationRequest"
        case type = "type"
        case offerCredential
        case orgRecordId
        case dataAgreement
        case walletRecordCertModel
    }
}

enum InboxType: String {
    case certOffer = "CertOffer"
    case certRequest = "CertReq"
    case EBSIOffer
}

enum CertType: String {
    //old values don't delete
    case oldCredentials = ""
    case oldSelfAttestedRecords = "self-attested-records"

    //New
    case credentials = "attested_credentials"
    case selfAttestedRecords = "self_attested"
    case idCards = "id_cards"
    case EBSI = "EBSI"
    

    static func isCredential(type:String?) -> String {
        guard let typeString = type else { return "" }
        if (typeString == CertType.oldCredentials.rawValue || typeString == CertType.credentials.rawValue) {
            return typeString
        }else {
            return CertType.credentials.rawValue
        }
    }
    
    static func isSelfAttested(type:String?) -> String {
        guard let typeString = type else {return ""}
        if (typeString == CertType.oldSelfAttestedRecords.rawValue || typeString == CertType.selfAttestedRecords.rawValue) {
            return typeString
        }else {
            return CertType.selfAttestedRecords.rawValue
        }
    }
}

enum CertSubType: String {
    case Reciept = "Receipt"
}

enum EBSI_CredentialType: String {
    case StudentID = "EBSI STUDENT ID"
    case Diploma = "EBSI DIPLOMA CERTIFICATE"
    case VerifiableID = "EBSI VERIFIABLE ID"
    case PDA1 = "PORTABLE DOCUMENT A1"
    case PhotoIDWithAge = "photo_with_age_badge"
    case PWA = "PAYMENT WALLET ATTESTATION"
}

enum EBSI_CredentialSearchText: String {
    case StudentID = "EBSI - STUDENT ID"
    case Diploma = "EBSI - DIPLOMA"
    case VerifiableID = "EBSI - VERIFIABLE ID"
    case PDA1 = "ESSPASS - PORTABLE DOCUMENT A1"
}

enum SelfAttestedCertTypes: String {
    case passport = "passport"
    case idCard = "idCard"
    case covidCert_IN = "covidCert_IN"
    case covidCert_PHL = "covidCert_PHL"
    case covidCert_EU = "covidCert_EU"
    case aadhar = "aadhar"
    case pkPass = "PKPass"
    case digitalTestCertificateEU = "EU TEST CERTIFICATE"
    case generic = "parking_ticket"
    case profile = "profile"
    case PhotoIDWithAge = "photo_with_age_badge"
}
