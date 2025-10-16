//
//  RecieptStateViewModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 27/01/23.
//

import Foundation
import IndyCWrapper

class ReceiptStateViewModel {
    var walletHandle: IndyHandle?
    var certDetail: SearchCertificateRecord?
    var reqId : String?
    weak var delegate: WalletCertificateDetailDelegate?
    var inboxId: String?
    var certModel:SearchItems_CustomWalletRecordCertModel?
    var orgInfo: OrganisationInfoModel?
    var receiptModel: ReceiptCredentialModel?
    weak var pageDelegate: CirtificateDelegate?

    init(walletHandle: IndyHandle?,reqId: String?,certDetail: SearchCertificateRecord?, inboxId: String?, certModel:SearchItems_CustomWalletRecordCertModel? = nil, receiptModel: ReceiptCredentialModel?) {
        self.walletHandle = walletHandle
        self.certDetail = certDetail
        self.reqId = reqId
        self.inboxId = inboxId
        self.certModel = certModel
        self.orgInfo = certModel?.value?.connectionInfo?.value?.orgDetails
        self.receiptModel = receiptModel
    }
    
    func getOrgInfo(completion:@escaping ((Bool) -> Void)){
        let walletHandler = self.walletHandle ?? IndyHandle()
        AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid: certModel?.value?.connectionInfo?.value?.myDid ?? "", completion: { [weak self] (metadataReceived,metadata, error) in
                    let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata ?? "")
                    if let verKey = metadataDict?["verkey"] as? String{
                        let didcom = self?.certDetail?.type?.split(separator: ";").first ?? ""

                            AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnectionInvitation, searchType: .searchWithId,searchValue: self?.certModel?.value?.connectionInfo?.value?.requestID ?? "") {[weak self] (success, searchHandler, error) in
                                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) {[weak self] (searchSuccess, records, error) in
                                    let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: records)
                                    let invitationRecord = (resultsDict?["records"] as? [[String: Any]])?.first
                                    let serviceEndPoint = (invitationRecord?["value"] as? [String: Any])?["serviceEndpoint"] as? String ?? ""
                                    AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: self?.certModel?.value?.connectionInfo?.value?.reciepientKey ?? "", didCom: String(didcom), myVerKey: verKey, type: .getIgrantOrgDetail,isRoutingKeyEnabled: false) {[weak self] (success, orgPackedData, error) in
                                    NetworkManager.shared.sendMsg(isMediator: false, msgData: orgPackedData ?? Data(),url: serviceEndPoint) { [weak self](statuscode,orgServerResponseData) in
                                        if statuscode != 200 {
                                            completion(true)
                                           UIApplicationUtils.hideLoader()
                                           return
                                        }
                                        AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: orgServerResponseData ?? Data()) {[weak self] (unpackedSuccessfully, orgDetailsData, error) in
                                            if let messageModel = try? JSONSerialization.jsonObject(with: orgDetailsData ?? Data(), options: []) as? [String : Any] {
                                                print("unpackmsg -- \(messageModel)")
                                                let msgString = (messageModel)["message"] as? String
                                                let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                                let recipient_verkey = (messageModel)["recipient_verkey"] as? String ?? ""
                                                let sender_verkey = (messageModel)["sender_verkey"] as? String ?? ""
                                                print("Org details received")
                                                var orgInfoModel = OrganisationInfoModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? OrganisationInfoModel
                                                if orgInfoModel == nil {
                                                    orgInfoModel = self?.certModel?.value?.connectionInfo?.value?.orgDetails
                                                }
                                                self?.orgInfo = orgInfoModel
                                                completion(true)
                                               UIApplicationUtils.hideLoader()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                       UIApplicationUtils.hideLoader()
                    }
        })
    }
    
    func deleteCredentialWith(id:String,walletRecordId: String?) {
        let walletHandler = self.walletHandle ?? 0
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, id: walletRecordId ?? "") { [weak self](success, error) in
            AriesPoolHelper.shared.deleteCredentialFromWallet(withId: id, walletHandle: walletHandler) {[weak self] (success, error) in
                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                self?.pageDelegate?.popVC()
            }
        }
    }
}
