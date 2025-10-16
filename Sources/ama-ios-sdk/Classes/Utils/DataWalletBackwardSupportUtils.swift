//
//  DataWalletBackwardSupportUtils.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 20/02/23.
//

import Foundation
import IndyCWrapper

struct DataWalletBackwardSupportUtils {
    
    let userDefaultKey = "LocalDB_update"
    let version = "1"
    
    func checkAndUpdateDataWallet() async{
        if getLastUpdatedVersion() == nil {
            await update()
        }else if let db_version = getLastUpdatedVersion(), db_version != version {
            await update()
        }
    }
    
    func update() async{
        saveLastUpdatedVersion(appVersion: version)
        let _ = await DataWallet_Update_1().update()
    }
    
    func saveLastUpdatedVersion(appVersion: String){
        UserDefaults.standard.set(appVersion, forKey: userDefaultKey)
    }
    
    func getLastUpdatedVersion() -> String? {
        return UserDefaults.standard.value(forKey: userDefaultKey) as? String
    }
}

//MARK: Backward Compatibility
class DataWallet_Update_1 {
    // Change EBSI searchable text
    func update() async -> Bool{
        let walletCredentials = await WalletRecord.shared.fetchAllCert()
        for cred in walletCredentials?.records ?? [] {
            //Make changes
            let newCred = cred.value
            switch cred.value?.subType ?? "" {
                case EBSI_CredentialType.Diploma.rawValue:
                    newCred?.searchableText = EBSI_CredentialSearchText.Diploma.rawValue
                case EBSI_CredentialType.StudentID.rawValue:
                    newCred?.searchableText = EBSI_CredentialSearchText.StudentID.rawValue
                case EBSI_CredentialType.VerifiableID.rawValue:
                    newCred?.searchableText = EBSI_CredentialSearchText.VerifiableID.rawValue
                case EBSI_CredentialType.PDA1.rawValue:
                    newCred?.searchableText = EBSI_CredentialSearchText.PDA1.rawValue
                default: break
            }
            
            if cred.value?.type == CertType.EBSI.rawValue {
                let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
                do {
                    let _ = try await WalletRecord.shared.update(walletHandler: walletHandler, recordId: cred.id ?? "", type: AriesAgentFunctions.walletCertificates, value: newCred?.dictionary?.toString() ?? "")
                }catch{
                    debugPrint(error.localizedDescription)
                    return false
                }
            }
        }
        return true
    }
}

////MARK: For future
//class DataWallet_Update_2: DataWallet_Update_1{
//    // Change EBSI to ESSPASS (EBSI)
//    override func update() async -> Bool{
//        await super.update()
//        let walletCredentials = await WalletRecord.shared.fetchAllCert()
//        for cred in walletCredentials?.records ?? [] {
//            //Make changes
//        }
//        return true
//    }
//}
