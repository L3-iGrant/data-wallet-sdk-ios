//
//  SignImageTableViewCell.swift
//  dataWallet
//
//  Created by sreelekh N on 04/01/22.
//

import UIKit

final class SignImageTableViewCell: UITableViewCell {

    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var signImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        baseView.layer.cornerRadius = 10
    }
}
