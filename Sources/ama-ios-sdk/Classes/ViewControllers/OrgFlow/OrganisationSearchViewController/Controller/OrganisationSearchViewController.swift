//
//  OrganisationSearchViewController.swift
//  dataWallet
//
//  Created by sreelekh N on 20/12/21.
//

import UIKit

final class OrganisationSearchViewController: AriesBaseViewController {
    
    let topView = WalletHomeTitle(type: .organisationSearch)
    let tableView = UITableView.getTableview()
    var errorView = EmptyMessageView()
    
    var viewModel = DataHistoryViewModel()
    
    var navHandler: NavigationHandler!
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .appColor(.walletBg)
        view.tupleViews(views: topView, tableView, errorView)
        topView.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 125)
        tableView.addAnchor(top: topView.bottomAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        errorView.addAnchorFull(tableView)
        
        tableView.register(cellType: OrganisationSearchTableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        topView.pageDelegate = self
        viewModel.pageDelegate = self
        viewModel.getHistories(completion: { [weak self] success in
            self?.tableView.reloadInMain()
        })
        setNav()
    }
    
    override func localizableValues() {
        super.localizableValues()
        loadLocalize()
    }
    
    private func loadLocalize() {
        topView.lbl.text = "My Shared Data".localizedForSDK()
        topView.searchField.placeholder = "Search".localizedForSDK()
        self.setEmptyMessage()
    }
    
    private func setNav() {
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(right: [.connectionSettings])
    }
}
