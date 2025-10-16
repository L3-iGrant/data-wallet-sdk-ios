//
//  DataAgreementPageViewController+Pager.swift
//  dataWallet
//
//  Created by sreelekh N on 15/09/22.
//

import Foundation
import UIKit

extension DataAgreementPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let current = pageViewController.viewControllers?.first
        var index = getPageIndex(current)
        if index == 0 {
            return nil
        }
        index -= 1
        let vc = pageViews[index]
        return vc
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let current = pageViewController.viewControllers?.first
        var index = getPageIndex(current)
        if index >= self.pageViews.count - 1 {
            return nil
        }
        index += 1
        let vc = pageViews[index]
        return vc
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {}
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return (pageViews.count == 1) ? 0 : pageViews.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let currentVC = pageViewController.viewControllers?.first, let currentIndex = pageViews.firstIndex(of: currentVC) else {
            return 0
        }
        return currentIndex
    }
    
    private func getPageIndex(_ viewController: UIViewController?) -> Int {
        let vc = viewController as? DataAgreementViewController
        return vc?.pageIndex ?? 0
    }
}
