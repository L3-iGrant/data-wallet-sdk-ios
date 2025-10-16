//
//  ThirdPartyGroupViewController+Confirm.swift
//  dataWallet
//
//  Created by sreelekh N on 07/09/22.
//

import Foundation
extension ThirdPartyGroupViewController: WalletHomeTitleDelegate {
    func searchStarted(value: String) {
        self.viewModel.searchKey = value
    }
    
    func closeButtonAction() {
        //dismiss(animated: true)
    }
}

extension ThirdPartyGroupViewController: NavigationHandlerProtocol {
    func rightTapped(tag: Int) {
        switch tag {
        case 0:
            let sheet = ViewControllerPannable(renderFor: .thirdPartyPage(sections: self.viewModel.sectors))
            sheet.connectionsActionSheet.pageDelegate = self
            sheet.connectionsActionSheet.selectedIndex = self.viewModel.filterIndex
            self.present(vc: sheet, transStyle: .crossDissolve, presentationStyle: .overCurrentContext)
        default: break
        }
    }
}

extension ThirdPartyGroupViewController: ActionSheetViewControllerDelegate {
    func sheetFilterAction(index: Int) {
        self.viewModel.filterIndex = index
    }
}

extension ThirdPartyGroupViewController: ThirdPartyGroupViewModelBind {
    func updateForsearch() {
        self.tableView.reloadInMain()
    }
}
