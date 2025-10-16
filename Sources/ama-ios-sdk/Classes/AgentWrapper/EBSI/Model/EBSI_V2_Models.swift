//
//  EBSI_V2_Authorization_Details.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 01/08/22.
//

import Foundation

struct EBSI_V2_Authorization_Details: Codable {
    let type, credentialType, format: String

    enum CodingKeys: String, CodingKey {
        case type
        case credentialType = "credential_type"
        case format
    }
    
    func toString() -> String {
        return self.dictionary?.toString() ?? ""
    }
}

struct EBSI_V2_URL_Params: Codable {
    let scope, responseType, redirectURI, clientID: String?
    let responseMode, state, authorizationDetails: [EBSI_V2_Authorization_Details]?

    enum CodingKeys: String, CodingKey {
        case scope
        case responseType = "response_type"
        case redirectURI = "redirect_uri"
        case clientID = "client_id"
        case responseMode = "response_mode"
        case state
        case authorizationDetails = "authorization_details"
    }
}

struct EBSIV2AuthTokenResponse: Codable {
    let tokenType, accessToken: String?
    let expiresIn: Int?
    let cNonce, idToken: String?

    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case cNonce = "c_nonce"
        case idToken = "id_token"
    }
}

struct EBSIV2IssueCredentialResponse: Codable {
    let format, credential, cNonce: String?
    let cNonceExpiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case format, credential
        case cNonce = "c_nonce"
        case cNonceExpiresIn = "c_nonce_expires_in"
    }
}

// MARK: - EBSIV2IssueCredential
struct EBSI_V2_VerifiableID: Codable {
    let jti, sub, iss, vct: String?
    
    let vc: Vc?
    let accounts: [Accounts]?
    let account_holder_id: String?
    let fundingSource: FundingSource?
}

struct EBSI_Credential: Codable {
    let jti, sub, iss, vct: String?
    
    let vc: VC?
    let accounts: [Accounts]?
    let account_holder_id: String?
    let fundingSource: FundingSource?
}

struct Accounts: Codable {
    let card: String?
    let iban: String?
}

struct FundingSource: Codable {
    let type: String?
    let panLastFour: String?
    let iin: String?
    let parLastFour: String?
    let aliasId: String?
    let currency: String?
    let scheme: String?
    let icon: String?
}

// MARK: - Vc
struct VC: Codable {
    let context: [String]?
    let id: String?
    let type: [String]?
    let issuanceDate, validFrom, issued: String?

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case id, type, issuanceDate, validFrom, issued
    }
}


// MARK: - Vc
struct Vc: Codable {
    let context: [String]?
    let id: String?
    let type: [String]?
    let issuer: String?
    let issuanceDate, validFrom, issued: String?
    let credentialSubject: EBSI_CredentialSubject?

    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case id, type, issuer, issuanceDate, validFrom, issued, credentialSubject
    }
}

// MARK: - CredentialSubject
struct EBSI_CredentialSubject: Codable {
    let id, personalIdentifier, familyName, firstName: String?
    let dateOfBirth: String?
    let achieved: [Achieved]? //diploma
    let identifier: [Identifier]? //Student ID
    
    //PDA 1
    let section1: Section1?
    let section2: Section2?
    let section3: Section3?
    let section4: Section4?
    let section5: Section5?
    let section6: Section6?
    
    let iso23220: Iso23220?
    let photoid: Photoid?
}

// MARK: - Achieved
struct Achieved: Codable {
    let id: String?
    let identifier: [Identifier]?
    let specifiedBy: [SpecifiedBy]?
    let title: String?
    let wasAwardedBy: WasAwardedBy?
}

// MARK: - Identifier
struct Identifier: Codable {
    let schemeID, value: String?
}

// MARK: - SpecifiedBy
struct SpecifiedBy: Codable {
    let id: String?
    let eqflLevel: String?
    let title: String?
}

// MARK: - WasAwardedBy
struct WasAwardedBy: Codable {
    let awardingBody: [String]?
    let awardingDate: String?
    let awardingLocation: [String]?
    let id: String?
}

// MARK: - Section1
class Section1: Codable {
    let personalIdentificationNumber, sex, surname, forenames: String?
    let dateBirth: String?
    let nationalities: [String]?
    let stateOfResidenceAddress, stateOfStayAddress: Address?
    let placeBirth: PlaceBirth?
    let surnameAtBirth: String?

    init(personalIdentificationNumber: String?, sex: String?, surname: String?, forenames: String?, dateBirth: String?, nationalities: [String]?, stateOfResidenceAddress: Address?, stateOfStayAddress: Address?, placeBirth: PlaceBirth?, surnameAtBirth: String?) {
        self.personalIdentificationNumber = personalIdentificationNumber
        self.sex = sex
        self.surname = surname
        self.forenames = forenames
        self.dateBirth = dateBirth
        self.nationalities = nationalities
        self.stateOfResidenceAddress = stateOfResidenceAddress
        self.stateOfStayAddress = stateOfStayAddress
        self.placeBirth = placeBirth
        self.surnameAtBirth = surnameAtBirth
    }
}

// MARK: - Address
class Address: Codable {
    let streetNo, postCode, town, countryCode: String?

    init(streetNo: String?, postCode: String?, town: String?, countryCode: String?) {
        self.streetNo = streetNo
        self.postCode = postCode
        self.town = town
        self.countryCode = countryCode
    }
    
    func addressToString() -> String {
           return "\(streetNo ?? "") \(postCode ?? "") \(town ?? "") \(countryCode ?? "")";
       }
}

class PlaceBirth: Codable {
    let countryCode, region, town: String?
    
    init(countryCode: String?, region: String?, town: String?) {
        self.region = region
        self.town = town
        self.countryCode = countryCode
    }
    
    func addressToString() -> String {
           return "\(region ?? "") \(town ?? "") \(countryCode ?? "")";
       }
}

// MARK: - Section2
class Section2: Codable {
    let memberStateWhichLegislationApplies, startingDate, endingDate: String?
    let certificateForDurationActivity, determinationProvisional, transitionRulesApplyAsEC8832004: Bool?

    init(memberStateWhichLegislationApplies: String?, startingDate: String?, endingDate: String?, certificateForDurationActivity: Bool?, determinationProvisional: Bool?, transitionRulesApplyAsEC8832004: Bool?) {
        self.memberStateWhichLegislationApplies = memberStateWhichLegislationApplies
        self.startingDate = startingDate
        self.endingDate = endingDate
        self.certificateForDurationActivity = certificateForDurationActivity
        self.determinationProvisional = determinationProvisional
        self.transitionRulesApplyAsEC8832004 = transitionRulesApplyAsEC8832004
    }
}

// MARK: - Section3
class Section3: Codable {
    let postedEmployedPerson, employedTwoOrMoreStates, postedSelfEmployedPerson, selfEmployedTwoOrMoreStates: Bool?
    let civilServant, contractStaff, mariner, employedAndSelfEmployed: Bool?
    let civilAndEmployedSelfEmployed, flightCrewMember, exception: Bool?
    let exceptionDescription: String?
    let workingInStateUnder21: Bool?

    init(postedEmployedPerson: Bool?, employedTwoOrMoreStates: Bool?, postedSelfEmployedPerson: Bool?, selfEmployedTwoOrMoreStates: Bool?, civilServant: Bool?, contractStaff: Bool?, mariner: Bool?, employedAndSelfEmployed: Bool?, civilAndEmployedSelfEmployed: Bool?, flightCrewMember: Bool?, exception: Bool?, exceptionDescription: String?, workingInStateUnder21: Bool?) {
        self.postedEmployedPerson = postedEmployedPerson
        self.employedTwoOrMoreStates = employedTwoOrMoreStates
        self.postedSelfEmployedPerson = postedSelfEmployedPerson
        self.selfEmployedTwoOrMoreStates = selfEmployedTwoOrMoreStates
        self.civilServant = civilServant
        self.contractStaff = contractStaff
        self.mariner = mariner
        self.employedAndSelfEmployed = employedAndSelfEmployed
        self.civilAndEmployedSelfEmployed = civilAndEmployedSelfEmployed
        self.flightCrewMember = flightCrewMember
        self.exception = exception
        self.exceptionDescription = exceptionDescription
        self.workingInStateUnder21 = workingInStateUnder21
    }
}

// MARK: - Section4
class Section4: Codable {
    let employee, selfEmployedActivity: Bool?
    let nameBusinessName: String?
    let registeredAddress: Address?
    let employerSelfEmployedActivityCodes: [String]?

    init(employee: Bool?, selfEmployedActivity: Bool?, nameBusinessName: String?, registeredAddress: Address?, employerSelfEmployedActivityCodes: [String]?) {
        self.employee = employee
        self.selfEmployedActivity = selfEmployedActivity
        self.nameBusinessName = nameBusinessName
        self.registeredAddress = registeredAddress
        self.employerSelfEmployedActivityCodes = employerSelfEmployedActivityCodes
    }
}

// MARK: - Section5
class Section5: Codable {
    let noFixedAddress: Bool?
    let workPlaceAddresses: [WorkPlaceAddresses]?
    let workPlaceNames: [WorkPlaceNames]?

    init(noFixedAddress: Bool?, workPlaceAddresses: [WorkPlaceAddresses]?,  workPlaceNames: [WorkPlaceNames]?) {
        self.noFixedAddress = noFixedAddress
        self.workPlaceAddresses = workPlaceAddresses
        self.workPlaceNames = workPlaceNames
    }
}

class WorkPlaceAddresses: Codable {
    let address: Address?
    let seqno: String?
    
    init(address: Address?, seqno: String?) {
        self.address = address
        self.seqno = seqno
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.address = try container.decodeIfPresent(Address.self, forKey: .address)
        
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: .seqno) {
            self.seqno = String(intValue)
        } else if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: .seqno) {
            self.seqno = String(doubleValue)
        } else {
            self.seqno = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case address
        case seqno
    }
    
}

class WorkPlaceNames: Codable {
    let companyNameVesselName: String?
    let seqno: String?
    
    init(companyNameVesselName: String?, seqno: String?) {
        self.companyNameVesselName = companyNameVesselName
        self.seqno = seqno
    }
    
    required public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.companyNameVesselName = try container.decodeIfPresent(String.self, forKey: .companyNameVesselName)
        
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: .seqno) {
            self.seqno = String(intValue)
        } else if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: .seqno) {
            self.seqno = String(doubleValue)
        } else {
            self.seqno = nil
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case companyNameVesselName
        case seqno
    }
}

// MARK: - Section6
class Section6: Codable {
    let name: String?
    let address: Address?
    let institutionID, officeFaxNo, officePhoneNo, email: String?
    let date, signature: String?

    init(name: String?, address: Address?, institutionID: String?, officeFaxNo: String?, officePhoneNo: String?, email: String?, date: String?, signature: String?) {
        self.name = name
        self.address = address
        self.institutionID = institutionID
        self.officeFaxNo = officeFaxNo
        self.officePhoneNo = officePhoneNo
        self.email = email
        self.date = date
        self.signature = signature
    }
}
