//
//  OverViewTableViewCell.swift
//  dataWallet
//
//  Created by sreelekh N on 14/12/21.
//

import UIKit

final class OverViewTableViewCell: UITableViewCell {

    @IBOutlet weak var desLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    // Setting card color based on credential branding
    func setTitleColor(color: UIColor) {
        desLbl.textColor = color
        titleLbl.textColor = color
    }
    
}
