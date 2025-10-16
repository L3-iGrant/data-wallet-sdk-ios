//
//  LedgerListViewController.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 18/01/21.
//

import UIKit

class LedgerListViewController: AriesBaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    public static var ledgers = CoreDataManager().getAllGenesis() ?? []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
//        self.tableView.layer.cornerRadius = 10
//        self.tableView.layer.borderWidth = 10
//        self.tableView.layer.borderColor = UIColor.white.cgColor
        UIApplicationUtils.showLoader()
        AriesPoolHelper.shared.getGenesisFromServerAndToCoreData { _ in
            UIApplicationUtils.hideLoader()
            let manager = CoreDataManager()
            LedgerListViewController.ledgers = manager.getAllGenesis() ?? []
            self.tableView.reloadData()
        }
        tableView.registerNib(CovidValuesRowTableViewCell.self)
    }
    
    override func localizableValues() {
        super.localizableValues()
        self.title = "Ledger".localizedForSDK()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
//        heightConstraint.constant = CGFloat(55 * LedgerListViewController.ledgers.count) + 5
    }
}

extension LedgerListViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(with:  CovidValuesRowTableViewCell.self, for: indexPath)
            cell.blurView.isHidden = true
            cell.setData(model: IDCardAttributes.init(name: "European Blockchain Service Infrastructure", value: ""), blurStatus: false,makeFirstLetterUppercase: false)
            cell.renderUI(index: indexPath.row, tot: 1)
            cell.containerStackRighConstaint.constant = 40
            cell.rightImage =  "checked".getImage()
            cell.selectionStyle = .none
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
            cell.blurView.isHidden = true
            cell.setData(model: IDCardAttributes.init(name: LedgerListViewController.ledgers[indexPath.row].str, value: ""), blurStatus: false, makeFirstLetterUppercase: false)
            cell.renderUI(index: indexPath.row, tot: LedgerListViewController.ledgers.count)
            if let selectedLedgerid = UserDefaults.standard.value(forKey: Constants.userDefault_ledger) as? Int{
                if (selectedLedgerid == LedgerListViewController.ledgers[indexPath.row].id){
                    cell.rightImage =  "checked".getImage()
                }
            }else {
                if indexPath.row == 0 {
                    cell.rightImage = "checked".getImage()
                }
                cell.accessoryView = nil
            }
            cell.selectionStyle = .none
            return cell
        default: return UITableViewCell()
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return LedgerListViewController.ledgers.count
        default: return 0
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return 55
//    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = GeneralTitleView.init()
        view.value = section == 0 ? "Other Ledgers" : "Hyperledger Indy"
        view.btnNeed = false
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let index = indexPath.row
            if let walletHandler = WalletViewModel.openedWalletHandler {
                UIApplicationUtils.showLoader(message: "Configuring pool...")
                if AriesPoolHelper.shared.saveGenesisToFile(string: LedgerListViewController.ledgers[index].genesisString) != nil {
                    UserDefaults.standard.setValue(LedgerListViewController.ledgers[index].id, forKey: Constants.userDefault_ledger)
                    AriesPoolHelper.shared.configurePool(walletHandler: walletHandler) { [weak self] (success) in
                        UIApplicationUtils.hideLoader()
                        DispatchQueue.main.async { self?.tableView.reloadData() }
                    }
                }
            } else {
                //From Welcome screen - Wallet is not configured yet
                if AriesPoolHelper.shared.saveGenesisToFile(string: LedgerListViewController.ledgers[index].genesisString) != nil {
                    UserDefaults.standard.setValue(LedgerListViewController.ledgers[index].id, forKey: Constants.userDefault_ledger)
                    UIApplicationUtils.hideLoader()
                    DispatchQueue.main.async { self.tableView.reloadData() }
                }
            }
        }
    }
}
