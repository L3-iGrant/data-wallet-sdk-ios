//
//  TrustMechanismManager.swift
//  dataWallet
//
//  Created by iGrant on 18/06/25.
//

import Foundation
import eudiWalletOidcIos
import SwiftCBOR
import CryptoKit
import Security
import ASN1Decoder
import CommonCrypto
import X509
import Crypto
import SwiftASN1
import BigInt

class TrustMechanismManager {
    
    let url = "https://ewc-consortium.github.io/ewc-trust-list/EWC-TL"
    let fallbackUrl = "https://raw.githubusercontent.com/decentralised-dataexchange/ewc-trust-list/refs/heads/main/EWC-TL.xml"
    
    func extractX5cFromCredential(data: String?) -> [String]? {
        let credSegments = data?.split(separator: ".")
        var x5c: [String]? = nil
        if credSegments?.count ?? 0 > 1 {
            let jsonString = "\(credSegments?[0] ?? "")".decodeBase64() ?? ""
            let jsonObject = UIApplicationUtils.shared.convertStringToDictionary(text: jsonString)
            x5c = jsonObject?["x5c"] as? [String]
        }
        return x5c
    }
    
    func extractDidOrKidFromCredential(data: String?) -> (String?, String?) {
        let credSegments = data?.split(separator: ".")
        var kid: String? = nil
        var did: String? = nil
        var credentialFilter: String?
        if credSegments?.count ?? 0 > 1 {
            let jsonString = "\(credSegments?[0] ?? "")".decodeBase64() ?? ""
            let jsonObject = UIApplicationUtils.shared.convertStringToDictionary(text: jsonString)
            if let data =  jsonObject?["kid"] as? String {
                credentialFilter = data
            } else if let data = jsonObject?["did"] as? String {
                credentialFilter = data
            }
        }
        if credentialFilter?.hasPrefix("did") == true {
            did = credentialFilter
        } else {
            kid = credentialFilter
        }
        return (kid, did)
    }
    
    
    
    func trustProviderInfo(credential: String?, format: String?, jwksURI: String?, completion: @escaping (TrustServiceProvider?) -> Void) {
        var x5cData: [String]?
        var kid: String?
        var did: String?
        let credentialCount = credential?.split(separator: ".")

        if credentialCount?.count == 1 {
            guard let issuerAuthData = MDocVpTokenBuilder().getIssuerAuth(credential: credential ?? "") else {
                completion(nil)
                return
            }
            x5cData = extractX5cFromIssuerAuth1(issuerAuth: issuerAuthData)
            (kid, did) = extractKidOrDidFromIssuerAuth(issuerAuth: issuerAuthData)
        } else {
            x5cData = extractX5cFromCredential(data: credential)
            (kid, did) = extractDidOrKidFromCredential(data: credential)
        }

        guard x5cData != nil || kid != nil || did != nil else {
            completion(nil)
            return
        }
        
        var completionCalled = false
        
        func safeComplete(_ result: TrustServiceProvider?) {
            guard !completionCalled else { return }
            completionCalled = true
            completion(result)
        }
        
        fetchTrustDetails(url: url, x5cList: x5cData, kid: kid, did: did, jwksURI: jwksURI) { result in
                if result != nil {
                    safeComplete(result)
                } else {
                    // Fallback to secondary URL if primary fails
                    self.fetchTrustDetails(url: self.fallbackUrl, x5cList: x5cData, kid: kid, did: did, jwksURI: jwksURI) { fallbackResult in
                        safeComplete(fallbackResult)
                    }
                }
            }
    }
    
    
    private func fetchTrustDetails(url: String,
                                   x5cList: [String]?,
                                   kid: String?,
                                   did: String?,
                                   jwksURI: String?,
                                   completion: @escaping (TrustServiceProvider?) -> Void) {
        
        var results: [TrustServiceProvider] = []
        let dispatchGroup = DispatchGroup()

        func processX5CSerially(index: Int) {
            guard let x5cList = x5cList, index < x5cList.count else {
                processKidDid()
                return
            }

            let cert = x5cList[index]

            fetchCertificateWithFallback(certificate: cert, jwksURI: jwksURI) { result in
                if let result = result {
                    results.append(result)
                }
                processX5CSerially(index: index + 1)
            }
        }

        func processKidDid() {
            if let kid = kid {
                dispatchGroup.enter()
                TrustMechanismService.shared.fetchTrustDetails(url: url, x5c: kid, jwksURI: jwksURI) { trustDetails in
                    defer { dispatchGroup.leave() }
                    if let trustDetails = trustDetails {
                        results.append(trustDetails)
                    }
                }
            }

            if let did = did {
                dispatchGroup.enter()
                TrustMechanismService.shared.fetchTrustDetails(url: url, x5c: did, jwksURI: jwksURI) { trustDetails in
                    defer { dispatchGroup.leave() }
                    if let trustDetails = trustDetails {
                        results.append(trustDetails)
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(results.first)
            }
        }

        processX5CSerially(index: 0)
    }
    
    private func fetchCertificateWithFallback(certificate: String,
                                              jwksURI: String?,
                                              completion: @escaping (TrustServiceProvider?) -> Void) {
        fetchTrustForCertificate(url: url, certificate: certificate, jwksURI: jwksURI) { result in
            if let result = result {
                completion(result)
            } else {
                // Fallback URL
                self.fetchTrustForCertificate(url: self.fallbackUrl, certificate: certificate, jwksURI: jwksURI) { fallbackResult in
                    completion(fallbackResult)
                }
            }
        }
    }
    
    private func fetchTrustForCertificate(url: String,
                                          certificate: String,
                                          jwksURI: String?,
                                          completion: @escaping (TrustServiceProvider?) -> Void) {
        
        TrustMechanismService.shared.fetchTrustDetails(url: url, x5c: certificate, jwksURI: jwksURI) { directResult in
            if let directResult = directResult {
                completion(directResult)
                return
            }

            // Try SKI
            guard let ski = X509SkiGeneratorHelper.generateSKI(from: certificate) else {
                completion(nil)
                return
            }

            TrustMechanismService.shared.fetchTrustDetails(url: url, x5c: ski, jwksURI: jwksURI) { skiResult in
                if let skiResult = skiResult {
                    completion(skiResult)
                    return
                }

                // Try public key
                guard let pubKey = X509SkiGeneratorHelper.extractBase64PublicKey(from: certificate) else {
                    completion(nil)
                    return
                }

                TrustMechanismService.shared.fetchTrustDetails(url: url, x5c: pubKey, jwksURI: jwksURI) { pubKeyResult in
                    completion(pubKeyResult)
                }
            }
        }
    }
    
    func isIssuerOrVerifierTrusted(credential: String?, format: String? = nil, jwksURI: String?, completion: @escaping (Bool?) -> Void) {

        var x5cData: [String]?
        var kid: String?
        var did: String?
        let credentialCount = credential?.split(separator: ".")

        if credentialCount?.count == 1 {
            guard let issuerAuthData = MDocVpTokenBuilder().getIssuerAuth(credential: credential ?? "") else {
                completion(nil)
                return
            }
            x5cData = extractX5cFromIssuerAuth1(issuerAuth: issuerAuthData)
            (kid, did) = extractKidOrDidFromIssuerAuth(issuerAuth: issuerAuthData)
        } else {
            x5cData = extractX5cFromCredential(data: credential)
            (kid, did) = extractDidOrKidFromCredential(data: credential)
        }

        guard x5cData != nil || kid != nil || did != nil else {
            completion(nil)
            return
        }

        var completionCalled = false
        func safeComplete(_ result: Bool?) {
            guard !completionCalled else { return }
            completionCalled = true
            completion(result)
        }
        
        validateIdentifiers(url: url, x5cList: x5cData, kid: kid, did: did, jwksURI: jwksURI) { result in
               if result == true {
                   safeComplete(true)
               } else {
                   // Fallback to secondary URL if primary fails
                   self.validateIdentifiers(url: self.fallbackUrl, x5cList: x5cData, kid: kid, did: did, jwksURI: jwksURI) { fallbackResult in
                       safeComplete(fallbackResult)
                   }
               }
           }

//        func checkTrustListValidity(urlToUse: String, x5cList: [String], jwksURI: String?, completion: @escaping (Bool?) -> Void) {
//            let innerGroup = DispatchGroup()
//            var validationResults: [Bool] = []
//
//            for item in x5cList {
//                innerGroup.enter()
//                TrustMechanismService.shared.isIssuerOrVerifierTrusted(url: urlToUse, x5c: item, jwksURI: jwksURI) { isValid in
//                    defer { innerGroup.leave() }
//                    if let isValid = isValid {
//                        validationResults.append(isValid)
//                    }
//
//                    guard let ski = X509SkiGeneratorHelper.generateSKI(from: item) else {
//                        return
//                    }
//
//                    innerGroup.enter()
//                    TrustMechanismService.shared.isIssuerOrVerifierTrusted(url: urlToUse, x5c: ski, jwksURI: jwksURI) { skiResult in
//                        defer { innerGroup.leave() }
//                        if let skiResult = skiResult {
//                            validationResults.append(skiResult)
//                            return
//                        }
//
//                        guard let publicKey = X509SkiGeneratorHelper.extractBase64PublicKey(from: item) else {
//                            return
//                        }
//
//                        innerGroup.enter()
//                        TrustMechanismService.shared.isIssuerOrVerifierTrusted(url: urlToUse, x5c: publicKey, jwksURI: jwksURI) { pubKeyResult in
//                            defer { innerGroup.leave() }
//                            if let pubKeyResult = pubKeyResult {
//                                validationResults.append(pubKeyResult)
//                            }
//                        }
//                    }
//                }
//            }
//
//            innerGroup.notify(queue: .main) {
//                if validationResults.isEmpty {
//                    completion(nil)
//                } else {
//                    completion(validationResults.contains(true))
//                }
//            }
//        }
//
//        checkTrustListValidity(urlToUse: url, x5cList: x5cData ?? [], jwksURI: jwksURI) { result in
//            if let result = result, result == true {
//                safeComplete(true)
//            } else {
//                // Step 2: Try fallback URL
//                checkTrustListValidity(urlToUse: self.fallbackUrl, x5cList: x5cData ?? [], jwksURI: jwksURI) { fallbackResult in
//                    safeComplete(fallbackResult)
//                }
//            }
//        }
    }
    
    private func validateIdentifiers(url: String,
                                   x5cList: [String]?,
                                   kid: String?,
                                   did: String?,
                                   jwksURI: String?,
                                   completion: @escaping (Bool?) -> Void) {
        let group = DispatchGroup()
        var validationResults: [Bool] = []
        
        // Validate x5c certificates
        if let x5cList = x5cList {
            for cert in x5cList {
                validateCertificate(url: url, certificate: cert, jwksURI: jwksURI, group: group) { result in
                    if let result = result { validationResults.append(result) }
                }
            }
        }
        
        // Validate kid if present
        if let kid = kid {
            group.enter()
            TrustMechanismService.shared.isIssuerOrVerifierTrusted(url: url, x5c: kid, jwksURI: jwksURI) { result in
                defer { group.leave() }
                if let result = result { validationResults.append(result) }
            }
        }
        
        // Validate did if present
        if let did = did {
            group.enter()
            TrustMechanismService.shared.isIssuerOrVerifierTrusted(url: url, x5c: did, jwksURI: jwksURI) { result in
                defer { group.leave() }
                if let result = result { validationResults.append(result) }
            }
        }
        
        group.notify(queue: .main) {
            completion(validationResults.contains(true) ? true : false)
        }
    }

    private func validateCertificate(url: String,
                                    certificate: String,
                                    jwksURI: String?,
                                    group: DispatchGroup,
                                    completion: @escaping (Bool?) -> Void) {
        group.enter()
        TrustMechanismService.shared.isIssuerOrVerifierTrusted(url: url, x5c: certificate, jwksURI: jwksURI) { result in
            defer { group.leave() }
            if let result = result {
                completion(result)
                return
            }
            
            // If direct validation fails, try with SKI
            guard let ski = X509SkiGeneratorHelper.generateSKI(from: certificate) else {
                completion(nil)
                return
            }
            
            group.enter()
            TrustMechanismService.shared.isIssuerOrVerifierTrusted(url: url, x5c: ski, jwksURI: jwksURI) { skiResult in
                defer { group.leave() }
                if let skiResult = skiResult {
                    completion(skiResult)
                    return
                }
                
                // If SKI validation fails, try with public key
                guard let publicKey = X509SkiGeneratorHelper.extractBase64PublicKey(from: certificate) else {
                    completion(nil)
                    return
                }
                
                group.enter()
                TrustMechanismService.shared.isIssuerOrVerifierTrusted(url: url, x5c: publicKey, jwksURI: jwksURI) { pubKeyResult in
                    defer { group.leave() }
                    completion(pubKeyResult)
                }
            }
        }
    }
    
    func isIssuerOrVerifierTrustedAsync(credential: String?, format: String?, jwksURI: String?) async -> Bool? {
        return await withCheckedContinuation { continuation in
            self.isIssuerOrVerifierTrusted(credential: credential, format: format, jwksURI: jwksURI) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func extractX5cFromIssuerAuth1(issuerAuth: CBOR) -> [String]? {
        var certs: [String] = []

        guard case let CBOR.array(coseArray) = issuerAuth,
              coseArray.count >= 2 else {
            print("Invalid COSE_Sign1 structure")
            return nil
        }
        
        // The x5c is in the unprotected headers (second element)
        guard case let CBOR.map(unprotectedHeaders) = coseArray[1] else {
            print("No unprotected headers found")
            return nil
        }
        
        // Look for x5c in standard location (key 33)
        guard let x5cItem = unprotectedHeaders[CBOR.unsignedInt(33)] else {
            print("x5c not found in unprotected headers (key 33)")
            // Print all available headers for debugging
            print("Available unprotected headers:")
            for (key, _) in unprotectedHeaders {
                print("Key: \(key)")
            }
            return nil
        }
        // Handle array of items
        if case let CBOR.array(items) = x5cItem {
            for item in items {
                if case let CBOR.byteString(certData) = item {
                    certs.append(Data(certData).base64EncodedString())
                } else if case let CBOR.utf8String(certString) = item {
                    certs.append(certString)
                } else {
                    print("Unexpected x5c item format in array")
                    return nil
                }
            }
            return certs
        }

        // Handle single byteString
        if case let CBOR.byteString(certData) = x5cItem {
            certs.append(Data(certData).base64EncodedString())
            return certs
        }

        // Handle single utf8String
        if case let CBOR.utf8String(certString) = x5cItem,
           let certData = certString.data(using: .utf8) {
            certs.append(certData.base64EncodedString())
            return certs
        }

        // Fallback
        print("x5c item is not in expected format (array, byteString, or utf8String)")
        return nil
    }
    
    func extractKidOrDidFromIssuerAuth(issuerAuth: CBOR) -> (kid: String?, did: String?) {
        // issuerAuth is a COSE_Sign1 structure (array of 4 elements)
        guard case let CBOR.array(coseArray) = issuerAuth,
              coseArray.count >= 2 else {
            print("Invalid COSE_Sign1 structure")
            return (nil, nil)
        }
        
        // The headers are in the unprotected headers (second element)
        guard case let CBOR.map(unprotectedHeaders) = coseArray[1] else {
            print("No unprotected headers found")
            return (nil, nil)
        }
        
        var kid: String? = nil
        var did: String? = nil
        
        // Check for kid (key 4 in COSE)
        if let kidItem = unprotectedHeaders[CBOR.unsignedInt(4)] {
            switch kidItem {
            case .utf8String(let str):
                kid = str
            case .byteString(let bytes):
                kid = String(data: Data(bytes), encoding: .utf8)
            default:
                print("kid is in unexpected format")
            }
        }
        
        // Check for did (common location in some implementations)
        // Note: DID isn't standard in COSE, so implementations vary
        if let didItem = unprotectedHeaders[CBOR.utf8String("did")] {
            switch didItem {
            case .utf8String(let str):
                did = str
            case .byteString(let bytes):
                did = String(data: Data(bytes), encoding: .utf8)
            default:
                print("did is in unexpected format")
            }
        }
        
        // Alternative check for did in custom integer key (if used)
        if did == nil, let didItem = unprotectedHeaders[CBOR.unsignedInt(100)] { // Example custom key
            switch didItem {
            case .utf8String(let str):
                did = str
            case .byteString(let bytes):
                did = String(data: Data(bytes), encoding: .utf8)
            default:
                print("did is in unexpected format")
            }
        }
        
        return (kid, did)
    }

    
}

struct CertificateDetails {
    let subject: String
    let issuer: String
    let serialNumber: String
    let validFrom: String
    let validTo: String
    let authorityKeyIdentifier: String
    let subjectKeyIdentifier: String
    let sha256Fingerprint: String
}

func parseX509Certificate(base64String: String) -> CertificateDetails? {
    guard let certData = Data(base64Encoded: base64String),
          let certificate = try? Certificate(derEncoded: [UInt8](certData)) else {
        print("Invalid certificate")
        return nil
    }
    let subject = certificate.subject.description
    let issuer = certificate.issuer.description
    let serialNumber = hexSerialToDecimal(certificate.serialNumber.description.uppercased()) ?? ""
    let notBefore = certificate.notValidBefore
    let notAfter = certificate.notValidAfter
    
    let validFrom = notBefore.description
    let validTo = notAfter.description

    let subjectKeyId = certificate.extensions.first(where: { $0.oid == .init("2.5.29.14") })?.value.bytes
    let authorityKeyId = certificate.extensions.first(where: { $0.oid == .init("2.5.29.35") })?.value.bytes
    
    let subjectKeyHex = subjectKeyId?.map { String(format: "%02X", $0) }.joined() ?? "-"
    let authorityKeyHex = authorityKeyId?.map { String(format: "%02X", $0) }.joined() ?? "NA"

    let sha256Fingerprint = SHA256.hash(data: certData).compactMap { String(format: "%02X", $0) }.joined(separator: ":")

    return CertificateDetails(
        subject: subject,
        issuer: issuer,
        serialNumber: serialNumber,
        validFrom: validFrom,
        validTo: validTo,
        authorityKeyIdentifier: authorityKeyHex,
        subjectKeyIdentifier: subjectKeyHex,
        sha256Fingerprint: sha256Fingerprint
    )
}

func hexSerialToDecimal(_ hexString: String) -> String? {
    let paddedHexParts = hexString.split(separator: ":").map {
        $0.count == 1 ? "0\($0)" : String($0)
    }
    
    let cleanHex = paddedHexParts.joined()
    
    if let bigInt = BigInt(cleanHex, radix: 16) {
        return String(bigInt)
    }
    
    return nil
}


