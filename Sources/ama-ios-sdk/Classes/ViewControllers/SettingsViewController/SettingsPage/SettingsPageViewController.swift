//
//  SettingsPageViewController.swift
//  dataWallet
//
//  Created by sreelekh N on 06/09/22.
//

import UIKit
import UniformTypeIdentifiers

final class SettingsPageViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var igrandStackView: UIStackView!
    
    let viewModel = SettingsPageViewModel()
    
    var isWelcome: Bool? {
        didSet {
            if isWelcome ?? false {
                igrandStackView.isHidden = true
                //make backup and restore to toggle if it is a welcome screen
                viewModel.content[2].content[1].renderFor = .toggle
                viewModel.content.removeLast()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.title = "Settings".localize
        view.backgroundColor = .appColor(.walletBg)
        tableView.contentInset.top = 10
        tableView.register(cellType: SettingsTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        getSelectedCountries()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadInMain()
    }
    
    func toggleAction(indexPath: IndexPath) {
        if isWelcome ?? false {
            switch indexPath.section {
            case 2:
                switch indexPath.row {
                case 1:
                    Constants.autoBackupEnabled = !Constants.autoBackupEnabled
                default: break
                }
            default:
                break
            }
            return
        }
        switch indexPath.section {
        case 2:
            switch indexPath.row {
            case 0:
                let toggle = !(UserDefaults.standard.bool(forKey: "isSecurityDisabled"))
                UserDefaults.standard.set(toggle, forKey: "isSecurityDisabled")
                break
            case 1:
                break
            default: break
            }
        default: break
        }
    }
    
    func tapAction(indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if let vc = LanguageListViewController().initialize() as? LanguageListViewController {
                self.push(vc: vc)
            }
        case 1:
            if let vc = LedgerListViewController().initialize() as? LedgerListViewController {
                self.push(vc: vc)
            }
        case 2:
            switch indexPath.row {
            case 1: self.navigationController?.pushViewController(BackUpViewController(), animated: true)
            case 2:
                if let vc = DataHistoryViewController().initialize() as? DataHistoryViewController {
                    self.push(vc: vc)
                }
            case 3:
                if let vc =  CountriesViewController().initialize() as? CountriesViewController {
                    vc.delegate = self
                    vc.allowMultipleSelection = true
                    vc.selectedCountries = self.viewModel.selectedCountriesArray
                    self.push(vc: vc)
                }
            default:
                break
            }
        default:
            switch indexPath.row {
            case 0: break
//                DynamicLinkSharing.shared.showActivity(vc: self, type: .tellFriend)
            case 1:
                if let url = URL(string: "itms-apps://apple.com/app/id1546551969") {
                    UIApplication.shared.open(url)
                }
            default:
                if let vc = AboutViewController().initialize() as? AboutViewController {
                    self.push(vc: vc)
                }
            }
        }
    }
    
}
