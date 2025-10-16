//
//  MetaDataModel.swift
//  dataWallet
//
//  Created by sreelekh N on 01/03/22.
//

import Foundation
struct MetaDataModel: Codable, Equatable {
    
    let ledgerNetwork, pkpassBoardingPass, blinks, myDataProfile: String
    
    enum CodingKeys: String, CodingKey {
        case ledgerNetwork = "ledger_network"
        case pkpassBoardingPass = "pkpass_boarding_pass"
        case myDataProfile = "my_data_profile"
        case blinks
    }
    
    func isEqualTo(_ object: Any) -> Bool {
        guard let otherObj = object as? MetaDataModel else {
            return false
        }
        return ledgerNetwork == otherObj.ledgerNetwork && pkpassBoardingPass == otherObj.pkpassBoardingPass && blinks == otherObj.blinks && myDataProfile == otherObj.myDataProfile
    }
}

