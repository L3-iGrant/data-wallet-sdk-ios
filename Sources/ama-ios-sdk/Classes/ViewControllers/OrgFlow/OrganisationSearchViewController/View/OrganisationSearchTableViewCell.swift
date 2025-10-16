//
//  OrganisationSearchTableViewCell.swift
//  dataWallet
//
//  Created by sreelekh N on 20/12/21.
//

import UIKit

final class OrganisationSearchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var certName: UILabel!
    @IBOutlet weak var notificationType: UILabel!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var orgImage: UIImageView!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var notificationStatus: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setData(_ history: History) {
        certName.text = history.name ?? ""
        notificationType.text = history.type == HistoryType.exchange.rawValue ? "Data Using Service".localizedForSDK() : "Data Source".localizedForSDK()
        let dateFormat = DateFormatter.init()
        if history.name == CertType.EBSI.rawValue {
            var subType = history.certSubType
            switch history.certSubType ?? "" {
            case EBSI_CredentialType.Diploma.rawValue:
                subType = EBSI_CredentialSearchText.Diploma.rawValue
            case EBSI_CredentialType.StudentID.rawValue:
                subType = EBSI_CredentialSearchText.StudentID.rawValue
            case EBSI_CredentialType.VerifiableID.rawValue:
                subType = EBSI_CredentialSearchText.VerifiableID.rawValue
            case EBSI_CredentialType.PDA1.rawValue:
                subType = EBSI_CredentialSearchText.PDA1.rawValue
            default: break
        }
            certName.text = subType ?? history.name ?? ""
        }
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
        dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
        if let notifDate = dateFormat.date(from: history.date ?? "") {
            time.text = notifDate.timeAgoDisplay()
        }
        
        var logoUrl: String? = nil
        let orgName = history.connectionModel?.value?.orgDetails?.name
        logoUrl = history.display?.logo ?? history.connectionModel?.value?.orgDetails?.logoImageURL
        let bgColour = history.display?.backgroundColor
        let firstLetter =  orgName?.first ?? "U"
        let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
        ImageUtils.shared.setRemoteImage(for: orgImage, imageUrl: logoUrl, orgName: orgName, bgColor: bgColour, placeHolderImage: profileImage)
        //orgImage.loadFromUrl(history.connectionModel?.value?.imageURL ?? "")
    }
    
}
