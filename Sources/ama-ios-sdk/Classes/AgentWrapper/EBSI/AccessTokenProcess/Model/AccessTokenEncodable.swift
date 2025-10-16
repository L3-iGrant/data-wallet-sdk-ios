//
//  AccessTokenEncodable.swift
//  dataWallet
//
//  Created by sreelekh N on 14/07/22.
//

import Foundation
struct CreateHeaderJWT: Codable {
    let alg, typ: String?
    let kid: String?
}

struct ProofEncodable: Codable {
    let type: String?
    let created: String?
    let proofPurpose, verificationMethod, jws: String?
}

struct AuthenticationRequestsEncodable: Encodable {
    let scope: String
}

struct AuthenticationRequestsModel: Decodable {
    let uri: String?
}
