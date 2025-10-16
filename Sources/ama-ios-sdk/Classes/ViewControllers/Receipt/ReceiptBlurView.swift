//
//  ReceiptBlurView.swift
//  dataWallet
//
//  Created by iGrant on 01/08/25.
//

import UIKit
import Lottie

final class ReceiptBlurView: UIView, UIGestureRecognizerDelegate {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var blurLbl: BlurredLabel!
    
    var text: String? {
        didSet {
            blurLbl.attributedText = nil
            blurLbl.text = text
        }
    }
    
    var blurStatus: Bool = false {
        didSet {
            blurLbl.isBlurring = !blurStatus
        }
    }
    
    var textColor: UIColor? {
        didSet {
            blurLbl.textColor = textColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerView()
        addView(subview: view)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerView()
        addView(subview: view)
        sharedInit()
    }
    
    func sharedInit() {
        self.isUserInteractionEnabled = true
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(self.showMenu))
        gesture.delegate = self
        self.addGestureRecognizer(gesture)
    }
    
    @objc func showMenu(_ recognizer: UILongPressGestureRecognizer) {
        guard blurStatus else {
            return
        }
        self.becomeFirstResponder()
        HapticManager.tapped(type: .light)
        let menu = UIMenuController.shared
        let locationOfTouchInLabel = recognizer.location(in: self)
        if !menu.isMenuVisible {
            var rect = bounds
            rect.origin = locationOfTouchInLabel
            rect.size = CGSize(width: 1, height: 1)
            menu.showMenu(from: self, rect: rect)
        }
    }
    
    override func copy(_ sender: Any?) {
        let board = UIPasteboard.general
        board.string = text
        let menu = UIMenuController.shared
        menu.isMenuVisible = false
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy)
    }
}
