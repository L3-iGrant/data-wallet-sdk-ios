//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 20/08/25.
//

import Foundation
import SwiftCBOR

class CredentialManager {
    
    static var shared = CredentialManager()
    let walletHandler = WalletViewModel.openedWalletHandler ?? 0
    
    func checkCredentialExpiry(completion: @escaping (Bool) -> Void) {
            WalletRecord.shared.fetchAllCert { allCards in
                guard let records = allCards?.records else {
                    completion(false)
                    return
                }
                var success = true
                let group = DispatchGroup()
                
                for record in records {
                    var expiry = ""
                    if record.value?.type == CertType.idCards.rawValue || record.value?.type == CertType.selfAttestedRecords.rawValue {
                        if let passportData = record.value?.passport{
                            expiry = passportData.dateOfExpiry?.value ?? ""
                        }
                        if let covidData = record.value?.covidCert_EU {
                            expiry = covidData.validUntil?.value ?? ""
                        }
                    } else if let expiryDate = record.value?.validityDate {
                        expiry = expiryDate
                    }
                    if self.validateExpiryDate(jwt: record.value?.EBSI_v2?.credentialJWT, expiry: expiry) == true {
                        group.enter()
                        self.moveToExpiredWallet(record) { moveSuccess in
                            if !moveSuccess {
                                success = false
                            }
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    completion(success)
                }
            }
        }
    
    func moveToExpiredWallet(_ credential: SearchItems_CustomWalletRecordCertModel?, completion: @escaping(Bool) -> Void) {
        removeFromActiveWallet(credential) { success in
            if success {
                self.addToExpiredWallet(credential)
                completion(true)
                print("deleted")
            } else {
                completion(false)
                print("error")
            }
        }
    }
    
    func removeFromActiveWallet(_ credential: SearchItems_CustomWalletRecordCertModel?, completion: @escaping (Bool) -> Void) {
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: WalletViewModel.openedWalletHandler ?? 0, type: AriesAgentFunctions.walletCertificates, id: credential?.id  ?? "") { (deleteSuccess, error) in
            if deleteSuccess {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func addToExpiredWallet(_ credential: SearchItems_CustomWalletRecordCertModel?) {
        let credentialValue = credential?.value
        credentialValue?.isExpiredCredential = true
        credentialValue?.expiredTime = AgentWrapper.shared.getCurrentDateTime()
        WalletRecord.shared.add(connectionRecordId: "",walletCert: credential?.value , walletHandler: WalletViewModel.openedWalletHandler ?? 0, type: .expiredCertificate) { success, id, error in
            if success {
                print("expired cards added")
            } else {
                print("error while adding expired cards")
            }
        }
    }
    
    func validateExpiryDate(jwt: String?, expiry: String?) -> Bool? {
        // If `expiry` is provided, use it
        if let expiry = expiry, !expiry.isEmpty {
            let expiryFormats = ["yyMMdd", "yyyy-MM-dd", "yyyy-MM-dd'T'HH:mm:ss'Z'"]
            guard let expiryDate = DateUtils.shared.parseDate(from: expiry, formats: expiryFormats) else { return false }
            return Date() > expiryDate
        }
        // Otherwise, parse the JWT and extract the expiration date
        guard let split = jwt?.split(separator: "."), split.count > 1,
              let jsonString = "\(split[1])".decodeBase64(),
              let jsonObject = UIApplicationUtils.shared.convertStringToDictionary(text: jsonString) else { return false }
        var expiryDate: String = ""
        if let expirationDate = jsonObject["exp"] as? Double {
            let date = Date(timeIntervalSince1970: TimeInterval(expirationDate) )
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            let formattedDateString = dateFormatter.string(from: date)
            expiryDate = formattedDateString
        } else if let vc = jsonObject["vc"] as? [String: Any], let expirationDate = vc["expirationDate"] as? String {
            expiryDate = expirationDate
        }
        let expirationFormats = ["yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", "yyyy-MM-dd'T'HH:mm:ss'Z'", "yyyy-MM-dd hh:mm:ss.SSSSSS a'Z'"]
        guard let expiryDate = DateUtils.shared.parseDate(from: expiryDate, formats: expirationFormats) else { return false }
        
        return Date() > expiryDate
    }
    
    func addRevokedToWallet(_ credential: SearchItems_CustomWalletRecordCertModel?) {
        let credentialValue = credential?.value
        credentialValue?.isRevokedCredential = true
        credentialValue?.revokedTime = AgentWrapper.shared.getCurrentDateTime()
        WalletRecord.shared.add(connectionRecordId: "",walletCert: credential?.value , walletHandler: WalletViewModel.openedWalletHandler ?? 0, type: .expiredCertificate) { success, id, error in
            if success {
                print("expired cards added")
            } else {
                print("error while adding expired cards")
            }
        }
    }
    
}
