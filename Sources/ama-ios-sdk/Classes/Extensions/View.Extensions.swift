//
//  View.Extensions.swift
//  dataWallet
//
//  Created by sreelekh N on 24/10/21.
//

import Foundation
import UIKit

extension UIView {

    func registerView() {
        self.frame = UIScreen.main.bounds
        Bundle.module.loadNibNamed(self.className, owner: self, options: nil)
    }

    func addView(subview: UIView) {
        subview.frame = UIScreen.main.bounds
        subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addSubview(subview)
    }
    
    func addTransitionFade(_ duration: TimeInterval = 0.5) {
        let animation = CATransition()
        animation.type = CATransitionType.fade
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.default)
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.duration = duration
        layer.add(animation, forKey: "kCATransitionFade")
    }
}
