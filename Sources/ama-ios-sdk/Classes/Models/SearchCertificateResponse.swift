// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   var searchCertificateWelcome = try? newJSONDecoder().decode(SearchCertificateWelcome.self, from: jsonData)

import Foundation

// MARK: - SearchCertificateWelcome
public struct SearchCertificateResponse: Codable {
    var totalCount: Int?
    var records: [SearchCertificateRecord]?
}

// MARK: - SearchCertificateRecord
class SearchCertificateRecord: Codable {
    var type: String?
    var id: String?
    var value: SearchCertificateValue?
    var tags: SearchCertificateTags?
}

// MARK: - SearchCertificateTags
struct SearchCertificateTags: Codable {
    var threadID: String?
    var state: String?
    var requestID: String?

    enum CodingKeys: String, CodingKey {
        case threadID = "thread_id"
        case state = "state"
        case requestID = "request_id"
    }
}

// MARK: - SearchCertificateValue
struct SearchCertificateValue: Codable {
    var threadID, createdAt, updatedAt, connectionID: String?
    var credentialProposalDict: SearchCertificateCredentialProposalDict?
    var credentialOfferDict: JSONNull?
    var credentialOffer: SearchCertificateCredentialOffer?
    var credentialRequest: SearchCertificateCredentialRequest?
    var credentialRequestMetadata: SearchCertificateCredentialRequestMetadata?
    var errorMsg: JSONNull?
    var credDefJson: CredentialDefModel?
//    var autoOffer, autoIssue, autoRemove: Bool?
    var rawCredential: SearchCertificateRawCredential?
    var credential: SearchProofReqCredInfo?
    var parentThreadID: JSONNull?
    var credentialDefinitionID, schemaID, credentialID: String?
    var revocRegID, revocationID: JSONNull?
    var role, state: String?
//    var trace: Bool?

    enum CodingKeys: String, CodingKey {
        case threadID = "thread_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case connectionID = "connection_id"
        case credentialProposalDict = "credential_proposal_dict"
        case credentialOfferDict = "credential_offer_dict"
        case credentialOffer = "credential_offer"
        case credentialRequest = "credential_request"
        case credentialRequestMetadata = "credential_request_metadata"
        case errorMsg = "error_msg"
//        case autoOffer = "auto_offer"
//        case autoIssue = "auto_issue"
//        case autoRemove = "auto_remove"
        case rawCredential = "raw_credential"
        case credential
        case parentThreadID = "parent_thread_id"
//        case initiator
        case credentialDefinitionID = "credential_definition_id"
        case schemaID = "schema_id"
        case credentialID = "credential_id"
        case revocRegID = "revoc_reg_id"
        case revocationID = "revocation_id"
        case role, state
        case credDefJson
//        case trace
    }
}

// MARK: - SearchCertificateCredentialOffer
struct SearchCertificateCredentialOffer: Codable {
    var schemaID, credDefID: String?
    var keyCorrectnessProof: SearchCertificateKeyCorrectnessProof?
    var nonce: String?

    enum CodingKeys: String, CodingKey {
        case schemaID = "schema_id"
        case credDefID = "cred_def_id"
        case keyCorrectnessProof = "key_correctness_proof"
        case nonce
    }
}

// MARK: - SearchCertificateKeyCorrectnessProof
struct SearchCertificateKeyCorrectnessProof: Codable {
    var c, xzCap: String?
    var xrCap: [[String]]?

    enum CodingKeys: String, CodingKey {
        case c
        case xzCap = "xz_cap"
        case xrCap = "xr_cap"
    }
}

// MARK: - SearchCertificateCredentialProposalDict
struct SearchCertificateCredentialProposalDict: Codable {
    var type, id, comment, credDefID: String?
    var schemaID: String?
    var credentialProposal: SearchCertificateCredentialProposal?

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case comment
        case credDefID = "cred_def_id"
        case schemaID = "schema_id"
        case credentialProposal = "credential_proposal"
    }
}

// MARK: - SearchCertificateCredentialProposal
struct SearchCertificateCredentialProposal: Codable {
    var type: String?
    var attributes: [SearchCertificateAttribute]?

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case attributes
    }
}

// MARK: - SearchCertificateAttribute
class SearchCertificateAttribute: Codable {
    var name, value: String?
    
    init(name: String?, value: String?) {
        self.name = name
        self.value = value
    }
    
    enum CodingKeys: String, CodingKey {
           case name
           case value
       }
       
//       required init(from decoder: Decoder) throws {
//           let container = try decoder.container(keyedBy: CodingKeys.self)
//           name = try? container.decodeIfPresent(String.self, forKey: .name)
//           value = CodableUtils.decodeAsString(container: container, codingKey: .value)
//       }
//
//       public func encode(to encoder: Encoder) throws {
//           var container = encoder.container(keyedBy: CodingKeys.self)
//               try container.encodeIfPresent(self.name, forKey: .name)
//               try container.encodeIfPresent(self.value, forKey: .value)
//       }
}

// MARK: - SearchCertificateCredentialRequest
struct SearchCertificateCredentialRequest: Codable {
    var proverDid, credDefID: String?
    var blindedMS: SearchCertificateBlindedMS?
    var blindedMSCorrectnessProof: SearchCertificateBlindedMSCorrectnessProof?
    var nonce: String?

    enum CodingKeys: String, CodingKey {
        case proverDid = "prover_did"
        case credDefID = "cred_def_id"
        case blindedMS = "blinded_ms"
        case blindedMSCorrectnessProof = "blinded_ms_correctness_proof"
        case nonce
    }
}

// MARK: - SearchCertificateBlindedMS
struct SearchCertificateBlindedMS: Codable {
    var u: String?
    var ur: JSONNull?
    var hiddenAttributes: [String]?
    var committedAttributes: SearchCertificateCommittedAttributes?

    enum CodingKeys: String, CodingKey {
        case u, ur
        case hiddenAttributes = "hidden_attributes"
        case committedAttributes = "committed_attributes"
    }
}

// MARK: - SearchCertificateCommittedAttributes
struct SearchCertificateCommittedAttributes: Codable {
}

// MARK: - SearchCertificateBlindedMSCorrectnessProof
struct SearchCertificateBlindedMSCorrectnessProof: Codable {
    var c, vDashCap: String?
    var mCaps: SearchCertificateMCaps?
    var rCaps: SearchCertificateCommittedAttributes?

    enum CodingKeys: String, CodingKey {
        case c
        case vDashCap = "v_dash_cap"
        case mCaps = "m_caps"
        case rCaps = "r_caps"
    }
}

// MARK: - SearchCertificateMCaps
struct SearchCertificateMCaps: Codable {
    var masterSecret: String?

    enum CodingKeys: String, CodingKey {
        case masterSecret = "master_secret"
    }
}

// MARK: - SearchCertificateCredentialRequestMetadata
struct SearchCertificateCredentialRequestMetadata: Codable {
    var masterSecretBlindingData: SearchCertificateMasterSecretBlindingData?
    var nonce, masterSecretName: String?

    enum CodingKeys: String, CodingKey {
        case masterSecretBlindingData = "master_secret_blinding_data"
        case nonce
        case masterSecretName = "master_secret_name"
    }
}

// MARK: - SearchCertificateMasterSecretBlindingData
struct SearchCertificateMasterSecretBlindingData: Codable {
    var vPrime: String?
    var vrPrime: JSONNull?

    enum CodingKeys: String, CodingKey {
        case vPrime = "v_prime"
        case vrPrime = "vr_prime"
    }
}

// MARK: - SearchCertificateRawCredential
struct SearchCertificateRawCredential: Codable {
    var schemaID, credDefID: String?
    var revRegID: JSONNull?
    var values: [String: Inner?]?
    var signature: SearchCertificateSignature?
    var signatureCorrectnessProof: SearchCertificateSignatureCorrectnessProof?
    var revReg, witness: JSONNull?

    enum CodingKeys: String, CodingKey {
        case schemaID = "schema_id"
        case credDefID = "cred_def_id"
        case revRegID = "rev_reg_id"
        case values
        case signature
        case signatureCorrectnessProof = "signature_correctness_proof"
        case revReg = "rev_reg"
        case witness
    }
}

// MARK: - SearchCertificateSignature
struct SearchCertificateSignature: Codable {
    var pCredential: SearchCertificatePCredential?
    var rCredential: JSONNull?

    enum CodingKeys: String, CodingKey {
        case pCredential = "p_credential"
        case rCredential = "r_credential"
    }
}

// MARK: - SearchCertificatePCredential
struct SearchCertificatePCredential: Codable {
    var m2, a, e, v: String?

    enum CodingKeys: String, CodingKey {
        case m2 = "m_2"
        case a, e, v
    }
}

// MARK: - SearchCertificateSignatureCorrectnessProof
struct SearchCertificateSignatureCorrectnessProof: Codable {
    var se, c: String?
}

class Inner: Codable {
    public let raw: String?
    public let encoded: String?
    
    enum CodingKeys: String, CodingKey {
        case raw
        case encoded
    }
    
//    required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        encoded = try? container.decodeIfPresent(String.self, forKey: .encoded)
//        raw = CodableUtils.decodeAsString(container: container, codingKey: .raw)
//    }
//    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//            try container.encodeIfPresent(self.encoded, forKey: .encoded)
//            try container.encodeIfPresent(self.raw, forKey: .raw)
//    }
}

// MARK: - CredentialDefModel
struct CredentialDefModel: Codable {
    let ver, id, schemaID, type: String?
    let tag: String?
    let value: CredentialDefModelValue?

    enum CodingKeys: String, CodingKey {
        case ver, id
        case schemaID = "schemaId"
        case type, tag, value
    }
}

// MARK: - CredentialDefModelValue
struct CredentialDefModelValue: Codable {
    let primary: CredentialDefModelPrimary?
    
    enum CodingKeys: String, CodingKey {
        case primary
    }
}

// MARK: - CredentialDefModelPrimary
struct CredentialDefModelPrimary: Codable {
    let n, s: String?
    let r: [String:String]?
    let rctxt, z: String?
    
    enum CodingKeys: String, CodingKey {
        case n,s,r,rctxt,z
    }
}



