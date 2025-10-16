//
//  PhotoIDCredential.swift
//  dataWallet
//
//  Created by iGrant on 17/02/25.
//

import Foundation

struct PhotoIDCredential: Codable {
    var iso23220: Iso23220?
    let id: String?
    let exp: Int?
    var photoid: Photoid?
    let vct: String?
    
    enum CodingKeys: String, CodingKey {
        case iso23220 = "iso23220"
        case id, exp, vct
        case photoid = "photoid"
    }
    
    init(iso23220: Iso23220? = nil, id: String?, exp: Int?, photoid: Photoid? = nil, vct: String?) {
        self.iso23220 = iso23220
        self.id = id
        self.exp = exp
        self.photoid = photoid
        self.vct = vct
    }
}

// MARK: - Iso23220
struct Iso23220: Codable {
    let documentNumber, expiryDate, portrait, issuingAuthorityUnicode: String?
    let givenNameLatin1, birthDate, residentAddressUnicode: String?
    let sex: String?
    let nameAtBirth, givenNameUnicode, birthplace: String?
    let sd: [String]?
    let familyNameUnicode, residentCountry, nationality, residentCityUnicode: String?
    let issueDate: String?
    let ageInYears: Int?
    let issuingCountry: String?
    let portraitCaptureDate: String?
    let ageOver18: Bool?
    let familyNameLatin1: String?
    let ageBirthYear: Int?
    let residentPostalCode: String?
    
    enum CodingKeys: String, CodingKey {
        case documentNumber = "document_number"
        case expiryDate = "expiry_date"
        case portrait
        case issuingAuthorityUnicode = "issuing_authority_unicode"
        case givenNameLatin1 = "given_name_latin1"
        case birthDate = "birth_date"
        case residentAddressUnicode = "resident_address_unicode"
        case sex
        case nameAtBirth = "name_at_birth"
        case givenNameUnicode = "given_name_unicode"
        case birthplace
        case sd = "_sd"
        case familyNameUnicode = "family_name_unicode"
        case residentCountry = "resident_country"
        case nationality
        case residentCityUnicode = "resident_city_unicode"
        case issueDate = "issue_date"
        case ageInYears = "age_in_years"
        case issuingCountry = "issuing_country"
        case portraitCaptureDate = "portrait_capture_date"
        case ageOver18 = "age_over_18"
        case familyNameLatin1 = "family_name_latin1"
        case ageBirthYear = "age_birth_year"
        case residentPostalCode = "resident_postal_code"
    }
    
    init(
        documentNumber: String?,
        expiryDate: String?,
        portrait: String?,
        issuingAuthorityUnicode: String? ,
        givenNameLatin1: String? ,
        birthDate: String? ,
        residentAddressUnicode: String? ,
        sex: String?,
        nameAtBirth: String?,
        givenNameUnicode: String? ,
        birthplace: String?,
        sd: [String]?,
        familyNameUnicode: String? ,
        residentCountry: String?,
        nationality: String?,
        residentCityUnicode: String?,
        issueDate: String? ,
        ageInYears: Int? ,
        issuingCountry: String? ,
        portraitCaptureDate: String?,
        ageOver18: Bool?,
        familyNameLatin1: String?,
        ageBirthYear: Int?,
        residentPostalCode: String?
    ) {
        self.documentNumber = documentNumber
        self.expiryDate = expiryDate
        self.portrait = portrait
        self.issuingAuthorityUnicode = issuingAuthorityUnicode
        self.givenNameLatin1 = givenNameLatin1
        self.birthDate = birthDate
        self.residentAddressUnicode = residentAddressUnicode
        self.sex = sex
        self.nameAtBirth = nameAtBirth
        self.givenNameUnicode = givenNameUnicode
        self.birthplace = birthplace
        self.sd = sd
        self.familyNameUnicode = familyNameUnicode
        self.residentCountry = residentCountry
        self.nationality = nationality
        self.residentCityUnicode = residentCityUnicode
        self.issueDate = issueDate
        self.ageInYears = ageInYears
        self.issuingCountry = issuingCountry
        self.portraitCaptureDate = portraitCaptureDate
        self.ageOver18 = ageOver18
        self.familyNameLatin1 = familyNameLatin1
        self.ageBirthYear = ageBirthYear
        self.residentPostalCode = residentPostalCode
    }
    
    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            documentNumber = try container.decodeIfPresent(String.self, forKey: .documentNumber)
            expiryDate = try container.decodeIfPresent(String.self, forKey: .expiryDate)
            portrait = try container.decodeIfPresent(String.self, forKey: .portrait)
            issuingAuthorityUnicode = try container.decodeIfPresent(String.self, forKey: .issuingAuthorityUnicode)
            givenNameLatin1 = try container.decodeIfPresent(String.self, forKey: .givenNameLatin1)
            birthDate = try container.decodeIfPresent(String.self, forKey: .birthDate)
            residentAddressUnicode = try container.decodeIfPresent(String.self, forKey: .residentAddressUnicode)
            
            // Handle sex being either Int or String
            if let sexInt = try? container.decode(Int.self, forKey: .sex) {
                sex = String(sexInt)
            } else if let sexString = try? container.decode(String.self, forKey: .sex) {
                sex = sexString
            } else {
                sex = nil
            }
            
            nameAtBirth = try container.decodeIfPresent(String.self, forKey: .nameAtBirth)
            givenNameUnicode = try container.decodeIfPresent(String.self, forKey: .givenNameUnicode)
            birthplace = try container.decodeIfPresent(String.self, forKey: .birthplace)
            sd = try container.decodeIfPresent([String].self, forKey: .sd)
            familyNameUnicode = try container.decodeIfPresent(String.self, forKey: .familyNameUnicode)
            residentCountry = try container.decodeIfPresent(String.self, forKey: .residentCountry)
            nationality = try container.decodeIfPresent(String.self, forKey: .nationality)
            residentCityUnicode = try container.decodeIfPresent(String.self, forKey: .residentCityUnicode)
            issueDate = try container.decodeIfPresent(String.self, forKey: .issueDate)
            ageInYears = try container.decodeIfPresent(Int.self, forKey: .ageInYears)
            issuingCountry = try container.decodeIfPresent(String.self, forKey: .issuingCountry)
            portraitCaptureDate = try container.decodeIfPresent(String.self, forKey: .portraitCaptureDate)
            ageOver18 = try container.decodeIfPresent(Bool.self, forKey: .ageOver18)
            familyNameLatin1 = try container.decodeIfPresent(String.self, forKey: .familyNameLatin1)
            ageBirthYear = try container.decodeIfPresent(Int.self, forKey: .ageBirthYear)
            residentPostalCode = try container.decodeIfPresent(String.self, forKey: .residentPostalCode)
        }

}

// MARK: - Photoid
struct Photoid: Codable {
    let birthCity, travelDocumentNumber, personID: String?
    let sd: [String]?
    let residentState, birthCountry, residentHouseNumber, residentStreet: String?
    let administrativeNumber, birthState: String?
    
    enum CodingKeys: String, CodingKey {
        case birthCity = "birth_city"
        case travelDocumentNumber = "travel_document_number"
        case personID = "person_id"
        case sd = "_sd"
        case residentState = "resident_state"
        case birthCountry = "birth_country"
        case residentHouseNumber = "resident_house_number"
        case residentStreet = "resident_street"
        case administrativeNumber = "administrative_number"
        case birthState = "birth_state"
    }
}

extension PhotoIDCredential {
    
    static func decode(withpDictionary dict: [String: Any]) -> PhotoIDCredential? {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let photoIDCredential = try decoder.decode(PhotoIDCredential.self, from: jsonData)
                return photoIDCredential
            } catch {
                print("Decoding error: \(error)")
                return nil
            }
        }
}

struct PhotoIDSection1 {
    var portrait: String?
    var ageOver18: Bool?
}

struct PhotoIDSection2 {
    var personID: String?
    var familyName: String?
    var givenName: String?
    var birthDate: String?
    var travelDocumentNumber: String?
}

struct PhotoIDSection3 {
    var birthCountry: String?
    var birthState: String?
    var birthCity: String?
    var administrativeNumber: String?
    var residentStreet: String?
    var residentHouseNumber: String?
    var residentState: String?
}

struct PhotoIDSection4 {
    var issueDate: String?
    var expiryDate: String?
    var issuingAuthority: String?
    var issuingCountry: String?
    var sex: Int?
    var nationality: String?
    var documentNumber: String?
    var nameAtBirth: String?
    var birthplace: String?
    var portraitCaptureDate: String?
    var residentAddress: String?
    var residentCity: String?
    var residentPostalCode: String?
    var residentCountry: String?
    var ageOver18: Bool?
    var ageInYears: Int?
    var birthYear: Int?
    var familyNameLatin1: String?
    var givenNameLatin1: String?
}
