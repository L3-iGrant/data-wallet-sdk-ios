//
//  PaymentDataConfirmationTableViewCell.swift
//  dataWallet
//
//  Created by iGrant on 07/05/25.
//

import Foundation
import eudiWalletOidcIos
import UIKit

final class PaymentDataConfirmationTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var orgImage: UIImageView!
    
    @IBOutlet weak var orgName: UILabel!
    
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    
    func configureCell(transactionData: TransactionData?, clientMetaDataModel: ClientMetaData?) {
        orgName.text = transactionData?.paymentData?.payee
        let verifierLogoUrl = clientMetaDataModel?.logoUri
        if PaymentUtils.isBankLeadFlow(clientMetaData: clientMetaDataModel, transactionData: transactionData) {
            let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: transactionData?.paymentData?.payee?.first ?? "U" , size: CGSize(width: 100, height: 100))
            orgImage.image = profileImage
            locationLabel.text = "via" + " " + (clientMetaDataModel?.clientName ?? "")
            verifiedImageView.isHidden = true
        } else {
            locationLabel.text = clientMetaDataModel?.location
            ImageUtils.shared.setRemoteImage(for: orgImage, imageUrl: verifierLogoUrl, orgName: transactionData?.paymentData?.payee)
        }
    }
    
}
