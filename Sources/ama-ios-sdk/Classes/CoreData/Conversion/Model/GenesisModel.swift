//
//  GenesisModel.swift
//  dataWallet
//
//  Created by sreelekh N on 01/03/22.
//

import Foundation
struct GenesisModel: Codable {
    
    let id: Int
    let str, genesisURL, registerDIDHTMLText, genesisString: String
    
    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case str = "Str"
        case genesisURL = "GenesisURL"
        case registerDIDHTMLText = "RegisterDIDHTMLText"
        case genesisString = "GenesisString"
    }
}

//extension GenesisCoreData {
//    func convertToGenesisModel() -> GenesisModel {
//        return GenesisModel(id: self.id?.toInt ?? 0,
//                            str: self.str ?? "",
//                            genesisURL: self.genesisURL ?? "",
//                            registerDIDHTMLText: self.registerDIDHTMLText ?? "",
//                            genesisString: self.genesisString ?? "")
//    }
//}
