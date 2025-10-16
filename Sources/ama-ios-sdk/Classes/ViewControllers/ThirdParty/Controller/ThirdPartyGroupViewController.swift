//
//  ThirdPartyGroupViewController.swift
//  dataWallet
//
//  Created by sreelekh N on 07/09/22.
//

import UIKit
import Localize_Swift

final class ThirdPartyGroupViewController: UIViewController {
    
    let tableView: UITableView
    let topView: WalletHomeTitle
    var navHandler: NavigationHandler!
    let viewModel: ThirdPartyGroupViewModel
    
    init(connectionModel: CloudAgentConnectionWalletModel) {
        tableView = UITableView.getTableview()
        topView = WalletHomeTitle(type: .thirdParty)
        viewModel = ThirdPartyGroupViewModel(connectionModel: connectionModel)
        super.init(nibName: nil, bundle: nil)
    }
    
    override func loadView() {
        super.loadView()
        
        view.addSubview(self.topView)
        view.addSubview(self.tableView)
        
        topView.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 80)
        tableView.addAnchor(top: topView.bottomAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        
        tableView.register(cellType: SettingsTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        topView.pageDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .appColor(.walletBg)
        self.setNav()
        self.viewModel.bind = self
        
    }
    
    private func setNav() {
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(title: "third_party_data_sharing".localizedForSDK(),
                                           right: [.connectionSettings])
    }
    
    @objc func mainToggleUpdated(_ sender: UISwitch){
        Task {
            let responseData = viewModel.responseData[sender.tag]
            let result = await ThirdPartyDataSharing.shared.updateDAPreferenceUsingOrgID(responseData: responseData, orgID: self.viewModel.connectionModel?.value?.orgDetails?.orgId ?? "")
            if result.0 ?? false {
                guard let item = result.1 else { return }
                if let main = self.viewModel.responseMainCarrier.firstIndex(where: { $0.id == item.id }) {
                    self.viewModel.responseMainCarrier[main] = item
                }
                self.viewModel.responseData[sender.tag] = item
                viewModel.bind?.updateForsearch()
            }
        }
    }
    
    @objc func infoButtonTapped(_ sender: UIButton){
        if let dataAgreementContext = viewModel.responseData[sender.tag].dataAgreement{
            DispatchQueue.main.async {
                let vc = DataAgreementPageViewController(agreement: [dataAgreementContext],
                                                         connectionRecordId: "",
                                                         mode: .thirdPartyDataShare)
                self.push(vc: vc)
            }
        }
    }
}
