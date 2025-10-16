//
//  EncryptionKeyBuilder.swift
//  ama-ios-sdk
//
//  Created by iGrant on 31/07/25.
//

import Foundation
import CryptoKit
import JOSESwift
import CryptoSwift
import eudiWalletOidcIos

public class EncryptionKeyBuilder {
    
    func build(issuerConfig: IssuerWellKnownConfiguration?) -> (ECPrivateKey?, String?, String?){
        let privateKey1 = P256.KeyAgreement.PrivateKey()
        guard let privateKey = convertToJOSESwiftKey(cryptoKitPrivateKey: privateKey1) else {
            print("Failed to convert to JOSESwift key")
            return (nil, nil, nil)
        }
        return (privateKey, issuerConfig?.credentialResponseEncryption?.algValuesSupported?.first, issuerConfig?.credentialResponseEncryption?.encValuesSupported?.first)
    }

    private func convertToJOSESwiftKey(cryptoKitPrivateKey: P256.KeyAgreement.PrivateKey) -> ECPrivateKey? {
    // Extract raw private key bytes (32 bytes for P-256)
    let rawPrivateKey = cryptoKitPrivateKey.rawRepresentation
    
    // Extract public key components
    let publicKey = cryptoKitPrivateKey.publicKey
    let publicKeyRaw = publicKey.x963Representation
    guard publicKeyRaw.count == 65 else {
        print("Unexpected key size")
        return nil
    }
    
    let xBytes = publicKeyRaw[1...32]
    let yBytes = publicKeyRaw[33...64]
    // Create ECPrivateKeyComponents
    do {
        return try ECPrivateKey(crv: "P-256", x: Data(xBytes).base64URLEncodedString(), y: Data(yBytes).base64URLEncodedString(), privateKey: rawPrivateKey.base64URLEncodedString())
    } catch {
        print("Failed to create JOSESwift private key: \(error)")
        return nil
    }
}
}
