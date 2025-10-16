//
//  CertificateListViewController + Sticky.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 11/05/22.
//

import Foundation
import UIKit

extension CertificateListViewController {
    
    func addToHeaderView() {
        orgTableView.tableHeaderView = nil
        orgTableView.addSubview(headerView)
        self.orgTableView.contentInset = UIEdgeInsets(top: headerHeight, left: 0, bottom: 0, right: 0)
        self.orgTableView.contentOffset = CGPoint(x: 0, y: -headerHeight)
        updateHeaderView()
        view.layoutIfNeeded()
    }
    
    func updateHeaderView() {
        var headerRect = CGRect(x: 0, y: -headerHeight, width: self.orgTableView.bounds.width, height: headerHeight)
        if self.orgTableView.contentOffset.y < -headerHeight {
            headerRect.origin.y = self.orgTableView.contentOffset.y
            headerRect.size.height = -self.orgTableView.contentOffset.y
        }
        headerView.frame = headerRect
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        positionOffset = scrollView
        updateHeaderView()
        var y = scrollView.contentOffset.y
        y += headerHeight
        let threshold: CGFloat = headerHeight - (300 - navBarHeight - screenStatusBarHeight)
        if y < threshold {
            wx_navigationBar.alpha = 0.0
            backNavIcon.updateForAlpha(alpha: 0.0)
//            eyeNavIcon.updateForAlpha(alpha: 0.0)
        } else if y < threshold + navBarHeight {
        } else {
            let progress = (y - threshold - navBarHeight)/navBarHeight
            let alpha = max(0, min(progress, 1))
            wx_navigationBar.alpha = alpha
            backNavIcon.updateForAlpha(alpha: alpha)
//            eyeNavIcon.updateForAlpha(alpha: alpha)
            if !initialLoad {
                if alpha > 0.7 {
                    isDark = false
                    self.title = pageTitle
                } else {
                    self.isDark = imageLightValue
                    self.title = ""
                }
            } else {
                initialLoad = false
            }
        }
    }
}
