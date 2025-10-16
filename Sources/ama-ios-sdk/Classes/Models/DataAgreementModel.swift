//
//  DataAgreementModel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 21/09/21.
//
// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let dataAgreementModel = try? newJSONDecoder().decode(DataAgreementModel.self, from: jsonData)

import Foundation

// MARK: - DataAgreementModel
class DataAgreementModel: Codable {
    let type: String?
    let id: String?
    let orgDetails: OrgDetails?
    let purposeDetails: PurposeDetails?
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case orgDetails = "org_details"
        case purposeDetails = "purpose_details"
    }
    
    init(type: String?, id: String?, orgDetails: OrgDetails?, purposeDetails: PurposeDetails?) {
        self.type = type
        self.id = id
        self.orgDetails = orgDetails
        self.purposeDetails = purposeDetails
    }
}

// MARK: - OrgDetails
class OrgDetails: Codable {
    let orgID: String?
    let name: String?
    let coverImageURL: String?
    let logoImageURL: String?
    let location: String?
    let orgType: String?
    let orgDetailsDescription: String?
    let policyURL: String?
    let eulaURL: String?
    let privacyDashboard: PrivacyDashboard?
    
    enum CodingKeys: String, CodingKey {
        case orgID = "org_id"
        case name = "name"
        case coverImageURL = "cover_image_url"
        case logoImageURL = "logo_image_url"
        case location = "location"
        case orgType = "org_type"
        case orgDetailsDescription = "description"
        case policyURL = "policy_url"
        case eulaURL = "eula_url"
        case privacyDashboard = "privacy_dashboard"
    }
    
    init(orgID: String?, name: String?, coverImageURL: String?, logoImageURL: String?, location: String?, orgType: String?, orgDetailsDescription: String?, policyURL: String?, eulaURL: String?, privacyDashboard: PrivacyDashboard?) {
        self.orgID = orgID
        self.name = name
        self.coverImageURL = coverImageURL
        self.logoImageURL = logoImageURL
        self.location = location
        self.orgType = orgType
        self.orgDetailsDescription = orgDetailsDescription
        self.policyURL = policyURL
        self.eulaURL = eulaURL
        self.privacyDashboard = privacyDashboard
    }
}

// MARK: - PrivacyDashboard
class PrivacyDashboard: Codable {
    let hostName: String?
    let version: String?
    let status: Int?
    let delete: Bool?
    
    enum CodingKeys: String, CodingKey {
        case hostName = "host_name"
        case version = "version"
        case status = "status"
        case delete = "delete"
    }
    
    init(hostName: String?, version: String?, status: Int?, delete: Bool?) {
        self.hostName = hostName
        self.version = version
        self.status = status
        self.delete = delete
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        hostName = try? container.decode(String.self, forKey: .hostName)
        version = try? container.decode(String.self, forKey: .version)
        status = try? container.decode(Int.self, forKey: .status)
        do{
            delete = try container.decode(Bool.self, forKey: .delete)
        } catch {
            delete = false
        }
    }
}

// MARK: - PurposeDetails
class PurposeDetails: Codable {
    let purpose: Purpose?
    let templates: [Template]?
    
    enum CodingKeys: String, CodingKey {
        case purpose = "purpose"
        case templates = "templates"
    }
    
    init(purpose: Purpose?, templates: [Template]?) {
        self.purpose = purpose
        self.templates = templates
    }
}

// MARK: - Purpose
class Purpose: Codable {
    let id: String?
    let name: String?
    let lawfulBasisOfProcessing: String?
    let purposeDescription: String?
    var lawfulUsage: Bool?
    let policyURL: String?
    let attributeType: Int?
    let jurisdiction: String?
    let disclosure: String?
    let industryScope: String?
    let dataRetention: DataRetention?
    let restriction: String?
    var shared3Pp: Bool?
    let ssiID: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case lawfulBasisOfProcessing = "lawful_basis_of_processing"
        case purposeDescription = "description"
        case lawfulUsage = "lawful_usage"
        case policyURL = "policy_url"
        case attributeType = "attribute_type"
        case jurisdiction = "jurisdiction"
        case disclosure = "disclosure"
        case industryScope = "industry_scope"
        case dataRetention = "data_retention"
        case restriction = "restriction"
        case shared3Pp = "shared_3pp"
        case ssiID = "ssi_id"
    }
    
    init(id: String?, name: String?, lawfulBasisOfProcessing: String?, purposeDescription: String?, lawfulUsage: Bool?, policyURL: String?, attributeType: Int?, jurisdiction: String?, disclosure: String?, industryScope: String?, dataRetention: DataRetention?, restriction: String?, shared3Pp: Bool?, ssiID: String?) {
        self.id = id
        self.name = name
        self.lawfulBasisOfProcessing = lawfulBasisOfProcessing
        self.purposeDescription = purposeDescription
        self.lawfulUsage = lawfulUsage
        self.policyURL = policyURL
        self.attributeType = attributeType
        self.jurisdiction = jurisdiction
        self.disclosure = disclosure
        self.industryScope = industryScope
        self.dataRetention = dataRetention
        self.restriction = restriction
        self.shared3Pp = shared3Pp
        self.ssiID = ssiID
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try? container.decode(String.self, forKey: .id)
        self.name = try? container.decode(String.self, forKey: .name)
        self.lawfulBasisOfProcessing = try? container.decode(String.self, forKey: .lawfulBasisOfProcessing)
        self.purposeDescription = try? container.decode(String.self, forKey: .purposeDescription)
        self.policyURL = try? container.decode(String.self, forKey: .policyURL)
        self.attributeType = try? container.decode(Int.self, forKey: .attributeType)
        self.jurisdiction = try? container.decode(String.self, forKey: .jurisdiction)
        self.disclosure = try? container.decode(String.self, forKey: .disclosure)
        self.industryScope = try? container.decode(String.self, forKey: .industryScope)
        self.dataRetention = try? container.decode(DataRetention.self, forKey: .dataRetention)
        self.restriction = try? container.decode(String.self, forKey: .restriction)
        self.ssiID = try? container.decode(String.self, forKey: .ssiID)
        do{
            lawfulUsage = try container.decode(Bool.self, forKey: .lawfulUsage)
            shared3Pp = try container.decode(Bool.self, forKey: .shared3Pp)
        } catch {
            lawfulUsage = false
            shared3Pp = false
        }
    }
}

// MARK: - DataRetention
class DataRetention: Codable {
    let retentionPeriod: Int?
    let enabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case retentionPeriod = "retention_period"
        case enabled = "enabled"
    }
    
    init(retentionPeriod: Int?, enabled: Bool?) {
        self.retentionPeriod = retentionPeriod
        self.enabled = enabled
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        retentionPeriod = try container.decode(Int.self, forKey: .retentionPeriod)
        do{
            enabled = try container.decode(Bool.self, forKey: .enabled)
        } catch {
            enabled = false
        }
    }
}

// MARK: - Template
class Template: Codable {
    let id: String?
    let consent: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case consent = "consent"
    }
    
    init(id: String?, consent: String?) {
        self.id = id
        self.consent = consent
    }
}
