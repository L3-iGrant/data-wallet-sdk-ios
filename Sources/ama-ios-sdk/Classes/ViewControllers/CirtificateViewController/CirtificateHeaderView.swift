//
//  CirtificateHeaderView.swift
//  dataWallet
//
//  Created by sreelekh N on 07/01/22.
//

import UIKit
protocol CirtificateHeaderDelegate: AnyObject {
    func scanAction()
}

final class CirtificateHeaderView: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var subLbl: UILabel!
    @IBOutlet weak var scanBtn: UIButton!
    
    weak var delegate: CirtificateHeaderDelegate?
    var btnImage: UIImage? {
        didSet {
            scanBtn.setImage(btnImage?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
    }
    
    @IBAction func scanBtnAction(_ sender: Any) {
        delegate?.scanAction()
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
