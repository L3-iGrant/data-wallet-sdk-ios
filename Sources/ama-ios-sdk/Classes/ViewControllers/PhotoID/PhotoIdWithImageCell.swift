//
//  PhotoIdWithImageCell.swift
//  dataWallet
//
//  Created by iGrant on 14/02/25.
//

import Foundation
//import OrderedDictionary
import UIKit

class PhotoIdWithImageCell: UITableViewCell {
    
    @IBOutlet weak var photoIDLogo: UIImageView!
    @IBOutlet weak var ageBadge: UIView!
    @IBOutlet weak var ageOverLabel: UILabel!
    
    @IBOutlet weak var ageBadgeInnerView: UIView!
    
    weak var delegate: ValuesRowImageTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        photoIDLogo.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        photoIDLogo.addGestureRecognizer(tapGesture)
        self.selectionStyle = .none
        // Initialization code
    }
    
    @objc private func imageTapped() {
        delegate?.showImageDetail(image: photoIDLogo.image)
    }
        
    func configureCell(model: OrderedDictionary<String,DWAttributesModel>, blureStatus: Bool = false) {
        print("")
        photoIDLogo.layer.cornerRadius = 70
        ageBadge.layer.cornerRadius = 17.5
        ageBadgeInnerView.layer.cornerRadius = 15.5
        if EBSIWallet.shared.isBase64(string: model["portrait"]?.value ?? "") {
            guard let photoIDImage = UIApplicationUtils.shared.convertBase64StringToImage(imageBase64String: model["portrait"]?.value ?? "") else { return }
            let blurredImage = ImageUtils.shared.blurEffect(image: photoIDImage)
            photoIDLogo.image = blureStatus ? photoIDImage : blurredImage
        } else {
            
            photoIDLogo.tintColor = .black
            let blurredImage = ImageUtils.shared.blurEffect(image: UIImage(systemName: "person.fill")!)
            photoIDLogo.image = blureStatus ? UIImage(systemName: "person.fill") : blurredImage
        }
        if let isAgeOver = model["ageOver18"]?.value {
            if isAgeOver == "true" {
                ageOverLabel.text = "Over 18".localized().uppercased()
                ageBadgeInnerView.backgroundColor = UIColor(hex: "93C74F")
                
            } else {
                ageOverLabel.text = "Under 18".localized().uppercased()
                ageBadgeInnerView.backgroundColor = UIColor(hex: "#E28CF7")
            }
        } else {
            ageBadge.isHidden = true
            ageOverLabel.isHidden = true
            ageBadgeInnerView.isHidden = true
        }
    }
    
    func configureCell(portait: String, ageOver18: Bool?, blureStatus: Bool = false) {
        print("")
        photoIDLogo.layer.cornerRadius = 70
        ageBadge.layer.cornerRadius = 17.5
        ageBadgeInnerView.layer.cornerRadius = 15.5
        if EBSIWallet.shared.isBase64(string: portait) {
            guard let photoIDImage = UIApplicationUtils.shared.convertBase64StringToImage(imageBase64String: portait) else { return }
            let blurredImage = ImageUtils.shared.blurEffect(image: photoIDImage)
            photoIDLogo.image = blureStatus ? photoIDImage : blurredImage
        }else {
            photoIDLogo.image = UIImage(systemName: "person.fill")
            photoIDLogo.tintColor = .black
        }
        if let isAgeOver = ageOver18 {
            if isAgeOver == true {
                ageOverLabel.text = "Over 18".localized().uppercased()
                ageBadgeInnerView.backgroundColor = UIColor(hex: "93C74F")
                
            } else {
                ageOverLabel.text = "Under 18".localized().uppercased()
                ageBadgeInnerView.backgroundColor = UIColor(hex: "#E28CF7")
            }
        } else {
            ageBadge.isHidden = true
            ageOverLabel.isHidden = true
            ageBadgeInnerView.isHidden = true
        }
    }
    
}
