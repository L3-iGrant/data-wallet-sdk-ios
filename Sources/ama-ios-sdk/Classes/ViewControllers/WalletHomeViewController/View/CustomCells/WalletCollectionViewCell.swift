//
//  WalletCollectionViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 25/06/21.
//

import UIKit

class WalletCollectionViewCell: HFCardCollectionViewCell {
    var cardCollectionViewLayout: HFCardCollectionViewLayout?

    @IBOutlet weak var certLogo: UIImageView!
    @IBOutlet weak var certName: UILabel!
    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var baseCardView: UIView!
    @IBOutlet weak var stripView: UIView!
    @IBOutlet weak var orgName: UILabel!
    @IBOutlet weak var heightContraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.baseCardView.layer.cornerRadius = 10
        self.certLogo.layer.cornerRadius = 30
        self.baseCardView.backgroundColor = .white
        self.backgroundColor = .white
//        self.stripView.backgroundColor = AriesMobileAgent.themeColor.withAlphaComponent(0.5).inverse()
        // Initialization code
    }
}
