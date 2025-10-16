//
//  ExchangeDataImagePreviewTableViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 03/06/21.
//

import UIKit

class ExchangeDataImagePreviewTableViewCell: UITableViewCell {
    @IBOutlet weak var attrName: UILabel!
    @IBOutlet weak var attrImage: UIImageView!
    @IBOutlet weak var seperator: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setBlur(value: Bool){
//        attrValue.isBlurring = value
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
