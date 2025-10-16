//
//  OrganizationDetailViewController+Sticky.swift
//  dataWallet
//
//  Created by sreelekh N on 15/12/21.
//

import Foundation
import UIKit

extension OrganizationDetailViewController {
    
    func addToHeaderView() {
        if viewMode == .BottomSheet {
            tableView.tableHeaderView = nil
            tableView.addSubview(bottomSheetHeaderView)
            self.tableView.contentInset = UIEdgeInsets(top: headerHeight, left: 0, bottom: 0, right: 0)
            self.tableView.contentOffset = CGPoint(x: 0, y: -headerHeight)
            updateHeaderView()
            view.layoutIfNeeded()
        } else {
            tableView.tableHeaderView = nil
            tableView.addSubview(headerView)
            self.tableView.contentInset = UIEdgeInsets(top: headerHeight, left: 0, bottom: 0, right: 0)
            self.tableView.contentOffset = CGPoint(x: 0, y: -headerHeight)
            updateHeaderView()
            view.layoutIfNeeded()
        }
    }
    
    func updateHeaderView() {
        if viewMode == .BottomSheet {
            var headerRect = CGRect(x: 0, y: -headerHeight, width: self.tableView.bounds.width, height: headerHeight)
            if self.tableView.contentOffset.y < -headerHeight {
                headerRect.origin.y = self.tableView.contentOffset.y
                headerRect.size.height = -self.tableView.contentOffset.y
            }
            bottomSheetHeaderView.frame = headerRect
        } else {
            var headerRect = CGRect(x: 0, y: -headerHeight, width: self.tableView.bounds.width, height: headerHeight)
            if self.tableView.contentOffset.y < -headerHeight {
                headerRect.origin.y = self.tableView.contentOffset.y
                headerRect.size.height = -self.tableView.contentOffset.y
            }
            headerView.frame = headerRect
        }
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
            eyeNavIcon.updateForAlpha(alpha: 0.0)
        } else if y < threshold + navBarHeight {
        } else {
            let progress = (y - threshold - navBarHeight)/navBarHeight
            let alpha = max(0, min(progress, 1))
            wx_navigationBar.alpha = alpha
            backNavIcon.updateForAlpha(alpha: alpha)
            eyeNavIcon.updateForAlpha(alpha: alpha)
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
