//
//  BlurredTextView.swift
//  dataWallet
//
//  Created by sreelekh N on 22/12/21.
//

import UIKit
import Lottie

final class BlurredTextView: UIView, UIGestureRecognizerDelegate {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var blurLbl: BlurredLabel!
    
    @IBOutlet weak var blurLabelVerification: UILabel!
    
    var isFromVerification: Bool = false
    var text: String? {
        didSet {
            if isFromVerification {
                blurLbl.isHidden = true
                blurLabelVerification.attributedText = nil
                blurLabelVerification.text = text
            } else {
                blurLabelVerification.isHidden = true
                blurLbl.attributedText = nil
                blurLbl.text = text
            }
        }
    }
    
    var blurStatus: Bool = false {
        didSet {
            if isFromVerification {
                blurLbl.isHidden = true
                if !blurStatus {
                    blurLabelVerification.addBlurrEffect()
                } else {
                    blurLabelVerification.removeBlurEffect()
                }
            } else {
                blurLabelVerification.isHidden = true
                blurLbl.isBlurring = !blurStatus
            }
        }
    }
    
    var textColor: UIColor? {
        didSet {
            if isFromVerification {
                blurLbl.isHidden = true
                blurLabelVerification.textColor = textColor
            } else {
                blurLabelVerification.isHidden = true
                blurLbl.textColor = textColor

            }
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
