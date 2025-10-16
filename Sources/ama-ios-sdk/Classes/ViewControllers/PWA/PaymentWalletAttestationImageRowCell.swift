//
//  ValuesRowImageTableViewCell.swift
//  dataWallet
//
//  Created by sreelekh N on 24/01/22.
//

import UIKit

final class PaymentWalletAttestationImageRowCell: UITableViewCell {

    @IBOutlet weak var lbl: UILabel!
    @IBOutlet weak var img: UIImageView!
    
    @IBOutlet weak var blurredView: BlurredTextView!
    @IBOutlet weak var leftPadding: NSLayoutConstraint!
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var top: NSLayoutConstraint!
    @IBOutlet weak var bottom: NSLayoutConstraint!
    @IBOutlet weak var contentBack: UIView!
    @IBOutlet weak var rightPadding: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setData(model: IDCardAttributes, tot: Int, blurStatus: Bool)  {
        img.image = identifyCardType(model: model)
        if model.value?.isNotEmpty ?? true {
            blurredView.text = model.value
        } else {
            blurredView.text = "NA"
        }
        img.tintColor = .black
        blurredView.blurStatus = blurStatus
    }
    
    func renderUI(index: Int, tot: Int) {
        if tot == 1 {
            roundAllCorner()
        } else if index == 0 {
            roundTop()
        } else if index == (tot - 1) {
            roundBottom()
        } else {
            regularCell()
        }
    }
    
    func identifyCardType(model: IDCardAttributes) -> UIImage? {
        if model.type == .account {
            return UIImage(named: "account_balance")!
        } else if model.type == .card {
            guard let cardNumber = model.value, !cardNumber.isEmpty else {
                return UIImage(named: "visa")!
            }
            let sanitizedCardNumber = cardNumber.replacingOccurrences(of: "[-\\s]", with: "", options: .regularExpression)
            guard sanitizedCardNumber.count >= 6 else {
                return UIImage(named: "visa")!
            }
            let prefix = String(sanitizedCardNumber.prefix(6))
            if sanitizedCardNumber.hasPrefix("4") {
                return UIImage(named: "visa")!
            } else if let firstTwoDigits = Int(sanitizedCardNumber.prefix(2)),
                      (51...55).contains(firstTwoDigits) || (2221...2720).contains(Int(prefix) ?? 0) {
                return UIImage(named: "mastercard")!
            } else if sanitizedCardNumber.hasPrefix("34") || sanitizedCardNumber.hasPrefix("37") {
                return UIImage(named: "american_express")!
            } else if let firstFourDigits = Int(sanitizedCardNumber.prefix(4)),
                      (3528...3589).contains(firstFourDigits) {
                return UIImage(named: "jcb")!
            } else if let firstFourDigits = Int(sanitizedCardNumber.prefix(4)),
                      firstFourDigits == 6011 || (622126...622925).contains(firstFourDigits) ||
                        (644...649).contains(firstFourDigits) || sanitizedCardNumber.hasPrefix("65") {
                return UIImage(named: "discover")!
            } else if sanitizedCardNumber.hasPrefix("60") ||
                        (6521...6522).contains(Int(prefix) ?? 0) {
                return UIImage(named: "RuPay")!
            } else if let firstTwoDigits = Int(sanitizedCardNumber.prefix(2)),
                      (56...69).contains(firstTwoDigits) {
                return UIImage(named: "maestro")!
            } else {
                return UIImage(named: "visa")!
            }
        }
        return nil
    }
    
    private func roundAllCorner(){
        top.constant = 8
        bottom.constant = 8
        contentBack.maskedCornerRadius = 10
        lineView.isHidden = true
    }
    
    private func roundTop() {
        top.constant = 8
        bottom.constant = 0
        contentBack.topMaskedCornerRadius = 10
        lineView.isHidden = false
    }
    
    private func roundBottom() {
        top.constant = 0
        bottom.constant = 8
        contentBack.bottomMaskedCornerRadius = 10
        lineView.isHidden = true
    }
    
    private func regularCell() {
        top.constant = 0
        bottom.constant = 0
        contentBack.IBcornerRadius = 0
        lineView.isHidden = false
    }
    
    func removePadding(){
        leftPadding.constant = 0
        rightPadding.constant = 0
        self.updateConstraintsIfNeeded()
    }
    
    func setPadding(padding: CGFloat) {
        leftPadding.constant = padding
        rightPadding.constant = padding
        self.updateConstraintsIfNeeded()
    }
    
    // Setting card color based on credential branding
    func setCredentialBrandingColor(color: UIColor) {
        lineView.backgroundColor = color
        blurredView.textColor = color.withAlphaComponent(0.5)
        contentBack.backgroundColor = color.withAlphaComponent(0.1)
    }
    
}
