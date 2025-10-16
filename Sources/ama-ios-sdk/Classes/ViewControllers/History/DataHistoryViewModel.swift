//
//  DataHistoryViewModel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 25/09/21.
//

import Foundation
import IndyCWrapper

protocol DataHistoryViewModelDelegate {
    func reloadData()
    func cellTapped(_ index: Int)
}

final class DataHistoryViewModel {
    
    var history: HistoryRecordValue?
    var filters = ["All History", "Active Data Sharing", "Passive Data Sharing"]
    var filterIndex = 0{
        didSet {
            self.updateSearchedItems()
        }
    }
    var histories: [HistoryRecordValue]?
    var filteredList: [HistoryRecordValue]?
    var pageDelegate: DataHistoryViewModelDelegate?
    var searchKey: String = "" {
        didSet {
            updateSearchedItems()
        }
    }
    var connectionId = ""
    
    func getHistories(completion: @escaping (Bool) -> Void) {
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.history, searchType:.withoutQuery) { [weak self](success, prsntnExchngSearchWallet, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: prsntnExchngSearchWallet, count: 1000) { [weak self] (success, response, error) in
                let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: response)
                let searchModel = SearchHistoryModel.decode(withDictionary: recordResponse ?? [:]) as? SearchHistoryModel
                if let records = searchModel?.records {
                    let sortedSelfAttestedCert = records.sorted(by: { ($0.value?.history?.date ?? "") > ($1.value?.history?.date ?? "") })
                    if self?.connectionId.isNotEmpty ?? true {
                        self?.histories = sortedSelfAttestedCert.filter({ $0.tags?.organisationID ==  self?.connectionId })
                        self?.filteredList = self?.histories
                    } else {
                        self?.histories = sortedSelfAttestedCert
                        self?.filteredList = self?.histories
                    }
                    completion(true)
                } else {
                    self?.histories = []
                    completion(false)
                }
            }
        }
    }
    
    func updateSearchedItems() {
        if searchKey.isEmpty {
            filteredList = self.histories?.filter({ value in
                filterAsPerSelection(value: value)
            })
        } else {
            filteredList = histories?.filter({ value in
                (value.value?.history?.name ?? "").contains(searchKey) && filterAsPerSelection(value: value)
            })
        }
        pageDelegate?.reloadData()
    }
    
    func filterAsPerSelection(value: HistoryRecordValue) -> Bool{
        switch filterIndex {
        case 0: return true
        case 1: return (value.tags?.isThirdPartyDataShare != "True")
        case 2: return (value.tags?.isThirdPartyDataShare == "True")
        default: return false
        }
    }
}
