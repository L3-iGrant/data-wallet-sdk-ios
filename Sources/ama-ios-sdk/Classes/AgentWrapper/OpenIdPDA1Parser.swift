//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 28/08/25.
//

import Foundation
//import OrderedDictionary

class OpenIdPDA1Parser {
    
    static let shared = OpenIdPDA1Parser()
    
    func createPDA(_ section1: Section1?, _ section2: Section2?, _ section3: Section3?, _ section4: Section4?, _ section5: Section5?, _ section6: Section6?, _ customWalletModel: CustomWalletRecordCertModel, _ connectionModel: CloudAgentConnectionWalletModel, credentialModel: EBSI_V2_VerifiableID? = nil, _ credential_jwt: String, format: String, searchableText: String = "", accessToken: String = "", refreshToken: String = "", notificationEndPoint: String = "", notificationID: String = "", tokenEndPoint: String = "") {
        let nationalitiesString = section1?.nationalities?.joined(separator: ", ") ?? ""
        var addressArray: [String] = []
        for item in section5?.workPlaceAddresses ?? [] {
            if let stringData = item.address?.addressToString() {
                addressArray.append(stringData)
            }
        }
        let formattedAddresses = addressArray.joined(separator: "\n")
        var workPlaceNames: [String] = []
        for name in section5?.workPlaceNames ?? [] {
            if let nameString = name.companyNameVesselName {
                workPlaceNames.append(nameString)
            }
        }
        var attributes: [IDCardAttributes] = []
        var sectionStruct: [DWSection] = []
        var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
        if let section1 = section1 {
            var section1Attributes: [IDCardAttributes] = []
                let nationalitiesString = section1.nationalities?.joined(separator: ", ") ?? ""
            section1Attributes += [
                    IDCardAttributes.init(name: "Personal Identification Number", value: section1.personalIdentificationNumber, schemeID: "personalIdentificationNumber"),
                    IDCardAttributes.init(name: "Sex", value: section1.sex, schemeID: "sex"),
                    IDCardAttributes.init(name: "Surname", value: section1.surname, schemeID: "surname"),
                    IDCardAttributes.init(name: "Forenames", value: section1.forenames, schemeID: "forenames"),
                    IDCardAttributes.init(name: "DateBirth", value: section1.dateBirth, schemeID: "dateBirth"),
                    IDCardAttributes.init(name: "Nationalities", value: nationalitiesString, schemeID: "nationalities"),
                    IDCardAttributes.init(name: "State Of Residence Address", value: section1.stateOfResidenceAddress?.addressToString(), schemeID: "stateOfResidenceAddress"),
                    IDCardAttributes.init(name: "State Of Stay Address", value: section1.stateOfStayAddress?
                        .addressToString(), schemeID: "stateOfStayAddress"),
                    IDCardAttributes.init(name: "Place Of Birth", value: section1.placeBirth?
                        .addressToString(), schemeID: "placeBirth"),
                    IDCardAttributes.init(name: "Surname At Birth", value: section1.surnameAtBirth, schemeID: "surnameAtBirth")
                ]
            attributes.append(contentsOf: section1Attributes)
                sectionStruct.append(DWSection(title: "Personal Details", key: "section1"))
            for attr in section1Attributes {
                let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section1")
                attributeStructure[key] = value
            }
            }

            if let section2 = section2 {
                var section2Attributes: [IDCardAttributes] = []
                section2Attributes += [
                    IDCardAttributes.init(name: "Member State Which Legislation Applies", value: section2.memberStateWhichLegislationApplies, schemeID: "memberStateWhichLegislationApplies"),
                    IDCardAttributes.init(name: "Starting Date", value: section2.startingDate, schemeID: "startingDate"),
                    IDCardAttributes.init(name: "Ending Date", value: section2.endingDate, schemeID: "endingDate"),
                    IDCardAttributes.init(name: "Certificate For Duration Activity", value: section2.certificateForDurationActivity?.toString(), schemeID: "certificateForDurationActivity"),
                    IDCardAttributes.init(name: "Determination Provisional", value: section2.determinationProvisional?.toString(), schemeID: "determinationProvisional"),
                    IDCardAttributes.init(name: "Transition Rules Apply As EC8832004", value: section2.transitionRulesApplyAsEC8832004?.toString(), schemeID: "transitionRulesApplyAsEC8832004")
                ]
                sectionStruct.append(DWSection(title: "Member State Legislation", key: "section2"))
                attributes.append(contentsOf: section2Attributes)
                for attr in section2Attributes {
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section2")
                    attributeStructure[key] = value
                }
            }

            // Section 3
            if let section3 = section3 {
                var section3Attributes: [IDCardAttributes] = []
                section3Attributes += [
                    IDCardAttributes.init(name: "Posted Employed Person", value: section3.postedEmployedPerson?.toString(), schemeID: "postedEmployedPerson"),
                    IDCardAttributes.init(name: "Employed Two Or More States", value: section3.employedTwoOrMoreStates?.toString(), schemeID: "employedTwoOrMoreStates"),
                    IDCardAttributes.init(name: "Posted Self Employed Person", value: section3.postedSelfEmployedPerson?.toString(), schemeID: "postedSelfEmployedPerson"),
                    IDCardAttributes.init(name: "Self Employed Two Or More States", value: section3.selfEmployedTwoOrMoreStates?.toString(), schemeID: "selfEmployedTwoOrMoreStates"),
                    IDCardAttributes.init(name: "Civil Servant", value: section3.civilServant?.toString(), schemeID: "civilServant"),
                    IDCardAttributes.init(name: "Contract Staff", value: section3.contractStaff?.toString(), schemeID: "contractStaff"),
                    IDCardAttributes.init(name: "Mariner", value: section3.mariner?.toString(), schemeID: "mariner"),
                    IDCardAttributes.init(name: "Employed And Self Employed", value: section3.employedAndSelfEmployed?.toString(), schemeID: "employedAndSelfEmployed"),
                    IDCardAttributes.init(name: "Civil And Employed Self Employed", value: section3.civilAndEmployedSelfEmployed?.toString(), schemeID: "civilAndEmployedSelfEmployed"),
                    IDCardAttributes.init(name: "Flight Crew Member", value: section3.flightCrewMember?.toString(), schemeID: "flightCrewMember"),
                    IDCardAttributes.init(name: "Exception", value: section3.exception?.toString(), schemeID: "exception"),
                    IDCardAttributes.init(name: "Exception Description", value: section3.exceptionDescription, schemeID: "exceptionDescription"),
                    IDCardAttributes.init(name: "Working In State Under 21", value: section3.workingInStateUnder21?.toString(), schemeID: "workingInStateUnder21")
                ]
                sectionStruct.append(DWSection(title: "Status Confirmation", key: "section3"))
                attributes.append(contentsOf: section3Attributes)
                for attr in section3Attributes {
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section3")
                    attributeStructure[key] = value
                }
            }

            // Section 4
            if let section4 = section4 {
                var section4Attributes: [IDCardAttributes] = []
                section4Attributes += [
                    IDCardAttributes.init(name: "Employee", value: section4.employee?.toString(), schemeID: "employee"),
                    IDCardAttributes.init(name: "Self Employed Activity", value: section4.selfEmployedActivity?.toString(), schemeID: "selfEmployedActivity"),
                    IDCardAttributes.init(name: "Name Business Name", value: section4.nameBusinessName, schemeID: "nameBusinessName"),
                    IDCardAttributes.init(name: "Registered Address", value: section4.registeredAddress?.addressToString(), schemeID: "registeredAddress"),
                    IDCardAttributes.init(name: "Employer Self Employed ActivityCodes", value: section4.employerSelfEmployedActivityCodes?.joined(separator: ", "), schemeID: "employerSelfEmployedActivityCodes")
                ]
                sectionStruct.append(DWSection(title: "Employment Details", key: "section4"))
                attributes.append(contentsOf: section4Attributes)
                for attr in section4Attributes {
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section4")
                    attributeStructure[key] = value
                }
            }

            // Section 5
            if let section5 = section5 {
                var section5Attributes: [IDCardAttributes] = []
                section5Attributes += [
                    IDCardAttributes.init(name: "No Fixed Address", value: section5.noFixedAddress?.toString(), schemeID: "noFixedAddress"),
                    IDCardAttributes.init(name: "Work Place Addresses", value: formattedAddresses, schemeID: "workPlaceAddresses"),
                    IDCardAttributes.init(name: "Work Place Names", value: workPlaceNames.joined(separator: "\n"), schemeID: "workPlaceNames")
                ]
                sectionStruct.append(DWSection(title: "Activity Employment Details", key: "section5"))
                attributes.append(contentsOf: section5Attributes)
                for attr in section5Attributes {
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section5")
                    attributeStructure[key] = value
                }
            }

            // Section 6
            if let section6 = section6 {
                var section6Attributes: [IDCardAttributes] = []
                section6Attributes += [
                    IDCardAttributes.init(name: "Name", value: section6.name, schemeID: "name"),
                    IDCardAttributes.init(name: "Address", value: section6.address?.addressToString(), schemeID: "address"),
                    IDCardAttributes.init(name: "Institution ID", value: section6.institutionID, schemeID: "institutionID"),
                    IDCardAttributes.init(name: "Office Fax No", value: section6.officeFaxNo, schemeID: "officeFaxNo"),
                    IDCardAttributes.init(name: "Office Phone No", value: section6.officePhoneNo, schemeID: "officePhoneNo"),
                    IDCardAttributes.init(name: "Email", value: section6.email, schemeID: "email"),
                    IDCardAttributes.init(name: "Date", value: section6.date, schemeID: "date"),
                    IDCardAttributes.init(name: "Signature", value: section6.signature, schemeID: "signature")
                ]
                sectionStruct.append(DWSection(title: "Completing Institution", key: "section6"))
                attributes.append(contentsOf: section6Attributes)
                for attr in section6Attributes {
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: "section6")
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
        customWalletModel.subType = EBSI_CredentialType.PDA1.rawValue
        customWalletModel.searchableText = credentialType?.camelCaseToWords().uppercased() ??  EBSI_CredentialSearchText.PDA1.rawValue.uppercased()
        customWalletModel.format = format
        customWalletModel.vct = credentialModel?.vct
        customWalletModel.accessToken = accessToken
        customWalletModel.refreshToken = refreshToken
        customWalletModel.notificationID = notificationID
        customWalletModel.notificationEndPont = notificationEndPoint
        customWalletModel.tokenEndPoint = tokenEndPoint
        customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel?.iss, credentialJWT: credential_jwt)
    }
    
    func createPDAWithResponse(_ section1: Section1?, _ section2: Section2?, _ section3: Section3?, _ section4: Section4?, _ section5: Section5?, _ section6: Section6?, _ customWalletModel: CustomWalletRecordCertModel, _ connectionModel: CloudAgentConnectionWalletModel, credentialModel: EBSI_V2_VerifiableID? = nil, _ credential_jwt: String, searchableText: String = "") -> CustomWalletRecordCertModel{
        
        var walletModel = customWalletModel
        let nationalitiesString = section1?.nationalities?.joined(separator: ", ") ?? ""
        var addressArray: [String] = []
        for item in section5?.workPlaceAddresses ?? [] {
            if let stringData = item.address?.addressToString() {
                addressArray.append(stringData)
            }
        }
        var workPlaceNames: [String] = []
        for name in section5?.workPlaceNames ?? [] {
            if let nameString = name.companyNameVesselName {
                workPlaceNames.append(nameString)
            }
        }
        let formattedAddresses = addressArray.joined(separator: "\n")
        var section1Count = 0
        var section2Count = 0
        var section3Count = 0
        var section4Count = 0
        var section5Count = 0
        var section6Count = 0
        
        var attributes = [IDCardAttributes]()
        if ((section1?.personalIdentificationNumber) != nil) {
            attributes.append(IDCardAttributes.init(name: "Personal Identification Number", value: section1?.personalIdentificationNumber, schemeID: "personalIdentificationNumber"))
            section1Count+=1
        }
        if ((section1?.sex) != nil) {
            attributes.append(IDCardAttributes.init(name: "Sex", value: section1?.sex, schemeID: "sex"))
            section1Count+=1
        }
        if ((section1?.surname) != nil) {
            attributes.append(IDCardAttributes.init(name: "Surname", value: section1?.surname, schemeID: "surname"))
            section1Count+=1
        }
        if ((section1?.forenames) != nil) {
            attributes.append(IDCardAttributes.init(name: "Forenames", value: section1?.forenames, schemeID: "forenames"))
            section1Count+=1
        }
        if ((section1?.dateBirth) != nil) {
            attributes.append(IDCardAttributes.init(name: "DateBirth", value: section1?.dateBirth, schemeID: "dateBirth"))
            section1Count+=1
        }
        if ((section1?.nationalities) != nil) {
            attributes.append(IDCardAttributes.init(name: "Nationalities", value: nationalitiesString, schemeID: "nationalities"))
            section1Count+=1
        }
        if ((section1?.stateOfResidenceAddress) != nil) {
            attributes.append(IDCardAttributes.init(name: "State Of Residence Address", value: section1?.stateOfResidenceAddress?.addressToString(), schemeID: "stateOfResidenceAddress"))
            section1Count+=1
        }
        if ((section1?.stateOfStayAddress) != nil) {
            attributes.append(IDCardAttributes.init(name: "State Of Stay Address", value: section1?.stateOfStayAddress?
                .addressToString(), schemeID: "stateOfStayAddress"))
            section1Count+=1
        }
        
        if ((section1?.placeBirth) != nil) {
            attributes.append(IDCardAttributes.init(name: "Place Of Birth", value: section1?.placeBirth?
                .addressToString(), schemeID: "placeBirth"))
            section1Count+=1
        }
        
        if ((section1?.surnameAtBirth) != nil) {
            attributes.append(IDCardAttributes.init(name: "Surname At Birth", value: section1?.surnameAtBirth
                , schemeID: "surnameAtBirth"))
            section1Count+=1
        }
        
        if ((section2?.memberStateWhichLegislationApplies) != nil) {
            attributes.append(IDCardAttributes.init(name: "Member State Which Legislation Applies", value: section2?.memberStateWhichLegislationApplies, schemeID: "memberStateWhichLegislationApplies"))
            section2Count+=1
        }
        if ((section2?.startingDate) != nil) {
            attributes.append(IDCardAttributes.init(name: "Starting Date", value: section2?.startingDate, schemeID: "startingDate"))
            section2Count+=1
        }
        if ((section2?.endingDate) != nil) {
            attributes.append(IDCardAttributes.init(name: "Ending Date", value: section2?.endingDate, schemeID: "endingDate"))
            section2Count+=1
        }
        if ((section2?.certificateForDurationActivity) != nil) {
            attributes.append(IDCardAttributes.init(name: "Certificate For Duration Activity", value: section2?.certificateForDurationActivity?.toString(), schemeID: "certificateForDurationActivity"))
            section2Count+=1
        }
        if ((section2?.determinationProvisional) != nil) {
            attributes.append(IDCardAttributes.init(name: "Determination Provisional", value: section2?.determinationProvisional?.toString(), schemeID: "determinationProvisional"))
            section2Count+=1
        }
        if ((section2?.transitionRulesApplyAsEC8832004) != nil) {
            attributes.append(IDCardAttributes.init(name: "Transition Rules Apply As EC8832004", value: section2?.transitionRulesApplyAsEC8832004?.toString(), schemeID: "transitionRulesApplyAsEC8832004"))
            section2Count+=1
        }
        
        if ((section3?.postedEmployedPerson) != nil) {
            attributes.append(IDCardAttributes.init(name: "Posted Employed Person", value: section3?.postedEmployedPerson?.toString(), schemeID: "postedEmployedPerson"))
            section3Count+=1
        }
        if ((section3?.employedTwoOrMoreStates) != nil) {
            attributes.append(IDCardAttributes.init(name: "Employed Two Or More States", value: section3?.employedTwoOrMoreStates?.toString(), schemeID: "employedTwoOrMoreStates"))
            section3Count+=1
        }
        if ((section3?.postedSelfEmployedPerson) != nil) {
            attributes.append(IDCardAttributes.init(name: "Posted Self Employed Person", value: section3?.postedSelfEmployedPerson?.toString(), schemeID: "postedSelfEmployedPerson"))
            section3Count+=1
        }
        if ((section3?.selfEmployedTwoOrMoreStates) != nil) {
            attributes.append(IDCardAttributes.init(name: "Self Employed Two Or More States", value: section3?.selfEmployedTwoOrMoreStates?.toString(), schemeID: "selfEmployedTwoOrMoreStates"))
            section3Count+=1
        }
        if ((section3?.civilServant) != nil) {
            attributes.append(IDCardAttributes.init(name: "Civil Servant", value: section3?.civilServant?.toString(), schemeID: "civilServant"))
            section3Count+=1
        }
        if ((section3?.contractStaff) != nil) {
            attributes.append(IDCardAttributes.init(name: "Contract Staff", value: section3?.contractStaff?.toString(), schemeID: "contractStaff"))
            section3Count+=1
        }
        if ((section3?.mariner) != nil) {
            attributes.append(IDCardAttributes.init(name: "Mariner", value: section3?.mariner?.toString(), schemeID: "mariner"))
            section3Count+=1
        }
        if ((section3?.employedAndSelfEmployed) != nil) {
            attributes.append(IDCardAttributes.init(name: "Employed And Self Employed", value: section3?.employedAndSelfEmployed?.toString(), schemeID: "employedAndSelfEmployed"))
            section3Count+=1
        }
        if ((section3?.civilAndEmployedSelfEmployed) != nil) {
            attributes.append(IDCardAttributes.init(name: "Civil And Employed Self Employed", value: section3?.civilAndEmployedSelfEmployed?.toString(), schemeID: "civilAndEmployedSelfEmployed"))
            section3Count+=1
        }
        if ((section3?.flightCrewMember) != nil) {
            attributes.append(IDCardAttributes.init(name: "Flight Crew Member", value: section3?.flightCrewMember?.toString(), schemeID: "flightCrewMember"))
            section3Count+=1
        }
        if ((section3?.exception) != nil) {
            attributes.append(IDCardAttributes.init(name: "Exception", value: section3?.exception?.toString(), schemeID: "exception"))
            section3Count+=1
        }
        if ((section3?.exceptionDescription) != nil) {
            attributes.append(IDCardAttributes.init(name: "Exception Description", value: section3?.exceptionDescription, schemeID: "exceptionDescription"))
            section3Count+=1
        }
        if ((section3?.workingInStateUnder21) != nil) {
            attributes.append(IDCardAttributes.init(name: "Working In State Under 21", value: section3?.workingInStateUnder21?.toString(), schemeID: "workingInStateUnder21"))
            section3Count+=1
        }
        
        
        if ((section4?.employee) != nil) {
            attributes.append(IDCardAttributes.init(name: "Employee", value: section4?.employee?.toString(), schemeID: "employee"))
            section4Count+=1
        }
        if ((section4?.selfEmployedActivity) != nil) {
            attributes.append(IDCardAttributes.init(name: "Self Employed Activity", value: section4?.selfEmployedActivity?.toString(), schemeID: "selfEmployedActivity"))
            section4Count+=1
        }
        if ((section4?.nameBusinessName) != nil) {
            attributes.append(IDCardAttributes.init(name: "Name Business Name", value: section4?.nameBusinessName, schemeID: "nameBusinessName"))
            section4Count+=1
        }
        if ((section4?.registeredAddress) != nil) {
            attributes.append(IDCardAttributes.init(name: "Registered Address", value: section4?.registeredAddress?.addressToString(), schemeID: "registeredAddress"))
            section4Count+=1
        }
        if ((section4?.employerSelfEmployedActivityCodes) != nil) {
            attributes.append(IDCardAttributes.init(name: "Employer Self Employed ActivityCodes", value: section4?.employerSelfEmployedActivityCodes?.joined(separator: " ,"), schemeID: "employerSelfEmployedActivityCodes"))
            section4Count+=1
        }
        
        if ((section5?.noFixedAddress) != nil) {
            attributes.append(IDCardAttributes.init(name: "No Fixed Address", value: section5?.noFixedAddress?.toString(), schemeID: "noFixedAddress"))
            section5Count+=1
        }
        if ((section5?.workPlaceAddresses) != nil) {
            attributes.append(IDCardAttributes.init(name: "Work Place Addresses", value: section5?.noFixedAddress?.toString(), schemeID: "workPlaceAddresses"))
            section5Count+=1
        }
        if ((section5?.workPlaceNames) != nil) {
            attributes.append(IDCardAttributes.init(name: "Work Place Names", value: workPlaceNames.joined(separator: "\n"), schemeID: "workPlaceNames"))
            section5Count+=1
        }
               
        if ((section6?.name) != nil) {
            attributes.append(IDCardAttributes.init(name: "Name", value: section6?.name, schemeID: "name"))
            section6Count+=1
        }
        if ((section6?.address) != nil) {
            attributes.append(IDCardAttributes.init(name: "Address", value: section6?.address?.addressToString(), schemeID: "address"))
            section6Count+=1
        }
        if ((section6?.institutionID) != nil) {
            attributes.append(IDCardAttributes.init(name: "Institution ID", value: section6?.institutionID, schemeID: "institutionID"))
            section6Count+=1
        }
        if ((section6?.officeFaxNo) != nil) {
            attributes.append(IDCardAttributes.init(name: "Office Fax No", value: section6?.officeFaxNo, schemeID: "officeFaxNo"))
            section6Count+=1
        }
        if ((section6?.officePhoneNo) != nil) {
            attributes.append(IDCardAttributes.init(name: "Office Phone No", value: section6?.officePhoneNo, schemeID: "officePhoneNo"))
            section6Count+=1
        }
        if ((section6?.email) != nil) {
            attributes.append(IDCardAttributes.init(name: "Email", value: section6?.email, schemeID: "email"))
            section6Count+=1
        }
        if ((section6?.date) != nil) {
            attributes.append(IDCardAttributes.init(name: "Date", value: section6?.date, schemeID: "date"))
            section6Count+=1
        }
        if ((section6?.signature) != nil) {
            attributes.append(IDCardAttributes.init(name: "Signature", value: section6?.signature, schemeID: "signature"))
            section6Count+=1
        }

        
        var sectionStruct = [DWSection]()
        
        if (section1 != nil){
            sectionStruct.append(DWSection(title: "Personal Details", key: "section1"))
        }
        if (section2 != nil){
            sectionStruct.append(DWSection(title: "Member State Legislation", key: "section2"))
        }
        if (section3 != nil){
            sectionStruct.append(DWSection(title: "Status Confirmation", key: "section3"))
        }
        if (section4 != nil){
            sectionStruct.append(DWSection(title: "Employment Details", key: "section4"))
        }
        if (section5 != nil){
            sectionStruct.append(DWSection(title: "Activity Employment Details", key: "section5"))
        }
        if (section6 != nil){
            sectionStruct.append(DWSection(title: "Completing Institution", key: "section6"))
        }
       
        
        var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
        
        var totalProcessed = 0
        for item in sectionStruct {
            switch item.key {
            case "section1":
                for i in totalProcessed...((section1Count-1)+totalProcessed){
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attributes[i], parent: item.key ?? "")
                    attributeStructure[key] = value
                    totalProcessed+=1
                }
            case "section2":
                for i in totalProcessed...((section2Count-1)+totalProcessed){
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attributes[i], parent: item.key ?? "")
                    attributeStructure[key] = value
                    totalProcessed+=1
                }
            case "section3":
                for i in totalProcessed...((section3Count-1)+totalProcessed){
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attributes[i], parent: item.key ?? "")
                    attributeStructure[key] = value
                    totalProcessed+=1
                }
            case "section4":
                for i in totalProcessed...((section4Count-1)+totalProcessed){
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attributes[i], parent: item.key ?? "")
                    attributeStructure[key] = value
                    totalProcessed+=1
                }
            case "section5":
                for i in totalProcessed...((section5Count-1)+totalProcessed){
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attributes[i], parent: item.key ?? "")
                    attributeStructure[key] = value
                    totalProcessed+=1
                }
            case "section6":
                for i in totalProcessed...((section6Count-1)+totalProcessed){
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attributes[i], parent: item.key ?? "")
                    attributeStructure[key] = value
                    totalProcessed+=1
                }
            default:break
            }
        }
        
        walletModel.attributes = attributeStructure
        walletModel.sectionStruct = sectionStruct
        walletModel.referent = nil
        walletModel.schemaID = nil
        walletModel.certInfo = nil
        walletModel.connectionInfo = connectionModel
        walletModel.type = CertType.EBSI.rawValue
        walletModel.subType = EBSI_CredentialType.PDA1.rawValue
        walletModel.searchableText = searchableText.camelCaseToWords().uppercased()
        walletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: credentialModel?.iss, credentialJWT: credential_jwt)
        return walletModel
    }
    
}
