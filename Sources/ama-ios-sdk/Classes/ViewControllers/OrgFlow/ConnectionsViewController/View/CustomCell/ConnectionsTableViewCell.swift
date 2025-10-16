//
//  ConnectionsTableViewCell.swift
//  dataWallet
//
//  Created by sreelekh N on 10/12/21.
//

import UIKit

final class ConnectionsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var layerView: UIView!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var companyNameLbl: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var separator: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setData(model: CloudAgentConnectionValue, tot: Int, index: Int) {
        companyNameLbl.text = model.theirLabel != "" ? model.theirLabel : "No Name".localized()
        
        if let imageUrl = model.orgDetails?.logoImageURL {
            let orgName = model.orgDetails?.name
            ImageUtils.shared.setRemoteImage(for: imgView, imageUrl: imageUrl, orgName: orgName)
        } else {
            // If no image available
            guard let firstLetter = model.orgDetails?.name?.first else { return }
            let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
            imgView.image = profileImage
        }
        let createdDate = model.createdAt == "" ? AgentWrapper.shared.getCurrentDateTime() : model.createdAt
        let date = createdDate?.substring(to: 10)
        dateLbl.text = date
        if tot == 1 {
            layerView.IBcornerRadius = 10
            separator.isHidden = true
        } else if index == 0 {
            roundTop()
        } else if index == (tot - 1) {
            roundBottom()
        } else {
            regularCell()
        }
    }
    
    private func roundTop() {
        layerView.topMaskedCornerRadius = 10
        separator.isHidden = false
    }
    
    private func roundBottom() {
        layerView.bottomMaskedCornerRadius = 10
        separator.isHidden = true
    }
    
    private func regularCell() {
        layerView.IBcornerRadius = 0
        separator.isHidden = false
    }
}
