//
//  MyDataProfileTableViewCell.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 27/11/22.
//

import UIKit

class MyDataProfileTableViewCell: UITableViewCell {

    @IBOutlet weak var rightIcon: UIImageView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    @IBOutlet weak var itemValue: UITextField!
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var lineView: UIView!
    var data: MyDataProfileModel?
    var onValueChanged: ((MyDataProfileModel?) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        itemValue.delegate = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
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
        topConstraint.constant = 18
        bottomConstraint.constant = 10
        baseView.topMaskedCornerRadius = 10
        lineView.isHidden = false
    }
    
    private func roundBottom() {
        topConstraint.constant = 10
        bottomConstraint.constant = 18
        baseView.bottomMaskedCornerRadius = 10
        lineView.isHidden = true
    }
    
    private func roundAllCorner(){
        topConstraint.constant = 18
        bottomConstraint.constant = 18
        baseView.IBcornerRadius = 10
        lineView.isHidden = true
    }
    
    private func regularCell() {
        topConstraint.constant = 10
        bottomConstraint.constant = 10
        baseView.IBcornerRadius = 0
        lineView.isHidden = false
    }
    
}

extension MyDataProfileTableViewCell: UITextFieldDelegate {
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        data?.value = textField.text
        if let onValueChangedFunc = onValueChanged {
            onValueChangedFunc(data)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        data?.value = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let onValueChangedFunc = onValueChanged {
            onValueChangedFunc(data)
        }
    }
}
