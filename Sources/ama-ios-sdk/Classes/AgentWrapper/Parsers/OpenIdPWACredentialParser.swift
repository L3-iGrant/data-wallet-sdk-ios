//
//  OpenIdPWACredentialParser.swift
//  dataWallet
//
//  Created by oem on 19/11/24.
//

import Foundation

class OpenIdPWACredentialParser {
    
    static let shared = OpenIdPWACredentialParser()
    
    func createPWACredential(_ customWalletModel: CustomWalletRecordCertModel, _ connectionModel: CloudAgentConnectionWalletModel, _ credentialModel: EBSI_V2_VerifiableID, _ credential_jwt: String, format: String, searchableText: String = "", accessToken: String, refreshToken: String, notificationEndPoint: String, notificationID: String, tokenEndPoint: String) {
        var ibanValueArray: [String] = []
        for iban in credentialModel.accounts ?? []{
            ibanValueArray.append(iban.iban ?? "")
        }
        let ibanValues = Array(Set(ibanValueArray)).filter { !$0.isEmpty }
        
        var cardValueArray: [String] = []
        for iban in credentialModel.accounts ?? []{
            cardValueArray.append(iban.card ?? "")
        }
        let cardValues = Array(Set(cardValueArray)).filter { !$0.isEmpty }
        
        var attributes: [IDCardAttributes] = []
        var sectionStruct: [DWSection] = []
        
        if let accountHolderId = credentialModel.account_holder_id {
            attributes.append(IDCardAttributes(name: "Account Holder ID", value: accountHolderId, schemeID: "personalIdentificationNumber"))
            sectionStruct.append(DWSection(title: EBSIWallet.shared.credentialDisplay?.name?.camelCaseToWords(), key: "holderDetails"))
        }
        
        if !ibanValues.isEmpty {
            for (index, ibanValue) in ibanValues.enumerated(){
                attributes.append(IDCardAttributes(type: .account, name: "", value: ibanValue, schemeID: "bankAccount\(index)"))
            }
            sectionStruct.append(DWSection(title: "pwa_bank_account".localizedForSDK().capitalized, key: "accountDetails"))
        }
        
        if !cardValues.isEmpty {
            for (index, cardValue) in cardValues.enumerated(){
                attributes.append(IDCardAttributes(type: .card, name: "", value: cardValue, schemeID: "cardDetails\(index)"))
            }
            sectionStruct.append(DWSection(title: "pwa_payment_cards".localizedForSDK(), key: "cardDetails"))
        }
        
        var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
        for attr in attributes {
            if attr.type == .string, let sectionIndex = sectionStruct.firstIndex(where: { $0.key == "holderDetails" }) {
                let sectionKey = sectionStruct[sectionIndex].key ?? ""
                let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionKey)
                attributeStructure[key] = value
            } else if attr.type == .card, let sectionIndex = sectionStruct.firstIndex(where: { $0.key == "cardDetails" }) {
                let sectionKey = sectionStruct[sectionIndex].key ?? ""
                let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionKey)
                attributeStructure[key] = value
            } else if attr.type == .account, let sectionIndex = sectionStruct.firstIndex(where: { $0.key == "accountDetails" }) {
                let sectionKey = sectionStruct[sectionIndex].key ?? ""
                let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionKey)
                attributeStructure[key] = value
            }
        }

        let credentialType = EBSIWallet.shared.fetchCredentialType(list: credentialModel.vc?.type)
        customWalletModel.attributes = attributeStructure
        customWalletModel.sectionStruct = sectionStruct
        customWalletModel.referent = nil
        customWalletModel.schemaID = nil
        customWalletModel.certInfo = nil
        customWalletModel.connectionInfo = connectionModel
        customWalletModel.type = CertType.EBSI.rawValue
        customWalletModel.subType = EBSI_CredentialType.PWA.rawValue
        customWalletModel.searchableText = credentialType?.camelCaseToWords().uppercased() ??  EBSI_CredentialSearchText.PDA1.rawValue.uppercased()
        customWalletModel.format = format
        customWalletModel.vct = credentialModel.vct
        customWalletModel.accessToken = accessToken
        customWalletModel.refreshToken = refreshToken
        customWalletModel.notificationID = notificationID
        customWalletModel.notificationEndPont = notificationEndPoint
        customWalletModel.tokenEndPoint = tokenEndPoint
        customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel.iss, credentialJWT: credential_jwt)
    }
    
    func createPWACredentialWithResponse(_ customWalletModel: CustomWalletRecordCertModel, _ connectionModel: CloudAgentConnectionWalletModel, _ credentialModel: EBSI_V2_VerifiableID, _ credential_jwt: String, searchableText: String = "", credentialDict: Any) -> CustomWalletRecordCertModel {
        var ibanValueArray: [String] = []
        for iban in credentialModel.accounts ?? []{
            ibanValueArray.append(iban.iban ?? "")
        }
        let ibanValues = Array(Set(ibanValueArray)).filter { !$0.isEmpty }
        
        var cardValueArray: [String] = []
        for iban in credentialModel.accounts ?? []{
            cardValueArray.append(iban.card ?? "")
        }
        let cardValues = Array(Set(cardValueArray)).filter { !$0.isEmpty }
        
        var attributes: [IDCardAttributes] = []
        var sectionStruct: [DWSection] = []
        
        if let accountHolderId = credentialModel.account_holder_id {
           // attributes.append(IDCardAttributes(name: "Account Holder ID", value: accountHolderId, schemeID: "personalIdentificationNumber"))
            sectionStruct.append(DWSection(title: searchableText.camelCaseToWords(), key: "holderDetails"))
        }
        
        if !ibanValues.isEmpty {
            for (index, ibanValue) in ibanValues.enumerated(){
               // attributes.append(IDCardAttributes(type: .account, name: "", value: ibanValue, schemeID: "bankAccount\(index)"))
            }
            sectionStruct.append(DWSection(title: "pwa_bank_account".localizedForSDK().capitalized, key: "accountDetails"))
        }
        
        if !cardValues.isEmpty {
            for (index, cardValue) in cardValues.enumerated(){
               // attributes.append(IDCardAttributes(type: .card, name: "", value: cardValue, schemeID: "cardDetails\(index)"))
            }
            sectionStruct.append(DWSection(title: "pwa_payment_cards".localizedForSDK(), key: "cardDetails"))
        }
        
        var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
        for attr in attributes {
            if attr.type == .string, let sectionIndex = sectionStruct.firstIndex(where: { $0.key == "holderDetails" }) {
                let sectionKey = sectionStruct[sectionIndex].key ?? ""
                let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionKey)
                attributeStructure[key] = value
            } else if attr.type == .card, let sectionIndex = sectionStruct.firstIndex(where: { $0.key == "cardDetails" }) {
                let sectionKey = sectionStruct[sectionIndex].key ?? ""
                let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionKey)
                attributeStructure[key] = value
            } else if attr.type == .account, let sectionIndex = sectionStruct.firstIndex(where: { $0.key == "accountDetails" }) {
                let sectionKey = sectionStruct[sectionIndex].key ?? ""
                let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionKey)
                attributeStructure[key] = value
            }
        }

        let credentialType = EBSIWallet.shared.fetchCredentialType(list: credentialModel.vc?.type)
        attributes = EBSIWallet.shared.convertToOutputFormat(data : credentialDict)
        customWalletModel.attributes = attributeStructure
        customWalletModel.sectionStruct = sectionStruct
        customWalletModel.referent = nil
        customWalletModel.schemaID = nil
        customWalletModel.certInfo = nil
        customWalletModel.fundingSource = credentialModel.fundingSource
        customWalletModel.connectionInfo = connectionModel
        customWalletModel.type = CertType.EBSI.rawValue
        customWalletModel.subType = EBSI_CredentialType.PWA.rawValue
        customWalletModel.searchableText = searchableText
        customWalletModel.vct = credentialModel.vct
        customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel.iss, credentialJWT: credential_jwt)
        return customWalletModel
    }
    
}
