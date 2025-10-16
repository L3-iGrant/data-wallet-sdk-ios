//
//  BoardingPassDetailsTableViewCell.swift
//  dataWallet
//
//  Created by iGrant on 06/08/25.
//

import Foundation
import UIKit

final class BoardingPassDetailsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imageLogo: UIImageView!
    
    @IBOutlet weak var seatLabel: UILabel!
    
    @IBOutlet weak var typeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    func updateCellData(imageData: String?, seat: String?, type: String?) {
        if let image = imageData {
            ImageUtils.shared.setRemoteImage(for: imageLogo, imageUrl: image, orgName: nil)
        }
        if let seat = seat {
            seatLabel.text = "Seat: \(seat)"
        }
        
        if let type = type {
            typeLabel.text = "Type: \(type)"
        }
    }
    
    func renderForCredebtialBranding(clr: UIColor) {
        seatLabel.textColor = clr
        typeLabel.textColor = clr
    }
    
}
