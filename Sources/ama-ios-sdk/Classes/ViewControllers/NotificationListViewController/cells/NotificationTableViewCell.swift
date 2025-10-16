//
//  NotificationTableViewCell.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 19/01/21.
//

import UIKit

class NotificationTableViewCell: UITableViewCell {

    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var notificationType: UILabel!
    @IBOutlet weak var certName: UILabel!
    @IBOutlet weak var orgImage: UIImageView!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var notificationStatus: UILabel!
    @IBOutlet weak var cardLeftAnchor: NSLayoutConstraint!
    @IBOutlet weak var cardRightAnchor: NSLayoutConstraint!
    @IBOutlet weak var rightArrowIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        orgImage.layer.cornerRadius = 35
        // Initialization code
    }
    
    func configForPullDataNotification(){
        cardLeftAnchor.constant = 20
        cardRightAnchor.constant = 20
        shadowView.layer.cornerRadius = 10
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCredentialBrandingBGcolor(color: UIColor) {
        shadowView.backgroundColor = color
    }

    func setCredentialBrandingTextColor(textColor: UIColor) {
        time.textColor = textColor
        certName.textColor = textColor
        notificationType.textColor = textColor
        notificationStatus.textColor = textColor
//        if let deleteButton = deleteButton {
//            deleteButton.tintColor = textColor
//        }
    }
    
}
