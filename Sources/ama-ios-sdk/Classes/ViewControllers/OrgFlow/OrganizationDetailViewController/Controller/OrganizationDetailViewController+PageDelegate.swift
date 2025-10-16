//
//  OrganizationDetailViewController+PageDelegate.swift
//  dataWallet
//
//  Created by sreelekh N on 14/12/21.
//

import UIKit
extension OrganizationDetailViewController: OrganizationDelegate, OrganizationHeaderDelegate {
    
    func getHeaderFetchedImage(image: UIImage) {
        let dominantClr = image.getDominantColor()
        let isLight = dominantClr.isLight()
        imageLightValue = isLight
    }
    
    func updatePageTitle(title: String) {
        pageTitle = title
    }
    
    func goBackAction() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Constants.reloadOrgList, object: nil)
            self.pop()
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    func reload() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func tappedRow(index: IndexPath) {
        switch viewModel?.loadUIFor {
        case .history,.receiptHistory:
            switch index.section {
            case tableView.numberOfSections - 1:
                //if dataagreement not available
                if viewModel?.history?.value?.history?.dataAgreementModel == nil {
                    return
                }
                // if it is a pullDataNotification
                if viewModel?.history?.value?.history?.pullDataNotification != nil && tableView.numberOfSections - 2 == index.section {
                    return
                }
                let vm = DataAgreementViewModel(dataAgreement: viewModel?.history?.value?.history?.dataAgreementModel,
                                                connectionRecordId: self.viewModel?.history?.value?.history?.connectionModel?.id ?? self.viewModel?.connectionModel?.id ?? viewModel?.reqId ?? "",
                                                mode: .history)
                vm.history = self.viewModel?.history
                let vc = DataAgreementViewController(vm: vm)
                self.push(vc: vc)
            default:
                break
            }
        case .genericCard:
            switch index.row {
            case 4:
                AlertHelper.shared.askConfirmationRandomButtons(message: Alerts.deleteItem.localize, btn_title: [AppButtonTitles.yes.localizedForSDK(), AppButtonTitles.no.localizedForSDK()], completion: { [weak self] index in
                    switch index {
                    case 0:
                        self?.deleteParkingCirtificate()
                    default:
                        break
                    }
                })
            default:
                break
            }
        default:
            switch index.row {
            case 1:
                if viewMode == .BottomSheet {
                    if let vc = DataHistoryViewController().initialize() as? DataHistoryViewController {
                        vc.viewMode = .BottomSheet
                        vc.viewModel.connectionId = self.viewModel?.connectionModel?.value?.orgDetails?.orgId ?? ""
                        vc.modalPresentationStyle = .overCurrentContext
                        vc.modalTransitionStyle = .crossDissolve
                        if let topVC = UIApplicationUtils.shared.getTopVC() {
                            topVC.present(vc, animated: false, completion: nil)
                        }
                        //present(vc, animated: true)
                    }
                    
                    
                    
                    
                    
                    
                    
//                    let vc = DataHistoryBottomSheetVC(nibName: "DataHistoryBottomSheetVC", bundle: UIApplicationUtils.shared.getResourcesBundle())
//                    vc.viewMode = .BottomSheet
//                    vc.viewModel.connectionId = self.viewModel?.connectionModel?.value?.orgDetails?.orgId ?? ""
//                    vc.modalPresentationStyle = .overFullScreen
//                    vc.modalTransitionStyle = .crossDissolve
//                    present(vc, animated: true)
//                    if let topVC = UIApplicationUtils.shared.getTopVC() {
//                        topVC.present(vc, animated: true, completion: nil)
//                    }
                } else {
                    if let vc = DataHistoryViewController().initialize() as? DataHistoryViewController {
                        vc.viewMode = viewMode
                        vc.viewModel.connectionId = self.viewModel?.connectionModel?.value?.orgDetails?.orgId ?? ""
                        self.push(vc: vc)
                    }
                }
            case 2:
                let vc = ThirdPartyGroupViewController(connectionModel: self.viewModel?.connectionModel ?? CloudAgentConnectionWalletModel())
                self.push(vc: vc)
            case 3:
                if viewMode == .BottomSheet {
                    AlertHelper.shared.askConfirmationFromBottomSheet(on: self,message: Alerts.removeOrg.localizedForSDK(), btn_title: [AppButtonTitles.yes.localizedForSDK(), AppButtonTitles.no.localizedForSDK()], completion: { [weak self] index in
                        switch index {
                        case 0:
                            self?.viewModel?.deleteOrg()
                        default:
                            break
                        }
                    })
                } else {
                    AlertHelper.shared.askConfirmationRandomButtons(message: Alerts.removeOrg.localizedForSDK(), btn_title: [AppButtonTitles.yes.localizedForSDK(), AppButtonTitles.no.localizedForSDK()], completion: { [weak self] index in
                        switch index {
                        case 0:
                            self?.viewModel?.deleteOrg()
                        default:
                            break
                        }
                    })
                }
            default:
                break
            }
        }
    }
    
}

