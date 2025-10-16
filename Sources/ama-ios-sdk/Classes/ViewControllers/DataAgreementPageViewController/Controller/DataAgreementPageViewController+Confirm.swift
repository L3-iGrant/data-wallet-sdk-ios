//
//  DataAgreementPageViewController+Confirm.swift
//  dataWallet
//
//  Created by sreelekh N on 15/09/22.
//

import Foundation
import UIKit

extension DataAgreementPageViewController: PageControllerNavHelp {
    func pushWith(vc: UIViewController) {
        self.push(vc: vc)
    }
    
    func presentWith(vc: UIViewController) {
        self.present(vc: vc)
    }
}
