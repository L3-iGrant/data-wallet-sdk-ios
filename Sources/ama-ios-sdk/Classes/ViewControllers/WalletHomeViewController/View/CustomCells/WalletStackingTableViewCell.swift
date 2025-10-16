//
//  WalletStackingTableViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 26/06/21.
//

import UIKit

class WalletStackingTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: HFCardCollectionView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collectionView.layer.cornerRadius = 10
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
