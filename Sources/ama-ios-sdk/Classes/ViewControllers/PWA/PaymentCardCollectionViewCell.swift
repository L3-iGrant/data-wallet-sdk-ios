//
//  PaymentCardCollectionViewCell.swift
//  dataWallet
//
//  Created by iGrant on 04/02/25.
//

import Foundation
import UIKit

protocol PaymentCardCollectionViewCellDelegate: AnyObject {
    func deletePWACard()
}

class PaymentCardCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var cardNumber: UILabel!
    @IBOutlet weak var cardBgLogo: UIImageView!
    @IBOutlet weak var cardSchemeLogo: UIImageView!
    @IBOutlet weak var verifierLogo: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var blurredTextView: BlurredTextView!
    
    @IBOutlet weak var deleteBgView: UIView!
    
    @IBOutlet weak var verifierLogoWidth: NSLayoutConstraint!
    
    @IBOutlet weak var verifierLogoHeight: NSLayoutConstraint!
    
    var isFromVerification: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    weak var delegate: PaymentCardCollectionViewCellDelegate?
    
    func updateCell(model: SearchItems_CustomWalletRecordCertModel?, showValue: Bool, hideDelete: Bool = false) {
        guard let data = model, let fundingSource = data.value?.fundingSource else { return }
        cardBgLogo.image = nil
        blurredTextView.blurLbl.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        ImageUtils.shared.loadImage(from: fundingSource.icon ?? "", imageIcon: verifierLogo, logoWidth: verifierLogoWidth, logoHeight: verifierLogoHeight)
        blurredTextView.blurStatus = showValue
        blurredTextView.blurLbl.textAlignment = .left
        blurredTextView.text = "****" + " " + (fundingSource.panLastFour ?? "")
        if let cover = data.value?.cover {
            UIApplicationUtils.shared.setRemoteImageOn(cardBgLogo, url: cover, placeholderImage: nil)
        } else {
            cardBgLogo.backgroundColor = UIColor(hex: data.value?.backgroundColor ?? "")
        }
        deleteButton.isHidden = hideDelete ? true : false
        deleteBgView.isHidden = hideDelete ? true : false
        parentView.layer.shadowColor = UIColor.gray.cgColor
        parentView.layer.shadowOpacity = 0.5
        parentView.layer.shadowRadius = 8
        parentView.layer.masksToBounds = false
        parentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        cardSchemeLogo.image = getLogoDetails(cardScheme: fundingSource.scheme)
        if let textColor = model?.value?.textColor {
            blurredTextView.blurLbl.textColor = UIColor(hex: textColor)
            cardSchemeLogo.tintColor = UIColor(hex: textColor)
        }
    }

    
    func getLogoDetails(cardScheme: String?) -> UIImage {
            guard let cardScheme = cardScheme, !cardScheme.isEmpty else {
                return "visa".getImage()
            }
        if cardScheme.contains("visa") {
                return "visa".getImage()
            } else if  cardScheme.contains("Mastercard"){
                return "mastercard".getImage()
            } else if  cardScheme.contains("American Express"){
                return "american_express".getImage()
            } else if cardScheme.contains("JCB") {
                return "jcb".getImage()
            } else if cardScheme.contains("Discover") {
                return "discover".getImage()
            } else if cardScheme.contains("RuPay") {
                return "RuPay".getImage()
            } else if cardScheme.contains("maestro") {
                return "maestro".getImage()
            } else {
                return "visa".getImage()
            }
    }
    
    @IBAction func deletePWACard(_ sender: Any) {
        delegate?.deletePWACard()
    }
    
    
}
