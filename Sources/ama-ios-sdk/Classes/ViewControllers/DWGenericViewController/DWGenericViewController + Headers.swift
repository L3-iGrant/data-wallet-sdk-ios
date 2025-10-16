//
//  DWGenericViewController + Headers.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 05/01/23.
//

import Foundation

extension DWGenericViewController {
    
    func setupHeader(){
        if let topImage = viewModel.credentialModel?.attributes?.orderedValues.first(where: { e in
            e.parent == "topImage"
        }){
            debugPrint(topImage.value ?? "")
            //add top image header
        }
    }
}
