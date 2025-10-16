//
//  JWTHelper.swift
//  dataWallet
//
//  Created by Mumthasir mohammed on 10/01/24.
//

import Foundation
import KeychainSwift
import CryptoKit
import Base58Swift
import IndyCWrapper

public class SelfAttestedToOpenID {
    static let shared = SelfAttestedToOpenID()
    let keychain = KeychainSwift()
    var DID = ""
    
    public init() {}
    
    func configDID() async {
        if let connectionModel = await getPassportIssuanceConnection() {
            DID = connectionModel.value?.myDid ?? ""
        } else {
            await self.connectionConfigurationForPassportIssuance()
        }
    }
    
    func createOpenIDSDJWTForPassport(passportModel: IDCardModel, selectedDisclosures: [String]) async -> String {
        let privateKey =  getPrivateKeyOfOpenIDPassport()
        var vpToken = ""
        await configDID()
        debugPrint("### DID From JWTHelper class:\(DID)")
        
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
        
        // Generate JWT header
        let header =
        ([
            "alg": "ES256",
            "kid": "\(DID)#\(DID.replacingOccurrences(of: "did:key:", with: ""))",
            "typ": "dc+sd-jwt"
        ]).toString() ?? ""
        
        let credentialSubject =
        ([
            "id": DID,
            "firstName": "\(passportModel.firstName?.value ?? "")",
            "lastName": "\(passportModel.surName?.value ?? "")",
            "gender": "\(passportModel.gender?.value ?? "")",
            "nationality": "\(passportModel.nationality?.value ?? "")",
            "birthDate": "\(passportModel.dateOfBirth?.value ?? "")",
            "personalNumber": "\(passportModel.personalNumber?.value ?? "")",
            "serialNumber": "\(passportModel.documentNumber?.value ?? "")",
            "issuerAuthority": "\(passportModel.issuingCountry?.value ?? "")",
            "expiryDate": "\(passportModel.dateOfExpiry?.value ?? "")",
            "image": "\(passportModel.profileImage?.value ?? "")",
            "signature": "\(passportModel.signature?.value ?? "")"
        ] as [String : Any])
        
        let sdData = credentialSubjectToDisclosureArray(credentialSubject: credentialSubject)
        
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
            "vct": "Passport"
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
        debugPrint(vpToken)
        return vpToken
    }
    
    func createOpenIDJWTForPassport(passportModel: IDCardModel, type: String? = "array") async -> String {
        let privateKey =  getPrivateKeyOfOpenIDPassport()
        var vpToken = ""
        await configDID()
        debugPrint("### DID From JWTHelper class:\(DID)")
        
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
        
        // Generate JWT header
        let header =
        ([
            "alg": "ES256",
            "kid": "\(DID)#\(DID.replacingOccurrences(of: "did:key:", with: ""))",
            "typ": "JWT"
        ]).toString() ?? ""
        
        let credentialSubject =
        ([
            "id": DID,
            "firstName": "\(passportModel.firstName?.value ?? "")",
            "lastName": "\(passportModel.surName?.value ?? "")",
            "gender": "\(passportModel.gender?.value ?? "")",
            "nationality": "\(passportModel.nationality?.value ?? "")",
            "birthDate": "\(passportModel.dateOfBirth?.value ?? "")",
            "personalNumber": "\(passportModel.personalNumber?.value ?? "")",
            "serialNumber": "\(passportModel.documentNumber?.value ?? "")",
            "issuerAuthority": "\(passportModel.issuingCountry?.value ?? "")",
            "expiryDate": "\(passportModel.dateOfExpiry?.value ?? "")",
            "image": "\(passportModel.profileImage?.value ?? "")",
            "signature": "\(passportModel.signature?.value ?? "")"
        ] as [String : Any])
        
        let schema = [[
            "id":"https://raw.githubusercontent.com/L3-iGrant/data-schemas/main/schemas/passport_eu_schema.json",
            "type": "FullJsonSchemaValidator2021"
        ]]
        
        let vc =
        ([
            "@context": ["https://www.w3.org/2018/credentials/v1"],
            "credentialSchema": schema,
            "credentialSubject": credentialSubject,
            "expirationDate": dateAfterAYearStr,
            "id": "urn:did:\(uuid)",
            "issuanceDate": startDateStr,
            "issued": startDateStr,
            "issuer": "\(DID)",
            "type": type == "string" ? "Passport" : ["Passport"],
            "validFrom": startDateStr
        ] as [String : Any])
        
        // Generate JWT payload
        let payload =
        ([
            "exp": currentTime + 1314000,
            "iat": currentTime,
            "iss": DID,
            "jti": "urn:did:\(uuid)",
            "nbf": currentTime,
            "sub": DID,
            "vc":  vc
        ] as [String : Any]).toString() ?? ""
        
        let headerData = Data(header.utf8)
        let payloadData = Data(payload.utf8)
        let unsignedToken = "\(headerData.base64URLEncodedString()).\(payloadData.base64URLEncodedString())"
        let signatureData = try? privateKey.signature(for: unsignedToken.data(using: .utf8)!)
        let signature = signatureData?.rawRepresentation ?? Data()
        vpToken = "\(unsignedToken).\(signature.base64URLEncodedString())"
        debugPrint(vpToken)
        return vpToken
    }
    
    func credentialSubjectToDisclosureArray(credentialSubject: [String: Any]?) -> SDCustomClass {
        var disclosureList = [String]()
        var sdList = [String]()
        
        // Check if credentialSubject is not nil
        credentialSubject?.forEach { (key, value) in
            // Process each key-value pair in the map
            let salt = UUID().uuidString
            let disclosure = [salt, key, String(describing: value)]
            
            if let disclosureJsonData = try? JSONEncoder().encode(disclosure),
               let disclosureJsonString = String(data: disclosureJsonData, encoding: .utf8) {
                
                // Base64 encode the JSON string
                let base64String = disclosureJsonString.data(using: .utf8)?.base64EncodedString()
                
                // Ensure the Base64 string is URL-safe
                var base64StringWithoutPadding = base64String?.replacingOccurrences(of: "=", with: "") ?? ""
                base64StringWithoutPadding = base64StringWithoutPadding.replacingOccurrences(of: "+", with: "-")
                base64StringWithoutPadding = base64StringWithoutPadding.replacingOccurrences(of: "/", with: "_")
                
                print("credentialSubjectToDisclosureArray: \(base64StringWithoutPadding)")
                
                let sdJwtUtils = SDJWTUtils()
                if let hash = sdJwtUtils.calculateSHA256Hash(inputString: base64StringWithoutPadding) {
                    print("credentialSubjectToDisclosureArray: \(hash)")
                    disclosureList.append(base64StringWithoutPadding)
                    sdList.append(hash)
                }
            }
        }
        
        return SDCustomClass(disclosureList: disclosureList, sdList: sdList)
    }
}

class SDCustomClass {
    var disclosureList: [String]
    var sdList: [String]
    
    init(disclosureList: [String], sdList: [String]) {
        self.disclosureList = disclosureList
        self.sdList = sdList
    }
}
    
//MARK: - DID Connection related
extension SelfAttestedToOpenID {
    func createDIDforPassportIssuance(privateKey: P256.Signing.PrivateKey) async -> String? {
        if let connectionModel = await getPassportIssuanceConnection() {
            let did = connectionModel.value?.myDid ?? ""
            debugPrint("###DID:\(did)")
            return did
        } else {
            // Step 1: Create P-256 public and private key pair
            let publicKey = privateKey.publicKey
            
            // Step 2: Export public key JWK
            let rawRepresentation = publicKey.rawRepresentation
            let x = rawRepresentation[rawRepresentation.startIndex..<rawRepresentation.index(rawRepresentation.startIndex, offsetBy: 32)]
            let y = rawRepresentation[rawRepresentation.index(rawRepresentation.startIndex, offsetBy: 32)..<rawRepresentation.endIndex]
            let jwk: [String: Any] = [
                "crv": "P-256",
                "kty": "EC",
                "x": x.urlSafeBase64EncodedString(),
                "y": y.urlSafeBase64EncodedString()
            ]
            
            do {
                // Step 3: Convert JWK to JSON string
                let jsonData = try JSONSerialization.data(withJSONObject: jwk, options: [.sortedKeys])
                guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                    return nil
                }
                
                // Step 4: Remove whitespaces from the JSON string
                let compactJsonString = jsonString.replacingOccurrences(of: " ", with: "")
                
                // Step 5: UTF-8 encode the string
                guard let encodedData = compactJsonString.data(using: .utf8) else {
                    return nil
                }
                
                // Step 6: Add multicodec byte for jwk_jcs-pub
                let multicodecByte: [UInt8] = [209, 214, 3]
                var multicodecData = Data(fromArray: multicodecByte)
                multicodecData.append(encodedData)
                
                // Step 7: Apply multibase base58-btc encoding
                let multibaseEncodedString =  Base58.base58Encode([UInt8](multicodecData))
                
                // Step 8: Prefix the string with did:key:z
                let didKeyIdentifier = "did:key:z" + multibaseEncodedString
                debugPrint("###didKeyIdentifier ghenerated:\(didKeyIdentifier)")
                return didKeyIdentifier
            } catch {
                print("Error: \(error)")
                return nil
            }
        }
    }
    
    func connectionConfigurationForPassportIssuance() async {
        do {
            let orgId = "open_id_for_self_attested_credentials"
            let privateKey = getPrivateKeyOfOpenIDPassport()
            DID = await createDIDforPassportIssuance(privateKey: privateKey) ?? ""
            let label = "JWT"
            let imageURL = "https://i.ibb.co/jwPYjLb/Screenshot-2022-06-29-152618.png"
            var orgDetail = OrganisationInfoModel.init()
            orgDetail.orgId = orgId
            orgDetail.logoImageURL = imageURL
            orgDetail.location = "European Union"
            orgDetail.organisationInfoModelDescription = "EBSI is a joint initiative from the European Commission and the European Blockchain Partnership. The vision is to leverage blockchain to accelerate the creation of cross-border services for public administrations and their ecosystems to verify information and to make services more trustworthy."
            orgDetail.name = "JWT"
            let (_, connID) = try await WalletRecord.shared.add(invitationKey: "", label: label, serviceEndPoint: "", connectionRecordId: "",imageURL: "", walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),type: .connection, orgID: orgId)
            let (_, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),recipientKey: "",label: label, type: UpdateWalletType.trusted, id: connID, theirDid: "", myDid: DID,imageURL: "",invitiationKey: "", isIgrantAgent: false, routingKey: nil, orgDetails: orgDetail, orgID:orgId)
            _ = try await
            AriesAgentFunctions.shared.updateWalletTags(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), id: connID, myDid: DID, type: .cloudAgentActive, orgID: orgId)
            guard let connectionModel = await getPassportIssuanceConnection() else { return }
            debugPrint("JWT Conn:\(connectionModel)")
        } catch {
            UIApplicationUtils.hideLoader()
            debugPrint(error.localizedDescription)
        }
    }
    
    func getPassportIssuanceConnection() async -> CloudAgentConnectionWalletModel? {
        do {
            let orgId = "open_id_for_self_attested_credentials"
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithOrgId,searchValue: orgId)
            let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
            guard let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response) else { return nil}
            
            let connectionModels = Connections.decode(withDictionary: messageModel as [String : Any]) as? Connections
            let filteredRecord = connectionModels?.records.filter({ $0.value.orgID == orgId })
            let records = messageModel["records"] as? [[String:Any]]
            debugPrint("###records.count:\(records?.count ?? 0)")
            debugPrint("###records.keys:\(records?[0] ?? [:]))")
            guard let firstRecord = filteredRecord?.first?.dictionary as NSDictionary? else {return nil}
            let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord) as? CloudAgentConnectionWalletModel
            return connectionModel
        } catch {
            UIApplicationUtils.hideLoader()
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    // Return if private key exising for OpenID Passport issusance
    public func getPrivateKeyOfOpenIDPassport() ->  P256.Signing.PrivateKey {
        var privateKey: P256.Signing.PrivateKey
        if let data = keychain.getData("EBSI_V3_PVTKEY"), let pvtKey = try? P256.Signing.PrivateKey(rawRepresentation: data) {
            privateKey = pvtKey
        } else {
            privateKey = P256.Signing.PrivateKey()
            keychain.set(privateKey.rawRepresentation, forKey: "EBSI_V3_PVTKEY")
        }
        return privateKey
    }
}
