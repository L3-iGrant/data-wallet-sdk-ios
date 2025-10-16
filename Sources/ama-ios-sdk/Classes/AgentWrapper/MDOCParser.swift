//
//  MDOCParser.swift
//  dataWallet
//
//  Created by iGrant on 17/09/24.
//

import Foundation
//import MdocDataModel18013
//import OrderedCollections
import SwiftCBOR
//import AnyCodable
import eudiWalletOidcIos

class MDOCParser {
    
    static let shared = MDOCParser()
    
    // input will be the mdoc credential, output will be array of DWSection
    //for this case it will be one, the key will be u.europa.ec.eudi.pid.1
    func createSectionStruct(credential: String) -> [DWSection] {
        var sectionStruct: [DWSection] = []
        let sectionKeys = extractValues(credential: credential).1
        for key in sectionKeys {
            sectionStruct = [
                DWSection(title: key, key: "section1")
            ]
        }
        return sectionStruct
    }
    
    // input will be the mdoc credential, output will be array of IDCardAttributes
    func createAttributeList(credential: String) -> [IDCardAttributes] {
        var resultDict =  extractValues(credential: credential).0
        var attributeStruct: [IDCardAttributes] = []
        for (key, value) in resultDict {
            let valueString = value
            let schemeID = key
            let name = key.replacingOccurrences(of: "_", with: " ").capitalized
            attributeStruct.append(IDCardAttributes(name: name, value: valueString as? String, schemeID: schemeID))
        }
        return attributeStruct
    }
    
    //need to add the fuction for extracting the attributes from mdoc credential
    func extractValues(credential: String) -> ([String: Any], [String]) {
        if let data = Data(base64URLEncoded: credential) {
            do {
                // Decode the CBOR data into a generic CBOR object
                let decodedCBOR = try CBOR.decode([UInt8](data))
                if let dictionary = decodedCBOR {
                    
                    // Access the 'nameSpaces' key
                    if let nameSpacesValue = dictionary[CBOR.utf8String("nameSpaces")],
                       case let CBOR.map(nameSpaces) = nameSpacesValue {
                        
                        var resultDict: [String: Any] = [:]
                        var keysArray: [String] = []
                        // Loop through all the keys in 'nameSpaces'
                        for (key, namespaceValue) in nameSpaces {
                            if case let CBOR.utf8String(str) = key {
                                    keysArray.append(str)
                            }
                            // Access the specific key value array
                            if case let CBOR.array(orgValues) = namespaceValue {
                                // Iterate over the array of tagged ByteStrings
                                for value in orgValues {
                                    if case let CBOR.tagged(tag, taggedValue) = value, tag.rawValue == 24 {
                                        if case let CBOR.byteString(byteString) = taggedValue {
                                            // Convert ByteString to Data
                                            let data = Data(byteString)
                                            
                                            // Decode the inner CBOR data
                                            if let decodedInnerCBOR = try? CBOR.decode([UInt8](data)),
                                               case let CBOR.map(decodedMap) = decodedInnerCBOR {
                                                // Find 'elementIdentifier' and 'elementValue'
                                                if let identifier = decodedMap[CBOR.utf8String("elementIdentifier")],
                                                   let value = decodedMap[CBOR.utf8String("elementValue")],
                                                   case let CBOR.utf8String(identifierString) = identifier {
                                                    
                                                    // Add to result dictionary
                                                    resultDict[identifierString] = convertCBORValueToSwiftValue(value)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        return (resultDict, keysArray)
                    } else if let decodedCBOR = try? CBOR.decode([UInt8](data)),
                              case let CBOR.map(topLevel) = decodedCBOR,
                              let documentsArray = topLevel[CBOR.utf8String("documents")],
                              case let CBOR.array(documents) = documentsArray,
                              let firstDoc = documents.first,
                              case let CBOR.map(docMap) = firstDoc,
                              let issuerSignedMap = docMap[CBOR.utf8String("issuerSigned")],
                              case let CBOR.map(issuerSigned) = issuerSignedMap,
                              let nameSpacesValue = issuerSigned[CBOR.utf8String("nameSpaces")],
                              case let CBOR.map(nameSpaces) = nameSpacesValue {
                        
                        var resultDict: [String: Any] = [:]
                        var keysArray: [String] = []
                        
                        for (key, namespaceValue) in nameSpaces {
                            if case let CBOR.utf8String(str) = key {
                                    keysArray.append(str)
                                }
                            if case let CBOR.array(orgValues) = namespaceValue {
                                for value in orgValues {
                                    if case let CBOR.tagged(tag, taggedValue) = value, tag.rawValue == 24,
                                       case let CBOR.byteString(byteString) = taggedValue {
                                        
                                        let data = Data(byteString)
                                        if let decodedInnerCBOR = try? CBOR.decode([UInt8](data)),
                                           case let CBOR.map(decodedMap) = decodedInnerCBOR,
                                           let identifier = decodedMap[CBOR.utf8String("elementIdentifier")],
                                           let value = decodedMap[CBOR.utf8String("elementValue")],
                                           case let CBOR.utf8String(identifierString) = identifier {
                                            
                                            resultDict[identifierString] = convertCBORValueToSwiftValue(value)
                                        }
                                    }
                                }
                            }
                        }
                        
                        return (resultDict, keysArray)
                    } else {
                        print("Key 'nameSpaces' not found or not a valid map.")
                    }
                }
            } catch {
                print("Error decoding CBOR: \(error)")
            }
        }
        return ([:], [])
    }
    
    func extractPhotoIDSectionFromCbor(credential: String) -> (Iso23220?, Photoid?){
        if let data = Data(base64URLEncoded: credential) {
            do {
                let decodedCBOR = try CBOR.decode([UInt8](data))
                if let dictionary = decodedCBOR {
                    
                    if let nameSpacesValue = dictionary[CBOR.utf8String("nameSpaces")],
                       case let CBOR.map(nameSpaces) = nameSpacesValue {
                        
                        var photoID: Photoid?
                        var isoData: Iso23220?
                       
                        for (key, namespaceValue) in nameSpaces {
                            
                            if case let CBOR.array(orgValues) = namespaceValue {
                                for value in orgValues {
                                    if case let CBOR.tagged(tag, taggedValue) = value, tag.rawValue == 24 {
                                        if case let CBOR.byteString(byteString) = taggedValue {
                                            let data = Data(byteString)
                                            
                                            if let decodedInnerCBOR = try? CBOR.decode([UInt8](data)),
                                               case let CBOR.map(decodedMap) = decodedInnerCBOR {
                                                if let identifier = decodedMap[CBOR.utf8String("elementIdentifier")],
                                                   let value = decodedMap[CBOR.utf8String("elementValue")],
                                                   case let CBOR.utf8String(identifierString) = identifier {
                                                    
                                                    if case let CBOR.map(valueMap) = value {
                                                        var nestedDict: [String: Any] = [:]
                                                        for (keyData, valueData) in valueMap {
                                                            if case let CBOR.utf8String(keyString) = keyData {
                                                                nestedDict[keyString] = convertCBORValueToSwiftValue(valueData)
                                                            }
                                                        }
                                                        switch identifierString {
                                                        case "iso23220":
                                                            isoData = try? JSONDecoder().decode(Iso23220.self, from: JSONSerialization.data(withJSONObject: nestedDict))
                                                        case "photoid":
                                                            photoID = try? JSONDecoder().decode(Photoid.self, from: JSONSerialization.data(withJSONObject: nestedDict))
                                                        
                                                        default:
                                                            break
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        return (isoData, photoID)
                    } else {
                        print("Key 'nameSpaces' not found or not a valid map.")
                    }
                }
            } catch {
                print("Error decoding CBOR: \(error)")
            }
        }
        return (nil, nil)
    }
        
    func extractPDA1SectionsFromCbor(credential: String) -> (Section1?, Section2?, Section3?, Section4?, Section5?, Section6?) {
        if let data = Data(base64URLEncoded: credential) {
            do {
                let decodedCBOR = try CBOR.decode([UInt8](data))
                if let dictionary = decodedCBOR {
                    
                    if let nameSpacesValue = dictionary[CBOR.utf8String("nameSpaces")],
                       case let CBOR.map(nameSpaces) = nameSpacesValue {
                        
                        var section1: Section1?
                        var section2: Section2?
                        var section3: Section3?
                        var section4: Section4?
                        var section5: Section5?
                        var section6: Section6?
                        for (key, namespaceValue) in nameSpaces {
                            
                            if case let CBOR.array(orgValues) = namespaceValue {
                                for value in orgValues {
                                    if case let CBOR.tagged(tag, taggedValue) = value, tag.rawValue == 24 {
                                        if case let CBOR.byteString(byteString) = taggedValue {
                                            let data = Data(byteString)
                                            
                                            if let decodedInnerCBOR = try? CBOR.decode([UInt8](data)),
                                               case let CBOR.map(decodedMap) = decodedInnerCBOR {
                                                if let identifier = decodedMap[CBOR.utf8String("elementIdentifier")],
                                                   let value = decodedMap[CBOR.utf8String("elementValue")],
                                                   case let CBOR.utf8String(identifierString) = identifier {
                                                    
                                                    if case let CBOR.map(valueMap) = value {
                                                        var nestedDict: [String: Any] = [:]
                                                        for (keyData, valueData) in valueMap {
                                                            if case let CBOR.utf8String(keyString) = keyData {
                                                                nestedDict[keyString] = convertCBORValueToSwiftValue(valueData)
                                                            }
                                                        }
                                                        switch identifierString {
                                                        case "section1":
                                                            section1 = try? JSONDecoder().decode(Section1.self, from: JSONSerialization.data(withJSONObject: nestedDict))
                                                        case "section2":
                                                            section2 = try? JSONDecoder().decode(Section2.self, from: JSONSerialization.data(withJSONObject: nestedDict))
                                                        case "section3":
                                                            section3 = try? JSONDecoder().decode(Section3.self, from: JSONSerialization.data(withJSONObject: nestedDict))
                                                        case "section4":
                                                            section4 = try? JSONDecoder().decode(Section4.self, from: JSONSerialization.data(withJSONObject: nestedDict))
                                                        case "section5":
                                                            section5 = try? JSONDecoder().decode(Section5.self, from: JSONSerialization.data(withJSONObject: nestedDict))
                                                        case "section6":
                                                            section6 = try? JSONDecoder().decode(Section6.self, from: JSONSerialization.data(withJSONObject: nestedDict))
                                                        default:
                                                            break
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        return (section1, section2, section3, section4, section5, section6)
                    } else {
                        print("Key 'nameSpaces' not found or not a valid map.")
                    }
                }
            } catch {
                print("Error decoding CBOR: \(error)")
            }
        }
        return (nil, nil, nil, nil, nil, nil)
    }
    
    func convertCBORValueToSwiftValue(_ cborValue: CBOR) -> Any {
        switch cborValue {
        case .utf8String(let string):
            return string
        case .boolean(let bool):
            return bool
        case .unsignedInt(let uint):
            return uint
        case .negativeInt(let nint):
            return -Int(nint) - 1
        case .byteString(let bytes):
            return Data(bytes)
        case .array(let array):
            return array.map { convertCBORValueToSwiftValue($0) }
        case .map(let map):
            var result: [String: Any] = [:]
            for (key, value) in map {
                if case let CBOR.utf8String(keyString) = key {
                    result[keyString] = convertCBORValueToSwiftValue(value)
                }
            }
            return result
        case .tagged(let tag, let taggedValue):
            return convertCBORValueToSwiftValue(taggedValue)
        default:
            return convertCBORValueToSwiftValue(cborValue)
        }
    }
    
    
    func createMDOCCredential(customWalletModel: CustomWalletRecordCertModel, connectionModel: CloudAgentConnectionWalletModel, credential_cbor: String, format: String, accessToken: String, refreshToken: String, notificationEndPoint: String, notificationID: String, tokenEndPoint: String) {
        let sectionStruct = createSectionStruct(credential: credential_cbor)
        var docType = String()
        if let issuerAuth = MDocVpTokenBuilder().getIssuerAuth(credential: credential_cbor) {
            docType = MDocVpTokenBuilder().getDocTypeFromIssuerAuth(cborData: issuerAuth) ?? ""
        }
        if let title = sectionStruct.first?.title, title.contains("pda1") || docType.contains("pda1") {
            let section1 = extractPDA1SectionsFromCbor(credential: credential_cbor).0
            let section2 = extractPDA1SectionsFromCbor(credential: credential_cbor).1
            let section3 = extractPDA1SectionsFromCbor(credential: credential_cbor).2
            let section4 = extractPDA1SectionsFromCbor(credential: credential_cbor).3
            let section5 = extractPDA1SectionsFromCbor(credential: credential_cbor).4
            let section6 = extractPDA1SectionsFromCbor(credential: credential_cbor).5
            OpenIdPDA1Parser.shared.createPDA(section1, section2, section3, section4, section5, section6, customWalletModel, connectionModel, credential_cbor, format: format, accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: notificationID, tokenEndPoint: tokenEndPoint)
        } else if let title = sectionStruct.first?.title, title.contains("photoid") || docType.contains("photoid") {
            let isoSection = extractPhotoIDSectionFromCbor(credential: credential_cbor).0
            let photoIDSection = extractPhotoIDSectionFromCbor(credential: credential_cbor).1
            PhotoIDParser.shared.createPhotoID(dict: [:], customWalletModel: customWalletModel, credential_jwt: credential_cbor, format: format, connectionModel: connectionModel, accessToken: accessToken, refreshToken: refreshToken, notificationEndPoint: notificationEndPoint, notificationID: notificationID, tokenEndPoint: tokenEndPoint, photoID: photoIDSection, iso: isoSection)
        } else {
            let attributes = EBSIWallet.shared.convertToOutputFormat(data : extractValues(credential: credential_cbor).0)
            let issuerAuth = getIssuerAuth(credential: credential_cbor) ?? nil
            let expiryDate = getExpiryFromIssuerAuth(cborData: issuerAuth)
            var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
            for (index,attr) in attributes.enumerated() {
                switch index {
                case 0...:
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[0].key ?? "")
                    attributeStructure[key] = value
                default:
                    break
                }
            }
            let credentialType  = EBSIWallet.shared.credentialOffer?.credentials?.first?.types?.last ?? ""
            customWalletModel.attributes = attributeStructure
            customWalletModel.sectionStruct = sectionStruct
            customWalletModel.referent = nil
            customWalletModel.schemaID = nil
            customWalletModel.certInfo = nil
            customWalletModel.connectionInfo = connectionModel
            customWalletModel.type = CertType.EBSI.rawValue
            customWalletModel.format = format
            customWalletModel.validityDate = expiryDate
            customWalletModel.notificationEndPont = notificationEndPoint
            customWalletModel.notificationID = notificationID
            customWalletModel.accessToken = accessToken
            customWalletModel.refreshToken = refreshToken
            customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: "", credentialJWT: credential_cbor)
        }
    }
    
    func getMDOCCredentialWalletRecord(connectionModel: CloudAgentConnectionWalletModel, credential_cbor: String, format: String, credentialType: String? = "")  -> CustomWalletRecordCertModel{
        var customWalletModel = CustomWalletRecordCertModel.init()
        let sectionStruct = createSectionStruct(credential: credential_cbor)
        var docType = String()
        if let issuerAuth = MDocVpTokenBuilder().getIssuerAuth(credential: credential_cbor) {
            docType = MDocVpTokenBuilder().getDocTypeFromIssuerAuth(cborData: issuerAuth) ?? ""
        }
        if let title = sectionStruct.first?.title, title.contains("pda1") || docType.contains("pda1") {
            let section1 = extractPDA1SectionsFromCbor(credential: credential_cbor).0
            let section2 = extractPDA1SectionsFromCbor(credential: credential_cbor).1
            let section3 = extractPDA1SectionsFromCbor(credential: credential_cbor).2
            let section4 = extractPDA1SectionsFromCbor(credential: credential_cbor).3
            let section5 = extractPDA1SectionsFromCbor(credential: credential_cbor).4
            let section6 = extractPDA1SectionsFromCbor(credential: credential_cbor).5
            return OpenIdPDA1Parser.shared.createPDAWithResponse(section1, section2, section3, section4, section5, section6, customWalletModel, connectionModel, credential_cbor, searchableText: credentialType ?? "")
        }  else if let title = sectionStruct.first?.title, title.contains("photoid") || docType.contains("photoid") {
            let isoSection = extractPhotoIDSectionFromCbor(credential: credential_cbor).0
            let photoIDSection = extractPhotoIDSectionFromCbor(credential: credential_cbor).1
            return PhotoIDParser.shared.createPhotoIDWithResponse(dict: [:], customWalletModel: customWalletModel, credential_jwt: credential_cbor, format: format, connectionModel: connectionModel, photoID: photoIDSection, iso: isoSection) ?? CustomWalletRecordCertModel()
        }
        else {
            let attributes = EBSIWallet.shared.convertToOutputFormat(data : extractValues(credential: credential_cbor).0)
            let issuerAuth = getIssuerAuth(credential: credential_cbor) ?? nil
            let expiryDate = getExpiryFromIssuerAuth(cborData: issuerAuth)
            var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
            for (index,attr) in attributes.enumerated() {
                switch index {
                case 0...:
                    let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[0].key ?? "")
                    attributeStructure[key] = value
                default:
                    break
                }
            }
            customWalletModel.attributes = attributeStructure
            customWalletModel.sectionStruct = sectionStruct
            customWalletModel.referent = nil
            customWalletModel.schemaID = nil
            customWalletModel.certInfo = nil
            customWalletModel.connectionInfo = connectionModel
            customWalletModel.type = CertType.EBSI.rawValue
            customWalletModel.subType =  credentialType?.camelCaseToWords().uppercased()
            customWalletModel.searchableText = credentialType?.camelCaseToWords().uppercased()
            customWalletModel.format = format
            customWalletModel.validityDate = expiryDate
            customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: "", credentialJWT: credential_cbor)
            return customWalletModel
        }
    }
    
    
    func getIssuerAuth(credential: String) -> CBOR? {
            // Convert the base64 URL encoded credential to Data
            if let data = Data(base64URLEncoded: credential) {
                do {
                    // Decode the CBOR data into a dictionary
                    let decodedCBOR = try CBOR.decode([UInt8](data))
                    
                    if let dictionary = decodedCBOR {
                        // Check for the presence of "issuerAuth" in the dictionary
                        if let issuerAuthValue = dictionary[CBOR.utf8String("issuerAuth")] {
                            return issuerAuthValue // Return the issuerAuth value directly
                        }
                    }
                } catch {
                    print("Error decoding CBOR: \(error)")
                    return nil
                }
            } else {
                print("Invalid base64 URL encoded credential.")
                return nil
            }
            
            return nil // Return nil if "issuerAuth" is not found
        }


    func getExpiryFromIssuerAuth(cborData: CBOR) -> String? {
        guard case let CBOR.array(elements) = cborData else {
            print("Expected CBOR array, but got something else.")
            return nil
        }
        var expiryDate: String? = ""
        for element in elements {
            if case let CBOR.byteString(byteString) = element {
                if let nestedCBOR = try? CBOR.decode(byteString) {
            if case let CBOR.tagged(tag, item) = nestedCBOR, tag.rawValue == 24 {
                if case let CBOR.byteString(data) = item {
                    if let decodedInnerCBOR = try? CBOR.decode([UInt8](data)) {
                        expiryDate = extractExpiry(cborData: decodedInnerCBOR )
                    } else {
                        print("Failed to decode inner ByteString under Tag 24.")
                    }
                }
            }
                } else {
                    print("Could not decode ByteString as CBOR, inspecting data directly.")
                    print("ByteString data: \(byteString)")
                }
            } else {
                print("Element: \(element)")
            }
        }
        return expiryDate ?? ""
    }

    func extractExpiry(cborData: CBOR) -> String? {
        guard case let CBOR.map(map) = cborData else {
            return nil
        }
       for (key, value) in map {
            if case let CBOR.utf8String(keyString) = key, keyString == "validityInfo" {
                if case let CBOR.map(validityMap) = value {
                    for (validityKey, validityValue) in validityMap {
                        if case let CBOR.utf8String(validityKeyString) = validityKey, validityKeyString == "validUntil" {
                            if case let CBOR.tagged(_, CBOR.utf8String(validUntilString)) = validityValue {
                                return validUntilString
                            } else {
                                print("The value associated with 'validUntil' is not in the expected format.")
                            }
                        }
                    }
                } else {
                    print("The value associated with 'validityInfo' is not a map.")
                }
            }
        }
        print("validityInfo not found in the CBOR map.")
        return nil
    }
      
    func getValidFromIssuerAuth(cborData: CBOR) -> String? {
        guard case let CBOR.array(elements) = cborData else {
            print("Expected CBOR array, but got something else.")
            return nil
        }
        var expiryDate: String? = ""
        for element in elements {
            if case let CBOR.byteString(byteString) = element {
                if let nestedCBOR = try? CBOR.decode(byteString) {
            if case let CBOR.tagged(tag, item) = nestedCBOR, tag.rawValue == 24 {
                if case let CBOR.byteString(data) = item {
                    if let decodedInnerCBOR = try? CBOR.decode([UInt8](data)) {
                        expiryDate = extractValidFrom(cborData: decodedInnerCBOR )
                    } else {
                        print("Failed to decode inner ByteString under Tag 24.")
                    }
                }
            }
                } else {
                    print("Could not decode ByteString as CBOR, inspecting data directly.")
                    print("ByteString data: \(byteString)")
                }
            } else {
                print("Element: \(element)")
            }
        }
        return expiryDate ?? ""
    }

    func extractValidFrom(cborData: CBOR) -> String? {
        guard case let CBOR.map(map) = cborData else {
            return nil
        }
       for (key, value) in map {
            if case let CBOR.utf8String(keyString) = key, keyString == "validityInfo" {
                if case let CBOR.map(validityMap) = value {
                    for (validityKey, validityValue) in validityMap {
                        if case let CBOR.utf8String(validityKeyString) = validityKey, validityKeyString == "validFrom" {
                            if case let CBOR.tagged(_, CBOR.utf8String(validUntilString)) = validityValue {
                                return validUntilString
                            } else {
                                print("The value associated with 'validUntil' is not in the expected format.")
                            }
                        }
                    }
                } else {
                    print("The value associated with 'validityInfo' is not a map.")
                }
            }
        }
        print("validityInfo not found in the CBOR map.")
        return nil
    }
    
}
