//
//  DataAgreementViewModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 22/02/22.
//

import Foundation

enum VerificationStatus {
    case loading
    case success
    case failed
}

enum DataAgreementMode {
    case history
    case dataExchange
    case issueCredential
    case thirdPartyDataShare
    case queryDataAgrement
}

protocol DataAgreementViewModelDelegate: AnyObject {
    func reloadData()
}

final class DataAgreementViewModel {
    
    var verification: VerificationStatus = .loading
    var dataAgreement: DataAgreementContext?
    var connectionRecordId: String?
    var mode: DataAgreementMode = .dataExchange
    var delegate: DataAgreementViewModelDelegate?
    var history: HistoryRecordValue?
    var inboxId: String?
    var inboxModel: InboxModelRecord?

    init(dataAgreement: DataAgreementContext? = nil,
         connectionRecordId: String? = nil,
         mode: DataAgreementMode? = nil) {
        self.dataAgreement = dataAgreement
        self.connectionRecordId = connectionRecordId
        self.mode = mode ?? .dataExchange
    }
    
    func verifyCredential() async {
        
        if history?.value?.history?.connectionModel?.value?.isThirdPartyShareSupported == "true" || dataAgreement?.message?.body?.dataPolicy?.thirdPartyDataSharing == true{
            verification = .success
            delegate?.reloadData()
            return
        }
        
        if let valid = history?.value?.history?.dataAgreementModel?.validated ?? dataAgreement?.validated, valid == .valid {
            verification = valid == .valid ? .success : .failed
            delegate?.reloadData()
            return
        }
        
        if let dataAgreement = dataAgreement, let recordId = connectionRecordId, (dataAgreement.message?.body?.proof != nil || dataAgreement.message?.body?.proofChain != nil){
            switch mode {
            case .history:
                let valid = await ValidateCredential.shared.validateCredentialFromHistory(dataAgreement: dataAgreement, recordId: recordId, connectionModel: history?.value?.history?.connectionModel)
                verification = valid ? .success : .failed
                delegate?.reloadData()
                Task{
                    await updateStatusInHistory(valid: valid)
                }
            case .dataExchange, .issueCredential:
                let valid = await ValidateCredential.shared.validateCredential(dataAgreement: dataAgreement, recordId: recordId, connectionModel: history?.value?.history?.connectionModel)
                verification = valid ? .success : .failed
                delegate?.reloadData()
                Task {
                    await updateStatusInInbox(valid: valid)
                }
            case .thirdPartyDataShare:
                break
            case .queryDataAgrement:
                break
            }
        }
    }
    
    func updateStatusInHistory(valid: Bool) async {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        guard let updatedHistory = history?.value,let id = history?.id else {
            return
        }
        do {
            var validated: DataAgreementValidations = .not_validate
            if valid {
                validated = .valid
            } else {
                validated = .invalid
            }
            updatedHistory.history?.dataAgreementModel = dataAgreement
            updatedHistory.history?.dataAgreementModel?.validated = validated
            let value = updatedHistory.dictionary?.toString() ?? ""
            try await WalletRecord.shared.update(walletHandler: walletHandler, recordId: id, type: AriesAgentFunctions.history, value: value)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    func updateStatusInInbox(valid: Bool) async{
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        var validated: DataAgreementValidations = .not_validate
        if valid {
            validated = .valid
        } else {
            validated = .invalid
        }
        dataAgreement?.validated = validated
        do {
            if (inboxModel == nil && ((inboxId?.isNotEmpty) != nil)){
                let (_,record) = try await WalletRecord.shared.get(walletHandler: walletHandler, connectionRecordId: inboxId ?? "", type: AriesAgentFunctions.inbox)
                let recordDict = UIApplicationUtils.shared.convertToDictionary(text: record ?? "") ?? [:]
                inboxModel = InboxModelRecord.decode(withDictionary: recordDict) as? InboxModelRecord
            }
            guard let inboxModel = inboxModel?.value else {return}
            inboxModel.dataAgreement?.validated = validated
            let value = inboxModel.dictionary?.toString() ?? ""
            try await WalletRecord.shared.update(walletHandler: walletHandler, recordId: inboxId ?? "", type: AriesAgentFunctions.inbox, value: value)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    func getProofCount() -> Int {
       return ((dataAgreement?.message?.body?.proofChain != nil) ? (dataAgreement?.message?.body?.proofChain?.count ?? 0) : dataAgreement?.message?.body?.proof == nil ? 0 : 1)
    }
    
    func getReceiptCount() -> Int {
        return (dataAgreement?.receipt != nil ? 1 : 0)
    }
}
