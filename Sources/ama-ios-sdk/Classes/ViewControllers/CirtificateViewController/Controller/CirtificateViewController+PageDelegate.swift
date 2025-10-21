//
//  CirtificateViewController+PageDelegate.swift
//  dataWallet
//
//  Created by sreelekh N on 08/01/22.
//

import Foundation
extension CertificateViewController: CirtificateDelegate, ShareDataFlotingDelegate, CirtificateHeaderDelegate, NavigationHandlerProtocol {
    
    func popVC() {
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            dismiss(animated: true)
        } else {
            self.pop()
        }
    }
    
    func notSupportedPKPass() {
        UIApplicationUtils.showErrorSnackbar(message: "Sorry, currently we support boarding passes only.")
        self.pop()
    }
    
    func shareDataTapped() {
        nextAction()
    }
    
    func idCardSaved() {
        switch pageType {
            case .passport:
                self.navigationController?.popToRootViewController(animated: true)
            default:
                self.pop(animated: true)
        }
    }
    
    func updateUI() {
        self.tableView.reloadInMain()
        switch pageType {
        case .pkPass:
            updatePKPassHeader()
        default:
            break
        }
    }
    
    func rightTapped(tag: Int) {
        showValues = !showValues
        addNavigationItems()
        self.tableView.reloadInMain()
    }
    
    func scanAction() {
        if let vc = ShowQRCodeViewController().initialize() as? ShowQRCodeViewController {
            switch pageType {
            case .aadhar:
                vc.QRCodeImage = self.viewModel.aadhar?.QRCodeImage
            default:
                break
            }
            self.present(vc: vc, transStyle: .crossDissolve, presentationStyle: .overCurrentContext)
        }
    }
}

extension CertificateViewController {
    func nextAction() {
        switch pageType {
        case .passport:
            if let model = self.viewModel.passport.passportModel {
                self.viewModel.passport.saveIDCardToWallet(model: model)
            }
        case .aadhar:
            self.viewModel.aadhar?.saveAadharCertToWallet()
        case .pkPass:
            self.viewModel.pkPass?.savePKPassToWallet()
        case .general:
            break //TODO
        case .issueReceipt(mode: let mode):
            break
        case .multipleTypeCards(isScan: let isScan):
            multipleTypeCardAction()
        case .pwa(isScan: let isScan):
            break
        case .photoId(isScan: let isScan):
            if let model = viewModel.photoID?.photoIDCredential {
                self.viewModel.photoID?.saveIDCardToWallet(model: model) { success in
                    let newRootVC = WalletHomeViewController()
                    self.navigationController?.setViewControllers([newRootVC], animated: true)
                }
            }
        }
    }
    
    func multipleTypeCardAction() {
        Task {
            if !EBSIWallet.shared.enoughCredentials {
                DispatchQueue.main.async {
                    UIApplicationUtils.hideLoader ()
                    UIApplicationUtils.showErrorSnackbar(message: "No enough certificates to start exchange!".localized ())
                }
            } else {
                self.navigationController?.popViewController(animated:true)
                await EBSIWallet.shared.credentialRequestAfterCertificateExchange()
            }
        }
    }
    
    @objc
    func showAdditionalDetails() {
        let vc = PKPassAdditionalDetailViewController()
        vc.bgColor = self.viewModel.pkPass?.bgColor
        vc.labelColor = self.viewModel.pkPass?.labelColor
        vc.backFieldArray = self.viewModel.pkPass?.backFieldArray ?? []
        self.push(vc: vc)
    }
}
