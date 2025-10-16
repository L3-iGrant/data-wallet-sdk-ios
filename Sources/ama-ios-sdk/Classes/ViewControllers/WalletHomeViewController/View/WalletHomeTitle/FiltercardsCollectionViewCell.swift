//
//  FiltercardsCollectionViewCell.swift
//  dataWallet
//
//  Created by sreelekh N on 02/11/21.
//

import UIKit

class FiltercardsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func loadData(row: Int, selectedIndex: Int) {
        imgView.isHidden = HomeFilterContents(rawValue: row)?.image == nil ? true : false
        imgView.image = HomeFilterContents(rawValue: row)?.image ?? nil
        lbl.text = HomeFilterContents(rawValue: row)?.name.localizedForSDK() ?? ""
        backView.IBborderColor = row == selectedIndex ? .black : .clear
    }
}

enum HomeFilterContents: Int, CaseIterable {
    case all, profile, idCards, health, travel, receipts
    
    var image: UIImage? {
        switch self {
        case .all:
            return nil
        case .profile:
            return UIImage.getImage("user")
        case .idCards:
            return UIImage.getImage("id-card")
        case .health:
            return UIImage.getImage("first-aid-kit")
        case .travel:
            return UIImage.getImage("passport")
        case .receipts:
            return UIImage.getImage("bill")
        }
    }
    
    var name: String {
        switch self {
        case .all:
            return "All"
        case .profile:
            return "My Profile"
        case .idCards:
            return "ID Cards"
        case .health:
            return "Health"
        case .travel:
            return "Travel"
        case .receipts:
            return "Receipts"
        }
    }
}
