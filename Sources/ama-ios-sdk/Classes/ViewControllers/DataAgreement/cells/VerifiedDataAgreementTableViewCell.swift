//
//  VerifiedDataAgreementTableViewCell.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 22/02/22.
//

import UIKit

final class VerifiedDataAgreementTableViewCell: UITableViewCell {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var verifyLoader: UIActivityIndicatorView!
    @IBOutlet weak var verifiedHeaderStackView: UIStackView!
    @IBOutlet weak var verifiedLockImageView: UIImageView!
    @IBOutlet weak var didLabel: UILabel!
    @IBOutlet weak var signatureLabel: UILabel!
    @IBOutlet weak var didLabelTitle: UILabel!
    @IBOutlet weak var lblVerifiedDataAgreement: UILabel!
    
}
