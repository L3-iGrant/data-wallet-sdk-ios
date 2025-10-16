//
//  DataAgreementButton.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 03/10/21.
//

import UIKit

class DataAgreementButton: UIView,NibLoadable {

    @IBOutlet weak var dataAgreementButton: UIButton!
    
    required init?(coder aDecoder: NSCoder) {
           super.init(coder: aDecoder)
           setupFromNib()
        dataAgreementButton.layer.cornerRadius = 10
       }

       override init(frame: CGRect) {
           super.init(frame: frame)
           setupFromNib()
           dataAgreementButton.layer.cornerRadius = 10
       }

}
