//
//  ReceiptTableViewCell.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 28/01/23.
//

import UIKit

class ReceiptTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lineView: UIView!
    @IBOutlet weak var mainLbl: UILabel!
    @IBOutlet weak var QntyLbl: UILabel!
    @IBOutlet weak var top: NSLayoutConstraint!
    @IBOutlet weak var bottom: NSLayoutConstraint!
    @IBOutlet weak var contentBack: UIView!
    @IBOutlet weak var blurView: BlurredTextView!
    @IBOutlet weak var frameView: UIView!
    @IBOutlet weak var containerStack: UIStackView!
    @IBOutlet weak var leftPadding: NSLayoutConstraint!
    @IBOutlet weak var rightPadding: NSLayoutConstraint!
    @IBOutlet weak var containerStackRighConstaint: NSLayoutConstraint!
    @IBOutlet weak var headerStack: UIStackView!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var itemLabel: UILabel!
    
    @IBOutlet weak var quantityHeaderLabel: UILabel!
    
    var tapGesture = UITapGestureRecognizer()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
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
    
    func setData(model: InvoiceLine, blurStatus: Bool,
                 currency: String, makeFirstLetterUppercase: Bool = true) {
        containerStack.isHidden = false
        headerStack.isHidden = true
        if makeFirstLetterUppercase {
            mainLbl.text = model.item?.name?.uppercaseFirstWords
        } else {
            mainLbl.text = model.item?.name ?? ""
        }
        if let price = model.price?.priceAmount {
            blurView.text = currency + " \(price)"
        } else {
            blurView.text = "NA"
        }
        QntyLbl.text = model.invoicedQuantity
        blurView.blurStatus = blurStatus
        blurView.blurLbl.textAlignment = .left
    }
    
    func setHeader( blurStatus: Bool, isFromNewReceipt: Bool = false) {
        containerStack.isHidden = true
        headerStack.isHidden = false
        if isFromNewReceipt {
            mainLbl.translatesAutoresizingMaskIntoConstraints = false
            quantityHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
            priceLabel.translatesAutoresizingMaskIntoConstraints = false

            headerStack.distribution = .fill

               NSLayoutConstraint.activate([
                itemLabel.widthAnchor.constraint(equalTo: containerStack.widthAnchor, multiplier: 0.4),
                quantityHeaderLabel.widthAnchor.constraint(equalTo: headerStack.widthAnchor, multiplier: 0.2),
                priceLabel.widthAnchor.constraint(equalTo: headerStack.widthAnchor, multiplier: 0.4)
               ])
            priceLabel.text = "receipt_tax_incl_amount".localizedForSDK()
        }
    }
    
    func setHeader( blurStatus: Bool) {
        containerStack.isHidden = true
        headerStack.isHidden = false
    }
    
    func setTotal(total: String, currency: String, blurStatus: Bool) {
        containerStack.isHidden = false
        headerStack.isHidden = true
        QntyLbl.text = ""
        mainLbl.text = "Total"
        blurView.blurStatus = blurStatus
        blurView.blurLbl.textAlignment = .left
        blurView.text = currency + " " + total
    }
    
    func setDataForReciept(itemName: String?, blurStatus: Bool, totalAmount: String?, qty: String?,
                 currency: String, makeFirstLetterUppercase: Bool = true) {
        containerStack.isHidden = false
        headerStack.isHidden = true
        mainLbl.translatesAutoresizingMaskIntoConstraints = false
        QntyLbl.translatesAutoresizingMaskIntoConstraints = false
        blurView.translatesAutoresizingMaskIntoConstraints = false

        containerStack.distribution = .fill

           NSLayoutConstraint.activate([
            mainLbl.widthAnchor.constraint(equalTo: containerStack.widthAnchor, multiplier: 0.4),
            QntyLbl.widthAnchor.constraint(equalTo: containerStack.widthAnchor, multiplier: 0.2),
            blurView.widthAnchor.constraint(equalTo: containerStack.widthAnchor, multiplier: 0.4)
           ])
        if makeFirstLetterUppercase {
            mainLbl.text = itemName
        } else {
            mainLbl.text = itemName
        }
        if let price = totalAmount {
            blurView.text = currency + " \(price)"
        } else {
            blurView.text = "NA"
        }
        QntyLbl.text = qty
        blurView.blurStatus = blurStatus
        blurView.blurLbl.textAlignment = .left
    }
    
    func renderUI(index: Int, tot: Int) {
        if tot == 1 {
            roundAllCorner()
        } else if index == 0  {
            roundTop()
        } else if index == (tot - 1) {
            roundBottom()
        } else {
            regularCell()
        }
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
    
    private func roundAllCorner(){
        top.constant = 8
        bottom.constant = 8
        contentBack.IBcornerRadius = 10
        lineView.isHidden = true
    }
    
    private func regularCell() {
        top.constant = 0
        bottom.constant = 0
        contentBack.IBcornerRadius = 0
        lineView.isHidden = false
    }
}
