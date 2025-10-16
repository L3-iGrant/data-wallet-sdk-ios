//
//  PullDataNotificationModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 20/09/22.
//

import Foundation

// MARK: - PullDataNotificationModel
struct PullDataNotificationModel: Codable {
    let id, type: String?
    let controllerDetails: ControllerDetails?
    let daInstanceID: String?

    enum CodingKeys: String, CodingKey {
        case id = "@id"
        case type = "@type"
        case controllerDetails = "controller_details"
        case daInstanceID = "da_instance_id"
    }
}

// MARK: - ControllerDetails
struct ControllerDetails: Codable {
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

