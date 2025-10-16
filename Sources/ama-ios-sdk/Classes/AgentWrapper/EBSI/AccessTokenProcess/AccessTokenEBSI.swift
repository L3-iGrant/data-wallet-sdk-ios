//
//  AccessTokenEBSI.swift
//  dataWallet
//
//  Created by sreelekh N on 14/07/22.
//

import Foundation
import web3swift
import Base58Swift
import JOSESwift
import CryptoKit
import CommonCrypto
import CoreMedia
import secp256k1
import Web3Core
//import secp256k1Swift

struct AccessTokenStatic {
    static let proofType = "EcdsaSecp256k1Signature2019"
    static let proofPurpose = "assertionMethod"
    static let dollar = "$"
    static let walletPassword = "igrant_datawallet"
    static let request = "request"
    static let clientId = "client_id"
    static let vPresentation = "VerifiablePresentation"
    static let jwt = "JWT"
    static let alg = "ES256K"
    static let k1 = "secp256k1"
}

struct AccessTokenStaticPointers {
    static let iat = Date().epochTime
    static let iat300 = (Date().epochTime.toInt + 300).toString
    static let iat8601 = Date().epochTimeISO8601
    static let headerKidUrl = "https://api.conformance.intebsi.xyz/did-registry/v2/identifiers/$#key-1"
    static let verificationEbsi = "$#key-1"
}

struct FormJwtPass {
    let did: String?
    let iss: String?
    let verifiableCredential: VerifiableCredential?
    let redirectUri: String?
    let wallet: Wallet?
    let token: String?
}

final class AccessTokenEBSI {
    
    private var passedData: FormJwtPass?
    var client: AccessTokenEBSIClientProtocol?
    
    init(client: AccessTokenEBSIClientProtocol = AccessTokenEBSIClient()) {
        self.client = client
    }
    
    func formJwtSignature(data: FormJwtPass) {
        //Create Verifiable Presentation from Verifiable Authorization
        passedData = data
        Task {
//            3.1 POST /authentication-requests
        let (client_id,parts) = await self.authenticationRequests()
            guard parts?.count == 3 else { return}
            let payloadJWT = parts?[1]
            guard let jsonPayload = payloadJWT?.decodeJWTPart(), let iss = jsonPayload["iss"] as? String else { return}
            
        let createHeader = CreateHeaderJWT(alg: AccessTokenStatic.alg,
                                     typ: AccessTokenStatic.jwt,
                                     kid: AccessTokenStaticPointers.headerKidUrl.replacingOccurrences(of: AccessTokenStatic.dollar, with: data.did ?? ""))
        
        var verifiableCredential: [VerifiableCredential] = []
        if let val = data.verifiableCredential {
            verifiableCredential.append(val)
        }
        
        let payload = CreatePayloadJWT(iat: AccessTokenStaticPointers.iat,
                                       exp: AccessTokenStaticPointers.iat300,
                                       iss: iss,
                                       context: ["https://www.w3.org/2018/credentials/v1"],
                                       type: AccessTokenStatic.vPresentation,
                                       verifiableCredential: verifiableCredential,
                                       holder: data.did)
        
        let jws = self.getJwtSignature(header: createHeader, payload: payload)
        let proof = self.constructProof(jws: jws)
        let verifiablePresentation = VerifiablePresentation(context: ["https://www.w3.org/2018/credentials/v1"],
                                                            type: AccessTokenStatic.vPresentation,
                                                            verifiableCredential: verifiableCredential,
                                                            holder: data.did,
                                                            proof: proof)
        
        print(jws)
        print(proof)
        print(verifiablePresentation)
        
            
            //3.3 Create Authentication Response
            let jwt = self.createAuthenticationResponse(authRequest: parts ?? [], verifiablePresentation: verifiablePresentation)
           
            //Header
            let header = JWTHeader.init(alg: "ES256K", typ: "JWT", kid: "\(passedData?.did ?? "")#key-1")
            let token = EBSIUtils.signAndCreateJWTToken(payloadDict: jwt, header: header, privateKey: getPrivateKey()) ?? ""
            let verifyResponse = await client?.getAuthenticationResponse(bearerToken: passedData?.token ?? "", jwtToken: token, endPoint: client_id ?? "")
            
            debugPrint(verifyResponse)
        }
       
    }
    
    private func authenticationRequests() async -> (String?,[String]?)  {
            let authResponse = await client?.getAuthenticationRequests(token: passedData?.token ?? "")
            switch authResponse {
            case .success(let data):
                guard let request = data?.uri?.getPath(of: AccessTokenStatic.request) else { return (nil,nil)}
                guard let client_id = data?.uri?.getPath(of: AccessTokenStatic.clientId) else { return (nil,nil)}

                let parts = request.components(separatedBy: ".")
                guard parts.count == 3 else { return (nil,nil)}
                let payload = parts[1]
                guard let jsonPayload = payload.decodeJWTPart(), let iss = jsonPayload["iss"] as? String else { return (nil,nil) }
                self.verifyAuthenticationRequest(iss: iss, parts: parts)
                return (client_id,parts)
            default:
                return (nil,nil)
                break
        }
    }
    
    private func verifyAuthenticationRequest(iss: String, parts: [String]) {
        Task {
            let verifyResponse = await client?.verifyAuthenticationRequests(did: iss)
            switch verifyResponse {
            case .success(let data):
                guard let method = data?.verificationMethod?.first else { return }
                self.verifyRequestOfJwt(curve: method)
            default:
                break
            }
        }
    }
    
    private func verifyRequestOfJwt(curve: VerificationMethod) {
        
//        let jwk = try? ECPublicKey.init(crv: ECCurveType., x: curve.publicKeyJwk?.x, y: curve.publicKeyJwk?.y)
//        let publicKey = try! secp256k1.Recovery.PublicKey(messageData, signature: recoverySignature)
        
//        let json = cko
//        var success: Bool

            // We have the following x and y values in base64 (for an EC point on the P-256 curve).
//            var x: String? = "Dn7uB1O7kgk74G6qfQwFJESeDnxO6lLjGZFWZJE16tw"
//            var y: String? = "iOWA5DInzK6nuUGvHJbMVq1Dpj248FqSV2teN3HzmhU"

            // Build a JWK that looks like this:

            // {
            //   "kty": "EC",
            //   "crv": "P-256",
            //   "x": "Dn7uB1O7kgk74G6qfQwFJESeDnxO6lLjGZFWZJE16tw",
            //   "y": "iOWA5DInzK6nuUGvHJbMVq1Dpj248FqSV2teN3HzmhU"
            // }

            //let json = CKOperation
//            json.update("kty", value: "EC")
//            json.update("crv", value: "P-256")
//            json.update("x", value: x)
//            json.update("y", value: y)

//            // Load from the JWK.
//            let pubkey = CkoPublicKey()!
//            success = pubkey.load(from: json.emit())
//            if success == false {
//                print("\(pubkey.lastErrorText!)")
//                return
//            }
//
//            print("Success.")
        
        
    }
    
    private func getJwtSignature(header: CreateHeaderJWT, payload: CreatePayloadJWT) -> String {
        guard let headerData = try? JSONEncoder().encode(header), let payloadData = try? JSONEncoder().encode(payload) else { return "" }
        let signingInput = headerData.urlSafeBase64EncodedString() + "." + payloadData.urlSafeBase64EncodedString()
        let msg = [UInt8](signingInput.data(using: .utf8) ?? Data())
        let privkey = [UInt8](getPrivateKey() ?? Data())
        let privateKey = try? secp256k1.Signing.PrivateKey(rawRepresentation: privkey)
        let signature = try? privateKey?.ecdsa.signature(for: msg)
        let signaturePart = (try? signature?.compactRepresentation.urlSafeBase64EncodedString()) ?? ""
        let jws = signingInput + "." + signaturePart
        return jws
    }
    
    private func constructProof(jws: String) -> ProofEncodable {
        let proof = ProofEncodable(type: AccessTokenStatic.proofType,
                                   created: AccessTokenStaticPointers.iat8601,
                                   proofPurpose: AccessTokenStatic.proofPurpose,
                                   verificationMethod: AccessTokenStaticPointers.verificationEbsi.replacingOccurrences(of: AccessTokenStatic.dollar, with: passedData?.did ?? ""),
                                   jws: jws)
        return proof
    }
    
    private func getPrivateKey() -> Data? {
        guard let wallet = passedData?.wallet else { return nil }
        let data = wallet.data
        let keystoreManager: KeystoreManager
        if wallet.isHD {
            let keystore = BIP32Keystore(data)!
            keystoreManager = KeystoreManager([keystore])
        } else {
            let keystore = EthereumKeystoreV3(data)!
            keystoreManager = KeystoreManager([keystore])
        }
        let password = AccessTokenStatic.walletPassword
        guard let ethereumAddress = EthereumAddress(wallet.address) else { return nil }
        do {
            let pkData = try keystoreManager.UNSAFE_getPrivateKeyData(password: password, account: ethereumAddress)
            return pkData
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    private func createAuthenticationResponse(authRequest: [String], verifiablePresentation: VerifiablePresentation) -> JWTPayload {
        let payload = authRequest[safe: 1] ?? ""
        let dict = UIApplicationUtils.shared.convertToDictionary(text: payload.decodeBase64() ?? "")
        let exp = Double(dict?["exp"] as? Int ?? 0)
        let redirectUri = dict?["redirect_uri"] as? String ?? ""
        let iat = Date().epochTime
        var jwk = getECPublicKey(did: passedData?.did ?? "")?.parameters
        jwk?["crv"] = "secp256k1"
        let jwt_thumbprint = getThumbprint(did: passedData?.did ?? "") ?? ""
        let verifiablePresentationDict = verifiablePresentation.dictionary ?? [:]
        let verifiablePresentationJSON = try? JSONSerialization.data(withJSONObject: verifiablePresentationDict, options: .sortedKeys)
        let subJWKModel = SubJwk.init(crv: jwk?["crv"], kid: jwk?["kid"], kty: jwk?["kty"], x: jwk?["x"], y: jwk?["y"])
        let authResponseModel = JWTPayload.init(aud: redirectUri, did: passedData?.did ?? "", exp: exp + (Double(iat) ?? 0), iat: iat, iss: "https://self-issued.me/v2", nonce: NSUUID().uuidString.lowercased(), sub: jwt_thumbprint, subJwk: subJWKModel,claims: Claims.init(encryption_key: SubJwk.init(crv: "secp256k1", kid: "", kty: "EC", x: jwk?["x"], y: jwk?["y"]), verified_claims: verifiablePresentationJSON?.urlSafeBase64EncodedString()))
        return authResponseModel
    }
    
    private func getThumbprint(did: String) -> String? {
        let publicKeyData = getPublicKey() ?? Data()
        let jwk = try? ECPublicKey.init(publicKey: publicKeyData)
        var param = jwk?.requiredParameters
        param?["crv"] = AccessTokenStatic.k1
        guard let json = try? JSONSerialization.data(withJSONObject: param, options: .sortedKeys) else {
            return nil
        }
        let thumbprint = try? Thumbprint.calculate(from: json, algorithm: .SHA256)
        return thumbprint
    }
    
    private func getPublicKey() -> Data?{
        let privateKey = getPrivateKey() ?? Data()
        let publicKey: Data? = nil
        return publicKey
    }
    
    private func getECPublicKey(did: String) -> ECPublicKey? {
        let publicKeyData = getPublicKey() ?? Data()
        let jwk = try? ECPublicKey.init(publicKey: publicKeyData, additionalParameters: [
            "kid": "\(passedData?.did ?? "")#key-1",
        ])
        debugPrint(jwk)
        return jwk
    }

}
