//
//  SettingsHeader.swift
//  dataWallet
//
//  Created by sreelekh N on 06/09/22.
//

import UIKit

final class SettingsHeader: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var lbl: UILabel!
    @IBOutlet weak var toggle: UISwitch!
    @IBOutlet weak var topContrain: NSLayoutConstraint!
    @IBOutlet weak var leftConstrain: NSLayoutConstraint!
    @IBOutlet weak var infoButton: UIButton!
    
    var title: String? {
        didSet {
            lbl.text = title?.localize ?? ""
        }
    }
    
    @IBAction func toggleAction(_ sender: Any) {
        
    }
    
    func updateForThirdParty() {
        topContrain.constant = 10
        toggle.isHidden = false
        leftConstrain.constant = 18
        infoButton.isHidden = false
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
