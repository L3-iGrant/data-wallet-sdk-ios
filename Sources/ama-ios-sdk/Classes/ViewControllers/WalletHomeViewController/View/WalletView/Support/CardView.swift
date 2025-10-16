//
//  CardView.swift
//  dataWallet
//
//  Created by sreelekh N on 07/12/21.
//

import UIKit
open class CardView: UIView {
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGestures()
    }
    
    open var presented: Bool = false
    
    public var walletView: WalletView? {
        return container()
    }
    
    @objc open func tapped() {
        if let _ = walletView?.presentedCardView {
            walletView?.dismissPresentedCardView(animated: true)
        } else {
            walletView?.present(cardView: self, animated: true)
        }
    }
    
    public var cardViewCanPanBlock: WalletView.CardViewShouldAllowBlock?
    public var cardViewCanReleaseBlock: WalletView.CardViewShouldAllowBlock?
    private var calledCardViewBeganPanBlock = true
    public var cardViewBeganPanBlock: WalletView.CardViewBeganPanBlock?
    
    @objc open func panned(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            walletView?.grab(cardView: self, popup: false)
            calledCardViewBeganPanBlock = false
        case .changed:
            updateGrabbedCardViewOffset(gestureRecognizer: gestureRecognizer)
        default:
            if cardViewCanReleaseBlock?() == false {
                walletView?.layoutWalletView(animationDuration: WalletView.grabbingAnimationSpeed)
            } else {
                walletView?.releaseGrabbedCardView()
            }
        }
    }
    
    @objc open func longPressed(gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            walletView?.grab(cardView: self, popup: true)
        case .changed: ()
        default:
            if cardViewCanReleaseBlock?() == false {
                walletView?.layoutWalletView(animationDuration: WalletView.grabbingAnimationSpeed)
            } else {
                walletView?.releaseGrabbedCardView()
            }
        }
    }
    
    public let tapGestureRecognizer    = UITapGestureRecognizer()
    public let panGestureRecognizer    = UIPanGestureRecognizer()
    public let longGestureRecognizer   = UILongPressGestureRecognizer()
    
    func setupGestures() {
        
        tapGestureRecognizer.addTarget(self, action: #selector(CardView.tapped))
        tapGestureRecognizer.delegate = self
        addGestureRecognizer(tapGestureRecognizer)
        
        panGestureRecognizer.addTarget(self, action: #selector(CardView.panned(gestureRecognizer:)))
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
        
        longGestureRecognizer.addTarget(self, action: #selector(CardView.longPressed(gestureRecognizer:)))
        longGestureRecognizer.delegate = self
        addGestureRecognizer(longGestureRecognizer)
    }
    
    
    func updateGrabbedCardViewOffset(gestureRecognizer: UIPanGestureRecognizer) {
        let offset = gestureRecognizer.translation(in: walletView).y
        if presented && offset > 0 {
            walletView?.updateGrabbedCardView(offset: offset)
            if cardViewCanPanBlock?() == true, calledCardViewBeganPanBlock == false {
                cardViewBeganPanBlock?()
                calledCardViewBeganPanBlock = true
            }
        } else if !presented {
            walletView?.updateGrabbedCardView(offset: offset)
        }
    }
}

extension CardView: UIGestureRecognizerDelegate {
    
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGestureRecognizer {
            let cardViewCanPan = cardViewCanPanBlock?() ?? true
            if !cardViewCanPan {
                return false
            }
        }
        if gestureRecognizer == longGestureRecognizer && presented {
            return false
        } else if gestureRecognizer == panGestureRecognizer && !presented && walletView?.grabbedCardView != self {
            return false
        }
        return true
    }
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer != tapGestureRecognizer && otherGestureRecognizer != tapGestureRecognizer
    }
}

extension UIView {
    func container<T: UIView>() -> T? {
        var view = superview
        while view != nil {
            if let view = view as? T {
                return view
            }
            view = view?.superview
        }
        return nil
    }
}
