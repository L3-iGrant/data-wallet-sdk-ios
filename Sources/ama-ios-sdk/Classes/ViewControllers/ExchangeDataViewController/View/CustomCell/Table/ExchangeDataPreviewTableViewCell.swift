//
//  ExchangeDataPreviewTableViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 29/07/21.
//


import UIKit

class ExchangeDataPreviewTableViewCell: UITableViewCell {

    @IBOutlet weak var attrValue: BlurredLabel!
    @IBOutlet weak var attrName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        layoutIfNeeded()
    }

    func setBlur(value: Bool){
        attrValue.isBlurring = value
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
