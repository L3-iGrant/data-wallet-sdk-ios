//
//  RemoveBtnTableViewCell.swift
//  dataWallet
//
//  Created by sreelekh N on 14/12/21.
//

import UIKit

class RemoveBtnTableViewCell: UITableViewCell {
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var arrowContainer: UIView!
    @IBOutlet weak var lbl: UILabel!
    @IBOutlet weak var topConst: NSLayoutConstraint!
    @IBOutlet weak var bottomConst: NSLayoutConstraint!
    
    enum RenderFor {
        case forward
        case delete
        case forwardPolicy
        case inActive
    }
    
    var renderFor: RenderFor = .forward {
        didSet {
            topConst.constant = 10
            switch renderFor {
            case .forward:
                lbl.textColor = .black
                arrowContainer.isHidden = false
            case .forwardPolicy:
                lbl.font = UIFont.systemFont(ofSize: 15)
                lbl.textColor = .systemGray
                arrowContainer.isHidden = false
            case .inActive:
                lbl.textColor = .lightGray
                lbl.alpha = 0.5
                arrowContainer.isHidden = false
            case .delete:
                lbl.textColor = .red
                arrowContainer.isHidden = true
            }
        }
    }
    
    var title: String = "" {
        didSet {
            lbl.text = title
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        self.alpha = 1
        self.contentView.isUserInteractionEnabled = true
    }
    
    // Setting card color based on credential branding
    func setCredentialColor(textColor: UIColor) {
        backView.backgroundColor = textColor.withAlphaComponent(0.1)
        lbl.textColor = textColor
    }
}
