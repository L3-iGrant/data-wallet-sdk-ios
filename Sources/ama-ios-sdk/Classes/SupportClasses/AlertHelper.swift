//
//  AlertHelper.swift
//  SocialMob
//
//  Created by sreelekh N on 18/07/21.
//  Copyright © 2021 Sreelekh_N. All rights reserved.
//

import Foundation
import UIKit

struct AppDetails {
    static let appName = "Data Wallet"
    static let bundleId = "io.iGrant.DataWallet"
    static let domainURIPrefix = "https://socialmob.page.link"
}

struct AppButtonTitles {
    static let cancel = "Cancel"
    static let yes = "Yes"
    static let no = "No"
}

struct Alerts {
    static let removeOrg = "Do you want to remove the organisation?"
    static let deleteItem = "delete_item_message"
}

struct AlertHelper {
    
    static let shared = AlertHelper()
    
    let keyWindow = AppData.keyWindow
    
    func askConfirmationFromBottomSheet(
        on controller: UIViewController,
        title: String = AppDetails.appName,
        message: String,
        btn_title : [String],
        controllerStyle: UIAlertController.Style = .alert,
        completion:@escaping (_ result: Int) -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: controllerStyle)
        
        for i in 0..<btn_title.count {
            let style: UIAlertAction.Style = (controllerStyle == .actionSheet && btn_title[i] == AppButtonTitles.cancel)
                ? .cancel : .default
            alert.addAction(UIAlertAction(title: btn_title[i], style: style) { _ in
                completion(i)
            })
        }
        
        controller.present(alert, animated: true)
    }
    
    func askConfirmationRandomButtons(title: String = AppDetails.appName, message: String, btn_title : [String], controllerStyle: UIAlertController.Style = .alert, completion:@escaping (_ result: Int) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: controllerStyle)
        for i in 0..<btn_title.count {
            if controllerStyle == .actionSheet {
                if btn_title[i] == AppButtonTitles.cancel {
                    alert.addAction(UIAlertAction(title: btn_title[i], style: .cancel, handler: { (_) in
                        completion(i)
                    }))
                } else {
                    alert.addAction(UIAlertAction(title: btn_title[i], style: .default, handler: { (_) in
                        completion(i)
                    }))
                }
            } else {
                alert.addAction(UIAlertAction(title: btn_title[i], style: .default, handler: { (_) in
                    completion(i)
                }))
            }
        }
        let root = keyWindow?.rootViewController ?? UIApplicationUtils.shared.getTopVC()
        if let presentedViewController = root?.presentedViewController {
            presentedViewController.present(alert, animated: true, completion: nil)
        } else {
            root?.present(alert, animated: true, completion: nil)
        }
    }
}
