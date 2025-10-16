//
//  GeneralStateViewModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 22/08/22.
//

import Foundation
import IndyCWrapper
import eudiWalletOidcIos

class GeneralStateViewModel {
    var walletHandle: IndyHandle?
    var certDetail: SearchCertificateRecord?
    var reqId : String?
    weak var delegate: WalletCertificateDetailDelegate?
    var inboxId: String?
    var certModel:SearchItems_CustomWalletRecordCertModel?
    var orgInfo: OrganisationInfoModel?
    weak var pageDelegate: CirtificateDelegate?

    init(walletHandle: IndyHandle?,reqId: String?,certDetail: SearchCertificateRecord?, inboxId: String?, certModel:SearchItems_CustomWalletRecordCertModel? = nil) {
        self.walletHandle = walletHandle
        self.certDetail = certDetail
        self.reqId = reqId
        self.inboxId = inboxId
        self.certModel = certModel
        self.orgInfo = certModel?.value?.connectionInfo?.value?.orgDetails
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
                
                Task { [weak self] in
                    if let notificationEndPont = self?.certModel?.value?.notificationEndPont, let notificationID = self?.certModel?.value?.notificationID {
                        let accessTokenParts = self?.certModel?.value?.accessToken?.split(separator: ".")
                        var accessTokenData: String? =  nil
                        var refreshTokenData: String? =  nil
                        if accessTokenParts?.count ?? 0 > 1 {
                            let accessTokenBody = "\(accessTokenParts?[1] ?? "")".decodeBase64()
                            let dict = UIApplicationUtils.shared.convertToDictionary(text: String(accessTokenBody ?? "{}")) ?? [:]
                            let exp = dict["exp"] as? Int ?? 0
                            let expiryDate = TimeInterval(exp)
                            let currentTimestamp = Date().timeIntervalSince1970
                            if expiryDate < currentTimestamp {
                                accessTokenData = await NotificationService().refreshAccessToken(refreshToken: self?.certModel?.value?.refreshToken ?? "", endPoint: self?.certModel?.value?.tokenEndPoint ?? "").0
                                refreshTokenData = await NotificationService().refreshAccessToken(refreshToken: self?.certModel?.value?.refreshToken ?? "", endPoint: self?.certModel?.value?.tokenEndPoint ?? "").1
                            } else {
                                accessTokenData = self?.certModel?.value?.accessToken
                                refreshTokenData = self?.certModel?.value?.refreshToken
                            }
                        }
                        self?.certModel?.value?.refreshToken = refreshTokenData
                        self?.certModel?.value?.accessToken = accessTokenData
                        await NotificationService().sendNoticationStatus(endPoint: self?.certModel?.value?.notificationEndPont, event: NotificationStatus.credentialDeleted.rawValue, notificationID: self?.certModel?.value?.notificationID, accessToken: self?.certModel?.value?.accessToken ?? "", refreshToken: self?.certModel?.value?.refreshToken ?? "", tokenEndPoint: self?.certModel?.value?.tokenEndPoint ?? "")
                    }
                }
                self?.pageDelegate?.popVC()
            }
        }
    }
    
    func isEBSI_diploma() -> Bool {
        if certModel?.value?.EBSI_v2 != nil && certModel?.value?.subType == EBSI_CredentialType.Diploma.rawValue {
            return true
        } else {
            return false
        }
    }
    
    func isEBSI() -> Bool {
        if certModel?.value?.EBSI_v2 != nil && certModel?.value?.type == CertType.EBSI.rawValue{
            return true
        } else {
            return false
        }
    }
}

class MultipleTypeCards {
    var walletHandle: IndyHandle?
    var certDetail: SearchCertificateRecord?
    var reqId : String?
    weak var delegate: WalletCertificateDetailDelegate?
    var inboxId: String?
    var certModel: [SearchItems_CustomWalletRecordCertModel]?
    var orgInfo: OrganisationInfoModel?
    weak var pageDelegate: CirtificateDelegate?

    init(walletHandle: IndyHandle?,reqId: String?,certDetail: SearchCertificateRecord?, inboxId: String?, certModel:[SearchItems_CustomWalletRecordCertModel]? = nil) {
        self.walletHandle = walletHandle
        self.certDetail = certDetail
        self.reqId = reqId
        self.inboxId = inboxId
        self.certModel = certModel
        self.orgInfo = certModel?[0].value?.connectionInfo?.value?.orgDetails
    }
    
    func getOrgInfo(completion:@escaping ((Bool) -> Void)) {
        let walletHandler = self.walletHandle ?? IndyHandle()
        AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid: certModel?[0].value?.connectionInfo?.value?.myDid ?? "", completion: { [weak self] (metadataReceived,metadata, error) in
            let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata ?? "")
            if let verKey = metadataDict?["verkey"] as? String{
                let didcom = self?.certDetail?.type?.split(separator: ";").first ?? ""
                
                AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnectionInvitation, searchType: .searchWithId,searchValue: self?.certModel?[0].value?.connectionInfo?.value?.requestID ?? "") {[weak self] (success, searchHandler, error) in
                    AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) {[weak self] (searchSuccess, records, error) in
                        let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: records)
                        let invitationRecord = (resultsDict?["records"] as? [[String: Any]])?.first
                        let serviceEndPoint = (invitationRecord?["value"] as? [String: Any])?["serviceEndpoint"] as? String ?? ""
                        AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: self?.certModel?[0].value?.connectionInfo?.value?.reciepientKey ?? "", didCom: String(didcom), myVerKey: verKey, type: .getIgrantOrgDetail,isRoutingKeyEnabled: false) {[weak self] (success, orgPackedData, error) in
                            NetworkManager.shared.sendMsg(isMediator: false, msgData: orgPackedData ?? Data(),url: serviceEndPoint) { [weak self](statuscode,orgServerResponseData) in
                                if statuscode != 200 {
                                    completion(true)
                                    UIApplicationUtils.hideLoader()
                                    return
                                }
                                AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: orgServerResponseData ?? Data()) {[weak self] (unpackedSuccessfully, orgDetailsData, error) in
                                    if let messageModel = try? JSONSerialization.jsonObject(with: orgDetailsData ?? Data(), options: []) as? [String : Any] {
                                        debugPrint("unpackmsg -- \(messageModel)")
                                        let msgString = (messageModel)["message"] as? String
                                        let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                        debugPrint("Org details received")
                                        var orgInfoModel = OrganisationInfoModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? OrganisationInfoModel
                                        if orgInfoModel == nil {
                                            orgInfoModel = self?.certModel?[0].value?.connectionInfo?.value?.orgDetails
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
    
    func isEBSI_diploma() -> Bool {
        if certModel?[0].value?.EBSI_v2 != nil && certModel?[0].value?.subType == EBSI_CredentialType.Diploma.rawValue {
            return true
        } else {
            return false
        }
    }
    
    func isEBSI() -> Bool {
        if certModel?[0].value?.EBSI_v2 != nil && certModel?[0].value?.type == CertType.EBSI.rawValue{
            return true
        } else {
            return false
        }
    }
}

class PWACertViewModel {
    var walletHandle: IndyHandle?
    var certDetail: SearchCertificateRecord?
    var reqId : String?
    weak var delegate: WalletCertificateDetailDelegate?
    var inboxId: String?
    var certModel:SearchItems_CustomWalletRecordCertModel?
    var orgInfo: OrganisationInfoModel?
    weak var pageDelegate: CirtificateDelegate?
    var isFromExpired: Bool? = false

    init(walletHandle: IndyHandle?,reqId: String?,certDetail: SearchCertificateRecord?, inboxId: String?, certModel:SearchItems_CustomWalletRecordCertModel? = nil) {
        self.walletHandle = walletHandle
        self.certDetail = certDetail
        self.reqId = reqId
        self.inboxId = inboxId
        self.certModel = certModel
        self.orgInfo = certModel?.value?.connectionInfo?.value?.orgDetails
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
    
    func deleteCredentialWith(id:String,walletRecordId: String?, data: SearchItems_CustomWalletRecordCertModel?) {
        let walletHandler = self.walletHandle ?? 0
        let type = isFromExpired ?? false ? AriesAgentFunctions.expiredCertificate : AriesAgentFunctions.walletCertificates
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: type, id: walletRecordId ?? "") { [weak self](success, error) in
            AriesPoolHelper.shared.deleteCredentialFromWallet(withId: id, walletHandle: walletHandler) {[weak self] (success, error) in
                UIApplicationUtils.showSuccessSnackbar(message: "Removed successfully".localized())
                Task {
                    if let notificationEndPont = data?.value?.notificationEndPont, let notificationID = data?.value?.notificationID {
                        let accessTokenParts = data?.value?.accessToken?.split(separator: ".")
                        var accessTokenData: String? =  nil
                        var refreshTokenData: String? =  nil
                        if accessTokenParts?.count ?? 0 > 1 {
                            let accessTokenBody = "\(accessTokenParts?[1] ?? "")".decodeBase64()
                            let dict = UIApplicationUtils.shared.convertToDictionary(text: String(accessTokenBody ?? "{}")) ?? [:]
                            let exp = dict["exp"] as? Int ?? 0
                            let expiryDate = TimeInterval(exp)
                            let currentTimestamp = Date().timeIntervalSince1970
                            if expiryDate < currentTimestamp {
                                accessTokenData = await NotificationService().refreshAccessToken(refreshToken: data?.value?.refreshToken ?? "", endPoint: data?.value?.tokenEndPoint ?? "").0
                                refreshTokenData = await NotificationService().refreshAccessToken(refreshToken: data?.value?.refreshToken ?? "", endPoint: data?.value?.tokenEndPoint ?? "").1
                            } else {
                                accessTokenData = data?.value?.accessToken
                                refreshTokenData = data?.value?.refreshToken
                            }
                        }
                        data?.value?.refreshToken = refreshTokenData
                        data?.value?.accessToken = accessTokenData
                        await NotificationService().sendNoticationStatus(endPoint: data?.value?.notificationEndPont, event: NotificationStatus.credentialDeleted.rawValue, notificationID: data?.value?.notificationID, accessToken: data?.value?.accessToken ?? "", refreshToken: data?.value?.refreshToken ?? "", tokenEndPoint: data?.value?.tokenEndPoint ?? "")
                    }
                }
            }
        }
    }
    
    func deleteAllCredentialInPWAWith(record: [SearchItems_CustomWalletRecordCertModel]?) {
        for item in record ?? [] {
            let walletHandler = self.walletHandle ?? 0
            let type = isFromExpired ?? false ? AriesAgentFunctions.expiredCertificate : AriesAgentFunctions.walletCertificates
            AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: type, id: item.id ?? "") { [weak self](success, error) in
                AriesPoolHelper.shared.deleteCredentialFromWallet(withId: item.value?.referent?.referent ?? "", walletHandle: walletHandler) {[weak self] (success, error) in
                    Task {
                        if let notificationEndPont = item.value?.notificationEndPont, let notificationID = item.value?.notificationID {
                            let accessTokenParts = item.value?.accessToken?.split(separator: ".")
                            var accessTokenData: String? =  nil
                            var refreshTokenData: String? =  nil
                            if accessTokenParts?.count ?? 0 > 1 {
                                let accessTokenBody = "\(accessTokenParts?[1] ?? "")".decodeBase64()
                                let dict = UIApplicationUtils.shared.convertToDictionary(text: String(accessTokenBody ?? "{}")) ?? [:]
                                let exp = dict["exp"] as? Int ?? 0
                                let expiryDate = TimeInterval(exp)
                                let currentTimestamp = Date().timeIntervalSince1970
                                if expiryDate < currentTimestamp {
                                    accessTokenData = await NotificationService().refreshAccessToken(refreshToken: item.value?.refreshToken ?? "", endPoint: item.value?.tokenEndPoint ?? "").0
                                    refreshTokenData = await NotificationService().refreshAccessToken(refreshToken: item.value?.refreshToken ?? "", endPoint: item.value?.tokenEndPoint ?? "").1
                                } else {
                                    accessTokenData = item.value?.accessToken
                                    refreshTokenData = item.value?.refreshToken
                                }
                            }
                            item.value?.refreshToken = refreshTokenData
                            item.value?.accessToken = accessTokenData
                            await NotificationService().sendNoticationStatus(endPoint: item.value?.notificationEndPont, event: NotificationStatus.credentialDeleted.rawValue, notificationID: item.value?.notificationID, accessToken: item.value?.accessToken ?? "", refreshToken: item.value?.refreshToken ?? "", tokenEndPoint: item.value?.tokenEndPoint ?? "")
                        }
                    }
                }
            }
        }
        UIApplicationUtils.showSuccessSnackbar(message: "Certificate removed successfully".localized())
        if self.isFromExpired ?? false {
            //NotificationCenter.default.post(name: Constants.reloadExpiredList, object: nil)
        } else {
            NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
        }
        self.pageDelegate?.popVC()
    }
    
    func isEBSI_diploma() -> Bool {
        if certModel?.value?.EBSI_v2 != nil && certModel?.value?.subType == EBSI_CredentialType.Diploma.rawValue {
            return true
        } else {
            return false
        }
    }
    
    func isEBSI() -> Bool {
        if certModel?.value?.EBSI_v2 != nil && certModel?.value?.type == CertType.EBSI.rawValue{
            return true
        } else {
            return false
        }
    }
}
