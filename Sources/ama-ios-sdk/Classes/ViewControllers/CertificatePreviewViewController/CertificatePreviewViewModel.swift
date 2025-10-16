//
//  CertificatePreviewViewModel.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 07/12/20.
//

import Foundation
import SVProgressHUD
import SwiftUI
import IndyCWrapper
import eudiWalletOidcIos

protocol CertificatePreviewDelegate: AnyObject {
    func popVC()
    func reloadData()
}

struct SignatureOption : Codable {
    let id, type, created, verificationMethod: String?
    let proofPurpose: String?
}


class CertificatePreviewViewModel {
    var walletHandle: IndyHandle?
    var certDetail: SearchCertificateRecord?
    var reqId : String?
    weak var delegate: CertificatePreviewDelegate?
    var inboxId: String?
    var certModel:SearchItems_CustomWalletRecordCertModel?
    var connectionModel: CloudAgentConnectionWalletModel?
    var dataAgreement: DataAgreementContext?
    private var new_dataAgreement: DataAgreementContext?
    var inboxModel: InboxModelRecord?
    var isRejectOrAcceptTapped: Bool = false
    
    init(walletHandle: IndyHandle?,reqId: String?,certDetail: SearchCertificateRecord?,inboxId: String?, certModel:SearchItems_CustomWalletRecordCertModel? = nil,connectionModel: CloudAgentConnectionWalletModel? = nil, dataAgreement: DataAgreementContext? = nil) {
        self.walletHandle = walletHandle
        self.certDetail = certDetail
        self.reqId = reqId
        self.inboxId = inboxId
        self.certModel = certModel
        self.connectionModel = connectionModel
        self.dataAgreement = dataAgreement
    }
    
    //Fetching data agreement to show in UI - This will be saving in history too
    func fetchDataAgreement(){
        if dataAgreement?.message?.id != nil { return}
        let walletHandler = walletHandle ?? IndyHandle()
        
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection,searchType: .searchWithId, searchValue: self.reqId ?? "", completion: { [weak self](success, searchWalletHandler, error) in
            if (success){
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler, completion: {[weak self] (fetchedSuccessfully,results,error) in
                    if (fetchedSuccessfully){
                        let resultDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                        let firstResult = (resultDict?["records"] as? [[String: Any]])?.first
                        if let connectionRecordId = (resultDict?["records"] as? [[String:Any]])?.first?["id"] as? String {
                            if let myDid = (firstResult?["value"] as? [String: Any])?["my_did"] as? String, let recipientKey = (firstResult?["value"] as? [String: Any])?["reciepientKey"] as? String {
                                AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid: myDid, completion: {[weak self] (metadataReceived,metadata, error) in
                                    let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata ?? "")
                                    if let verKey = metadataDict?["verkey"] as? String{
                                        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type:AriesAgentFunctions.cloudAgentConnectionInvitation,searchType: .searchWithId, searchValue: self?.reqId ?? "", completion: {[weak self] (success, searchWalletHandler, error) in
                                            if (success){
                                                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler, completion: {[weak self] (fetchedSuccessfully,results,error) in
                                                    if (fetchedSuccessfully){
                                                        let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                                                        let invitationRecord = (resultsDict?["records"] as? [[String: Any]])?.first
                                                        let serviceEndPoint = (invitationRecord?["value"] as? [String: Any])?["serviceEndpoint"] as? String ?? ""
                                                        let externalRoutingKey = (invitationRecord?["value"] as? [String: Any])?["routing_key"] as? [String] ?? []
                                                        let didcom = self?.certDetail?.value?.credentialProposalDict?.type?.split(separator: ";").first ?? ""
                                                        AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: recipientKey, didCom: String(didcom), myVerKey: verKey, type: .fetchDataAgreement_issue_cert, isRoutingKeyEnabled: externalRoutingKey.count > 0, externalRoutingKey: externalRoutingKey, QR_ID: self?.certDetail?.value?.credentialOffer?.credDefID ?? "") {[unowned self] (success, data, error) in
                                                            NetworkManager.shared.sendMsg(isMediator: false, msgData: data ?? Data(),url: serviceEndPoint) { [unowned self](statuscode,responseData) in
                                                                
                                                                AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responseData ?? Data()) { [unowned self](unpackSuccess, unpackedData, error) in
                                                                    if let messageModel = try? JSONSerialization.jsonObject(with: unpackedData ?? Data(), options: []) as? [String : Any] {
                                                                        
                                                                        print("unpackmsg -- \(messageModel)")
                                                                        let msgString = (messageModel)["message"] as? String
                                                                        let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                                                        let dataAgreement = DataAgreementModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? DataAgreementModel
                                                                        
                                                                        let dataPolicy = DataPolicy(industrySector: dataAgreement?.purposeDetails?.purpose?.industryScope ?? "",
                                                                                                    jurisdiction: dataAgreement?.purposeDetails?.purpose?.jurisdiction ?? "",
                                                                                                    policyURL: dataAgreement?.purposeDetails?.purpose?.policyURL ?? "",
                                                                                                    storageLocation: dataAgreement?.purposeDetails?.purpose?.restriction ?? "",
                                                                                                    dataRetentionPeriod: nil,
                                                                                                    geographicRestriction: dataAgreement?.purposeDetails?.purpose?.dataRetention?.retentionPeriod?.toString ?? "0", thirdPartyDataSharing: nil)
                                                                        
                                                                        let body = Body(purpose: nil,
                                                                                        dataControllerURL: nil,
                                                                                        dataSubjectDid: nil,
                                                                                        id: nil,
                                                                                        templateVersion: nil,
                                                                                        dataControllerName: nil,
                                                                                        personalData: nil,
                                                                                        templateID: nil,
                                                                                        purposeDescription: nil,
                                                                                        lawfulBasis: nil,
                                                                                        methodOfUse: nil,
                                                                                        dataPolicy: dataPolicy,
                                                                                        version: nil,
                                                                                        context: nil,
                                                                                        dpia: nil,
                                                                                        language: nil,
                                                                                        type: nil)
                                                                        
                                                                        self?.dataAgreement = DataAgreementContext(message: DataAgreementMessage(body: body,
                                                                                                                                                id: "",
                                                                                                                                                 from: nil,
                                                                                                                                                 to: nil, createdTime: nil,
                                                                                                                                                type: ""), messageType: "")
                                                                        self?.delegate?.reloadData()
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                })
                                            }
                                        })
                                    }
                                })
                            }
                        }
                    }
                })
            }
        })
    }
    
    func acceptCertificate(mode: CertificatePreviewVC_Mode? = .other) async {
        UIApplicationUtils.showLoader()
        var credReqPackTemplate: [String: Any]?
        if let dataAgreementContext = dataAgreement, dataAgreementContext.message?.body?.proof != nil {
            (credReqPackTemplate,new_dataAgreement) = await SignCredential.shared.signCredential(dataAgreement: dataAgreementContext, recordId: self.reqId ?? "")
        }
        let walletHandler = walletHandle ?? IndyHandle()
        

        do{
            let success = try await AriesPoolHelper.shared.pool_setProtocol(version: 2)
            let _ = try? await AriesPoolHelper.shared.pool_openLedger(name: "default", config: [String:Any]())
            let (success2, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithId, searchValue: self.reqId ?? "")
            if (success2){
                let (fetchedSuccessfully, results) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler)
                if (fetchedSuccessfully){
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                    let firstResult = (resultDict?["records"] as? [[String: Any]])?.first
                    if let connectionRecordId = (resultDict?["records"] as? [[String:Any]])?.first?["id"] as? String {
                        if let myDid = (firstResult?["value"] as? [String: Any])?["my_did"] as? String, let recipientKey = (firstResult?["value"] as? [String: Any])?["reciepientKey"] as? String {
                            let (metadataReceived, metadata) = try await AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid: myDid)
                            let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata)
                            if let verKey = metadataDict?["verkey"] as? String{
//                                let (success, credDefReqResponse) = try await AriesPoolHelper.shared.buildGetCredDefRequest(id: self.certDetail?.value?.credentialDefinitionID ?? "")
//                                let (success1, credDefSubmitResponse) = try await AriesPoolHelper.shared.submitRequest(poolHandle: AriesPoolHelper.poolHandler, requestJSON: credDefReqResponse)
                                let (success2, credDefId, credDefJson,error) = await AriesPoolHelper.shared.parseGetCredDefResponseWithLedgerSwitching(credentialDefinitionID: self.certDetail?.value?.credentialDefinitionID ?? "")
                                if error?.localizedDescription.contains("309") ?? false {
                                    UIApplicationUtils.hideLoader()
                                    UIApplicationUtils.showErrorSnackbar(message: "Invalid Ledger. You can choose proper ledger from settings".localizedForSDK())
                                    return
                                }
                                if success2{
                                    let credentialOfferData = try! JSONEncoder().encode(self.certDetail?.value?.credentialOffer)
                                    let credentialOfferJsonString = String(data: credentialOfferData, encoding: .utf8)!
                                    let (success, credReqJSON, credReqMetadataJSON) = try await AriesPoolHelper.shared.pool_prover_create_credential_request(walletHandle: walletHandler, forCredentialOffer: credentialOfferJsonString, credentialDefJSON: credDefJson, proverDID: myDid)
                                    if success {
                                        let label = (firstResult?["value"] as? [String: Any])?["their_label"] as? String
                                        let their_did = (firstResult?["value"] as? [String: Any])?["their_did"] as? String
                                        let (success, searchHandle) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: self.walletHandle ?? IndyHandle(), type:AriesAgentFunctions.certType, searchType: .searchWithId, searchValue: self.reqId ?? "")
                                        let (success1, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: self.walletHandle ?? IndyHandle(), searchWalletHandler: searchHandle)
                                        let resultDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                                        let certRecord = (resultDict?["records"] as? [[String: Any]])?.first
                                        let certRecordId = certRecord?["id"] as? String ?? ""
                                        var tempCertModel = self.certDetail
                                        tempCertModel?.value?.credentialOffer = SearchCertificateCredentialOffer.decode(withDictionary: (UIApplicationUtils.shared.convertToDictionary(text: credentialOfferJsonString) ?? [String:Any]()) as NSDictionary? ?? NSDictionary()) as? SearchCertificateCredentialOffer
                                        tempCertModel?.value?.credentialRequestMetadata = SearchCertificateCredentialRequestMetadata.decode(withDictionary: (UIApplicationUtils.shared.convertToDictionary(text:credReqMetadataJSON) ?? [String:Any]()) as NSDictionary? ?? NSDictionary()) as? SearchCertificateCredentialRequestMetadata
                                        tempCertModel?.value?.credentialRequest = SearchCertificateCredentialRequest.decode(withDictionary: (UIApplicationUtils.shared.convertToDictionary(text: credReqJSON) ?? [String:Any]()) as NSDictionary? ?? NSDictionary()) as? SearchCertificateCredentialRequest
                                        tempCertModel?.value?.credDefJson = CredentialDefModel.decode(withDictionary: (UIApplicationUtils.shared.convertToDictionary(text:credDefJson) ?? [String:Any]()) as NSDictionary? ?? NSDictionary()) as? CredentialDefModel
                                        tempCertModel?.value?.state = "request_sent"
                                        let (success2, newId) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: walletHandler, type: .issueCredential, id: certRecordId, certModel: tempCertModel ?? SearchCertificateRecord.init())
                                        let success3 = try await AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler, id: certRecordId, type: .issueCredential, threadId: self.certDetail?.value?.threadID ?? "", state: "request_sent")
                                        let success4 = try await AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler, id: self.inboxId, type: .inbox, threadId: self.certDetail?.value?.threadID ?? "", state: "request_sent")
                                        let (success5, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type:AriesAgentFunctions.cloudAgentConnectionInvitation, searchType: .searchWithId, searchValue: self.reqId ?? "")
                                        if (success5){
                                            let (fetchedSuccessfully, results) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler)
                                            if (fetchedSuccessfully){
                                                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                                                let invitationRecord = (resultsDict?["records"] as? [[String: Any]])?.first
                                                let serviceEndPoint = (invitationRecord?["value"] as? [String: Any])?["serviceEndpoint"] as? String ?? ""
                                                let externalRoutingKey = (invitationRecord?["value"] as? [String: Any])?["routing_key"] as? [String] ?? []
                                                let didcom = self.certDetail?.value?.credentialProposalDict?.type?.split(separator: ";").first ?? ""
                                                
                                                let packTemplate = credReqPackTemplate != nil ?
                                                AriesPackMessageTemplates.requestCredentialWithDataAgreement(didCom: String(didcom), credReq: credReqJSON, threadId: self.certDetail?.value?.threadID ?? "", dataAgreementContext: credReqPackTemplate ?? [:]) : AriesPackMessageTemplates.requestCredential(didCom: String(didcom), credReq: credReqJSON, threadId: self.certDetail?.value?.threadID ?? "")
                                                let (_, packedData) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, label: label ?? "", recipientKey: recipientKey, id: connectionRecordId, didCom: String(didcom), myDid: myDid, myVerKey: verKey, serviceEndPoint: "", routingKey: "", deleteItemId: "", threadId: self.certDetail?.value?.threadID ?? "", credReq: credReqJSON, type: .rawDataBody, isRoutingKeyEnabled: externalRoutingKey.count > 0, externalRoutingKey: externalRoutingKey, rawDict: packTemplate)
                                                let (statuscode, _) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData , url: serviceEndPoint)
                                                if statuscode != 200 {
                                                    UIApplicationUtils.hideLoader()
                                                    return
                                                }
                                                let success1 = try await AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler, id: certRecordId, type: .issueCredential, threadId: self.certDetail?.value?.threadID ?? "", state: "processed")
                                                let success2 = try await AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler, id: self.inboxId, type: .inbox, threadId: self.certDetail?.value?.threadID ?? "", state: "processed")
                                                if success2{
                                                    Task {
                                                        await self.addHistory()
                                                    }
                                                    NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
                                                }
                                                UIApplicationUtils.hideLoader()
                                                self.delegate?.popVC()
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                    } else {
                        UIApplicationUtils.hideLoader()
                        UIApplicationUtils.showErrorSnackbar(message: "No related organisation found. You may have removed the organisation".localizedForSDK())
                    }
                }
            }
        } catch(let error){
            if error.localizedDescription.contains("309") {
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.showErrorSnackbar(message: "Invalid Ledger. You can choose proper ledger from settings".localizedForSDK())
                return
            }
            UIApplicationUtils.hideLoader()
//            UIApplicationUtils.showErrorSnackbar(message: "Invalid Ledger. You can choose proper ledger from settings".localizedForSDK())
            debugPrint(error.localizedDescription)
        }
    }
    
    //Saving copy to wallet in order to show in history screen.
    func addHistory(mode: CertificatePreviewVC_Mode = .other) async{
        do {
            let walletHandler = walletHandle ?? IndyHandle()
            var history = History()
            let attrArray = certDetail?.value?.credentialProposalDict?.credentialProposal?.attributes?.map({ (item) -> IDCardAttributes in
                return IDCardAttributes.init(type: CertAttributesTypes.string, name: item.name ?? "", value: item.value)
            }) ?? certModel?.value?.EBSI_v2?.attributes ?? []
            history.attributes = attrArray
            history.dataAgreementModel = new_dataAgreement ?? dataAgreement
            history.dataAgreementModel?.validated = .not_validate
            history.threadID = certDetail?.value?.threadID
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
            history.date = dateFormat.string(from: Date())
            history.type = HistoryType.issuedCertificate.rawValue
            
            switch mode {
            case .EBSI_V2,.EBSI_PDA1:
                    history.certSubType = certModel?.value?.subType
                case .other:
                    history.certSubType = certModel?.value?.subType
                case .Receipt:
                history.certSubType = CertSubType.Reciept.rawValue
            default:
                history.certSubType = certModel?.value?.subType
            }
            
//            if let schemeSeperated = certDetail?.value?.schemaID?.split(separator: ":"){
//                history.name = "\(schemeSeperated[2])".uppercased()
//            } else if let name = certModel?.value?.type {
//                history.name = name
//            }
            
            var historyName = ""
            if let schemeSeperated = certDetail?.value?.schemaID?.split(separator: ":"){
                historyName = "\(schemeSeperated[2])".uppercased()
            } else if let name = certModel?.value?.type {
                historyName = name
            }
            
            if history.display == nil {
                history.display = CredentialDisplay(name: nil, location: nil, locale: nil, description: nil, cover: nil, logo: nil, backgroundColor: nil, textColor: nil)
            }
            
            history.connectionModel = connectionModel
            history.name = certModel?.value?.searchableText ?? historyName
            history.display?.name = certModel?.value?.searchableText
            history.display?.description = certModel?.value?.description
            history.display?.logo = certModel?.value?.logo
            history.display?.cover = certModel?.value?.cover
            history.display?.backgroundColor = certModel?.value?.backgroundColor
            history.display?.textColor = certModel?.value?.textColor
            history.connectionModel = connectionModel
            let (success, id) = try await WalletRecord.shared.add(connectionRecordId: "", walletHandler: walletHandler, type: .dataHistory, historyModel: history)
            debugPrint("historySaved -- \(success)")
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    func rejectCertificate() {
        let walletHandler = walletHandle ?? IndyHandle()
        UIApplicationUtils.showLoader()
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.certType, id: self.reqId ?? "") {[weak self]
            (deletedSuccessfully, error) in
            AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: self?.inboxId ?? "") { [weak self](deletedSuccessfully, error) in
                print("Cert deleted \(deletedSuccessfully)")
                UIApplicationUtils.hideLoader()
                self?.delegate?.popVC()
                NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
            }
        }
    }
    
    func deleteCredentialWith(id:String,walletRecordId: String?){
        let walletHandler = self.walletHandle ?? 0
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, id: walletRecordId ?? "") {[weak self] (success, error) in
            AriesPoolHelper.shared.deleteCredentialFromWallet(withId: id, walletHandle: walletHandler) {[weak self] (success, error) in
                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                self?.delegate?.popVC()
                NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
            }
        }
    }
}


//EBSI_V2
extension CertificatePreviewViewModel{
    
    func acceptEBSI_V2_Certificate() async {
        let walletHandler = self.walletHandle ?? 0
        do {
            let (success, certRecordId) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: certModel?.value, walletHandler: walletHandler, type: .walletCert)
            await self.addHistory()
            
            if success {
                UIApplicationUtils.showSuccessSnackbar(message: "connect_new_certificate_is_added_to_your_data_wallet".localizedForSDK())
                AriesMobileAgent.shared.delegate?.notificationReceived(message: "New certificate is added to wallet".localizedForSDK())
                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                NotificationCenter.default.post(name: Constants.reloadOrgList, object: nil)
                if let notificationEndPont = certModel?.value?.notificationEndPont, let notificationID = certModel?.value?.notificationID {
                    let accessTokenParts = certModel?.value?.accessToken?.split(separator: ".")
                    var accessTokenData: String? =  nil
                    var refreshTokenData: String? =  nil
                    if accessTokenParts?.count ?? 0 > 1 {
                        let accessTokenBody = "\(accessTokenParts?[1] ?? "")".decodeBase64()
                        let dict = UIApplicationUtils.shared.convertToDictionary(text: String(accessTokenBody ?? "{}")) ?? [:]
                        let exp = dict["exp"] as? Int ?? 0
                        let expiryDate = TimeInterval(exp)
                        let currentTimestamp = Date().timeIntervalSince1970
                        if expiryDate < currentTimestamp {
                            accessTokenData = await NotificationService().refreshAccessToken(refreshToken: certModel?.value?.refreshToken ?? "", endPoint: certModel?.value?.tokenEndPoint ?? "").0
                            refreshTokenData = await NotificationService().refreshAccessToken(refreshToken: certModel?.value?.refreshToken ?? "", endPoint: certModel?.value?.tokenEndPoint ?? "").1
                        } else {
                            accessTokenData = certModel?.value?.accessToken
                            refreshTokenData = certModel?.value?.refreshToken
                        }
                    }
                    isRejectOrAcceptTapped = true
                    certModel?.value?.refreshToken = refreshTokenData
                    certModel?.value?.accessToken = accessTokenData
                    await NotificationService().sendNoticationStatus(endPoint: certModel?.value?.notificationEndPont, event: NotificationStatus.credentialAccepted.rawValue, notificationID: certModel?.value?.notificationID, accessToken: certModel?.value?.accessToken ?? "", refreshToken: certModel?.value?.refreshToken ?? "", tokenEndPoint: certModel?.value?.tokenEndPoint ?? "")
                }
            } else {
                UIApplicationUtils.showErrorSnackbar(message: "Error saving certificate to wallet")
            }
            
            if inboxId != nil { //ie from notification list. For EBSI, we need to delete the list item after adding cert.
                AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: self.inboxId ?? "") { [weak self](deletedSuccessfully, error) in
                    print("Cert deleted \(deletedSuccessfully)")
                    UIApplicationUtils.hideLoader()
                    self?.delegate?.popVC()
                }
            } else {
                UIApplicationUtils.hideLoader()
                self.delegate?.popVC()
            }
            
        } catch {
            UIApplicationUtils.hideLoader()
            UIApplicationUtils.showErrorSnackbar(message: "Error saving certificate to wallet")
            debugPrint(error.localizedDescription)
        }
    }
}
