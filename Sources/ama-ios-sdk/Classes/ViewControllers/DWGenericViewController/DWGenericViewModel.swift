//
//  DWGenericViewModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 05/01/23.
//

import Foundation

enum DWGenericViewMode{
    case edit
    case create
}
struct DWGenericViewModel {
    var mode: DWGenericViewMode = .create
    var credentialModel: CustomWalletRecordCertModel?
}
