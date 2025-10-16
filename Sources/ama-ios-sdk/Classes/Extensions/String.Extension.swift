//
//  String.Extension.swift
//  dataWallet
//
//  Created by sreelekh N on 15/10/21.
//

import Foundation
import UIKit

extension String {
    
    func CGFloatValue() -> CGFloat? {
        guard let doubleValue = Double(self) else {
            return nil
        }
        
        return CGFloat(doubleValue)
    }
    
    func localizedForSDK() -> String {
        return localized(using: nil, in: Constants.bundle)
    }
    
    var toUrl: URL {
        let query = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let fileUrl = URL(string: query)
        return fileUrl ?? URL(string: "")!
    }
    
    var toInt: Int {
        return Int(self) ?? 0
    }
    
    var trim: String {
        return self.trimmingCharacters(in: .whitespaces)
    }
    
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
    
    func camelCaseToWords() -> String {
        let betweenLowerAndUpper = "(?<=\\p{Ll})(?=\\p{Lu})"
        let beforeUpperAndLower = "(?<=\\p{L})(?=\\p{Lu}\\p{Ll})"
        let betweenLowerAndNumber = "(?<=\\p{Ll})(?=\\d)"
        
        let splitPattern = "\(betweenLowerAndUpper)|\(beforeUpperAndLower)|\(betweenLowerAndNumber)"
        
        let regex = try! NSRegularExpression(pattern: splitPattern, options: [])
        let range = NSRange(self.startIndex..., in: self)
        
        let modifiedString = regex
            .stringByReplacingMatches(in: self, options: [], range: range, withTemplate: " ")
        
        return modifiedString
    }
    
    func getImage( _ ifNotAvailable: String = "bellIcon") -> UIImage {
        if let customImage = UIImage(named: self) {
            return customImage
        } else if let systemImage = UIImage(systemName: self) {
            return systemImage
        }else if let sdK_image = UIImage.init(named: self, in: Constants.bundle, with: nil) {
            return sdK_image
        } else if let notSystem = UIImage(systemName: ifNotAvailable) {
            return notSystem
        } else if let notDevice = UIImage(named: ifNotAvailable) {
            return notDevice
        }
        return UIImage(named: "bellIcon") ?? UIImage()
    }
    
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }
    
    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }
    
    func substring(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    func stringByRemovingAll(characters: [Character]) -> String {
        return String.init(stringLiteral: (self.filter({ !characters.contains($0) })))
    }
    
    func stringByRemovingAll(subStrings: [String]) -> String {
        var resultString = self
        subStrings.forEach({ e in
            resultString = resultString.replacingOccurrences(of: e, with: "")})
        return resultString
    }
    
    /// Create `Data` from hexadecimal string representation
    ///
    /// This creates a `Data` object from hex string. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.
    
    var hexadecimal: Data? {
        var data = Data(capacity: count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        
        guard data.count > 0 else { return nil }
        
        return data
    }
    
    func formatedFor(stride: SeparateFor, separator: String = " ") -> String {
        return enumerated().map { $0.isMultiple(of: stride.rawValue) && ($0 != 0) ? "\(separator)\($1)" : String($1) }.joined()
    }
}

enum SeparateFor: Int {
    case aadhar = 4
    case pincode = 3
}

// Mark: EBSI
extension String {
    
    func getPath(of: String) -> String? {
        if let successValue = URLComponents(string: self)?.queryItems?.first(where: { $0.name == of })?.value {
            print("Value of success: \(successValue)")
            return successValue
        } else {
            print("Key success not found")
            return nil
        }
    }
    
    private func base64StringWithPadding(encodedString: String) -> String {
        var stringTobeEncoded = encodedString.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddingCount = encodedString.count % 4
        for _ in 0..<paddingCount {
            stringTobeEncoded += "="
        }
        return stringTobeEncoded
    }
    
    func decodeJWTPart() -> [String: Any]? {
        let payloadPaddingString = base64StringWithPadding(encodedString: self)
        guard let payloadData = Data(base64Encoded: payloadPaddingString) else {
            fatalError("payload could not converted to data")
        }
        return try? JSONSerialization.jsonObject(
            with: payloadData,
            options: []) as? [String: Any]
    }
}

extension String {

    func base64urlToBase64() -> String {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }
}

