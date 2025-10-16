//
//  GeneralTitleView.swift
//  dataWallet
//
//  Created by sreelekh N on 21/12/21.
//

import Foundation
import UIKit

final class GeneralTitleView: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var lbl: UILabel!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var leftPadding: NSLayoutConstraint!
    @IBOutlet weak var centerAxisConstraint: NSLayoutConstraint!
    
    var value: String = "" {
        didSet {
            lbl.text = value
        }
    }
    
    var btnNeed = false {
        didSet {
            addBtn.isHidden = !btnNeed
        }
    }
    
    func setLeftPadding(padding: CGFloat){
        self.leftPadding.constant = padding
        updateConstraintsIfNeeded()
    }
    
    func setCenterPadding(padding: CGFloat){
        self.centerAxisConstraint.constant = padding
        updateConstraintsIfNeeded()
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
    
    @IBAction func addAction(_ sender: Any) {
        
    }
}
