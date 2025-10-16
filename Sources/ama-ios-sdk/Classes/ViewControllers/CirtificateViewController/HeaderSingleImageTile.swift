//
//  HeaderSingleImageTile.swift
//  dataWallet
//
//  Created by sreelekh N on 02/01/22.
//

import Foundation
import UIKit
final class HeaderSingleImageTile: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var img: UIImageView!
    
    var image: UIImage? {
        didSet {
            img.image = image
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerView()
        addView(subview: view)
    }
    
    required init(title: String) {
        super.init(frame: .zero)
        registerView()
        addView(subview: view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
