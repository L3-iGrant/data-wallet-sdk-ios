//
//  IDCardListViewModel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 16/05/21.
//

import Foundation

protocol IDCardDelegate: AnyObject {
    func walletDataUpdated(itemCount: Int)
}

class IDCardListViewModel{
    var walletHandle = WalletViewModel.openedWalletHandler
    var certificates:[SearchItems_CustomWalletRecordCertModel] = []
    weak var delegate: IDCardDelegate?
    var searchCert: [SearchItems_CustomWalletRecordCertModel] = []

    func getSavedCertificates() {
        UIApplicationUtils.showLoader()
        let walletHandler = self.walletHandle ?? 0
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, searchType: .oldSelfAttestedCert) {[weak self] (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [weak self] (fetched, old_response, error) in
                let old_responseDict = UIApplicationUtils.shared.convertToDictionary(text: old_response)
                let old_idCardSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: old_responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                let oldCards = old_idCardSearchModel?.records?.filter({ item in
                    item.value?.subType == SelfAttestedCertTypes.passport.rawValue || item.value?.subType == SelfAttestedCertTypes.aadhar.rawValue
                })
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, searchType: .idCards) {[weak self] (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [weak self] (fetched, response, error) in
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let idCardSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                UIApplicationUtils.hideLoader()
                self?.certificates = (oldCards ?? []) + (idCardSearchModel?.records ?? [])
                self?.searchCert = (oldCards ?? []) + (idCardSearchModel?.records ?? [])
                self?.delegate?.walletDataUpdated(itemCount: self?.certificates.count ?? 0)
                print("wallet credentials fetched")
            }
        }
            }
        }
    }
    
    func updateSearchedItems(searchString: String){
        if searchString == "" {
            self.searchCert = certificates
            delegate?.walletDataUpdated(itemCount: self.certificates.count)
            return
        }
        let filteredArray = self.certificates.filter({ (item) -> Bool in
            return (item.value?.searchableText?.lowercased().contains(searchString.lowercased()) ?? false)
        })
        self.searchCert = filteredArray
        delegate?.walletDataUpdated(itemCount: self.certificates.count)
        return
    }
}
