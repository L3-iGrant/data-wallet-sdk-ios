//
//  ShareDataFloting.swift
//  dataWallet
//
//  Created by sreelekh N on 26/11/21.
//

import Foundation
import UIKit

protocol ShareDataFlotingDelegate: AnyObject {
    func shareDataTapped()
}

final class ShareDataFloting: UIView {
    @IBOutlet var view: UIView!
    @IBOutlet weak var shareBtn: UIButton!
    
    weak var delegate: ShareDataFlotingDelegate?
    
    func title(lbl: String) {
        shareBtn.setTitle(lbl, for: .normal)
        shareBtn.setImage(nil, for: .normal)
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
    
    @IBAction func shareAction(_ sender: Any) {
        delegate?.shareDataTapped()
    }
}
