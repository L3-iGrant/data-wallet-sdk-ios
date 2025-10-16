//
//  PWAHistoryView.swift
//  dataWallet
//
//  Created by iGrant on 05/02/25.
//

import Foundation
import UIKit

class PWAHistoryView: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var paymentConfirmedLabel: UILabel!
    @IBOutlet weak var rupeesLabel: UILabel!
    @IBOutlet weak var paymentCardView: UIView!
    @IBOutlet weak var cardBgImage: UIImageView!
    @IBOutlet weak var cardSchemeImage: UIImageView!
    @IBOutlet weak var cardNumber: UILabel!
    @IBOutlet weak var verifierLogo: UIImageView!
    @IBOutlet weak var issuanceLabel: UILabel!
    @IBOutlet weak var blurredTextView: BlurredTextView!
    @IBOutlet weak var labelStackView: UIStackView!
    
    @IBOutlet weak var verifierLogoWidth: NSLayoutConstraint!
    
    @IBOutlet weak var verifierLogoHeight: NSLayoutConstraint!
    
    @IBOutlet weak var cardParentView: UIView!
    
    @IBOutlet weak var overviewTitleLabel: UILabel!
    
    @IBOutlet weak var overviewDescription: UILabel!
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerView()
        addView(subview: view)
    }
    
    required init(title: String) {
        super.init(frame: .zero)
        registerView()
        addView(subview: view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(model: PaymentDataConfirmationMySharedDataViewModel?, blurStatus: Bool) {
//        bankAccountView.layer.cornerRadius = 8
//        rupeesBlurredView.blurLbl.font = UIFont.systemFont(ofSize: 55)
        if let model = model {
            blurredTextView.blurStatus = blurStatus
            blurredTextView.blurLbl.textAlignment = .left
            blurredTextView.blurLbl.font = UIFont.systemFont(ofSize: 17, weight: .bold)
            guard let fundingSource = model.history?.value?.history?.fundingSource else { return }
            ImageUtils.shared.loadImage(from: fundingSource.icon ?? "", imageIcon: verifierLogo, logoWidth: verifierLogoWidth, logoHeight: verifierLogoHeight)
            blurredTextView.text = "****" + " " + (fundingSource.panLastFour ?? "")
            if let cover = model.history?.value?.history?.display?.cover {
                UIApplicationUtils.shared.setRemoteImageOn(cardBgImage, url: cover)
            } else {
                cardBgImage.backgroundColor = UIColor(hex: model.history?.value?.history?.display?.backgroundColor ?? "")
            }
            cardSchemeImage.image = getLogoDetails(cardScheme: fundingSource.scheme)
            if let textColor = model.history?.value?.history?.display?.textColor {
                blurredTextView.blurLbl.textColor = UIColor(hex: textColor)
                cardSchemeImage.tintColor = UIColor(hex: textColor)
            }
            let dateFormats = ["yyyy-MM-dd hh:mm:ss.SSSSSS a'Z'", "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"]
            let historyDate = DateUtils.shared.parseDate(from: model.history?.value?.history?.date ?? "", formats: dateFormats)
            if let notifDate = historyDate {
                issuanceLabel.text = "welcome_issued_at".localizedForSDK() + notifDate.timeAgoDisplay()
            }
            overviewTitleLabel.text = "connection_overview".localizedForSDK()
            overviewDescription.text = model.history?.value?.history?.connectionModel?.value?.orgDetails?.organisationInfoModelDescription
            cardParentView.layer.shadowColor = UIColor.gray.cgColor
            cardParentView.layer.shadowOpacity = 0.5
            cardParentView.layer.shadowRadius = 8
            cardParentView.layer.masksToBounds = false
            cardParentView.layer.shadowOffset = CGSize(width: 0, height: 0)
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
    
}
