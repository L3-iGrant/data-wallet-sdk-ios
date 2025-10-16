//
//  EBSI_V2_WalletModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 10/08/22.
//

import Foundation

struct EBSI_V2_WalletModel: Codable {
    var id: String?
    var attributes: [IDCardAttributes]?
    var issuer: String?
    var credentialJWT: String?
}
