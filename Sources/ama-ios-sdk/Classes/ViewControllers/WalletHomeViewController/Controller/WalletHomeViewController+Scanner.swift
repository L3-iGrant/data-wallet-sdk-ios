//
//  WalletHomeViewController+Scanner.swift
//  dataWallet
//
//  Created by sreelekh N on 25/11/21.
//

import Foundation
import qr_code_scanner_ios
import UIKit
import IndyCWrapper

extension WalletHomeViewController: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess binary: [UInt8]) {
        UIApplicationUtils.showErrorSnackbar(message: "Invalid QR code")
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func initaiateNewExchangeDataForBottomSheet() {
        AgentWrapper.shared.transport = QRTransportMode()
        let newVC = ScannerBottomSheetVC()
        let qrScannerView = QRScannerView(frame: newVC.view.bounds)
        newVC.view.insertSubview(qrScannerView, belowSubview: newVC.closeButton)
        qrScannerView.configure(delegate: self)
        qrScannerView.startRunning()
        present(newVC, animated: true)
    }
    
    @objc private func dismissScanner() {
        self.dismiss(animated: true)
    }
    
    @objc func initaiateNewExchangeData() {
        AgentWrapper.shared.transport = QRTransportMode()
        let newVC = AriesBaseViewController()
        let qrScannerView = QRScannerView(frame: newVC.view.bounds)
        newVC.view.addSubview(qrScannerView)
        qrScannerView.configure(delegate: self)
        qrScannerView.startRunning()
        newVC.title = "Scan".localizedForSDK()
        self.navigationItem.backButtonTitle = ""
        self.navigationController?.navigationBar.tintColor = .black
        newVC.modalPresentationStyle = .fullScreen
        self.push(vc: newVC)
    }
    
    func getExchangeData(controller: WalletHomeViewController) -> UIViewController {
        AgentWrapper.shared.transport = QRTransportMode()
        let newVC = AriesBaseViewController()
        let qrScannerView = QRScannerView(frame: newVC.view.bounds)
        newVC.view.addSubview(qrScannerView)
        qrScannerView.configure(delegate: controller)
        qrScannerView.startRunning()
        newVC.title = "Scan".localizedForSDK()
        return newVC
    }
    
    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
        Task {
            if await EBSIWallet.shared.checkEBSI_QR(code: code) { return }
            var isAriesRequired = UserDefaults.standard.bool(forKey: "isAriesRequired")
            if  UserDefaults.standard.object(forKey: "isAriesRequired") == nil {
                isAriesRequired = true
            }
            if isAriesRequired {
                let value = "\(code.split(separator: "=").last ?? "")".decodeBase64() ?? ""
                let data = UIApplicationUtils.shared.convertToDictionary(text: value)
                let qrModel = ExchangeDataQRCodeModel.decode(withDictionary: data as NSDictionary? ?? NSDictionary()) as? ExchangeDataQRCodeModel
                
                if qrModel?.invitationURL == nil {
                    Task {
                        let (success, qrCodeModel, message, id) = await AriesMobileAgent.shared.saveConnection(withPopup: true, url: code)
                        if success {
                            if let message = message, message.isNotEmpty {
                                UIApplicationUtils.showSuccessSnackbar(message: message)
                            }
                        } else {
                            if let message = message, message.isNotEmpty {
                                //UIApplicationUtils.showErrorSnackbar(message: message)
                            }
                        }
                    }
                } else {
                    if let controller = ExchangeDataPreviewViewController().initialize() as? ExchangeDataPreviewViewController {
                        controller.viewModel = ExchangeDataPreviewViewModel.init(walletHandle: viewModel.walletHandle, reqDetail: nil,QRData: qrModel,isFromQR: true,inboxId: nil,connectionModel: nil)
                        self.push(vc: controller)
                    }
                }
            } else {
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.showErrorSnackbar(message: "Aries disabled".localizedForSDK())
                return
            }
        }
    }
    
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            dismiss(animated: true)
        } else {
            self.pop()
        }
    }
}
