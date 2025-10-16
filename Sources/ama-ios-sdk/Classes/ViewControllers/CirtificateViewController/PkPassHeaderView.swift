//
//  PkPassHeaderView.swift
//  dataWallet
//
//  Created by sreelekh N on 08/01/22.
//

import UIKit

final class PkPassHeaderView: UIView {
    
    @IBOutlet var view: UIView!
    
    @IBOutlet weak var logoHeight: NSLayoutConstraint!
    @IBOutlet weak var logoWidth: NSLayoutConstraint! {
        didSet {
            logoWidth.priority = UILayoutPriority(1000)
        }
    }
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var headerStack: UIStackView!
    @IBOutlet weak var from: UILabel!
    @IBOutlet weak var fromLocationShort: UILabel!
    @IBOutlet weak var pkpassTypeImage: UIImageView!
    @IBOutlet weak var to: UILabel!
    @IBOutlet weak var toLocationShort: UILabel!
    @IBOutlet weak var flightDetailTitleLbl: UILabel!
    @IBOutlet weak var flightDetailDesLbl: UILabel!
    
    
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
    
    func setData(model: PKPassStateViewModel) {
        self.view.backgroundColor = model.bgColor
        for subview in self.view.subviews {
            if let label = subview as? UILabel {
                label.textColor = model.fgColor ?? .black
            }
        }
        let labelColor = model.labelColor ?? .black
        let logoImage = UIImage(data: model.logoImageData ?? Data())?.withRenderingMode(.alwaysOriginal)
        self.logo.image = logoImage
        let estimateWidth = CGFloat(150)
        let estimateHeight = CGFloat(60)
        if (logo.image?.size.height ?? 0) > estimateHeight {
            let ratio = estimateHeight/(logoImage?.size.height ?? estimateHeight)
            self.logoWidth.constant = (logoImage?.size.width ?? estimateWidth) * ratio
            self.logoHeight.constant = (logoImage?.size.height ?? estimateHeight) * ratio
        } else {
            self.logoHeight.constant = logoImage?.size.height ?? estimateHeight
            if (logo.image?.size.width ?? 0) > estimateWidth {
                let ratio = estimateWidth/(logoImage?.size.width ?? estimateWidth)
                self.logoWidth.constant = (logoImage?.size.width ?? estimateWidth) * ratio
                self.logoHeight.constant = (logoImage?.size.height ?? estimateHeight) * ratio
            } else {
                self.logoWidth.constant = logoImage?.size.width ?? estimateWidth
            }
        }
        
        self.flightDetailTitleLbl.textColor = labelColor
        self.flightDetailTitleLbl.text = model.subTitle
        self.flightDetailTitleLbl.isHidden = (model.subTitle?.isEmpty ?? true) ? true : false
        
        var description = String()
        for item in model.headerFieldArray {
            let sub = (item.name ?? "") + ": " + (item.value ?? "")
            if description.isEmpty {
                description.append(contentsOf: sub)
            } else {
                description.append(contentsOf: "\n" + sub)
            }
        }
        self.flightDetailDesLbl.isHidden = description.isEmpty ? true : false
        self.flightDetailDesLbl.textColor  = labelColor
        self.flightDetailDesLbl.text = description
        
        self.from.text = model.origin
        self.fromLocationShort.text = model.origin_short
        self.to.text = model.destination
        self.toLocationShort.text = model.destination_short
        self.from.textColor = labelColor
        self.to.textColor = labelColor
        self.fromLocationShort.textColor = labelColor
        self.toLocationShort.textColor = labelColor
        self.pkpassTypeImage.image = PKPassUtils.shared.getImageofTransitForWalletList(transit: model.transitType).withTintColor(model.labelColor ?? .darkGray)
    }
}
