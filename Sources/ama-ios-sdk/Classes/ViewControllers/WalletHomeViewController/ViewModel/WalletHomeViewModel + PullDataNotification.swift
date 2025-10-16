//
//  WalletHomeViewModel + PullDataNotification.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 20/09/22.
//

import Foundation

extension WalletViewModel {
    func handlePullDataNotification(model: PullDataNotificationModel, receiptId: String){
        Task {
            let connModel = await AriesCloudAgentHelper.shared.getConnectionFromVerificationKey(verKey: receiptId)
            if connModel?.id != nil {
                let success = await WalletRecord.shared.addPullDataNotificationRecord(model: model)
                AriesMobileAgent.shared.delegate?.notificationReceived(message: "Received data pull notification".localizedForSDK())
            }
        }
    }
    
    func handleReceipt(model: ReceiptNotificationModel){
        Task {
            let success = await WalletRecord.shared.addReceiptRecord(model: model.body)
        }
    }
}
