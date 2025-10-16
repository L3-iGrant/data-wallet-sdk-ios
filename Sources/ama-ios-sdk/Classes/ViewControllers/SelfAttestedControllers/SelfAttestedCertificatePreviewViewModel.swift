//
//  Untitled.swift
//  Pods
//
//  Created by iGrant on 17/03/25.
//

import IndyCWrapper

class SelfAttestedCertificatePreviewViewModel {
    
    var walletHandle: IndyHandle?
    var certDetail: SearchCertificateRecord?
    var reqId : String?
    var inboxId: String?
    var certModel:SearchItems_CustomWalletRecordCertModel?
    weak var pageDelegate: CirtificateDelegate?

    init(walletHandle: IndyHandle?, certModel:SearchItems_CustomWalletRecordCertModel? = nil) {
        self.walletHandle = walletHandle
        self.certModel = certModel
    }
    
    func deleteCredentialWith(id:String,walletRecordId: String?) {
        let walletHandler = self.walletHandle ?? 0
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, id: walletRecordId ?? "") { [weak self](success, error) in
            AriesPoolHelper.shared.deleteCredentialFromWallet(withId: id, walletHandle: walletHandler) {[weak self] (success, error) in
                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                self?.pageDelegate?.popVC()
            }
        }
    }
    
}
