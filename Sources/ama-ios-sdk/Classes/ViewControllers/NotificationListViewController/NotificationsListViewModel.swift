//
//  ExchangeDataListViewModel.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 14/12/20.
//

import Foundation
import IndyCWrapper

class NotificationsListViewModel{
    var walletHandle: IndyHandle?
    var notifications: [InboxModelRecord]?

    init(walletHandle: IndyHandle?) {
        self.walletHandle = walletHandle
    }
    
    func fetchNotifications(completion: @escaping (Bool) -> Void) {
        WalletRecord.shared.fetchNotifications { searchInboxModel in
            if let records = searchInboxModel?.records {
                self.notifications = records
                completion(true)
            }else{
                self.notifications = []
                completion(false)
            }
        }
    }
    
}
