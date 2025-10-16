//
//  DeferredCredentialPollingHelper.swift
//  dataWallet
//
//  Created by iGrant on 10/09/24.
//

import Foundation
import JOSESwift
import eudiWalletOidcIos

class DeferredCredentialPollingHelper {
    
    static let shared = DeferredCredentialPollingHelper()
    private let deferredCredentialsKey = "DeferredCredentials"
    private var isRequestInProgress = false
    
    func fetchAllDeferredCredentialRequest() -> [DeferredCacheModel] {
        if let data = UserDefaults.standard.data(forKey: deferredCredentialsKey) {
            let decoder = JSONDecoder()
            if let deferredList = try? decoder.decode([DeferredCacheModel].self, from: data) {
                return deferredList
            }
        }
        return []
    }
    
    func updateDeferredCredentialRequestCacheList(_ model: DeferredCacheModel) {
        var deferredList = fetchAllDeferredCredentialRequest()
        deferredList.append(model)
        saveDeferredCredentialRequestList(deferredList)
    }
    
    func removeDeferredCredentialRequestCacheList(acceptanceToken: String) {
        var deferredList = fetchAllDeferredCredentialRequest()
        deferredList.removeAll { $0.acceptanceToken == acceptanceToken }
        saveDeferredCredentialRequestList(deferredList)
    }
    
    private func saveDeferredCredentialRequestList(_ deferredList: [DeferredCacheModel]) {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(deferredList) {
            UserDefaults.standard.set(encodedData, forKey: deferredCredentialsKey)
        }
    }
    
    func getDeferredCredentialUsingAcceptanceToken(acceptanceToken: String?) ->  DeferredCacheModel? {
        guard let acceptanceToken = acceptanceToken else {
            return nil
        }
        let deferredCredentials = fetchAllDeferredCredentialRequest()
        
        for credential in deferredCredentials {
            if credential.acceptanceToken == acceptanceToken {
                return credential
            }
        }
        return nil
    }
    
    
    func handleDeferredCredentialRequests() async {
        guard !isRequestInProgress else {
            debugPrint("Deferred credential request is in progress")
            return
        }
        
        let deferredCredentials = fetchAllDeferredCredentialRequest()
        
        for item in deferredCredentials {
            if let expiry = item.expiryTime {
                if expiry > Date() {
                   // await EBSIWallet.shared.defferedCredentialRequest(deferredCacheModel: item)
                } else {
                    removeDeferredCredentialRequestCacheList(acceptanceToken: item.acceptanceToken ?? "")
                }
            }
        }
        
        isRequestInProgress = true
    }
    
}


struct DeferredCacheModel: Codable {
    
    var acceptanceToken: String?
    var deferredEndPoint: String?
    var jwkUris: String?
    var expiryTime: Date?
    var credentialDisplay: Display?
    var connectionDetails: CloudAgentConnectionWalletModel?
    var accessToken: String?
    var version: String?
    var refreshToken: String?
    var notificationID: String?
    var notificationEndPont: String?
    var tokenEndPoint: String?
    var ecPrivateKey: ECPrivateKey?
    var jwks: JWKData?
    var encryptionRequired: Bool?
    
    init(acceptanceToken: String?, deferredEndPoint: String?, jwkUris: String?, credentialDisplay: Display?, connectionDetails: CloudAgentConnectionWalletModel?, accessToken: String?, version: String?, refreshToken: String?, notificationID: String?, notificationEndPont: String?, tokenEndPoint: String?, ecPrivateKey: ECPrivateKey?, jwks: JWKData?, encryptionRequired: Bool?) {
        self.acceptanceToken = acceptanceToken
        self.deferredEndPoint = deferredEndPoint
        self.jwkUris = jwkUris
        self.credentialDisplay = credentialDisplay
        self.expiryTime = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        self.connectionDetails = connectionDetails
        self.accessToken = accessToken
        self.version = version
        self.refreshToken = refreshToken
        self.notificationID = notificationID
        self.notificationEndPont = notificationEndPont
        self.tokenEndPoint = tokenEndPoint
        self.ecPrivateKey = ecPrivateKey
        self.jwks = jwks
        self.encryptionRequired = encryptionRequired
    }
    
}
