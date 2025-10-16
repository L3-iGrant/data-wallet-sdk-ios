//
//  ConnectionsViewController.swift
//  dataWallet
//
//  Created by sreelekh N on 10/12/21.
//

import UIKit
import SVProgressHUD

final class ConnectionsViewController: AriesBaseViewController, NavigationHandlerProtocol {
    
    func rightTapped(tag: Int) {
        let sheet = ViewControllerPannable(renderFor: .connectionActionSheet)
        sheet.connectionsActionSheet.pageDelegate = self
        sheet.connectionsActionSheet.selectedIndex = self.viewModel?.connectionType?.rawValue ?? 0
        self.present(vc: sheet, transStyle: .crossDissolve, presentationStyle: .overCurrentContext)
    }
    var viewMode: ViewMode = .FullScreen
    var viewModel :OrganisationListViewModel?
    
    let topView = WalletHomeTitle(type: .connection)
    let tableView = UITableView.getTableview()
    var errorView = EmptyMessageView()
    var navHandler: NavigationHandler!
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .appColor(.walletBg)
        view.tupleViews(views: topView, tableView, errorView)
        topView.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 125)
        tableView.addAnchor(top: topView.bottomAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        errorView.addAnchorFull(tableView)
        tableView.register(cellType: ConnectionsTableViewCell.self)
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        topView.pageDelegate = self
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(right: [.connectionSettings])
        topView.viewMode = viewMode
       // topView.renderView(type: .connection)
        didLoadFunc()
    }
    
    override func localizableValues() {
        super.localizableValues()
        loadLocalize()
    }
    
    private func loadLocalize() {
        topView.lbl.text = "Connections".localizedForSDK()
        topView.searchField.placeholder = LocalizationSheet.search_connections.localizedForSDK()
        self.setEmptyMessage()
    }
    
    @objc func reloadList() {
        viewModel?.fetchOrgList(completion: { [weak self] (success) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self?.setEmptyMessage()
            })
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if viewModel == nil {
            let quick = QuickActionNavigation.shared
            let orgInit = OrganisationListViewModel.init(walletHandle: quick.walletHandle,mediatorVerKey: quick.mediatorVerKey)
            self.viewModel = orgInit
            self.didLoadFunc()
            UIApplicationUtils.hideLoader()
        }
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    private func didLoadFunc() {
        loadLocalize()
        viewModel?.pageDelegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(reloadList), name: Constants.reloadOrgList, object: nil)
        viewModel?.fetchOrgList(completion: { [weak self] (success) in
            self?.setEmptyMessage()
        })
    }
    
    func setEmptyMessage() {
        self.tableView.reloadInMain()
        if self.viewModel?.searchedConnections?.isEmpty ?? false {
            errorView.isHidden = false
            self.errorView.setValues(value: .label(value: (self.viewModel?.searchKey?.isEmpty ?? true && self.viewModel?.connectionType == .All) ? "Click '+' next to Connections to connect to an organisation to add data.".localizedForSDK() : "No result found".localizedForSDK()))
        } else {
            errorView.isHidden = true
        }
    }
}
