//
//  CustomNavigationBarIconView.swift
//  dataWallet
//
//  Created by sreelekh N on 15/01/22.
//

import UIKit
protocol CustomNavigationBarIconViewDelegate: UIViewController {
    func cusNavtappedAction(tag: Int)
}

final class CustomNavigationBarIconView: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var iconImg: UIImageView!
    @IBOutlet weak var imageheight: NSLayoutConstraint!
    @IBOutlet weak var leftConstraint: NSLayoutConstraint!
    
    weak var delegate: CustomNavigationBarIconViewDelegate?
    
    @IBAction func actionTapped(_ sender: Any) {
        delegate?.cusNavtappedAction(tag: self.tag)
    }
    
    func updateForAlpha(alpha: CGFloat) {
        containerView.alpha = 1 - alpha
        if alpha > 0.7 {
            iconImg.tintColor = .black
        } else {
            iconImg.tintColor = .white
        }
    }
    
    func updateImageHeight(update: Int) {
        imageheight.constant = CGFloat(23 + update)
    }
    
    func setRight() {
        self.leftConstraint.constant = self.frame.width - self.containerView.frame.width + 10
    }
    
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
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
