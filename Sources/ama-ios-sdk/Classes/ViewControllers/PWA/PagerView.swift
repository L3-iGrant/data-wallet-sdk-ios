//
//  PagerView.swift
//  dataWallet
//
//  Created by iGrant on 04/02/25.
//

import Foundation
import UIKit

class PagerView: UIView {
    
    @IBOutlet weak var pageControll: UIPageControl!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    // MARK: - Helper Method to Load XIB
    private func commonInit() {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "PagerView", bundle: Bundle.module)
        
        if let view = nib.instantiate(withOwner: self, options: nil).first as? UIView {
            view.frame = bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(view)
            
        }
    }
}
