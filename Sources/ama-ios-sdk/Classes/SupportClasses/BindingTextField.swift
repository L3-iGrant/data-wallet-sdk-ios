//
//  BindingTextField.swift
//  dataWallet
//
//  Created by sreelekh N on 30/11/21.
//

import Foundation
import UIKit

final class BindingTextField: UITextField, UITextFieldDelegate {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.textAlignment = .left
        self.delegate = self
    }
    
    var textEdited: ((String) -> Void)? = nil
    
    func bind(completion: @escaping (String) -> Void) {
        textEdited = completion
        addTarget(self, action: #selector(textFieldEditingChanged(_ :)), for: .editingChanged)
    }
    
    @objc func textFieldEditingChanged(_ textField: UITextField) {
        guard let text = textField.text else {
            return
        }
        textEdited?(text)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
