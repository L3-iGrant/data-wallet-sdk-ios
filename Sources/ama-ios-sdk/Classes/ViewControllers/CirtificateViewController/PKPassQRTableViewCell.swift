//
//  PKPassQRTableViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 22/12/21.
//

import UIKit

final class PKPassQRTableViewCell: UITableViewCell {

    @IBOutlet weak var rightArrow: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var QRCode: UIImageView!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var buttonViewHeightConstarint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTop: NSLayoutConstraint!
    @IBOutlet weak var buttonViewTop: NSLayoutConstraint!
    
    weak var delegate: ValuesRowImageTableViewCellDelegate?
   
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func renderUI(clr: UIColor) {
        buttonView.backgroundColor = clr.withAlphaComponent(0.1)
        button.setTitleColor(clr, for: .normal)
        button.titleLabel?.textColor = clr
        rightArrow.tintColor = clr
    }
    
    func removeAdditionalData() {
        buttonViewHeightConstarint.constant = 0
        buttonViewTop.constant = 8
        imageViewTop.constant = 16
    }
    
}
