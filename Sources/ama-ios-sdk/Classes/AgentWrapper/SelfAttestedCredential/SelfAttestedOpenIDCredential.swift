//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 22/08/25.
//

import Foundation
import IndyCWrapper
import eudiWalletOidcIos


public class SelfAttestedOpenIDCredential {
    
    public init() {}
    
    public static let shared = SelfAttestedOpenIDCredential()
    let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
    
    private func addHistory(certModel: CustomWalletRecordCertModel?, connectionModel: CloudAgentConnectionWalletModel) async {
        do {
            var history = History()
            let attrArray = certModel?.attributes?.map({ (item) -> IDCardAttributes in
                return IDCardAttributes.init(type: CertAttributesTypes.string, name: item.key ?? "", value: item.value.value)
            })
            history.attributes = attrArray
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            history.date = dateFormat.string(from: Date())
            history.type = HistoryType.issuedCertificate.rawValue
            history.certSubType = certModel?.subType
            history.connectionModel = connectionModel
            if let schemeSeperated = certModel?.schemaID?.split(separator: ":"){
                history.name = "\(schemeSeperated[2])".uppercased()
            } else if let name = certModel?.subType {
                history.name = name
            }
            let (success, id) = try await WalletRecord.shared.add(connectionRecordId: "", walletHandler: walletHandler, type: .dataHistory, historyModel: history)
            debugPrint("historySaved -- \(success)")
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    
    public func add(
        title: String?,
        description: String?,
        attributes: [[String: String]],
        connectionID: String? = nil,
        connectionName: String? = nil,
        connectionLocation: String? = nil,
        issuedDate: Date? = nil,
        vct: String? = nil,
        logo: String? = nil
    ) async throws -> String {
        var missingFields: [String] = []
        var credentialId: String = ""
        let customWalletModel = CustomWalletRecordCertModel()
        customWalletModel.type = "self_attested"
        customWalletModel.subType = title
        customWalletModel.searchableText = title
        customWalletModel.headerFields = DWHeaderFields(title: title, subTitle: "", desc: description)
        if let issuedDate = issuedDate {
            customWalletModel.addedDate = "\(Int(issuedDate.timeIntervalSince1970))"
        }
        
        var attributesDict: [String: Any] = [:]
        for item in attributes {
            for (key, value) in item {
                
                attributesDict[key] = value
            }
        }
        var connectionModel: CloudAgentConnectionWalletModel? = nil
        
        if connectionID == nil || connectionID?.isEmpty == true {
            if connectionName == nil || connectionName?.isEmpty == true {
                missingFields.append("Connection Name")
            }
            if connectionLocation == nil || connectionLocation?.isEmpty == true {
                missingFields.append("Connection Location")
            }
            
            if !missingFields.isEmpty {
                throw NSError(
                    domain: "Missing Required Fields",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Missing fields: \(missingFields.joined(separator: ", "))"]
                )
            }
        }
        
        if let connectionID = connectionID, connectionID.isNotEmpty {
            let (success2, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(
                walletHandler: walletHandler,
                type: AriesAgentFunctions.cloudAgentConnection,
                searchType: .searchWithId,
                searchValue: connectionID
            )
            if success2 {
                let (fetchedSuccessfully, results) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(
                    walletHandler: walletHandler,
                    searchWalletHandler: searchWalletHandler
                )
                if fetchedSuccessfully {
                    print(results)
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                    if let firstResult = (resultDict?["records"] as? [[String: Any]])?.first {
                        connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstResult as NSDictionary? ?? NSDictionary()) as? CloudAgentConnectionWalletModel
                    }
                    //customWalletModel.connectionInfo = connectionModel
                }
            }
        } else if let connectionName = connectionName, let connectionLocation = connectionLocation, connectionName.isNotEmpty, connectionLocation.isNotEmpty {
            var connection = CloudAgentConnectionWalletModel.init()
            var orgDetail = OrganisationInfoModel.init()
            orgDetail.name = connectionName
            orgDetail.location = connectionLocation
            if connection.value == nil {
                connection.value = CloudAgentConnectionValue(myDid: "", updatedAt: "", alias: "", routingState: "", createdAt: "", theirRole: "", requestID: "", theirLabel: connectionName, inboxKey: "", invitationMode: "", accept: "", inboxID: "", invitationKey: "", state: "", inboundConnectionID: "", initiator: "", errorMsg: "", theirDid: "", imageURL: "", reciepientKey: "", isIgrantAgent: "", routingKey: [], orgDetails: orgDetail, orgId: "", isThirdPartyShareSupported: "")
            }
            connectionModel = connection
        }
        connectionModel?.value?.orgDetails?.logoImageURL = logo
        var vpToken = ""
        await SelfAttestedToOpenID.shared.configDID()
        let ebsiConnectionModel = await SelfAttestedToOpenID.shared.getPassportIssuanceConnection()
        let DID = ebsiConnectionModel?.value?.myDid ?? ""
        let header =
        ([
            "alg": "ES256",
            "kid": "\(DID)#\(DID.replacingOccurrences(of: "did:key:", with: ""))",
            "typ": "dc+sd-jwt"
        ]).toString() ?? ""
        let privateKey =  SelfAttestedToOpenID.shared.getPrivateKeyOfOpenIDPassport()
        let sdData = SelfAttestedToOpenID.shared.credentialSubjectToDisclosureArray(credentialSubject: attributesDict)
        let currentTime = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString
        let startDate = Date()
        var dateAfterAYear = Date(timeInterval: 365*86400, since: startDate)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        df.timeZone = TimeZone(abbreviation: "UTC")
        let dateAfterAYearStr = df.string(from: dateAfterAYear)
        dateAfterAYear = df.date(from: dateAfterAYearStr) ?? Date()
        let startDateStr = df.string(from: startDate)
        // Generate JWT payload
        let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyHandlerKeyID)
        var jwk : [String:Any]? = nil
        if let pubKey = keyHandler.generateSecureKey()?.publicKey {
            jwk = keyHandler.getJWK(publicKey: pubKey) ?? [:]
        }
        var payloadDict =
        [
            "exp": currentTime + 1314000,
            "iat": currentTime,
            "iss": DID,
            "jti": "urn:did:\(uuid)",
            "nbf": currentTime,
            "sub": DID,
            "_sd": sdData.sdList,
            "vct": vct ?? ""
        ] as [String : Any]
        
        if let jwk = jwk{
            payloadDict["cnf"] = ["jwk": jwk]
        }
         
        let payload = payloadDict.toString() ?? ""
        
        let headerData = Data(header.utf8)
        let payloadData = Data(payload.utf8)
        let unsignedToken = "\(headerData.base64URLEncodedString()).\(payloadData.base64URLEncodedString())"
        let signatureData = try? privateKey.signature(for: unsignedToken.data(using: .utf8)!)
        let signature = signatureData?.rawRepresentation ?? Data()
        vpToken = "\(unsignedToken).\(signature.base64URLEncodedString())"
        
        for data in sdData.disclosureList {
            vpToken.append("~\(data)")
        }
        
        let attributes = convertToOutputFormat(data : attributesDict)
        customWalletModel.referent = nil
        customWalletModel.schemaID = nil
        customWalletModel.certInfo = nil
        customWalletModel.connectionInfo = connectionModel
        customWalletModel.type = CertType.EBSI.rawValue
        customWalletModel.format = ""
        
        customWalletModel.vct = vct
        customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: "", credentialJWT: vpToken)
        
        if let connectionModel = connectionModel {
            customWalletModel.connectionInfo = connectionModel
            let (success, certRecordId) = try await WalletRecord.shared.add(
                connectionRecordId: "",
                walletCert: customWalletModel,
                walletHandler: walletHandler,
                type: .walletCert
            )
            credentialId = certRecordId
            if success {
                if let connectionID = connectionID, connectionID.isNotEmpty {
                    await addHistory(certModel: customWalletModel, connectionModel: connectionModel)
                }
                AriesMobileAgent.shared.delegate?.notificationReceived(message: "New certificate is added to wallet".localizedForSDK())
                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
            } else {
                throw NSError(
                    domain: "Wallet Error",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Error saving certificate to wallet"]
                )
            }
        } else {
            throw NSError(
                domain: "Connection Error",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Connection model could not be created or fetched"]
            )
        }
        return credentialId
    }
    
    
    func convertToOutputFormat(data: Any, parentKey: String? = nil) -> [IDCardAttributes] {
        var output: [IDCardAttributes] = []
        
        if let dict = data as? [String: Any] {
            for (key, value) in dict {
                let name = parentKey != nil ? "\(parentKey!) \(key)" : key
                if key == "_sd" {
                    
                } else if let nestedDict = value as? [String: Any] {
                    let nestedOutput = convertToOutputFormat(data: nestedDict, parentKey: name)
                    output.append(contentsOf: nestedOutput)
                } else if let array = value as? [String] {
                    for (index, element) in array.enumerated() {
                        var type: CertAttributesTypes? = .string
                        if key == "signature" || key == "image", let value = value as? String, isBase64(value) {
                            type = .image
                        }
                        let pair = IDCardAttributes(type: type, name: "\(name)[\(index)]".replacingOccurrences(of: "_", with: " ").camelCaseToWords(), value: element)
                        output.append(pair)
                    }
                } else if let array = value as? [Any] {
                    for (index, element) in array.enumerated() {
                        let nestedOutput = convertToOutputFormat(data: element, parentKey: "\(name)[\(index)]")
                        output.append(contentsOf: nestedOutput)
                    }
                } else if let stringValue = value as? String {
                    var type: CertAttributesTypes? = .string
                    if key == "signature" || key == "image", let value = value as? String, isBase64(value) {
                        type = .image
                    }
                    let pair = IDCardAttributes(type: type, name: name.replacingOccurrences(of: "_", with: " ").camelCaseToWords(), value: stringValue)
                    output.append(pair)
                } else if let anyValue = value as? Int {
                    let type: CertAttributesTypes? = .string
                    let stringValue = String(anyValue)
                    let pair = IDCardAttributes(type: type, name: name.replacingOccurrences(of: "_", with: " ").camelCaseToWords(), value: stringValue)
                    output.append(pair)
                }
            }
        }
        
        return output
    }
    
    func isBase64(_ value: String) -> Bool {
        if let data = Data(base64Encoded: value), !data.isEmpty {
            return true
        }
        return false
    }
    
    public func delete(id: String, completion: @escaping (Bool) -> Void) {
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, id: id ?? "") { [weak self](success, error) in
            completion(success)
            if success {
                print("Deleted successfully")
            }
        }
    }
    
    public func get(id: String, completion: @escaping (String, String, [[String: String]]) -> Void) async {
        do {
            let (success2, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(
                walletHandler: walletHandler,
                type: AriesAgentFunctions.walletCertificates,
                searchType: .searchWithId,
                searchValue: id
            )
            if success2 {
                let (fetchedSuccessfully, results) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(
                    walletHandler: walletHandler,
                    searchWalletHandler: searchWalletHandler
                )
                if fetchedSuccessfully {
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                    let firstResult = (resultDict?["records"] as? [[String: Any]])?.first
                    let certSearchModel = SearchItems_CustomWalletRecordCertModel.decode(withDictionary: firstResult as NSDictionary? ?? NSDictionary()) as? SearchItems_CustomWalletRecordCertModel
                    
                    var attributesArray: [[String: String]] = []
                    if let attributes = certSearchModel?.value?.attributes {
                        let convertedAttributes: [[String: String]] = attributes.map { key, value in
                            [
                                key: value.value ?? ""
                            ]
                        }
                        attributesArray = convertedAttributes
                    }
                    completion(certSearchModel?.value?.searchableText ?? "", certSearchModel?.value?.headerFields?.desc ?? "", attributesArray)
                }
            }
        } catch {
            print("Error in fetching data")
        }
    }
    
    public func update(title: String?,
                description: String?,
                attributes: [[String: String]],
                credentialId: String?, connectionID: String? = nil,
                connectionName: String? = nil,
                       connectionLocation: String? = nil, vct: String? = nil) async throws{
        var missingFields: [String] = []
        let customWalletModel = CustomWalletRecordCertModel()
        customWalletModel.type = "self_attested"
        customWalletModel.subType = title
        customWalletModel.searchableText = title
        customWalletModel.headerFields = DWHeaderFields(title: title, subTitle: "", desc: description)
        
//        var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
//        for item in attributes {
//            for (key, value) in item {
//                let attributeModel = DWAttributesModel(value: value, type: "string", imageType: "", parent: "", label: key)
//                attributeStructure[key] = attributeModel
//            }
//        }
//        customWalletModel.attributes = attributeStructure
        
        var attributesDict: [String: Any] = [:]
        for item in attributes {
            for (key, value) in item {
                
                attributesDict[key] = value
            }
        }
        
        var connectionModel: CloudAgentConnectionWalletModel? = nil
        
        if connectionID == nil || connectionID?.isEmpty == true {
            if connectionName == nil || connectionName?.isEmpty == true {
                missingFields.append("Connection Name")
            }
            if connectionLocation == nil || connectionLocation?.isEmpty == true {
                missingFields.append("Connection Location")
            }
            
            if !missingFields.isEmpty {
                throw NSError(
                    domain: "Missing Required Fields",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Missing fields: \(missingFields.joined(separator: ", "))"]
                )
            }
        }
        
        if let connectionID = connectionID, connectionID.isNotEmpty {
            let (success2, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(
                walletHandler: walletHandler,
                type: AriesAgentFunctions.cloudAgentConnection,
                searchType: .searchWithId,
                searchValue: connectionID
            )
            if success2 {
                let (fetchedSuccessfully, results) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(
                    walletHandler: walletHandler,
                    searchWalletHandler: searchWalletHandler
                )
                if fetchedSuccessfully {
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                    let firstResult = (resultDict?["records"] as? [[String: Any]])?.first
                    connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstResult as NSDictionary? ?? NSDictionary()) as? CloudAgentConnectionWalletModel
                }
            }
        } else if let connectionName = connectionName, let connectionLocation = connectionLocation, connectionName.isNotEmpty, connectionLocation.isNotEmpty {
            var connection = CloudAgentConnectionWalletModel.init()
            var orgDetail = OrganisationInfoModel.init()
            orgDetail.name = connectionName
            orgDetail.location = connectionLocation
            if connection.value == nil {
                connection.value = CloudAgentConnectionValue(myDid: "", updatedAt: "", alias: "", routingState: "", createdAt: "", theirRole: "", requestID: "", theirLabel: connectionName, inboxKey: "", invitationMode: "", accept: "", inboxID: "", invitationKey: "", state: "", inboundConnectionID: "", initiator: "", errorMsg: "", theirDid: "", imageURL: "", reciepientKey: "", isIgrantAgent: "", routingKey: [], orgDetails: orgDetail, orgId: "", isThirdPartyShareSupported: "")
            }
            connectionModel = connection
        }
        
        var vpToken = ""
        await SelfAttestedToOpenID.shared.configDID()
        let ebsiConnectionModel = await SelfAttestedToOpenID.shared.getPassportIssuanceConnection()
        let DID = ebsiConnectionModel?.value?.myDid ?? ""
        let header =
        ([
            "alg": "ES256",
            "kid": "\(DID)#\(DID.replacingOccurrences(of: "did:key:", with: ""))",
            "typ": "dc+sd-jwt"
        ]).toString() ?? ""
        let privateKey =  SelfAttestedToOpenID.shared.getPrivateKeyOfOpenIDPassport()
        let sdData = SelfAttestedToOpenID.shared.credentialSubjectToDisclosureArray(credentialSubject: attributesDict)
        let currentTime = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString
        let startDate = Date()
        var dateAfterAYear = Date(timeInterval: 365*86400, since: startDate)
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        df.timeZone = TimeZone(abbreviation: "UTC")
        let dateAfterAYearStr = df.string(from: dateAfterAYear)
        dateAfterAYear = df.date(from: dateAfterAYearStr) ?? Date()
        let startDateStr = df.string(from: startDate)
        // Generate JWT payload
        let payload =
        ([
            "exp": currentTime + 1314000,
            "iat": currentTime,
            "iss": DID,
            "jti": "urn:did:\(uuid)",
            "nbf": currentTime,
            "sub": DID,
            "_sd": sdData.sdList,
            "vct": vct ?? ""
        ] as [String : Any]).toString() ?? ""
        
        let headerData = Data(header.utf8)
        let payloadData = Data(payload.utf8)
        let unsignedToken = "\(headerData.base64URLEncodedString()).\(payloadData.base64URLEncodedString())"
        let signatureData = try? privateKey.signature(for: unsignedToken.data(using: .utf8)!)
        let signature = signatureData?.rawRepresentation ?? Data()
        vpToken = "\(unsignedToken).\(signature.base64URLEncodedString())"
        
        for data in sdData.disclosureList {
            vpToken.append("~\(data)")
        }
        
        let attributes = convertToOutputFormat(data : attributesDict)
        customWalletModel.referent = nil
        customWalletModel.schemaID = nil
        customWalletModel.certInfo = nil
        customWalletModel.connectionInfo = connectionModel
        customWalletModel.type = CertType.EBSI.rawValue
        customWalletModel.format = ""
        
        customWalletModel.vct = vct
        customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes, issuer: "", credentialJWT: vpToken)
        
        if let connectionModel = connectionModel {
            customWalletModel.connectionInfo = connectionModel
            let dict = customWalletModel.dictionary?.toString() ?? ""
            let success = try await WalletRecord.shared.update(walletHandler: walletHandler, recordId: credentialId ?? "", type: AriesAgentFunctions.walletCertificates, value: dict)
            if let connectionID = connectionID, connectionID.isNotEmpty, success {
                await addHistory(certModel: customWalletModel, connectionModel: connectionModel)
            }
        }
        
        else {
            throw NSError(
                domain: "Connection Error",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Connection model could not be created or fetched"]
            )
        }
    }

}
