//
//  ExchangeDataPreviewViewModel+EBSI.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 24/08/22.
//

import Foundation
import IndyCWrapper

extension ExchangeDataPreviewViewModel {
    
    func populateModelForEBSI(){
        //    var allItemsIncludedGroups: [GropedAttributes] = []
        Task {
            do{
                let walletHandler = walletHandle ?? IndyHandle()
                let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, searchType: .EBSI)
                let (_, results) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                let certSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                //EBSI_credentials = certSearchModel
                delegate?.refresh()
                delegate?.showAllViews()
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
    }
    
    func verifyEBSI_cred(){
        Task{
            if let search_cert_model = EBSI_credentials?.first?[safe: selectedCardIndex], let cert = search_cert_model.value {
                let success = await EBSIWallet.shared.verifyCredential(credential: cert,conformance: self.EBSI_conformance)
                DispatchQueue.main.async {
                    if success {
                        self.addHistoryToEBSI()
                    } else {
                        UIApplicationUtils.showErrorSnackbar(message: "Something went wrong".localizedForSDK())
                        UIApplicationUtils.hideLoader()
                    }
                }
            }
        }
    }
    
    //Saving copy to wallet in order to show in history screen.
    func addHistoryToEBSI() {
        if let search_cert_model = EBSI_credentials?.first?[safe: selectedCardIndex], let cert = search_cert_model.value {
            let walletHandler = walletHandle ?? IndyHandle()
            var history = History()
            history.attributes = cert.EBSI_v2?.attributes ?? []
            history.dataAgreementModel = nil
            history.dataAgreementModel?.validated = .not_validate
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            history.date = dateFormat.string(from: Date())
            history.connectionModel = connectionModel
            history.type = HistoryType.exchange.rawValue
            history.name = CertType.EBSI.rawValue
            history.certSubType = cert.subType
            history.threadID = cert.certInfo?.value?.threadID ?? ""
            WalletRecord.shared.add(connectionRecordId: "", walletHandler: walletHandler, type: .dataHistory, historyModel: history) { [weak self] success, id, error in
                debugPrint("historySaved -- \(success)")
                guard let strongSelf = self else { return}
                strongSelf.delegate?.goBack()
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.showSuccessSnackbar(message: "Data has been shared successfully".localizedForSDK())
            }
        }
    }
}
