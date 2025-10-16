//
//  ValuesRowImageTableViewCell.swift
//  dataWallet
//
//  Created by sreelekh N on 24/01/22.
//

import UIKit

protocol ValuesRowImageTableViewCellDelegate: AnyObject {
    func showImageDetail(image: UIImage?)
}

final class ValuesRowImageTableViewCell: UITableViewCell {

    @IBOutlet weak var lbl: UILabel!
    @IBOutlet weak var img: UIImageView!
    
    @IBOutlet weak var leftPadding: NSLayoutConstraint!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var top: NSLayoutConstraint!
    @IBOutlet weak var bottom: NSLayoutConstraint!
    @IBOutlet weak var contentBack: UIView!
    @IBOutlet weak var rightPadding: NSLayoutConstraint!
    
    weak var delegate: ValuesRowImageTableViewCellDelegate?

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func setData(model: IDCardAttributes)  {
        lbl.text = model.name
        img.image = UIApplicationUtils.shared.convertBase64StringToImage(imageBase64String: model.value ?? "")
    }
    
    func renderUI(index: Int, tot: Int) {
        if index == 0 {
            roundTop()
        } else if index == (tot - 1) {
            roundBottom()
        } else {
            regularCell()
        }
    }
    
    private func roundTop() {
        top.constant = 8
        bottom.constant = 0
        contentBack.topMaskedCornerRadius = 10
        lineView.isHidden = false
    }
    
    private func roundBottom() {
        top.constant = 0
        bottom.constant = 8
        contentBack.bottomMaskedCornerRadius = 10
        lineView.isHidden = true
    }
    
    private func regularCell() {
        top.constant = 0
        bottom.constant = 0
        contentBack.IBcornerRadius = 0
        lineView.isHidden = false
    }
    
    func removePadding(){
        leftPadding.constant = 0
        rightPadding.constant = 0
        self.updateConstraintsIfNeeded()
    }
    
    func setPadding(padding: CGFloat) {
        leftPadding.constant = padding
        rightPadding.constant = padding
        self.updateConstraintsIfNeeded()
    }
    
    // Setting card color based on credential branding
    func setCredentialBrandingColor(color: UIColor) {
        lbl.textColor = color.withAlphaComponent(0.5)
        contentBack.backgroundColor = color.withAlphaComponent(0.1)
    }
}
