//
//  NavigationHandler.swift
//  dataWallet
//
//  Created by sreelekh N on 31/10/21.
//

import Foundation
import UIKit

enum BarBtnItems: CaseIterable {
    case notification
    case back
    case notificationBadge
    case connect
    case settings
    case connectionSettings
    case eye
    case eyeFill
    case trash
    case info
    case edit
    
    var title: String {
        switch self {
        case .back:
            return ""
        default:
            return ""
        }
    }
    
    var image: UIImage {
        switch self {
        case .notification:
            return UIImage.getImage("bell", "bellIcon")
        case .back:
            return UIImage.getImage("chevron.left")
        case .notificationBadge:
            return UIImage.getImage("bell.badge", "bellBadge")
        case .connect:
            return UIImage.getImage("org-icon")
        case .settings:
            return UIImage.getImage("settings")
        case .connectionSettings:
            return "connectionSettings".getImage()
        case .eye:
            return "eye".getImage()
        case .eyeFill:
            return "eye.slash".getImage()
        case .trash:
            return "trash".getImage()
        case .info:
            return "info.circle".getImage()
        case .edit:
            return "pencil".getImage()
        }
    }
}

protocol NavigationHandlerProtocol: AnyObject {
    func leftTapped(tag: Int)
    func rightTapped(tag: Int)
}

extension NavigationHandlerProtocol {
    func leftTapped(tag: Int) {}
}

final class NavigationHandler: NSObject {
    
    weak var navDelegate: NavigationHandlerProtocol?
    weak var vc: UIViewController!
    
    init(parent: UIViewController, delegate: NavigationHandlerProtocol?) {
        super.init()
        vc = parent
        navDelegate = delegate
    }
    
    func setNavigationComponents(title: String? = "", isLarge: Bool = false , left: [BarBtnItems] = [.back], right: [BarBtnItems]? = [], tint: UIColor = .black) {
        if isLarge {
            vc.navigationController?.navigationBar.prefersLargeTitles = true
        }
        if title?.isNotEmpty ?? false {
            vc.title = title
        }
        var leftBarbtns = [UIBarButtonItem]()
        left.enumerated().forEach { index, items in
            if items.title.isNotEmpty {
                let nameItem = UIBarButtonItem(title: items.title, style: .plain, target: self, action: #selector(leftItemTapped))
                nameItem.tintColor = tint
                nameItem.tag = index
                leftBarbtns.append(nameItem)
            } else {
                let imageItem = UIBarButtonItem(image: items.image, style: .plain, target: self, action: #selector(leftItemTapped))
                imageItem.tintColor = tint
                imageItem.tag = index
                leftBarbtns.append(imageItem)
            }
        }
        vc.navigationItem.leftBarButtonItems = leftBarbtns
        
        var rightBarbtns = [UIBarButtonItem]()
        right?.enumerated().forEach { index, items in
            if items.title.isNotEmpty {
                let nameItem = UIBarButtonItem(title: items.title, style: .plain, target: self, action: #selector(rightItemTapped))
                nameItem.tintColor = tint
                nameItem.tag = index
                rightBarbtns.append(nameItem)
            } else {
                let imageItem = UIBarButtonItem(image: items.image, style: .plain, target: self, action: #selector(rightItemTapped))
                imageItem.tintColor = tint
                imageItem.tag = index
                rightBarbtns.append(imageItem)
            }
        }
        vc.navigationItem.rightBarButtonItems = rightBarbtns
    }
    
    @objc func leftItemTapped(sender: UIBarButtonItem) {
        if sender.image?.pngData() == UIImage.getImage("chevron.left").pngData() {
            vc?.returnBack()
        } else {
            navDelegate?.leftTapped(tag: sender.tag)
        }
    }
    
    @objc func rightItemTapped(sender: UIBarButtonItem) {
        navDelegate?.rightTapped(tag: sender.tag)
    }
    
    func updateLeftBarbtn(vc:UIViewController, left: [BarBtnItems], leftCompletion: @escaping ( _ leftTag: Int) -> Void) {
        var leftBarbtns = [UIBarButtonItem]()
        left.enumerated().forEach { index, items in
            if items.title.isNotEmpty {
                let nameItem = UIBarButtonItem(title: items.title, style: .plain, target: self, action: #selector(leftItemTapped))
                nameItem.tintColor = UIColor.black
                nameItem.tag = index
                leftBarbtns.append(nameItem)
            } else {
                let imageItem = UIBarButtonItem(image: items.image, style: .plain, target: self, action: #selector(leftItemTapped))
                imageItem.tintColor = UIColor.black
                imageItem.tag = index
                leftBarbtns.append(imageItem)
            }
        }
        vc.navigationItem.leftBarButtonItems = leftBarbtns
    }
}
