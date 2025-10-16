//
//  EBSI_Utils.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 31/07/22.
//

import Foundation
import secp256k1

struct EBSIUtils {
    static let shared = EBSIUtils()
    private init() {}
    
    static func signAndCreateJWTToken(payloadDict: JWTPayload,header: JWTHeader, privateKey: Data?) -> String? {
        //SigningInput
        do {
            let payloadData = try JSONEncoder().encode(payloadDict)
            let headerData = try JSONEncoder().encode(header)
            let id_token_part_a = headerData.urlSafeBase64EncodedString() + "." + (payloadData.urlSafeBase64EncodedString())
            
            //Signing
            let msg = [UInt8](id_token_part_a.data(using: .utf8) ?? Data())
            let privkey = [UInt8](privateKey ?? Data())
            let privateKey = try secp256k1.Signing.PrivateKey(rawRepresentation: privkey)
            let signature = try privateKey.ecdsa.signature(for: msg)
            let id_token_part_b = (try signature.compactRepresentation.urlSafeBase64EncodedString()) ?? ""
            let id_token = id_token_part_a + "." + (id_token_part_b )
            return id_token
        } catch {
            debugPrint("EBSI - Signing Error -- " + error.localizedDescription)
            return nil
        }
    }
    
    static func signAndCreateJWTToken(payloadDict: [String: Any],header: [String: Any], privateKey: Data?) -> String? {
        //SigningInput
        do {
            let payloadData = payloadDict.toString()?.utf8Encoded ?? Data()
            let headerData = header.toString()?.utf8Encoded ?? Data()
            let id_token_part_a = headerData.urlSafeBase64EncodedString() + "." + (payloadData.urlSafeBase64EncodedString())
            
            //Signing
            let msg = [UInt8](id_token_part_a.data(using: .utf8) ?? Data())
            let privkey = [UInt8](privateKey ?? Data())
            let privateKey = try secp256k1.Signing.PrivateKey(rawRepresentation: privkey)
            let signature = try privateKey.ecdsa.signature(for: msg)
            let id_token_part_b = (try signature.compactRepresentation.urlSafeBase64EncodedString()) ?? ""
            let id_token = id_token_part_a + "." + (id_token_part_b )
            return id_token
        } catch {
            debugPrint("EBSI - Signing Error -- " + error.localizedDescription)
            return nil
        }
    }
    
}
