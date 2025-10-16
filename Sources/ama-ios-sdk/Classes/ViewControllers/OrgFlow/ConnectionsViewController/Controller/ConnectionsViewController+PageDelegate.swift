//
//  ConnectionsViewController+PageDelegate.swift
//  dataWallet
//
//  Created by sreelekh N on 10/12/21.
//

import Foundation
import UIKit

extension ConnectionsViewController: WalletHomeTitleDelegate, OrganisationListDelegate, ActionSheetViewControllerDelegate {
    
    func sheetFilterAction(index: Int) {
        self.viewModel?.connectionType = ConnectionType(rawValue: index)
    }
    
    func closeButtonAction() {
        dismiss(animated: true)
    }
    
    func searchStarted(value: String) {
        self.viewModel?.searchKey = value
    }
    
    func addCardTapped() {
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            initaiateNewConnectionToCloudAgentBottomSheet()
        } else {
            self.initaiateNewConnectionToCloudAgent()
        }
    }
    
    func filterButtonAction() {
        let sheet = ViewControllerPannable(renderFor: .connectionActionSheet)
        sheet.connectionsActionSheet.pageDelegate = self
        sheet.connectionsActionSheet.selectedIndex = self.viewModel?.connectionType?.rawValue ?? 0
        self.present(vc: sheet, transStyle: .crossDissolve, presentationStyle: .overFullScreen)
    }
    
    func reloadData() {
        self.setEmptyMessage()
    }
    
    func tableAction(_ index: Int) {
        let item = viewModel?.searchedConnections?[safe: index]
        UIPasteboard.general.string = item?.value?.myDid ?? ""
        if item?.value?.isIgrantAgent == "1" || item?.value?.orgDetails?.orgId == EBSIWallet.shared.orgId || ((item?.value?.orgDetails?.orgId?.starts(with:"EBSI_")) != nil) {
            if viewMode == .BottomSheet {
                let vc = OrganizationDetailBottomSheetVC()
                vc.viewMode = viewMode
                vc.viewModel = OrganizationDetailViewModel(walletHandle: viewModel?.walletHandle,reqId: item?.value?.requestID, isiGrantOrg: item?.value?.isIgrantAgent == "1")
                if item?.value?.orgDetails?.orgId == EBSIWallet.shared.orgId || ((item?.value?.orgDetails?.orgId?.starts(with:"EBSI_")) != nil) {
                    vc.viewModel?.loadUIFor = .EBSI
                    vc.viewModel?.connectionModel = item
                }
                let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                sheetVC.modalTransitionStyle = .crossDissolve
                
                if let topVC = UIApplicationUtils.shared.getTopVC() {
                    topVC.present(sheetVC, animated: true, completion: nil)
                }
            } else {
                let vc = OrganizationDetailViewController()
                vc.viewMode = viewMode
                vc.viewModel = OrganizationDetailViewModel(walletHandle: viewModel?.walletHandle,reqId: item?.value?.requestID, isiGrantOrg: item?.value?.isIgrantAgent == "1")
                if item?.value?.orgDetails?.orgId == EBSIWallet.shared.orgId || ((item?.value?.orgDetails?.orgId?.starts(with:"EBSI_")) != nil) {
                    vc.viewModel?.loadUIFor = .EBSI
                    vc.viewModel?.connectionModel = item
                }
                push(vc: vc)
            }
        } else {
            let vc = CertificateListViewController()
            vc.viewModel = CertificateListViewModel.init(walletHandle: viewModel?.walletHandle, reqId: item?.value?.requestID,connectionModel:item?.value)
            push(vc: vc)
        }
    }
}
