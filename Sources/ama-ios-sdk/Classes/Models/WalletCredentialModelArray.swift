//
//  WalletCredentialModelArray.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 12/12/20.
//

import Foundation

struct  WalletCredentialModelArray: Codable{
    let records: [SearchProofReqCredInfo]?
    
    enum CodingKeys: String, CodingKey {
        case records
    }
}
