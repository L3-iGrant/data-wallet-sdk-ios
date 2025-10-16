//
//  AddCovidCertificateTableViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 17/07/21.
//

import UIKit

class AddCovidCertificateTableViewCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var subImage: UIImageView!
    @IBOutlet weak var shadowView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
//        mainImage.layer.cornerRadius = 35
        shadowView.layer.cornerRadius = 10
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
