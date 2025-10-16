//
//  BorderRoundView.swift
//  dataWallet
//
//  Created by sreelekh N on 10/12/21.
//

import Foundation
import UIKit

final class BorderRoundView: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var layerView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerView()
        addView(subview: view)
    }
    
    required init(type: Int) {
        super.init(frame: .zero)
        registerView()
        addView(subview: view)
        renderView(type)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func renderView(_ type: Int) {
        switch type {
        case 0:
            layerView.topMaskedCornerRadius = 7.5
        default:
            layerView.bottomMaskedCornerRadius = 7.5
        }
    }
}
