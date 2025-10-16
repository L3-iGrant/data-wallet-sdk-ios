//
//  ConnectionsViewController+Scanner.swift
//  dataWallet
//
//  Created by sreelekh N on 10/12/21.
//

import Foundation
import qr_code_scanner_ios
import UIKit

extension ConnectionsViewController: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess binary: [UInt8]) {
        UIApplicationUtils.showErrorSnackbar(message: "Invalid QR code")
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func initaiateNewConnectionToCloudAgentBottomSheet() {
        AgentWrapper.shared.transport = QRTransportMode()
        let newVC = ScannerBottomSheetVC()
        let qrScannerView = QRScannerView(frame: newVC.view.bounds)
        newVC.view.insertSubview(qrScannerView, belowSubview: newVC.closeButton)
        qrScannerView.configure(delegate: self)
        qrScannerView.startRunning()
        present(newVC, animated: true)
    }
    
    func initaiateNewConnectionToCloudAgent() {
        let newVC = AriesBaseViewController()
        let qrScannerView = QRScannerView(frame: newVC.view.bounds)
        newVC.view.addSubview(qrScannerView)
        qrScannerView.configure(delegate: self)
        qrScannerView.startRunning()
        newVC.title = "Scan".localizedForSDK()
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    func getCloudAgent() -> UIViewController {
        let newVC = AriesBaseViewController()
        let qrScannerView = QRScannerView(frame: newVC.view.bounds)
        newVC.view.addSubview(qrScannerView)
        qrScannerView.configure(delegate: self)
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
            if await EBSIWallet.shared.checkEBSI_QR(code: code) { return}
            var isAriesRequired = UserDefaults.standard.bool(forKey: "isAriesRequired")
            if  UserDefaults.standard.object(forKey: "isAriesRequired") == nil {
                isAriesRequired = true
            }
            if isAriesRequired {
                let value = "\(code.split(separator: "=").last ?? "")".decodeBase64() ?? ""
                let dataDID = UIApplicationUtils.shared.convertToDictionary(text: value)
                let recipientKey = (dataDID?["recipientKeys"] as? [String])?.first ?? ""
                let label = dataDID?["label"] as? String ?? ""
                let serviceEndPoint = dataDID?["serviceEndpoint"] as? String ?? ""
                let routingKey = (dataDID?["routingKeys"] as? [String]) ?? []
                let imageURL = dataDID?["imageUrl"] as? String ?? (dataDID?["image_url"] as? String ?? "")
                let type = dataDID?["@type"] as? String ?? ""
                let didcom = type.split(separator: ";").first ?? ""
                
                if serviceEndPoint == "" {
                    Task{
                        let (success, qrCodeModel, message, id) = await AriesMobileAgent.shared.saveConnection(withPopup: true, url: code)
                        if success {
                            if let message = message, message.isNotEmpty {
                                UIApplicationUtils.showSuccessSnackbar(message: message)
                            }
                        } else {
                            if let message = message, message.isNotEmpty {
                                UIApplicationUtils.showErrorSnackbar(message: message)
                            }
                        }
                        DispatchQueue.main.async {
                            self.viewModel?.fetchOrgList(completion: { [weak self] (success) in
                                self?.setEmptyMessage()
                            })
                        }
                    }
                } else {
                    self.viewModel?.newConnectionConfigCloudAgent(label: label, theirVerKey: recipientKey, serviceEndPoint: serviceEndPoint,routingKey: routingKey,imageURL: imageURL, didCom: String(didcom),completion: {[weak self] (success) in
                        self?.viewModel?.fetchOrgList(completion: { [weak self] (success) in
                            self?.setEmptyMessage()
                        })
                    })
                }
            } else {
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.showErrorSnackbar(message: "Aries disabled".localizedForSDK())
                return
            }
        }
    }
    
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        self.pop()
    }
}
