//
//  WalletCertModel.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 28/12/20.
//

import Foundation
import eudiWalletOidcIos
//import OrderedCollections

// MARK: - OrganisationListDataWalletCerttModel
 class CustomWalletRecordCertModel: Codable {
    var referent: SearchProofReqCredInfo?
    var schemaID:String?
    var addedDate: String?
    var certInfo: SearchCertificateRecord?
    var connectionInfo: CloudAgentConnectionWalletModel?
    var type: String?
    var passport: IDCardModel?
    var covidCert_IND: CovidIndiaCertificateWalletModel?
    var covidCert_PHL: CovidPHLCertificateWalletModel?
    var covidCert_EU: CovidEUCertificateWalletModel?
    var aadhar: AadharModel?
    var subType: String?
    var pkPass: PKPassWalletModel?
    var searchableText: String?
    var generic: SelfAttestedModel?
    var EBSI_v2: EBSI_V2_WalletModel?
    var description: String?
    var cover: String?
    var logo: String?
    var backgroundColor: String?
    var textColor: String?
    var format: String?
    var validityDate: String?
    var isExpiredCredential: Bool?
    var isRevokedCredential: Bool?
    var expiredTime: String?
    var revokedTime: String?
    var vct: String?
    var fundingSource: FundingSource?
    var accessToken: String?
    var refreshToken: String?
    var notificationID: String?
    var notificationEndPont: String?
    var tokenEndPoint: String?
    var receiptData: ReceiptItemModel?
    var photoIDCredential: PhotoIDCredential?
    
    //DataWallet - dynamic UI models
    var attributes: OrderedDictionary<String,DWAttributesModel>?
    var sectionStruct: [DWSection]?
    var headerFields: DWHeaderFields?
    var qrCodeData: DWQRCodeData?
    var version: Int?
    
    init() {
        addedDate = Date().epochTime
    }
    
    func getCardName() -> String{
        switch subType {
        case SelfAttestedCertTypes.profile.rawValue:
            if let firstName = attributes?["my-firstname"]?.value, let lastName = attributes?["my-lastname"]?.value{
                return firstName + " " + lastName
            }
            return ""
        default: return ""
        }
    }
    
    func getMyDataProfileCardNationality() -> String{
        switch subType {
        case SelfAttestedCertTypes.profile.rawValue:
            if let location = attributes?["my-nationality"]?.value{
                return location
            }
            return ""
        default: return ""
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case referent
        case addedDate
        case connectionInfo
        case schemaID
        case certInfo
        case type
        case passport
        case covidCert_IND
        case covidCert_EU
        case covidCert_PHL
        case aadhar
        case subType = "sub_type"
        case searchableText = "searchable_text"
        case pkPass
        case generic
        case EBSI_v2
        case attributes, sectionStruct, headerFields, qrCodeData, version
        case description
        case cover
        case logo
        case backgroundColor
        case textColor
        case format
        case validityDate
        case isExpiredCredential
        case isRevokedCredential
        case expiredTime
        case revokedTime
        case vct
        case fundingSource
        case accessToken
        case refreshToken
        case notificationID
        case notificationEndPont
        case tokenEndPoint
        case receiptData
        case photoIDCredential
    }
        
         required init(from decoder: Decoder) throws {
             let container = try decoder.container(keyedBy: CodingKeys.self)
             
             self.referent = try? container.decodeIfPresent(SearchProofReqCredInfo.self, forKey: .referent)
             self.addedDate = try? container.decodeIfPresent(String.self, forKey: .addedDate)
             self.connectionInfo = try? container.decodeIfPresent(CloudAgentConnectionWalletModel.self, forKey: .connectionInfo)
             self.schemaID = try? container.decodeIfPresent(String.self, forKey: .schemaID)
             self.certInfo = try? container.decodeIfPresent(SearchCertificateRecord.self, forKey: .certInfo)
             self.type = try? container.decodeIfPresent(String.self, forKey: .type)
             self.passport = try? container.decodeIfPresent(IDCardModel.self, forKey: .passport)
             self.covidCert_IND = try? container.decodeIfPresent(CovidIndiaCertificateWalletModel.self, forKey: .covidCert_IND)
             self.covidCert_EU = try? container.decodeIfPresent(CovidEUCertificateWalletModel.self, forKey: .covidCert_EU)
             self.covidCert_PHL = try? container.decodeIfPresent(CovidPHLCertificateWalletModel.self, forKey: .covidCert_PHL)
             self.aadhar = try? container.decodeIfPresent(AadharModel.self, forKey: .aadhar)
             self.subType = try? container.decodeIfPresent(String.self, forKey: .subType)
             self.searchableText = try? container.decodeIfPresent(String.self, forKey: .searchableText)
             self.pkPass = try? container.decodeIfPresent(PKPassWalletModel.self, forKey: .pkPass)
             self.generic = try? container.decodeIfPresent(SelfAttestedModel.self, forKey: .generic)
             self.EBSI_v2 = try? container.decodeIfPresent(EBSI_V2_WalletModel.self, forKey: .EBSI_v2)
             self.attributes = try? container.decodeIfPresent(OrderedDictionary<String,DWAttributesModel>.self, forKey: .attributes)
             self.format =  try? container.decodeIfPresent(String.self, forKey: .format)
             self.validityDate = try? container.decodeIfPresent(String.self, forKey: .validityDate)
             self.isExpiredCredential =  try? container.decodeIfPresent(Bool.self, forKey: .isExpiredCredential)
             self.isRevokedCredential = try? container.decodeIfPresent(Bool.self, forKey: .isRevokedCredential)
             self.expiredTime =  try? container.decodeIfPresent(String.self, forKey: .expiredTime)
             self.revokedTime = try? container.decodeIfPresent(String.self, forKey: .revokedTime)
             
             //support old datatype
             if self.attributes == nil, let dict = try? container.decodeIfPresent([String:DWAttributesModel].self, forKey: .attributes){
                 var attrDict: OrderedDictionary<String,DWAttributesModel> = [:]
                 dict.forEach { e in
                     attrDict[e.key] = e.value
                 }
                 self.attributes = attrDict
             }
             self.sectionStruct = try? container.decodeIfPresent([DWSection].self, forKey: .sectionStruct)
             self.headerFields = try? container.decodeIfPresent(DWHeaderFields.self, forKey: .headerFields)
             self.qrCodeData = try? container.decodeIfPresent(DWQRCodeData.self, forKey: .qrCodeData)
             self.version = try? container.decodeIfPresent(Int.self, forKey: .version)
             self.description = try? container.decodeIfPresent(String.self, forKey: .description)
             self.cover = try? container.decodeIfPresent(String.self, forKey: .cover)
             self.logo = try? container.decodeIfPresent(String.self, forKey: .logo)
             self.backgroundColor = try? container.decodeIfPresent(String.self, forKey: .backgroundColor)
             self.textColor = try? container.decodeIfPresent(String.self, forKey: .textColor)
             self.vct = try? container.decodeIfPresent(String.self, forKey: .vct)

             self.fundingSource = try? container.decodeIfPresent(FundingSource.self, forKey: .fundingSource)
             self.accessToken = try? container.decodeIfPresent(String.self, forKey: .accessToken)
             self.refreshToken = try? container.decodeIfPresent(String.self, forKey: .refreshToken)
             self.notificationID = try? container.decodeIfPresent(String.self, forKey: .notificationID)
             self.notificationEndPont = try? container.decodeIfPresent(String.self, forKey: .notificationEndPont)
             self.tokenEndPoint = try? container.decodeIfPresent(String.self, forKey: .tokenEndPoint)
             self.receiptData = try? container.decodeIfPresent(ReceiptItemModel.self, forKey: .receiptData)
             self.photoIDCredential = try? container.decodeIfPresent(PhotoIDCredential.self, forKey: .photoIDCredential)
         }
}

public struct Search_CustomWalletRecordCertModel: Codable {
    var totalCount: Int?
    var records: [SearchItems_CustomWalletRecordCertModel]?
}

class SearchItems_CustomWalletRecordCertModel: Codable {
    var type: String?
    var id: String?
    var value: CustomWalletRecordCertModel?
    
    internal init(type: String? = nil, id: String? = nil, value: CustomWalletRecordCertModel? = nil) {
        self.type = type
        self.id = id
        self.value = value
    }
    
    init(){}
    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.type = try container.decodeIfPresent(String.self, forKey: .type)
//        self.id = try container.decodeIfPresent(String.self, forKey: .id)
//
//        if let str = try? container.decodeIfPresent(String.self, forKey: .value), let dict = UIApplicationUtils.shared.convertStringToDictionary(text: str){
//            self.value = CustomWalletRecordCertModel.decode(withDictionary: dict as NSDictionary? ?? NSDictionary()) as? CustomWalletRecordCertModel
//        }else{
//            self.value = try container.decodeIfPresent(CustomWalletRecordCertModel.self, forKey: .value)
//        }
//    }
}

