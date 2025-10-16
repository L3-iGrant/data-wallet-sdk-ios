//
//  CertificatePreviewViewModel+Receipt.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 28/01/23.
//

import Foundation

//EBSI_V2
extension CertificatePreviewViewModel{
    
    func acceptReceipt() async {
        let walletHandler = self.walletHandle ?? 0
        do {
            let (success, certRecordId) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: certModel?.value, walletHandler: walletHandler, type: .walletCert)
            await self.addHistory()
            if success {
                //SDK
//                UIApplicationUtils.showSuccessSnackbar(message: "New certificate is added to wallet".localizedForSDK())
                AriesMobileAgent.shared.delegate?.notificationReceived(message: "New certificate is added to wallet".localizedForSDK())
                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
            } else {
                UIApplicationUtils.showErrorSnackbar(message: "Error saving certificate to wallet")
            }
            if inboxId != nil { //ie from notification list. For EBSI, we need to delete the list item after adding cert.
                AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: self.inboxId ?? "") { [weak self](deletedSuccessfully, error) in
                    print("Cert deleted \(deletedSuccessfully)")
                    UIApplicationUtils.hideLoader()
                    self?.delegate?.popVC()
                }
            } else {
                UIApplicationUtils.hideLoader()
                self.delegate?.popVC()
            }
            
        } catch {
            UIApplicationUtils.hideLoader()
            UIApplicationUtils.showErrorSnackbar(message: "Error saving certificate to wallet")
            debugPrint(error.localizedDescription)
        }
    }
}

//Receipt
extension CertificatePreviewViewController: ReceiptTableView{}

extension CertificatePreviewBottomSheet: ReceiptTableView{}
