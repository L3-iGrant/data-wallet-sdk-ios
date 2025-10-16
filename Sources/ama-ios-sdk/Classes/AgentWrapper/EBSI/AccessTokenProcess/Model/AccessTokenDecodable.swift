//
//  AccessTokenDecodable.swift
//  dataWallet
//
//  Created by sreelekh N on 14/07/22.
//

import Foundation
struct CreatePayloadJWT: Codable {
    let iat, exp, iss: String?
    let context: [String]?
    let type: String?
    let verifiableCredential: [VerifiableCredential]?
    let holder: String?
    
    enum CodingKeys: String, CodingKey {
        case iat, exp, iss
        case context = "@context"
        case type, holder
        case verifiableCredential
    }
}

struct VerifiablePresentation: Codable {
    let context: [String]?
    let type: String?
    var verifiableCredential: [VerifiableCredential]?
    let holder: String?
    let proof: ProofEncodable?
    
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case type, holder, proof
        case verifiableCredential
    }
}

struct VerifiableModel: Codable {
    let verifiableCredential: VerifiableCredential?
}

struct VerifiableCredential: Codable {
    let id, issuer: String?
    let validFrom: String?
    let credentialSubject: CredentialSubject?
    let credentialSchema: CredentialSchema?
    let issuanceDate, expirationDate: String?
    let context: [String]?
    let type: [String]?
    let proof: ProofVerifiable?
    
    enum CodingKeys: String, CodingKey {
        case id, issuer
        case validFrom
        case credentialSubject, credentialSchema
        case issuanceDate, expirationDate
        case context = "@context"
        case type
        case proof
    }
}

struct CredentialSchema: Codable {
    let id: String?
    let type: String?
}

struct CredentialSubject: Codable {
    let id: String?
}

struct ProofVerifiable: Codable {
    let type: String?
    let created: String?
    let proofPurpose, verificationMethod, jws: String?
}

struct VerifyAuthResponseModel: Decodable {
    let context: String?
    let id: String?
    let verificationMethod: [VerificationMethod]?
    let authentication, assertionMethod: [String]?
    
    enum CodingKeys: String, CodingKey {
        case context = "@context"
        case id, verificationMethod, authentication, assertionMethod
    }
}

struct VerificationMethod: Decodable {
    let id, type, controller: String?
    let publicKeyJwk: PublicKeyJwk?
}

struct PublicKeyJwk: Decodable {
    let kty, crv, x, y: String?
}
