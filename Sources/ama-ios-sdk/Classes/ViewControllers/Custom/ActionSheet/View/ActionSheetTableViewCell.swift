//
//  ActionSheetTableViewCell.swift
//  dataWallet
//
//  Created by sreelekh N on 10/12/21.
//

import UIKit
final class ActionSheetTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var lbl: UILabel!
    @IBOutlet weak var centerView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func loadData(row: Int, selectedIndex: Int) {
        let connect = ActionSheetContent.connections
        lbl.text = connect.array[row].localizedForSDK()
        centerView.isHidden = row == selectedIndex ? false : true
        let image = connect.images[row]
        imgView.isHidden = image.isEmpty ? true : false
        imgView.image = image.getImage()
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        if row > 1 {
            self.isUserInteractionEnabled = false
            self.contentView.alpha = 0.5
        } else {
            self.isUserInteractionEnabled = true
            self.contentView.alpha = 1
        }
    }
    
    func loadData(renderFor: ActionSheetPageType, row: Int, selectedIndex: Int) {
        switch renderFor {
        case .connectionActionSheet:
            break
        case .thirdPartyPage(let sections),.history(sections: let sections):
            lbl.text = sections[row].capitalized
            imgView.isHidden = true
        }
        centerView.isHidden = row == selectedIndex ? false : true
    }
}

enum ActionSheetContent: CaseIterable {
    case connections
    
    var array: [String] {
        switch self {
        case .connections:
            return [LocalizationSheet.all, LocalizationSheet.connection_organisations, LocalizationSheet.connection_people, LocalizationSheet.connection_devices]
        }
    }
    
    var images: [String] {
        switch self {
        case .connections:
            return ["", "organisation", "people", "laptopcomputer.and.iphone"]
        }
    }
}
