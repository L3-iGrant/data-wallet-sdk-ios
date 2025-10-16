//
//  RemoveBtnVew.swift
//  dataWallet
//
//  Created by sreelekh N on 21/12/21.
//

import UIKit

class RemoveBtnVew: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var lbl: UILabel!
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        backView.layer.cornerRadius = 10
    }
    
    var value: String = "" {
        didSet {
            lbl.text = value
        }
    }
    
    var layerColor: UIColor? {
        didSet {
            guard let layerColor = layerColor else {
                return
            }
            backView.backgroundColor = layerColor.withAlphaComponent(0.1)
            lbl.textColor = layerColor
        }
    }
    
    var tapAction: (() -> Void)?
    
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
    
    @IBAction func tapAction(_ sender: Any) {
        tapAction?()
    }
}
