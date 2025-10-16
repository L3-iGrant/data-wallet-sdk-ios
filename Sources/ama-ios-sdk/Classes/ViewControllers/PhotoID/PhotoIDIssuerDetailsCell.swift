//
//  PhotoIDIssuerDetailsCell..swift
//  dataWallet
//
//  Created by iGrant on 27/06/25.
//

import Foundation
import UIKit

final class PhotoIDIssuerDetailsCell: UITableViewCell {
    
    @IBOutlet weak var organizationImageView: UIImageView!
    
    @IBOutlet weak var verifiedImage: UIImageView!
    
    @IBOutlet weak var trustedLabel: UILabel!
    
    @IBOutlet weak var trustedStackView: UIStackView!
    
    
    @IBOutlet weak var parentView: UIView!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var organizationName: UILabel!
    
    @IBOutlet weak var imageLayerView: UIView!
    
    
    var orgInfo: OrganisationInfoModel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        parentView.layer.cornerRadius = 8
        imageLayerView.setShadowWithColor(color: .gray, opacity: 0.5, offset: CGSize.zero, radius: 5, viewCornerRadius: 20)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(trustServicetapped))
        self.trustedStackView.addGestureRecognizer(tapGesture)
        self.selectionStyle = .none
    }
    
    func renderForCredebtialBranding(clr: UIColor) {
        parentView.backgroundColor = clr.withAlphaComponent(0.1)
        organizationName.textColor = clr
    }
    
    
    func configureCell(value: OrganisationInfoModel?) {
        orgInfo = value
        guard let value = value else {
            return
        }
        locationLabel.text = value.location
        organizationName.text = value.name
        let imageURL = value.logoImageURL
        ImageUtils.shared.setRemoteImage(for: organizationImageView, imageUrl: imageURL, orgName: value.name)
        if let isValidOrganization = value.isValidOrganization {
            if isValidOrganization {
                trustedStackView.isHidden = false
                locationLabel.isHidden = true
                verifiedImage.image = UIImage(named: "gpp_good")
                verifiedImage.tintColor = UIColor(hex: "1EAA61")
                trustedLabel.textColor = UIColor(hex: "1EAA61")
                trustedLabel.text = "general_trusted_service_provider".localizedForSDK()
            } else {
                trustedStackView.isHidden = false
                locationLabel.isHidden = true
                verifiedImage.image = UIImage(named: "gpp_bad")
                verifiedImage.tintColor = .red
                trustedLabel.textColor = .red
                trustedLabel.text = "Untrusted Service Provider"
            }
        } else {
            trustedStackView.isHidden = true
            locationLabel.isHidden = false
        }
        imageLayerView.setShadowWithColor(color: .gray, opacity: 0.5, offset: CGSize.zero, radius: 5, viewCornerRadius: 20)
        
    }
    
    
    @objc func trustServicetapped() {
        var credential = orgInfo?.x5c
        TrustMechanismManager().trustProviderInfo(credential: credential, format: "", jwksURI: orgInfo?.jwksURL) { data in
            if let data = data {
                DispatchQueue.main.async {
                    let vc = TrustServiceProviersBottomSheetVC(nibName: "TrustServiceProviersBottomSheetVC", bundle: nil)
                    vc.modalPresentationStyle = .overFullScreen
                    vc.modalTransitionStyle = .crossDissolve
                    vc.viewModel.data = data
                    vc.viewModel.credential = credential
                    if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                        navVC.present(vc, animated: true, completion: nil)
                    } else {
                        UIApplicationUtils.shared.getTopVC()?.present(vc, animated: true)
                    }
                }
            }
        }
    }
    
    
    
    
    
}
