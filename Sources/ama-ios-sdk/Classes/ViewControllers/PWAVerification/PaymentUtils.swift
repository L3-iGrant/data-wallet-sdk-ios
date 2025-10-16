//
//  PaymentUtils.swift
//  dataWallet
//
//  Created by iGrant on 12/02/25.
//

import Foundation
import eudiWalletOidcIos

final class PaymentUtils {
        
    static func isBankLeadFlow(clientMetaData: ClientMetaData?, transactionData: TransactionData?) -> Bool {
        if transactionData == nil {
            return false
        } else {
            if clientMetaData?.clientName == transactionData?.paymentData?.payee {
                return false
            } else {
                return true
            }
        }
    }
    
}
