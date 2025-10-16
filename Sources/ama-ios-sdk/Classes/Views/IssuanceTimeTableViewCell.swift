//
//  IssuanceTimeTableViewCell.swift
//  ama-ios-sdk
//
//  Created by iGrant on 25/04/25.
//

import Foundation
import UIKit

class IssuanceTimeTableViewCell: UITableViewCell {
    
    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setTextColor(colour: UIColor = .systemGray) {
        timeLabel.textColor = colour
    }
    
    func setData(text: String, data: CustomWalletRecordCertModel? = nil, isFromExpired: Bool? = false, isFromExchange: Bool = false) {
        if isFromExchange {
            timeLabel.text = "Verified: " + text
        } else {
            timeLabel.text = "Issued: " + text
        }
    }
    
}
