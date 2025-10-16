//
//  ThirdPartyDecodable.swift
//  dataWallet
//
//  Created by sreelekh N on 16/09/22.
//

import Foundation
struct ThirdPartyDecodable: Codable {
    let prefs: [ThirdPartyPref]?
    let sectors: [String]?
}

struct ThirdPartyPref: Codable {
    let instanceID, sector: String?
    var dus: [ThirdPartyDus]?
    let instancePermissionState: PermissionState?

    enum CodingKeys: String, CodingKey {
        case instanceID = "instance_id"
        case instancePermissionState = "instance_permission_state"
        case sector, dus
    }
}

public struct ThirdPartyDus: Codable {
    var ddaInstancePermissionState: PermissionState?
    let controllerDetails: ThirdPartyDetails?
    let ddaInstanceID: String?
    var sector: String?
    var daInstanceID: String?

    enum CodingKeys: String, CodingKey {
        case ddaInstancePermissionState = "dda_instance_permission_state"
        case controllerDetails = "controller_details"
        case ddaInstanceID = "dda_instance_id"
        case sector
        case daInstanceID
    }
}

enum PermissionState: String, Codable {
    case allow
    case disallow
}

struct ThirdPartyDetails: Codable {
    let organisationDid, organisationName: String?
    let coverImageURL, logoImageURL: String?
    let location, organisationType, controllerDetailsDescription: String?
    let policyURL: String?
    let eulaURL: String?

    enum CodingKeys: String, CodingKey {
        case organisationDid = "organisation_did"
        case organisationName = "organisation_name"
        case coverImageURL = "cover_image_url"
        case logoImageURL = "logo_image_url"
        case location
        case organisationType = "organisation_type"
        case controllerDetailsDescription = "description"
        case policyURL = "policy_url"
        case eulaURL = "eula_url"
    }
}
