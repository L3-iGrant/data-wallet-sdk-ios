//
//  AriesBaseViewController.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 18/01/21.
//

import UIKit
import Localize_Swift
import WXNavigationBar

class AriesBaseViewController: UIViewController {

    override var wx_navigationBarBackgroundColor: UIColor? {
        return .clear
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(localizableValues), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
        self.view.backgroundColor = #colorLiteral(red: 0.9490196078, green: 0.9490196078, blue: 0.9647058824, alpha: 1)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        localizableValues()
        navigationItem.leftBarButtonItem?.imageInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
    }
    
    @objc func localizableValues() {
        
    }

}
