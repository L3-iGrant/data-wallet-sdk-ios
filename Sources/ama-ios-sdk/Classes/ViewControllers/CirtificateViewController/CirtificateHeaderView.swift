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
    
    func setTitles(type: CovidCertType?, issuer: String) {
        switch type {
        case .India:
            titleLbl.text = "Ministry of Health and Family Welfare".localizedForSDK()
            subLbl.text = "Government of India".localizedForSDK()
        case .Europe:
            titleLbl.text = "EU Digital COVID Certificate".localizedForSDK()
            subLbl.text = issuer
        case .Malaysia:
            titleLbl.text = "Ministry of Health".localizedForSDK()
            subLbl.text = "Government of Malaysia".localizedForSDK()
        case .UK:
            titleLbl.text = "Digital COVID Certificate".localizedForSDK()
            subLbl.text = "Covid vaccination certificate United Kingdom".localizedForSDK()
        case .Philippine:
            titleLbl.text = "Department of Health".localizedForSDK()
            subLbl.text = "Govt of Philippines".localizedForSDK()
        default:
            titleLbl.text = "Digital COVID Certificate".localizedForSDK()
            subLbl.text = issuer
        }
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
