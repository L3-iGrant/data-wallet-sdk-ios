//
//  OpenWallet.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 10/03/22.
//

import Foundation

//class OpenWallet{
//    static let shared = OpenWallet()
//    private init(){}
//
//        func openWallet(model: WalletViewModel,completion: @escaping (Bool?) -> Void) {
//            if !isFromWelcome {
//                self.loadingStatus.text = "Configuring wallet...".localizedForSDK()
//            } else {
//                UIApplicationUtils.showLoader()
//            }
//            let auth = AuthIdModel()
//            AgentWrapper.shared.openWallet(withConfig: auth.config, credentials: auth.cred) { [weak self] (error, indyHandle) in
//                if (indyHandle == 0) {
//                    self?.createWallet(model: model,completion: completion)
//                } else {
//                    QuickActionNavigation.shared.walletHandle = indyHandle
//                    QuickActionNavigation.shared.mediatorVerKey = WalletViewModel.mediatorVerKey
//                    model.walletHandle = indyHandle
//                    print("wallet opened")
//                    self?.endTime = Date().timeIntervalSince1970
//                    let differenceInSeconds = Int(self?.endTime ?? 0) - Int(self?.startTime ?? 0)
//                    if differenceInSeconds > 2 {
//                        completion(true)
//                    } else {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                            completion(true)
//                        }
//                    }
//
//                    if reachability.connection != .unavailable {
//                        WalletViewModel.shared.checkMediatorConnectionAvailable()
//        //                if !(self?.isFromWelcome ?? false) {
//        //                    self?.loadingStatus.text = "Configuring pool...".localizedForSDK()
//        //                }
//
//                        AriesPoolHelper.shared.configurePool(walletHandler: indyHandle,completion: {_ in
//                            UIApplicationUtils.shared.hideLedgerConfigToast()
//                            MetaDataUtils.shared.checkForMetaDataUpdate()
//                        })
//                        UIApplicationUtils.shared.showLedgerConfigToast()
//                    }
//
//                }
//            }
//        }
//}
