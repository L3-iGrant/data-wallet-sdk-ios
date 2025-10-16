//
//  Data.Extension.swift
//  dataWallet
//
//  Created by sreelekh N on 15/10/21.
//

import Foundation
import CryptoKit

extension Data {
    func prettyPrintedJSONString() -> NSString {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return "nil" }
        return prettyPrintedString
    }
    
    func urlSafeBase64EncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    func symmetricKey() -> SymmetricKey?{
        let key = try? SymmetricKey.init(data: self)
        return key
    }
    
}

extension Data {
    /// Returns cryptographically secure random data.
    ///
    /// - Parameter length: Length of the data in bytes.
    /// - Returns: Generated data of the specified length.
    static func random(length: Int) throws -> Data {
        return Data((0 ..< length).map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
    }
}
