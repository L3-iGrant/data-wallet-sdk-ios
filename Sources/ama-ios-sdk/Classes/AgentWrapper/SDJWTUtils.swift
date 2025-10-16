//
//  SDJWTUtils.swift
//  ama-ios-sdk
//
//  Created by iGrant on 01/08/25.
//

import Foundation
import CryptoKit

class SDJWTUtils {
    public static var shared = SDJWTUtils()
    
    func updateIssuerJwtWithDisclosures(credential: String?) -> String? {
        guard let split = credential?.split(separator: "."), split.count > 1,
              let jsonString = "\(split[1])".decodeBase64(),
              let jsonObject = UIApplicationUtils.shared.convertStringToDictionaryAny(text: jsonString) else { return nil }
        
        var object = jsonObject
        
        var hashList: [String] = []
        let disclosures = getDisclosuresFromSDJWT(credential) ?? []
        disclosures.forEach { encodedString in
            guard let hash = calculateSHA256Hash(inputString: encodedString) else { return }
            hashList.append(hash)
        }
        
        object = addDisclosuresToCredential(jsonElement: jsonObject, disclosures: disclosures, hashList: hashList)
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: object) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
    
    private func addDisclosuresToCredential(jsonElement: [String: Any], disclosures: [String], hashList: [String]) -> [String: Any] {
        var modifiedJsonElement = jsonElement
        
        if modifiedJsonElement["_sd"] != nil {
            guard let sdList = modifiedJsonElement["_sd"] as? [String] else { return [:] }
            for (index, hash) in hashList.enumerated() {
                if isStringPresentInJSONArray(jsonArray: sdList, searchString: hash) {
                    
                    if let disclosure = disclosures[index].decodeBase64() {
                        let (decodedKey, decodedValue) = extractKeyValue(from: disclosure) ?? ("","" as Any)
                        if let decodedValue = decodedValue as? [String: Any] {
                            modifiedJsonElement[decodedKey] = decodedValue as Any
                        } else if let decodedValue = decodedValue as? [Any] {
                            modifiedJsonElement[decodedKey] = decodedValue as Any
                        } else {
                            modifiedJsonElement[decodedKey] = decodedValue
                        }
                    }
                  }
               }
            }
    
        for (key, value) in modifiedJsonElement {
            if(value is [String: Any]){
                modifiedJsonElement[key] = addDisclosuresToCredential(jsonElement: value as! [String : Any], disclosures: disclosures, hashList: hashList)
            }
        }
        
        return modifiedJsonElement
    }
    

    private func isStringPresentInJSONArray(jsonArray: [String], searchString: String) -> Bool {
        for element in jsonArray {
            if element == searchString {
                 return true
            }
        }
        return false
    }
    
    private func extractKeyValue(from decodedString: String) -> (String, Any)? {
        guard let jsonArray = try? JSONSerialization.jsonObject(with: Data(decodedString.utf8)) as? [Any],
                      jsonArray.count >= 3,
                      let key = jsonArray[1] as? String,
                      let value = jsonArray[2] as? Any else {
            return nil
            }
         return (key, value)
    }
    
    private func getDisclosuresFromSDJWT(_ credential: String?) -> [String]? {
        guard let split = credential?.split(separator: "~"), split.count > 1 else {
            return []
        }
        return split.dropFirst().map { String($0) }
    }
    
    private func getIssuerJwtFromSDJWT(_ credential: String?) -> String? {
        guard let split = credential?.split(separator: "~"), let first = split.first else {
            return nil
        }
        return String(first)
    }
    
    public func calculateSHA256Hash(inputString: String?) -> String? {
        guard let inputString = inputString,
              let inputData = inputString.data(using: .utf8) else {
            return nil
        }
        
        // Compute the SHA-256 hash
        let sha256Digest = SHA256.hash(data: inputData)
        
        // Encode the hash using base64url encoding
        let base64EncodedHash = Data(sha256Digest).base64EncodedString()
        let base64urlEncodedHash = base64EncodedHash
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
        
        return base64urlEncodedHash
    }
}
