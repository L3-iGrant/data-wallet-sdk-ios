//
//  ReceiptTotalTableViewCell.swift
//  dataWallet
//
//  Created by iGrant on 13/05/25.
//

import Foundation
import UIKit

class ReceiptTotalTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var blurredTaxView: ReceiptBlurView!
    
    @IBOutlet weak var blurredTotalTextView: ReceiptBlurView!
    
    
    func renderForCredentialBranding(clr: UIColor) {
        titleLabel.textColor = clr.withAlphaComponent(0.5)
        amountLabel.textColor = clr.withAlphaComponent(0.5)
        parentView.backgroundColor = clr.withAlphaComponent(0.1)
        blurredTaxView.textColor = clr
        blurredTotalTextView.textColor = clr
    }
    
    func setTotalInfo( amount: String, percentage: String, taxAmount: String, currency: String, blurStatus: Bool) {
        parentView.bottomMaskedCornerRadius = 10
        titleLabel.text = "receipt_total_Tax".localizedForSDK() + "(\(percentage)%): "
        amountLabel.text = "receipt_total".localizedForSDK()
        blurredTaxView.text = currency + " " + taxAmount
        blurredTotalTextView.text = currency + " " + amount
        blurredTaxView.blurStatus = blurStatus
        blurredTotalTextView.blurStatus = blurStatus
        blurredTotalTextView.blurLbl.textAlignment = .left
        blurredTaxView.blurLbl.textAlignment = .left
    }
}
