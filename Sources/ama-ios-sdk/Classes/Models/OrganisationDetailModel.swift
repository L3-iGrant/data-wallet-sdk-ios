//
//  OrganisationDetailModel.swift
//  Alamofire
//
//  Created by Mohamed Rebin on 21/12/20.
//

import Foundation


// MARK: - OrganisationInfoModel
struct OrganisationInfoModel: Codable {
    var type: String?
    var id: String?
    var name: String?
    var policyURL: String?
    var orgType: String?
    var logoImageURL: String?
    var location: String?
    var privacyDashboard: OrganisationInfoPrivacyDashboard?
    var coverImageURL: String?
    var organisationInfoModelDescription: String?
    var eulaURL: String?
    var orgId: String?
    var isValidOrganization: Bool?
    var x5c: String?
    var jwksURL: String?
    
    init(dataControllerModel: DataControllerConnectionDetail){
        self.type = dataControllerModel.type
        self.id = dataControllerModel.id
        self.name = dataControllerModel.body?.organisationName
        self.policyURL = dataControllerModel.body?.policyURL
        self.orgType = dataControllerModel.body?.organisationType
        self.logoImageURL = dataControllerModel.body?.logoImageURL
        self.location = dataControllerModel.body?.location
        self.privacyDashboard = nil
        self.coverImageURL = dataControllerModel.body?.coverImageURL
        self.organisationInfoModelDescription = dataControllerModel.body?.bodyDescription
        self.eulaURL = dataControllerModel.body?.eulaURL
        self.orgId = dataControllerModel.body?.organisationID
        self.isValidOrganization = dataControllerModel.body?.isValidOrganization
        self.x5c = dataControllerModel.body?.x5c
        self.jwksURL = dataControllerModel.body?.jwksURL
    }
    
    init() {}
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case name = "name"
        case policyURL = "policy_url"
        case orgType = "org_type"
        case logoImageURL = "logo_image_url"
        case location = "location"
        case privacyDashboard = "privacy_dashboard"
        case coverImageURL = "cover_image_url"
        case organisationInfoModelDescription = "description"
        case eulaURL = "eula_url"
        case orgId = "org_id"
        case isValidOrganization
        case x5c
        case jwksURL
    }
}

// MARK: - OrganisationInfoPrivacyDashboard
struct OrganisationInfoPrivacyDashboard: Codable {
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
    
    init(delete: Bool?, version: String?, status: Int?, hostName: String?) {
           self.delete = delete
           self.version = version
           self.status = status
           self.hostName = hostName
       }
    
    init(from decoder: Decoder) throws {
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


struct DataControllerConnectionDetail: Codable {
    let type, id: String?
    let body: DCBody?
    let to, from, createdTime: String?

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case body, to, from
        case createdTime = "created_time"
    }
}

// MARK: - Body
struct DCBody: Codable {
    let organisationID, organisationName: String?
    let coverImageURL, logoImageURL: String?
    let location, organisationType, bodyDescription: String?
    let policyURL: String?
    let eulaURL: String?
    var isNewKey: Bool = false
    var isValidOrganization: Bool?
    var x5c: String?
    var jwksURL: String?

    enum CodingKeys: String, CodingKey {
        case organisationID = "organisation_did"
        case old_organisationID = "organisation_id"
        case organisationName = "organisation_name"
        case coverImageURL = "cover_image_url"
        case logoImageURL = "logo_image_url"
        case location
        case organisationType = "organisation_type"
        case bodyDescription = "description"
        case policyURL = "policy_url"
        case eulaURL = "eula_url"
        case isValidOrganization
        case x5c
        case jwksURL
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.organisationID) {
            self.isNewKey = true
        }
        organisationID = try? (container.decodeIfPresent(String.self, forKey: .organisationID) ?? container.decodeIfPresent(String.self, forKey: .old_organisationID))
        organisationName = try? container.decodeIfPresent(String.self, forKey: .organisationName)
        coverImageURL = try? container.decodeIfPresent(String.self, forKey: .coverImageURL)
        logoImageURL = try? container.decodeIfPresent(String.self, forKey: .logoImageURL)
        location = try? container.decodeIfPresent(String.self, forKey: .location)
        organisationType = try? container.decodeIfPresent(String.self, forKey: .organisationType)
        bodyDescription = try? container.decodeIfPresent(String.self, forKey: .bodyDescription)
        policyURL = try? container.decodeIfPresent(String.self, forKey: .policyURL)
        eulaURL = try? container.decodeIfPresent(String.self, forKey: .eulaURL)
        isValidOrganization = try? container.decodeIfPresent(Bool.self, forKey: .isValidOrganization)
        x5c = try? container.decodeIfPresent(String.self, forKey: .x5c)
        jwksURL = try? container.decodeIfPresent(String.self, forKey: .jwksURL)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if isNewKey {
            try container.encodeIfPresent(self.organisationID, forKey: .organisationID)
        } else {
            try container.encodeIfPresent(self.organisationID, forKey: .old_organisationID)
        }
        try container.encodeIfPresent(self.organisationName, forKey: .old_organisationID)
        try container.encodeIfPresent(self.coverImageURL, forKey: .old_organisationID)
        try container.encodeIfPresent(self.logoImageURL, forKey: .old_organisationID)
        try container.encodeIfPresent(self.location, forKey: .old_organisationID)
        try container.encodeIfPresent(self.organisationID, forKey: .old_organisationID)
        try container.encodeIfPresent(self.organisationID, forKey: .old_organisationID)
        try container.encodeIfPresent(self.organisationID, forKey: .old_organisationID)
        try container.encodeIfPresent(self.organisationID, forKey: .old_organisationID)
    }
}
