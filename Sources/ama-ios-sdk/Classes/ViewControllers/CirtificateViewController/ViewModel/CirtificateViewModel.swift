//
//  CirtificateViewModel.swift
//  dataWallet
//
//  Created by sreelekh N on 07/01/22.
//

import Foundation
protocol CirtificateDelegate: AnyObject {
    func idCardSaved()
    func updateUI()
    func popVC()
    func notSupportedPKPass()
}

final class CirtificateViewModel: NSObject {
    var addedDate = ""
    let passport = PassportStateViewModel()
    var aadhar: AadharStateViewModel?
    var covid: CovidCertificateStateViewModel?
    var pkPass: PKPassStateViewModel?
    var general: GeneralStateViewModel?
    var receipt: ReceiptStateViewModel?
    var pwaCert: PWACertViewModel?
    var photoID: SelfAttestedPhotoIDViewModel?
    var multipleType: MultipleTypeCards?
}
