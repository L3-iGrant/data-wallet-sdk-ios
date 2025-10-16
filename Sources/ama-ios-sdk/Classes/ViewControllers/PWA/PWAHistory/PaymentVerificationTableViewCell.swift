//
//  PaymentVerificationTableViewCell.swift
//  dataWallet
//
//  Created by iGrant on 09/05/25.
//

import Foundation
import UIKit

final class PaymentVerificationTableViewCell: UITableViewCell {
    
    @IBOutlet weak var paidToLabel: UILabel!
    
    @IBOutlet weak var paymentView: UIView!
    
    @IBOutlet weak var paidToLogo: UIImageView!
    
    
    @IBOutlet weak var payeeLocation: UILabel!
    
    @IBOutlet weak var payeeName: UILabel!
    
    @IBOutlet weak var issuanceTimeLabel: UILabel!
    
    @IBOutlet weak var paymentViewHeightConstraint: NSLayoutConstraint!
    
    
    
    func configureCell(model: PaymentDataConfirmationMySharedDataViewModel?) {
        paidToLabel.text =  "pwa_paid_to".localized().uppercased()
        if model?.history?.value?.history?.connectionModel?.value?.orgDetails?.name != model?.history?.value?.history?.transactionData?.paymentData?.payee {
            payeeName.text = model?.history?.value?.history?.transactionData?.paymentData?.payee
            payeeLocation.text = "via \(model?.history?.value?.history?.connectionModel?.value?.orgDetails?.name ?? "")"
            ImageUtils.shared.setRemoteImage(for: paidToLogo, imageUrl: "", orgName: model?.history?.value?.history?.transactionData?.paymentData?.payee, bgColor: nil)
        } else {
            paymentViewHeightConstraint.constant = 0
            paidToLabel.isHidden = true
            paymentView.isHidden = true
        }
        let dateFormats = ["yyyy-MM-dd hh:mm:ss.SSSSSS a'Z'", "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"]
        let historyDate = DateUtils.shared.parseDate(from: model?.history?.value?.history?.date ?? "", formats: dateFormats)
            if let notifDate = historyDate {
                issuanceTimeLabel.text = "welcome_verified_at".localizedForSDK() +  notifDate.timeAgoDisplay()
            }
    }
    
}
