//
//  ExchangeDataQRCodeModel.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 18/12/20.
//

import Foundation

// MARK: - ExchangeDataQRCodeModel
public struct ExchangeDataQRCodeModel: Codable {
    let invitationURL: String?
    let proofRequest: PresentationRequestModel?
    let threadId: String?
    let didCom: String?
    
    enum CodingKeys: String, CodingKey {
        case invitationURL = "invitation_url"
        case proofRequest = "proof_request"
        case threadId,didCom
    }
}

struct SelfAttestedModel: Codable {
    var type, subType: String?
    var version: Int?
    var headerFields: HeaderFields?
    var qrCodeData: QrCodeData?
    var topImageKey: String?
    var sectionCount: Int?
    var sectionModel: [SectionAttestModel]?
    var bottomImageKey: String?
    var attributes: AttestAttributes?
    
    enum CodingKeys: String, CodingKey {
        case type, subType
        case version = "Version"
        case headerFields, qrCodeData, topImageKey, sectionCount, bottomImageKey, attributes
        case sectionModel = "sectionStruct"
    }
}

struct AttestAttributes: Codable {
    var registration, ticketNumber, logo, coverImage: AttestLogo?
    
    enum CodingKeys: String, CodingKey {
        case registration = "Registration"
        case ticketNumber = "Ticket Number"
        case logo = "Logo"
        case coverImage = "Cover Image"
    }
}

struct AttestLogo: Codable {
    var value: String?
    var type, imageType, parent, label: String?
}

struct HeaderFields: Codable {
    var title, subTitle, desc: String?
}

struct QrCodeData: Codable {
    var rawData, imageBase64: String?
}

struct SectionAttestModel: Codable {
    var title, key: String?
}
