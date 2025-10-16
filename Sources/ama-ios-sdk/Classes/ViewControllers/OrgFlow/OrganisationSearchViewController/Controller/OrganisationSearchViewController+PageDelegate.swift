//
//  OrganisationSearchViewController+PageDelegate.swift
//  dataWallet
//
//  Created by sreelekh N on 20/12/21.
//

import UIKit
extension OrganisationSearchViewController: DataHistoryViewModelDelegate, WalletHomeTitleDelegate {
    func reloadData() {
        tableView.reloadInMain()
        setEmptyMessage()
    }
    
    func closeButtonAction() {
        //dismiss(animated: true)
    }
    
    func cellTapped(_ index: Int) {
        if viewModel.histories?[index].value?.history?.certSubType == "PAYMENT WALLET ATTESTATION" && viewModel.histories?[index].value?.history?.type == HistoryType.exchange.rawValue && viewModel.histories?[index].value?.history?.transactionData != nil {
            let vc = PaymentDataConfirmationMySharedDataVC(nibName: "PaymentDataConfirmationMySharedDataVC", bundle: nil)
            vc.viewModel = PaymentDataConfirmationMySharedDataViewModel(history: viewModel.histories?[safe: index])
            push(vc: vc)
        } else {
            let vc = OrganizationDetailViewController()
            vc.viewModel = OrganizationDetailViewModel(render: .history, history: viewModel.histories?[index])
            push(vc: vc)
        }
    }
    
    func searchStarted(value: String) {
        viewModel.searchKey = value
    }
    
    func setEmptyMessage() {
        self.tableView.reloadInMain()
        if self.viewModel.filteredList?.isEmpty ?? false {
            errorView.isHidden = false
            self.errorView.setValues(value: .label(value: "No result found".localizedForSDK()))
        } else {
            errorView.isHidden = true
        }
    }
}

extension OrganisationSearchViewController: NavigationHandlerProtocol {
    func rightTapped(tag: Int) {
        let sections = ["All History", "Active Data Sharing", "Passive Data Sharing"]
        let sheet = ViewControllerPannable(renderFor: .thirdPartyPage(sections: sections))
        sheet.connectionsActionSheet.pageDelegate = self
        sheet.connectionsActionSheet.selectedIndex = 0
        self.present(vc: sheet, transStyle: .crossDissolve, presentationStyle: .overCurrentContext)
    }
}

extension OrganisationSearchViewController: ActionSheetViewControllerDelegate {
    func sheetFilterAction(index: Int) {
        
    }
}
