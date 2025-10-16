//
//  CertificateListViewModel.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 07/12/20.
//

import Foundation
import SVProgressHUD
import IndyCWrapper

protocol CertificateListViewModelDelegate: AnyObject {
    func goBack()
}

class CertificateListViewModel {
    var walletHandle: IndyHandle?
    var reqId : String?
    var orgModel: [NonIgrantOrgModel] = []
    weak var delegate: CertificateListViewModelDelegate?
    var connectionModel:CloudAgentConnectionValue?

    init(walletHandle: IndyHandle?,reqId: String?,connectionModel:CloudAgentConnectionValue?) {
        self.walletHandle = walletHandle
        self.reqId = reqId
        self.connectionModel = connectionModel
    }
    
    func fetchCertificates(completion: @escaping (Bool) -> Void) {
        let walletHandler = self.walletHandle ?? IndyHandle()
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, searchType: .inbox_offerReceived, searchValue: self.reqId ?? "") {[weak self] (success, searchHandle, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandle,count: 100) {[weak self] (success, response, error) in
                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let resultModel = SearchInboxModel.decode(withDictionary: resultsDict as NSDictionary? ?? NSDictionary()) as? SearchInboxModel
                if let records = resultModel?.records {
                    var tempOrgModel: [NonIgrantOrgModel] = []
                    for item in records{
                        var attr: [SearchCertificateAttribute]?
                        let attrDict = item.value?.offerCredential?.value?.credential?.attrs
                        attrDict?.forEach({ (key,value) in
                            attr?.append(SearchCertificateAttribute.init(name: key, value: value))
                        })
                        let tempModel = NonIgrantOrgModel.init()
                        tempModel.certificates = item
                        tempModel.attr = attr
                        tempOrgModel.append(tempModel)
                    }
                    self?.orgModel = tempOrgModel
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    func deleteOrg() {
        let walletHandler = self.walletHandle ?? IndyHandle()
        UIApplicationUtils.showLoader()
        var numberOfBlockCompleted = 0
        
        //Use dispatch Queue - future improvements
        
        //delete didDoc
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: DidDocTypes.cloudAgentDidDoc.rawValue, searchType: .searchWithTheirDid,searchValue: self.connectionModel?.theirDid ?? "") {[weak self] (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler, count: 1) {[weak self] (success, response, error) in
                let resultDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let didDocModel = SearchDidDocModel.decode(withDictionary: resultDict as NSDictionary? ?? NSDictionary()) as? SearchDidDocModel
                AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type:DidDocTypes.cloudAgentDidDoc.rawValue , id: didDocModel?.records?.first?.value?.id ?? "") { [weak self](success, error) in
                    print("delete didDoc")
                    numberOfBlockCompleted += 1
                    self?.deletedSuccessfully(count: numberOfBlockCompleted)
                }
            }
        }
        
        //delete didKey
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: DidKeyTypes.cloudAgentDidKey.rawValue, searchType: .searchWithTheirDid,searchValue: self.connectionModel?.theirDid ?? "") { [weak self](success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler, count: 1) {[weak self] (success, response, error) in
                let resultDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let record = (resultDict?["records"] as? [[String: Any]])?.first
                let id = (record?["value"] as? [String: Any])?["@id"] as? String ?? ""
                AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type:DidKeyTypes.cloudAgentDidKey.rawValue , id: id ) { [weak self](success, error) in
                    print("delete didkey")
                    numberOfBlockCompleted += 1
                    self?.deletedSuccessfully(count: numberOfBlockCompleted)
                }
            }
        }
        
        //delete certType
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.certType, searchType: .searchWithId, searchValue: self.reqId ?? "") { [weak self](success, searchHandler, error) in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler, count: 1000) { [weak self](success, result, error) in
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: result)
                    let certificatedModel = SearchCertificateResponse.decode(withDictionary: resultDict as NSDictionary? ?? NSDictionary()) as? SearchCertificateResponse
                    if certificatedModel?.totalCount == 0 {
                        print("delete notifications")
                        numberOfBlockCompleted += 1
                        self?.deletedSuccessfully(count: numberOfBlockCompleted)
                        return
                    }
                    var count = 1
                    for item in certificatedModel?.records ?? [] {
                        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: item.id ?? "") { [weak self](deletedSuccessfully, error) in
                            if count == certificatedModel?.records?.count ?? 2 - 1 {
                                print("delete certType")
                                numberOfBlockCompleted += 1
                                self?.deletedSuccessfully(count: numberOfBlockCompleted)
                            }
                            count += 1
                        }
                    }
                }
            }
        
        //delete presentationExchange
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.presentationExchange, searchType: .searchWithId, searchValue: self.reqId ?? "") {[weak self] (success, searchHandler, error) in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler, count: 1000) { [weak self](success, result, error) in
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: result)
                    let presentationExchangeModel = SearchPresentationExchangeModel.decode(withDictionary: resultDict as NSDictionary? ?? NSDictionary()) as? SearchPresentationExchangeModel
                    if presentationExchangeModel?.totalCount == 0 {
                        print("delete notifications")
                        numberOfBlockCompleted += 1
                        self?.deletedSuccessfully(count: numberOfBlockCompleted)
                        return
                    }
                    var count = 1
                    for item in presentationExchangeModel?.records ?? [] {
                        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: item.id ?? "") {[weak self] (deletedSuccessfully, error) in
                            if count == presentationExchangeModel?.records?.count ?? 2 - 1 {
                                print("delete presentationExchange")
                                numberOfBlockCompleted += 1
                                self?.deletedSuccessfully(count: numberOfBlockCompleted)
                            }
                            count += 1
                        }
                    }
                }
            }
        
        //delete notifications
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, searchType: .searchWithId, searchValue: self.reqId ?? "") { [weak self](success, searchHandler, error) in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler, count: 1000) {[weak self] (success, result, error) in
                    let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: result)
                    let searchInboxModel = SearchInboxModel.decode(withDictionary: recordResponse as NSDictionary? ?? NSDictionary()) as? SearchInboxModel
                    if searchInboxModel?.totalCount == 0 {
                        print("delete notifications")
                        numberOfBlockCompleted += 1
                        self?.deletedSuccessfully(count: numberOfBlockCompleted)
                        return
                    }
                    var count = 1
                    for item in searchInboxModel?.records ?? [] {
                        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: item.id ?? "") { [weak self](deletedSuccessfully, error) in
                            if count == searchInboxModel?.records?.count ?? 2 - 1 {
                                print("delete notifications")
                                numberOfBlockCompleted += 1
                                self?.deletedSuccessfully(count: numberOfBlockCompleted)
                            }
                            count += 1
                        }
                    }
                }
            }
    }
    
    func deletedSuccessfully(count: Int){
        if count != 5 {
            return
        }
        print("deleted all")
        let walletHandler = self.walletHandle ?? IndyHandle()
        //delete Connection
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, id: self.reqId ?? "") {[weak self] (deletedSuccessfully, error) in
            //delete connection Invitation
            AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnectionInvitation, searchType: .searchWithId, searchValue: self?.reqId ?? "") { [weak self](success, searchHandler, error) in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [weak self](searchSuccess, records, error) in
                    let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: records)
                    let invitationRecord = (resultsDict?["records"] as? [[String: Any]])?.first
                    let connectionInvitationRecordId = (invitationRecord?["value"] as? [String: Any])?["@id"] as? String ?? ""
                    AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnectionInvitation, id: connectionInvitationRecordId ) { [weak self](success, error) in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                           UIApplicationUtils.hideLoader()
                            UIApplicationUtils.showSuccessSnackbar(message: "Organisation removed successfully".localizedForSDK())
                            self?.delegate?.goBack()
                        })
                    }
                }
                }
            }
            
    }
}

class NonIgrantOrgModel {
    var certificates: InboxModelRecord?
    var attr: [SearchCertificateAttribute]?
}
