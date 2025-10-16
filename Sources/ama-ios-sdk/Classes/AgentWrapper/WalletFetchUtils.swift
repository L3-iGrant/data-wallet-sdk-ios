//
//  WalletFetchUtils.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 20/09/22.
//

import Foundation

struct WalletFetchUtils {
    static func getDataAgreementContextFromInstanceId(id: String) async -> DataAgreementContext? {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        do{
        let (_, searchHandler) = try await  AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.history, searchType: .history_instanceID, searchValue: id)
            let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
            let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: response)
            let searchModel = SearchHistoryModel.decode(withDictionary: recordResponse ?? [:]) as? SearchHistoryModel
            if let model = searchModel?.records?.first?.value?.history?.dataAgreementModel {
                return model
            } else {
                return nil
            }
        }catch{
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    static func getShareHistoryFromInstanceId(id: String) async -> HistoryRecordValue? {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        do{
        let (_, searchHandler) = try await  AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.history, searchType: .history_instanceID, searchValue: id)
            let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
            let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: response)
            let searchModel = SearchHistoryModel.decode(withDictionary: recordResponse ?? [:]) as? SearchHistoryModel
            if let model = searchModel?.records?.first {
                return model
            } else {
                return nil
            }
        }catch{
            debugPrint(error.localizedDescription)
            return nil
        }
    }
}
