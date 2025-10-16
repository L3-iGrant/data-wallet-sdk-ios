//
//  SelfAttestedPhotoIDViewController.swift
//  dataWallet
//
//  Created by iGrant on 10/06/25.
//

import Foundation
import eudiWalletOidcIos
import IndyCWrapper

final class SelfAttestedPhotoIDViewModel {
    
    var photoIDCredential: PhotoIDCredential?
    weak var pageDelegate: CirtificateDelegate?
    var photoIdSections = [[IDCardAttributes]]()
    var orgInfo: OrganisationInfoModel?
    var display: Display?
    var recordId: String?
    var isFromExpired: Bool? = false
    
    func saveIDCardToWallet(model: PhotoIDCredential, completion: @escaping (Bool) -> ()) {
        self.checkDuplicate(docNumber: model.iso23220?.documentNumber ?? "") { duplicateExist in
            if(!duplicateExist){
                let customWalletModel = CustomWalletRecordCertModel.init()
                customWalletModel.referent = nil
                customWalletModel.schemaID = nil
                customWalletModel.certInfo = nil
                customWalletModel.connectionInfo = nil
                customWalletModel.type = CertType.idCards.rawValue
                //customWalletModel.subType = SelfAttestedCertTypes.PhotoIDWithAge.rawValue
                customWalletModel.searchableText = "PHOTO ID"
                customWalletModel.vct = "eu.europa.ec.eudi.photoid.1"
                customWalletModel.photoIDCredential = model
                WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .walletCert ) { [weak self] success, id, error in
                    if (!success) {
                        UIApplicationUtils.showErrorSnackbar(message: "Not able to save ID card".localized())
                    } else {
                        //self?.pageDelegate?.idCardSaved()
                        UIApplicationUtils.showSuccessSnackbar(message: "read_card_successfully_added_to_your_data_wallet".localized())
                        NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                    }
                    completion(success)
                }
            } else {
                completion(false)
                UIApplicationUtils.showErrorSnackbar(message: "Photo ID of this user already existing.".localized())
            }
        }
    }
    
    func checkDuplicate(docNumber: String, completion: @escaping((Bool) -> Void)){
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, searchType: .idCards) { (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (fetched, response, error) in
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let idCardSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                var duplicateExist = false
                for doc in idCardSearchModel?.records ?? []{
                    if (doc.value?.photoIDCredential?.iso23220?.documentNumber == docNumber){
                        duplicateExist = true
                    }
                }
                completion(duplicateExist)
            }
        }
    }
    
    func deleteIDCardFromWallet(walletRecordId: String?) {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        let type = isFromExpired ?? false ? AriesAgentFunctions.expiredCertificate : AriesAgentFunctions.walletCertificates
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: type, id: walletRecordId ?? "") { [weak self](success, error) in
            if self?.isFromExpired ?? false {
               // NotificationCenter.default.post(name: Constants.reloadExpiredList, object: nil)
            } else {
                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
            }
            self?.pageDelegate?.idCardSaved()
        }
    }
    
    func loadData(model: PhotoIDCredential) {
        photoIdSections.append(firstSection(photoIDCredential: model))
        photoIdSections.append(secondSection(photoIDCredential: model))
        photoIdSections.append(thirdSection(photoIDCredential: model))
        photoIdSections.append(fourthSection(photoIDCredential: model))
    }
    
    func createPhotoIDWithResponse(dict: [String: Any], customWalletModel: CustomWalletRecordCertModel, credential_jwt: String, credentialModel: EBSI_V2_VerifiableID, format: String, searchableText: String = "", connectionModel: CloudAgentConnectionWalletModel) -> CustomWalletRecordCertModel? {
        if let photoIDCredential = PhotoIDCredential.decode(withpDictionary: dict) {
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
            
            let credentialType = EBSIWallet.shared.fetchCredentialType(list: credentialModel.vc?.type)
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
            customWalletModel.vct = credentialModel.vct
            customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: "", credentialJWT: credential_jwt)
            return customWalletModel
        } else {
            print("error")
            return nil
        }
    }
    
    func firstSection(photoIDCredential: PhotoIDCredential) -> [IDCardAttributes] {
        let portrait = photoIDCredential.iso23220?.portrait
        let over18 = photoIDCredential.iso23220?.ageOver18 ?? false
        
        let array = [
            IDCardAttributes(name: "Portrait".localized(), value: portrait),
            IDCardAttributes(name: "Age over 18".localized(), value: String(over18))
        ]
        return array.createAndFindNumberOfLines()
    }
    
    func secondSection(photoIDCredential: PhotoIDCredential) -> [IDCardAttributes] {
        var section2Attributes: [IDCardAttributes] = []
        
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
        
        return section2Attributes.createAndFindNumberOfLines()
    }
    
    func thirdSection(photoIDCredential: PhotoIDCredential) -> [IDCardAttributes] {
        var section3Attributes: [IDCardAttributes] = []
        
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
        return section3Attributes.createAndFindNumberOfLines()
    }
    
    func fourthSection(photoIDCredential: PhotoIDCredential) -> [IDCardAttributes] {
        var section4Attributes: [IDCardAttributes] = []

        
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
        return section4Attributes.createAndFindNumberOfLines()
    }
    
}
