//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 16/09/25.
//

import Foundation
//import OrderedDictionary

class PhotoIDParser {
    
    static let shared = PhotoIDParser()
    
    func createPhotoID(dict: [String: Any], customWalletModel: CustomWalletRecordCertModel, credential_jwt: String, credentialModel: EBSI_V2_VerifiableID? = nil, format: String, searchableText: String = "", connectionModel: CloudAgentConnectionWalletModel, accessToken: String, refreshToken: String, notificationEndPoint: String, notificationID: String, tokenEndPoint: String, photoID: Photoid?, iso: Iso23220?) {
        let photoIDCredential = PhotoIDCredential(iso23220: iso, id: nil, exp: nil, photoid: photoID, vct: nil)
            var attributes: [IDCardAttributes] = []
            var sectionStruct: [DWSection] = []
            var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
            var section1Attributes: [IDCardAttributes] = []
            var section2Attributes: [IDCardAttributes] = []
            var section3Attributes: [IDCardAttributes] = []
            var section4Attributes: [IDCardAttributes] = []
            
            section1Attributes += [
                IDCardAttributes.init(name: "Portrait", value: photoIDCredential.iso23220?.portrait, schemeID: "portrait"),
                IDCardAttributes.init(name: "Age Over 18", value: String(photoIDCredential.iso23220?.ageOver18 ?? false), schemeID: "ageOver18")
                    ]
                    sectionStruct.append(DWSection(title: "", key: "section1", type: "photoIDwithImageBadge"))
                    attributes.append(contentsOf: section1Attributes)
                    for attr in section1Attributes {
                        let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section1")
                        attributeStructure[key] = value
                    }
            section2Attributes += [
                IDCardAttributes.init(name: "Person ID", value: photoIDCredential.photoid?.personID, schemeID: "personID"),
                IDCardAttributes.init(name: "Family Name", value: photoIDCredential.iso23220?.familyNameUnicode, schemeID: "familyName"),
                IDCardAttributes.init(name: "Given Name", value: photoIDCredential.iso23220?.givenNameUnicode, schemeID: "givenName"),
                IDCardAttributes.init(name: "Birth Date", value: photoIDCredential.iso23220?.birthDate, schemeID: "birthDate"),
                IDCardAttributes.init(name: "Travel Document Number", value: photoIDCredential.photoid?.travelDocumentNumber, schemeID: "travelDocumentNumber")
                    ]
            sectionStruct.append(DWSection(title: "PHOTO ID", key: "section2"))
                    attributes.append(contentsOf: section2Attributes)
                    for attr in section2Attributes {
                        let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section2")
                        attributeStructure[key] = value
                    }
            
            section3Attributes += [
                IDCardAttributes.init(name: "Birth Country", value: photoIDCredential.photoid?.birthCountry, schemeID: "birthCountry"),
                        IDCardAttributes.init(name: "Birth State", value:photoIDCredential.photoid?.birthState, schemeID: "birthState"),
                        IDCardAttributes.init(name: "Birth City", value: photoIDCredential.photoid?.birthCity, schemeID: "birthCity"),
                        IDCardAttributes.init(name: "Administrative Number", value: photoIDCredential.photoid?.administrativeNumber, schemeID: "administrativeNumber"),
                        IDCardAttributes.init(name: "Resident Street", value: photoIDCredential.photoid?.residentStreet, schemeID: "residentStreet"),
                        IDCardAttributes.init(name: "Resident House Number", value: photoIDCredential.photoid?.residentHouseNumber, schemeID: "residentHouseNumber"),
                        IDCardAttributes.init(name: "Resident State", value: photoIDCredential.photoid?.residentState, schemeID: "residentState")
                    ]
                    sectionStruct.append(DWSection(title: "", key: "section3"))
                    attributes.append(contentsOf: section3Attributes)
                    for attr in section3Attributes {
                        let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section3")
                        attributeStructure[key] = value
                    }
            
            section4Attributes += [
                        IDCardAttributes.init(name: "Issue Date", value: photoIDCredential.iso23220?.issueDate, schemeID: "issueDate"),
                        IDCardAttributes.init(name: "Expiry Date", value: photoIDCredential.iso23220?.expiryDate, schemeID: "expiryDate"),
                        IDCardAttributes.init(name: "Issuing Authority", value: photoIDCredential.iso23220?.issuingAuthorityUnicode, schemeID: "issuingAuthority"),
                        IDCardAttributes.init(name: "Issuing Country", value: photoIDCredential.iso23220?.issuingCountry, schemeID: "issuingCountry"),
                        IDCardAttributes.init(name: "Sex", value: photoIDCredential.iso23220?.sex ?? "", schemeID: "sex"),
                        IDCardAttributes.init(name: "Nationality", value: photoIDCredential.iso23220?.nationality, schemeID: "nationality"),
                        IDCardAttributes.init(name: "Document Number", value: photoIDCredential.iso23220?.documentNumber, schemeID: "documentNumber"),
                        IDCardAttributes.init(name: "Name at Birth", value: photoIDCredential.iso23220?.nameAtBirth, schemeID: "nameAtBirth"),
                        IDCardAttributes.init(name: "Birthplace", value: photoIDCredential.iso23220?.birthplace, schemeID: "birthplace"),
                        IDCardAttributes.init(name: "Resident Address", value: photoIDCredential.iso23220?.residentAddressUnicode, schemeID: "residentAddress"),
                        IDCardAttributes.init(name: "Resident City", value: photoIDCredential.iso23220?.residentCityUnicode, schemeID: "residentCity"),
                        IDCardAttributes.init(name: "Resident Postal Code", value: photoIDCredential.iso23220?.residentPostalCode, schemeID: "residentPostalCode"),
                        IDCardAttributes.init(name: "Resident Country", value: photoIDCredential.iso23220?.residentCountry, schemeID: "residentCountry"),
                        IDCardAttributes.init(name: "Age in Years", value: String(photoIDCredential.iso23220?.ageInYears ?? 0), schemeID: "ageInYears"),
                        IDCardAttributes.init(name: "Birth Year", value: String(photoIDCredential.iso23220?.ageBirthYear ?? 0), schemeID: "birthYear"),
                        IDCardAttributes.init(name: "Family Name Latin1", value: photoIDCredential.iso23220?.familyNameLatin1, schemeID: "familyNameLatin1"),
                        IDCardAttributes.init(name: "Given Name Latin1", value: photoIDCredential.iso23220?.givenNameLatin1, schemeID: "givenNameLatin1")
                    ]
                    sectionStruct.append(DWSection(title: "", key: "section4"))
                    attributes.append(contentsOf: section4Attributes)
                    for attr in section4Attributes {
                        let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section4")
                        attributeStructure[key] = value
                    }
            
            let credentialType = EBSIWallet.shared.fetchCredentialType(list: credentialModel?.vc?.type)
            customWalletModel.attributes = attributeStructure
            customWalletModel.sectionStruct = sectionStruct
            customWalletModel.referent = nil
            customWalletModel.schemaID = nil
            customWalletModel.certInfo = nil
            customWalletModel.connectionInfo = connectionModel
            customWalletModel.type = CertType.EBSI.rawValue
            customWalletModel.subType = EBSI_CredentialType.PhotoIDWithAge.rawValue
            customWalletModel.searchableText = credentialType?.camelCaseToWords().uppercased() ??  EBSI_CredentialSearchText.PDA1.rawValue.uppercased()
            customWalletModel.format = format
            customWalletModel.vct = credentialModel?.vct
            customWalletModel.accessToken = accessToken
            customWalletModel.refreshToken = refreshToken
            customWalletModel.notificationID = notificationID
            customWalletModel.notificationEndPont = notificationEndPoint
            customWalletModel.tokenEndPoint = tokenEndPoint
            customWalletModel.photoIDCredential = photoIDCredential
            customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: "", credentialJWT: credential_jwt)

    }
    
    func createPhotoIDWithResponse(dict: [String: Any], customWalletModel: CustomWalletRecordCertModel, credential_jwt: String, credentialModel: EBSI_V2_VerifiableID? = nil, format: String, searchableText: String = "", connectionModel: CloudAgentConnectionWalletModel, photoID: Photoid?, iso: Iso23220?) -> CustomWalletRecordCertModel? {
        let photoIDCredential = PhotoIDCredential(iso23220: iso, id: nil, exp: nil, photoid: photoID, vct: nil)
            var attributes: [IDCardAttributes] = []
            var sectionStruct: [DWSection] = []
            var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
            var section1Attributes: [IDCardAttributes] = []
            var section2Attributes: [IDCardAttributes] = []
            var section3Attributes: [IDCardAttributes] = []
            var section4Attributes: [IDCardAttributes] = []
            
            if let portrait = photoIDCredential.iso23220?.portrait {
                section1Attributes.append(IDCardAttributes(name: "Portrait", value: portrait, schemeID: "portrait"))
            }
            if let ageOver18 = photoIDCredential.iso23220?.ageOver18 {
                section1Attributes.append(IDCardAttributes(name: "Age Over 18", value: String(ageOver18), schemeID: "ageOver18"))
            }
            if !section1Attributes.isEmpty {
                sectionStruct.append(DWSection(title: "", key: "section1", type: "photoIDwithImageBadge"))
                attributes.append(contentsOf: section1Attributes)
                for attr in section1Attributes {
                    let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section1")
                    attributeStructure[key] = value
                }
            }
            
            // Section 2
            if let personID = photoIDCredential.photoid?.personID {
                section2Attributes.append(IDCardAttributes(name: "Person ID", value: personID, schemeID: "personID"))
            }
            if let familyName = photoIDCredential.iso23220?.familyNameUnicode {
                section2Attributes.append(IDCardAttributes(name: "Family Name", value: familyName, schemeID: "familyName"))
            }
            if let givenName = photoIDCredential.iso23220?.givenNameUnicode {
                section2Attributes.append(IDCardAttributes(name: "Given Name", value: givenName, schemeID: "givenName"))
            }
            if let birthDate = photoIDCredential.iso23220?.birthDate {
                section2Attributes.append(IDCardAttributes(name: "Birth Date", value: birthDate, schemeID: "birthDate"))
            }
            if let travelDocumentNumber = photoIDCredential.photoid?.travelDocumentNumber {
                section2Attributes.append(IDCardAttributes(name: "Travel Document Number", value: travelDocumentNumber, schemeID: "travelDocumentNumber"))
            }
            if !section2Attributes.isEmpty {
                sectionStruct.append(DWSection(title: "PHOTO ID", key: "section2"))
                attributes.append(contentsOf: section2Attributes)
                for attr in section2Attributes {
                    let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section2")
                    attributeStructure[key] = value
                }
            }
            
            // Section 3
            if let birthCountry = photoIDCredential.photoid?.birthCountry {
                section3Attributes.append(IDCardAttributes(name: "Birth Country", value: birthCountry, schemeID: "birthCountry"))
            }
            if let birthState = photoIDCredential.photoid?.birthState {
                section3Attributes.append(IDCardAttributes(name: "Birth State", value: birthState, schemeID: "birthState"))
            }
            if let birthCity = photoIDCredential.photoid?.birthCity {
                section3Attributes.append(IDCardAttributes(name: "Birth City", value: birthCity, schemeID: "birthCity"))
            }
            if let administrativeNumber = photoIDCredential.photoid?.administrativeNumber {
                section3Attributes.append(IDCardAttributes(name: "Administrative Number", value: administrativeNumber, schemeID: "administrativeNumber"))
            }
            if let residentStreet = photoIDCredential.photoid?.residentStreet {
                section3Attributes.append(IDCardAttributes(name: "Resident Street", value: residentStreet, schemeID: "residentStreet"))
            }
            if let residentHouseNumber = photoIDCredential.photoid?.residentHouseNumber {
                section3Attributes.append(IDCardAttributes(name: "Resident House Number", value: residentHouseNumber, schemeID: "residentHouseNumber"))
            }
            if let residentState = photoIDCredential.photoid?.residentState {
                section3Attributes.append(IDCardAttributes(name: "Resident State", value: residentState, schemeID: "residentState"))
            }
            if !section3Attributes.isEmpty {
                sectionStruct.append(DWSection(title: "", key: "section3"))
                attributes.append(contentsOf: section3Attributes)
                for attr in section3Attributes {
                    let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section3")
                    attributeStructure[key] = value
                }
            }
            
            // Section 4
            if let issueDate = photoIDCredential.iso23220?.issueDate {
                section4Attributes.append(IDCardAttributes(name: "Issue Date", value: issueDate, schemeID: "issueDate"))
            }
            if let expiryDate = photoIDCredential.iso23220?.expiryDate {
                section4Attributes.append(IDCardAttributes(name: "Expiry Date", value: expiryDate, schemeID: "expiryDate"))
            }
            if let issuingAuthority = photoIDCredential.iso23220?.issuingAuthorityUnicode {
                section4Attributes.append(IDCardAttributes(name: "Issuing Authority", value: issuingAuthority, schemeID: "issuingAuthority"))
            }
            if let issuingCountry = photoIDCredential.iso23220?.issuingCountry {
                section4Attributes.append(IDCardAttributes(name: "Issuing Country", value: issuingCountry, schemeID: "issuingCountry"))
            }
            if let sex = photoIDCredential.iso23220?.sex {
                section4Attributes.append(IDCardAttributes(name: "Sex", value: String(sex), schemeID: "sex"))
            }
            if let nationality = photoIDCredential.iso23220?.nationality {
                section4Attributes.append(IDCardAttributes(name: "Nationality", value: nationality, schemeID: "nationality"))
            }
            if let documentNumber = photoIDCredential.iso23220?.documentNumber {
                section4Attributes.append(IDCardAttributes(name: "Document Number", value: documentNumber, schemeID: "documentNumber"))
            }
            if let nameAtBirth = photoIDCredential.iso23220?.nameAtBirth {
                section4Attributes.append(IDCardAttributes(name: "Name at Birth", value: nameAtBirth, schemeID: "nameAtBirth"))
            }
            if let birthplace = photoIDCredential.iso23220?.birthplace {
                section4Attributes.append(IDCardAttributes(name: "Birthplace", value: birthplace, schemeID: "birthplace"))
            }
            if let residentAddress = photoIDCredential.iso23220?.residentAddressUnicode {
                section4Attributes.append(IDCardAttributes(name: "Resident Address", value: residentAddress, schemeID: "residentAddress"))
            }
            if let residentCity = photoIDCredential.iso23220?.residentCityUnicode {
                section4Attributes.append(IDCardAttributes(name: "Resident City", value: residentCity, schemeID: "residentCity"))
            }
            if let residentPostalCode = photoIDCredential.iso23220?.residentPostalCode {
                section4Attributes.append(IDCardAttributes(name: "Resident Postal Code", value: residentPostalCode, schemeID: "residentPostalCode"))
            }
            if let residentCountry = photoIDCredential.iso23220?.residentCountry {
                section4Attributes.append(IDCardAttributes(name: "Resident Country", value: residentCountry, schemeID: "residentCountry"))
            }
            if let ageInYears = photoIDCredential.iso23220?.ageInYears {
                section4Attributes.append(IDCardAttributes(name: "Age in Years", value: String(ageInYears), schemeID: "ageInYears"))
            }
            if let birthYear = photoIDCredential.iso23220?.ageBirthYear {
                section4Attributes.append(IDCardAttributes(name: "Birth Year", value: String(birthYear), schemeID: "birthYear"))
            }
            if let familyNameLatin1 = photoIDCredential.iso23220?.familyNameLatin1 {
                section4Attributes.append(IDCardAttributes(name: "Family Name Latin1", value: familyNameLatin1, schemeID: "familyNameLatin1"))
            }
            if let givenNameLatin1 = photoIDCredential.iso23220?.givenNameLatin1 {
                section4Attributes.append(IDCardAttributes(name: "Given Name Latin1", value: givenNameLatin1, schemeID: "givenNameLatin1"))
            }
            if !section4Attributes.isEmpty {
                sectionStruct.append(DWSection(title: "", key: "section4"))
                attributes.append(contentsOf: section4Attributes)
                for attr in section4Attributes {
                    let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section4")
                    attributeStructure[key] = value
                }
            }
            
            let credentialType = EBSIWallet.shared.fetchCredentialType(list: credentialModel?.vc?.type)
            customWalletModel.attributes = attributeStructure
            customWalletModel.sectionStruct = sectionStruct
            customWalletModel.referent = nil
            customWalletModel.schemaID = nil
            customWalletModel.certInfo = nil
            customWalletModel.connectionInfo = connectionModel
            customWalletModel.type = CertType.EBSI.rawValue
            customWalletModel.subType = EBSI_CredentialType.PhotoIDWithAge.rawValue
            customWalletModel.searchableText = "PHOTO ID"
            customWalletModel.format = format
            customWalletModel.vct = credentialModel?.vct
            customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: "", credentialJWT: credential_jwt)
            return customWalletModel
    }
    
    func createPhotoIDWithResponse(photoIDCredential: PhotoIDCredential?, credentialJwt: String?, connectionModel: CloudAgentConnectionWalletModel) -> CustomWalletRecordCertModel? {
        var customWalletModel = CustomWalletRecordCertModel.init()
        if let photoIDCredential = photoIDCredential {
            var attributes: [IDCardAttributes] = []
            var sectionStruct: [DWSection] = []
            var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
            var section1Attributes: [IDCardAttributes] = []
            var section2Attributes: [IDCardAttributes] = []
            var section3Attributes: [IDCardAttributes] = []
            var section4Attributes: [IDCardAttributes] = []
            
            if let portrait = photoIDCredential.iso23220?.portrait {
                section1Attributes.append(IDCardAttributes(name: "Portrait", value: portrait, schemeID: "portrait"))
            }
            if let ageOver18 = photoIDCredential.iso23220?.ageOver18 {
                section1Attributes.append(IDCardAttributes(name: "Age Over 18", value: String(ageOver18), schemeID: "ageOver18"))
            }
            if !section1Attributes.isEmpty {
                sectionStruct.append(DWSection(title: "", key: "section1", type: "photoIDwithImageBadge"))
                attributes.append(contentsOf: section1Attributes)
                for attr in section1Attributes {
                    let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section1")
                    attributeStructure[key] = value
                }
            }
            
            // Section 2
            if let personID = photoIDCredential.photoid?.personID {
                section2Attributes.append(IDCardAttributes(name: "Person ID", value: personID, schemeID: "personID"))
            }
            if let familyName = photoIDCredential.iso23220?.familyNameUnicode {
                section2Attributes.append(IDCardAttributes(name: "Family Name", value: familyName, schemeID: "familyName"))
            }
            if let givenName = photoIDCredential.iso23220?.givenNameUnicode {
                section2Attributes.append(IDCardAttributes(name: "Given Name", value: givenName, schemeID: "givenName"))
            }
            if let birthDate = photoIDCredential.iso23220?.birthDate {
                section2Attributes.append(IDCardAttributes(name: "Birth Date", value: birthDate, schemeID: "birthDate"))
            }
            if let travelDocumentNumber = photoIDCredential.photoid?.travelDocumentNumber {
                section2Attributes.append(IDCardAttributes(name: "Travel Document Number", value: travelDocumentNumber, schemeID: "travelDocumentNumber"))
            }
            if !section2Attributes.isEmpty {
                sectionStruct.append(DWSection(title: "PHOTO ID", key: "section2"))
                attributes.append(contentsOf: section2Attributes)
                for attr in section2Attributes {
                    let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section2")
                    attributeStructure[key] = value
                }
            }
            
            // Section 3
            if let birthCountry = photoIDCredential.photoid?.birthCountry {
                section3Attributes.append(IDCardAttributes(name: "Birth Country", value: birthCountry, schemeID: "birthCountry"))
            }
            if let birthState = photoIDCredential.photoid?.birthState {
                section3Attributes.append(IDCardAttributes(name: "Birth State", value: birthState, schemeID: "birthState"))
            }
            if let birthCity = photoIDCredential.photoid?.birthCity {
                section3Attributes.append(IDCardAttributes(name: "Birth City", value: birthCity, schemeID: "birthCity"))
            }
            if let administrativeNumber = photoIDCredential.photoid?.administrativeNumber {
                section3Attributes.append(IDCardAttributes(name: "Administrative Number", value: administrativeNumber, schemeID: "administrativeNumber"))
            }
            if let residentStreet = photoIDCredential.photoid?.residentStreet {
                section3Attributes.append(IDCardAttributes(name: "Resident Street", value: residentStreet, schemeID: "residentStreet"))
            }
            if let residentHouseNumber = photoIDCredential.photoid?.residentHouseNumber {
                section3Attributes.append(IDCardAttributes(name: "Resident House Number", value: residentHouseNumber, schemeID: "residentHouseNumber"))
            }
            if let residentState = photoIDCredential.photoid?.residentState {
                section3Attributes.append(IDCardAttributes(name: "Resident State", value: residentState, schemeID: "residentState"))
            }
            if !section3Attributes.isEmpty {
                sectionStruct.append(DWSection(title: "", key: "section3"))
                attributes.append(contentsOf: section3Attributes)
                for attr in section3Attributes {
                    let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section3")
                    attributeStructure[key] = value
                }
            }
            
            // Section 4
            if let issueDate = photoIDCredential.iso23220?.issueDate {
                section4Attributes.append(IDCardAttributes(name: "Issue Date", value: issueDate, schemeID: "issueDate"))
            }
            if let expiryDate = photoIDCredential.iso23220?.expiryDate {
                section4Attributes.append(IDCardAttributes(name: "Expiry Date", value: expiryDate, schemeID: "expiryDate"))
            }
            if let issuingAuthority = photoIDCredential.iso23220?.issuingAuthorityUnicode {
                section4Attributes.append(IDCardAttributes(name: "Issuing Authority", value: issuingAuthority, schemeID: "issuingAuthority"))
            }
            if let issuingCountry = photoIDCredential.iso23220?.issuingCountry {
                section4Attributes.append(IDCardAttributes(name: "Issuing Country", value: issuingCountry, schemeID: "issuingCountry"))
            }
            if let sex = photoIDCredential.iso23220?.sex {
                section4Attributes.append(IDCardAttributes(name: "Sex", value: String(sex), schemeID: "sex"))
            }
            if let nationality = photoIDCredential.iso23220?.nationality {
                section4Attributes.append(IDCardAttributes(name: "Nationality", value: nationality, schemeID: "nationality"))
            }
            if let documentNumber = photoIDCredential.iso23220?.documentNumber {
                section4Attributes.append(IDCardAttributes(name: "Document Number", value: documentNumber, schemeID: "documentNumber"))
            }
            if let nameAtBirth = photoIDCredential.iso23220?.nameAtBirth {
                section4Attributes.append(IDCardAttributes(name: "Name at Birth", value: nameAtBirth, schemeID: "nameAtBirth"))
            }
            if let birthplace = photoIDCredential.iso23220?.birthplace {
                section4Attributes.append(IDCardAttributes(name: "Birthplace", value: birthplace, schemeID: "birthplace"))
            }
            if let residentAddress = photoIDCredential.iso23220?.residentAddressUnicode {
                section4Attributes.append(IDCardAttributes(name: "Resident Address", value: residentAddress, schemeID: "residentAddress"))
            }
            if let residentCity = photoIDCredential.iso23220?.residentCityUnicode {
                section4Attributes.append(IDCardAttributes(name: "Resident City", value: residentCity, schemeID: "residentCity"))
            }
            if let residentPostalCode = photoIDCredential.iso23220?.residentPostalCode {
                section4Attributes.append(IDCardAttributes(name: "Resident Postal Code", value: residentPostalCode, schemeID: "residentPostalCode"))
            }
            if let residentCountry = photoIDCredential.iso23220?.residentCountry {
                section4Attributes.append(IDCardAttributes(name: "Resident Country", value: residentCountry, schemeID: "residentCountry"))
            }
            if let ageInYears = photoIDCredential.iso23220?.ageInYears {
                section4Attributes.append(IDCardAttributes(name: "Age in Years", value: String(ageInYears), schemeID: "ageInYears"))
            }
            if let birthYear = photoIDCredential.iso23220?.ageBirthYear {
                section4Attributes.append(IDCardAttributes(name: "Birth Year", value: String(birthYear), schemeID: "birthYear"))
            }
            if let familyNameLatin1 = photoIDCredential.iso23220?.familyNameLatin1 {
                section4Attributes.append(IDCardAttributes(name: "Family Name Latin1", value: familyNameLatin1, schemeID: "familyNameLatin1"))
            }
            if let givenNameLatin1 = photoIDCredential.iso23220?.givenNameLatin1 {
                section4Attributes.append(IDCardAttributes(name: "Given Name Latin1", value: givenNameLatin1, schemeID: "givenNameLatin1"))
            }
            if !section4Attributes.isEmpty {
                sectionStruct.append(DWSection(title: "", key: "section4"))
                attributes.append(contentsOf: section4Attributes)
                for attr in section4Attributes {
                    let (key, value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section4")
                    attributeStructure[key] = value
                }
            }
            
            //let credentialType = EBSIWallet.shared.fetchCredentialType(list: credentialModel.vc?.type)
            customWalletModel.attributes = attributeStructure
            customWalletModel.sectionStruct = sectionStruct
            customWalletModel.referent = nil
            customWalletModel.schemaID = nil
            customWalletModel.certInfo = nil
            customWalletModel.connectionInfo = connectionModel
            customWalletModel.type = CertType.EBSI.rawValue
            customWalletModel.subType = EBSI_CredentialType.PhotoIDWithAge.rawValue
            customWalletModel.searchableText = "PHOTO ID"
            //customWalletModel.format = format
            customWalletModel.vct = "eu.europa.ec.eudi.photoid.1"
            customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: "", credentialJWT: credentialJwt)
            return customWalletModel
        } else {
            print("error")
            return nil
        }
    }

}
