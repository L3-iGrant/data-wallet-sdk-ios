//
//  DataHistoryViewController.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 25/09/21.
//

import UIKit
import CoreML

class DataHistoryViewController: AriesBaseViewController {

    var viewModel = DataHistoryViewModel()
    var navHandler: NavigationHandler!

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var searchBarBgView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var bottomSheetViewHeader: UIView!
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var filterButton: UIButton!
    
    var viewMode: ViewMode = .FullScreen
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.pageDelegate = self
        viewModel.getHistories(completion: {[weak self] success in
            self?.tableView.reloadData()
        })
        searchBar.delegate = self
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = UIColor.white.cgColor
        searchBarBgView.layer.cornerRadius = 8
        searchBar.removeBg()
        self.searchBar.placeholder = "Search".localizedForSDK()
        descriptionLabel.text = "Here, you  can view the history of all data agreement signed.".localizedForSDK()
        setNav()
        bottomSheetViewHeader.isHidden = viewMode == .FullScreen
    }
    
    override func localizableValues() {
        super.localizableValues()
        self.descriptionLabel.text = "Here, you  can view the history of all data agreement signed.".localizedForSDK()
    }
    
    
    @IBAction func closeTapped(_ sender: Any) {
        if let nav = self.navigationController, nav.viewControllers.count > 1 {
                nav.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        //self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func filterTapped(_ sender: Any) {
        let sheet = ViewControllerPannable(renderFor: .history(sections: self.viewModel.filters))
        sheet.connectionsActionSheet.pageDelegate = self
        sheet.connectionsActionSheet.selectedIndex = self.viewModel.filterIndex
        self.present(vc: sheet, transStyle: .crossDissolve, presentationStyle: .overFullScreen)
    }
    
    private func setNav() {
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(title: "My Shared Data".localize,
                                           right: [.connectionSettings])
    }
    
    @IBAction func searchBarCancelButtonAction(_ sender: Any) {
        self.view.endEditing(true)
        self.cancelButton.isEnabled = false
    }
}

extension DataHistoryViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.filteredList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:"NotificationTableViewCell",for: indexPath) as! NotificationTableViewCell
        let history = viewModel.filteredList?[indexPath.row].value?.history
        cell.certName.text =  history?.name ?? ""
        let orgName = history?.connectionModel?.value?.orgDetails?.name
        if history?.name == CertType.EBSI.rawValue {
            var subType = history?.certSubType
            switch history?.certSubType ?? "" {
            case EBSI_CredentialType.Diploma.rawValue:
                subType = EBSI_CredentialSearchText.Diploma.rawValue
            case EBSI_CredentialType.StudentID.rawValue:
                subType = EBSI_CredentialSearchText.StudentID.rawValue
            case EBSI_CredentialType.VerifiableID.rawValue:
                subType = EBSI_CredentialSearchText.VerifiableID.rawValue
            case EBSI_CredentialType.PDA1.rawValue:
                subType = EBSI_CredentialSearchText.PDA1.rawValue
            default: break
        }
            cell.certName.text = subType ?? history?.name ?? ""
            
        }
        cell.notificationType.text = history?.type == HistoryType.exchange.rawValue ? "Data Using Service".localizedForSDK() : "Data Source".localizedForSDK()
        let dateFormats = ["yyyy-MM-dd hh:mm:ss.SSSSSS a'Z'", "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"]
        let historyDate = DateUtils.shared.parseDate(from: history?.date ?? "", formats: dateFormats)
        if let notifDate = historyDate {
            cell.time.text = notifDate.timeAgoDisplay()
        }
        cell.orgImage.backgroundColor = .white
        var logoUrl: String? = nil
        if history?.fundingSource != nil {
            logoUrl =  history?.connectionModel?.value?.orgDetails?.logoImageURL
        } else {
            logoUrl = history?.display?.logo ?? history?.connectionModel?.value?.orgDetails?.logoImageURL
        }
        let bgColour = history?.display?.backgroundColor
        let firstLetter =  orgName?.first ?? "U"
        let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
        ImageUtils.shared.setRemoteImage(for: cell.orgImage, imageUrl: logoUrl, orgName: orgName, bgColor: bgColour, placeHolderImage: profileImage)
        cell.shadowView.layer.cornerRadius = 10
        // Setting card color based on credential branding
        if let bgColor = history?.display?.backgroundColor {
            if history?.type != HistoryType.exchange.rawValue {
                cell.setCredentialBrandingBGcolor(color: UIColor(hex: bgColor))
            } else {
                cell.setCredentialBrandingBGcolor(color: UIColor.white)
            }
        } else {
            cell.setCredentialBrandingBGcolor(color: UIColor.white)
        }
        if let textColor = history?.display?.textColor {
            if history?.type != HistoryType.exchange.rawValue {
                cell.setCredentialBrandingTextColor(textColor: UIColor(hex: textColor))
            } else {
                cell.setCredentialBrandingTextColor(textColor: UIColor.darkGray)
            }
        } else {
            cell.setCredentialBrandingTextColor(textColor: UIColor.darkGray)
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if viewModel.histories?[indexPath.row].value?.history?.certSubType == "PAYMENT WALLET ATTESTATION" && viewModel.histories?[indexPath.row].value?.history?.type == HistoryType.exchange.rawValue && viewModel.histories?[indexPath.row].value?.history?.transactionData != nil {
            let vc = PaymentDataConfirmationMySharedDataVC(nibName: "PaymentDataConfirmationMySharedDataVC", bundle: Bundle.module)
            vc.viewModel = PaymentDataConfirmationMySharedDataViewModel(history: viewModel.histories?[safe: indexPath.row])
            push(vc: vc)
        } else if viewModel.histories?[indexPath.row].value?.history?.certSubType == "PAYMENT WALLET ATTESTATION" && viewModel.histories?[indexPath.row].value?.history?.fundingSource != nil {
            let vc = PaymentDataConfirmationMySharedDataVC(nibName: "PaymentDataConfirmationMySharedDataVC", bundle: Bundle.module)
            vc.viewModel = PaymentDataConfirmationMySharedDataViewModel(history: viewModel.histories?[safe: indexPath.row])
            vc.isIncludeFunding = true
            push(vc: vc)
        } else if viewModel.histories?[indexPath.row].value?.history?.receiptData != nil {
            let vc = ReceiptViewController(nibName: "ReceiptViewController", bundle: Bundle.module)
            vc.viewModel.histories = viewModel.histories?[indexPath.row]
            vc.viewModel.originatingFrom = .history
            vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
            vc.modalPresentationStyle = .fullScreen
            if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                UIApplicationUtils.hideLoader()
                navVC.pushViewController(vc, animated: true)
            } else {
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.shared.getTopVC()?.push(vc: vc)
            }
        } else if viewModel.histories?[indexPath.row].value?.history?.certSubType?.uppercased().contains("BOARDING PASS") == true {
            let vc = BoardingPassViewController(nibName: "BoardingPassViewController", bundle: Bundle.module)
            vc.viewModel.histories = viewModel.histories?[indexPath.row]
            vc.viewModel.originatingFrom = .history
            vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
            vc.modalPresentationStyle = .fullScreen
            if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                UIApplicationUtils.hideLoader()
                navVC.pushViewController(vc, animated: true)
            } else {
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.shared.getTopVC()?.push(vc: vc)
            }
        } else {
            let vc = OrganizationDetailViewController()
            vc.viewMode = viewMode
            vc.viewModel = OrganizationDetailViewModel(render: .history, history: viewModel.histories?[indexPath.row])
            push(vc: vc)
        }
    }
    
}

extension DataHistoryViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchKey = searchText
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.cancelButton.isEnabled = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.cancelButton.isEnabled = false
    }
}

extension DataHistoryViewController: DataHistoryViewModelDelegate {
    func reloadData() {
        tableView.reloadData()
    }
    
    func cellTapped(_ index: Int) {
        
    }
}

extension DataHistoryViewController: NavigationHandlerProtocol {
    func rightTapped(tag: Int) {
        switch tag {
        case 0:
            let sheet = ViewControllerPannable(renderFor: .history(sections: self.viewModel.filters))
            sheet.connectionsActionSheet.pageDelegate = self
            sheet.connectionsActionSheet.selectedIndex = self.viewModel.filterIndex
            self.present(vc: sheet, transStyle: .crossDissolve, presentationStyle: .overCurrentContext)
        default: break
        }
    }
}

extension DataHistoryViewController: ActionSheetViewControllerDelegate {
    func sheetFilterAction(index: Int) {
        self.viewModel.filterIndex = index
    }
}
