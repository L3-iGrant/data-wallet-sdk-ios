//
//  ViewController.Extension.swift
//  dataWallet
//
//  Created by sreelekh N on 08/10/21.
//

import Foundation
import UIKit

extension UIViewController {
    func initialize() -> UIViewController {
        if checkView(main: SBInstance.sbMain, withIdentifier: self.className) {
            let main = SBInstance.sbMain.instantiateViewController(withIdentifier: self.className) as! Self
            return main
        }
        return UIViewController()
    }
    
    func checkView(main: UIStoryboard, withIdentifier identifier: String) -> Bool {
        if let availableIdentifiers = main.value(forKey: UnknownAll.nibMap) as? [String: Any] {
            if availableIdentifiers[identifier] != nil {
                return true
            }
        }
        return false
    }
    
    func push(vc: UIViewController) {
        if let nav = self.navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            (AppData.keyWindow?.rootViewController as? UINavigationController)?.pushViewController(vc, animated: true)
        }
    }
    
    func present(vc: UIViewController, transStyle: UIModalTransitionStyle = .coverVertical, presentationStyle: UIModalPresentationStyle = .fullScreen) {
        let navController = UINavigationController(rootViewController: vc)
        navController.isModalInPresentation = false
        navController.modalTransitionStyle = transStyle
        navController.modalPresentationStyle = presentationStyle
        self.present(navController, animated: true, completion: nil)
    }
    
    func pop(animated: Bool = false) {
        self.navigationController?.popViewController(animated: animated)
    }
    
    func popToRoot() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func returnBack()  {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
            let vc = nav.viewControllers.first
            if vc == self {
                nav.dismiss(animated: true) {
                }
            }
        } else {
            menuDismiss()
        }
    }
    
    func dismissKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func menuDismiss()  {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    var screenStatusBarHeight: CGFloat {
        return AppData.keyWindow?.windowScene?.statusBarManager?.statusBarFrame.height ?? UIApplication.shared.statusBarFrame.height ?? 0
    }
    
    var topAreaHeight: CGFloat {
        return (AppData.keyWindow?.rootViewController as? UINavigationController)?.navigationBar.frame.height ?? 0.0
    }
    
    var topFullArea: CGFloat {
        return topAreaHeight + screenStatusBarHeight
    }
    
    var safeAreaBottom: CGFloat {
        return AppData.keyWindow?.safeAreaInsets.bottom ?? 0.0
    }
    
    @objc func gotoRootTab(_ root : UIViewController) {
        let nav = UINavigationController(rootViewController: root)
        DispatchQueue.main.async {
            if let window = UIApplication.shared.windows.first {
                window.rootViewController = nav
                UIView.transition(with: window,
                                  duration: 0.8,
                                  options: .transitionCrossDissolve,
                                  animations: nil)
                window.makeKeyAndVisible()
            }
        }
    }
}
