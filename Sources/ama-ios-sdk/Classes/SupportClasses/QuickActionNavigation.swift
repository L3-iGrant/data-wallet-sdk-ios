//
//  QuickActionNavigation.swift
//  dataWallet
//
//  Created by sreelekh N on 08/10/21.
//

import Foundation
import UIKit
import IndyCWrapper

enum QuickActionType: String {
    case connect = "ConnectAction"
    case shareData = "ShareAction"
    case addCard = "CardAction"
}

class QuickActionNavigation {
    
    static let shared = QuickActionNavigation()
    
    var savedShortCutItem: UIApplicationShortcutItem!
    var quickAction: QuickActionType?
    var shouldNavigate: Bool = false {
        didSet {
            navigate()
        }
    }
    
    //Wallet hold
    var mediatorVerKey: String?
    var walletHandle: IndyHandle?
    
    func navigate() {
        if quickAction != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
                switch self?.quickAction {
                case .addCard:
                    if let vc = AddCertificateViewController().initialize() as? AddCertificateViewController {
                        self?.pushWithRoot(vc: vc)
                    }
                case .connect:
                    let vc = ConnectionsViewController()
                    self?.pushWithRoot(vc: vc)
                    
                    //                    if let vc = OrganisationListViewController().initialize() as? OrganisationListViewController {
                    //                        self?.pushWithRoot(vc: vc)
                    //                    }
                    
                    // let vc = ConnectionsViewController()
                    //vc.viewModel = OrganisationListViewModel.init(walletHandle: viewModel.walletHandle, mediatorVerKey: WalletViewModel.mediatorVerKey)
                    //self?.pushWithRoot(vc: vc)
                    
                default:
                    let vc = WalletHomeViewController()
                    self?.pushWithRoot(vc: vc)
                }
            })
        }
    }
    
    func pushWithRoot(vc: UIViewController) {
        if let rootNav = AppData.keyWindow?.rootViewController as? UINavigationController {
            if shouldNavigate {
                savedShortCutItem = nil
                quickAction = nil
                shouldNavigate = false
            }
            if let viewIs = vc as? ConnectionsViewController {
                let controllers = [viewIs]
                guard rootNav.visibleViewController?.className != viewIs.className else {
                    return
                }
                rootNav.pushViewControllers(controllers, animated: true)
            } else if let viewIs = vc as? WalletHomeViewController {
                let exchangeView = viewIs.getExchangeData(controller: viewIs)
                guard rootNav.visibleViewController?.className != exchangeView.className else {
                    return
                }
                if let vc = rootNav.visibleViewController as? WalletHomeViewController {
                    vc.initaiateNewExchangeData()
                } else {
                    rootNav.popToRootViewController(animated: false)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                        if let vc = rootNav.visibleViewController as? WalletHomeViewController {
                            vc.initaiateNewExchangeData()
                        }
                    })
                }
            } else {
                guard rootNav.visibleViewController?.className != AddCertificateViewController.className else {
                    return
                }
                rootNav.pushViewController(vc, animated: true)
            }
        }
    }
}

extension UINavigationController {
    open func pushViewControllers(_ inViewControllers: [UIViewController], animated: Bool) {
        var stack = self.viewControllers
        stack.append(contentsOf: inViewControllers)
        self.setViewControllers(stack, animated: animated)
    }
}

extension UINavigationController {

  public func pushViewController(viewController: UIViewController,
                                 animated: Bool,
                                 completion: (() -> Void)?) {
    CATransaction.begin()
    CATransaction.setCompletionBlock(completion)
    pushViewController(viewController, animated: animated)
    CATransaction.commit()
  }

}
