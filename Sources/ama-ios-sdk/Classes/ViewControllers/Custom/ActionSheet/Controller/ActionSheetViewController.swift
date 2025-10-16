//
//  ActionSheetViewController.swift
//  dataWallet
//
//  Created by sreelekh N on 10/12/21.
//

import UIKit

protocol ActionSheetViewControllerDelegate: UIViewController {
    func sheetFilterAction(index: Int)
}

protocol SheetDelegate: UIViewController {
    func sheetReturnBack()
}

final class ActionSheetViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.register(cellType: ActionSheetTableViewCell.self)
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    @IBOutlet weak var tableBottom: NSLayoutConstraint! {
        didSet {
            tableBottom.constant = safeAreaBottom
        }
    }
    @IBOutlet weak var tableHeight: NSLayoutConstraint!
    @IBOutlet weak var dismissView: UIView! {
        didSet {
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(returnBackSheet))
            tap.cancelsTouchesInView = false
            dismissView.addGestureRecognizer(tap)
        }
    }
    
    weak var pageDelegate: ActionSheetViewControllerDelegate?
    weak var sheetDelegate: SheetDelegate?
    
    var selectedIndex = 0
    let renderFor: ActionSheetPageType
    
    init(renderFor: ActionSheetPageType) {
        self.renderFor = renderFor
        super.init(nibName: nil, bundle: Constants.bundle)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        switch renderFor {
        case .connectionActionSheet:
            tableHeight.constant = (ActionSheetContent.connections.array.count*50).toCGFloat
        case .thirdPartyPage(let sections),.history(sections: let sections):
            tableHeight.constant = (sections.count*50).toCGFloat
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableBottom.constant = self.view.safeAreaInsets.bottom
    }
    
    @objc func returnBackSheet() {
        sheetDelegate?.sheetReturnBack()
    }
}
