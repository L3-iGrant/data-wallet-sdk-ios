//
//  Pannable.swift
//  SocialMob
//
//  Created by sreelekh N on 13/11/21.
//

import Foundation
import UIKit

enum ActionSheetPageType {
    case connectionActionSheet
    case thirdPartyPage(sections: [String])
    case history(sections: [String])
}

final class ViewControllerPannable: UIViewController, SheetDelegate {
    
    func sheetReturnBack() {
        returnBack()
    }
    
    var viewTranslation = CGPoint(x: 0, y: 0)
    var transitionLevel = 200.0
    var backAction: (() -> Void)?
    
    var containerView = UIView()
    var renderFor: ActionSheetPageType
    let connectionsActionSheet: ActionSheetViewController
    
    init(renderFor: ActionSheetPageType) {
        self.renderFor = renderFor
        self.connectionsActionSheet = ActionSheetViewController(renderFor: renderFor)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        self.view.addSubview(containerView)
        containerView.addAnchorFull(view)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler(_:)))
        containerView.addGestureRecognizer(gestureRecognizer)
        containerView.backgroundColor = .clear
        setChild()
    }
    
    func setChild() {
        addChild(connectionsActionSheet)
        self.containerView.addSubview(connectionsActionSheet.view)
        connectionsActionSheet.didMove(toParent: self)
        connectionsActionSheet.didMove(toParent: self)
        connectionsActionSheet.view.frame = self.containerView.bounds
        connectionsActionSheet.view.isHidden = false
        connectionsActionSheet.sheetDelegate = self
        
        switch renderFor {
        case .connectionActionSheet:
            transitionLevel = 152.0
        case .thirdPartyPage(let sections):
            transitionLevel = (sections.count * 38).toDouble
        case .history(sections: let sections):
            transitionLevel = (sections.count * 38).toDouble
        }
    }
    
    @IBAction func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .changed:
            viewTranslation = sender.translation(in: containerView)
            guard self.viewTranslation.y > 0 else {
                return
            }
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.containerView.transform = CGAffineTransform(translationX: 0, y: self.viewTranslation.y)
            })
            let transition = (viewTranslation.y)/100
            view.backgroundColor = UIColor.black.withAlphaComponent(0.5 - (transition/2))
        case .ended:
            if viewTranslation.y < self.transitionLevel {
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                    self.containerView.transform = .identity
                    self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                })
            } else {
                returnBack()
                backAction?()
            }
        default:
            break
        }
    }
}
