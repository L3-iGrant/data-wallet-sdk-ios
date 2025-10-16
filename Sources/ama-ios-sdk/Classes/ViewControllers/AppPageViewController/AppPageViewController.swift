//
//  AppPageViewController.swift
//  dataWallet
//
//  Created by sreelekh N on 15/09/22.
//

import UIKit
protocol PageControllerNavHelp: UIViewController {
    func pushWith(vc: UIViewController)
    func presentWith(vc: UIViewController)
}

extension PageControllerNavHelp {
    func presentWith(vc: UIViewController) {}
}


final class AppPageViewController: UIPageViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}
