//
//  EmptyMessageView.swift
//  dataWallet
//
//  Created by sreelekh N on 29/11/21.
//

import Foundation
import UIKit
final class EmptyMessageView: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var lbl: UILabel!
    
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
    
    enum layoutOn {
        case image(value: String)
        case label(value: String)
        case both(img: String, str: String)
    }
    
    func setValues(value: layoutOn) {
        switch value {
        case .image(let value):
            lbl.isHidden = true
            image.isHidden = false
            image.image = UIImage.getImage(value)
        case .label(let value):
            lbl.isHidden = false
            image.isHidden = true
            lbl.text = value
        case .both(let img, let str):
            lbl.isHidden = false
            image.isHidden = false
            image.image = UIImage.getImage(img)
            lbl.text = str
        }
    }
}
