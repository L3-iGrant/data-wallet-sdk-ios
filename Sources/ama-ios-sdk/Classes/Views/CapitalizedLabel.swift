//
//  CapitalizedLabel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 24/07/21.
//

import Foundation
import UIKit

class CapitalizedLabel: UILabel {
    override var text: String? {
        didSet {
            super.text = text?.uppercaseFirstWords
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        super.text = text?.uppercased()
    }
}
