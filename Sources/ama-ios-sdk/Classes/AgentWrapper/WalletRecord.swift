//
//  WalletRecord.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 23/09/21.
//

import Foundation
import IndyCWrapper

enum AddWalletType: String {
    case mediatorConnection
    case mediatorInvitation
    case registryConnection
    case registryInvitation
    case connection
    case invitation
    case offerCredential
    case presentationRequest
    case walletCert
    case inbox = "inbox"
    case inbox_EBSIOffer
    case dataHistory = "data_history"
    case generic
    case ebsi_connection_natural_person
    case walletUnitAttestation
    case expiredCertificate = "expired_cert"
}

final class WalletRecord {
    static var shared = WalletRecord()
    
    //MARK: ADD
    @available(*, renamed: "add(invitationKey:threadID:label:serviceEndPoint:connectionRecordId:myVerKey:certIssueModel:imageURL:reciepientKey:presentationExchangeModel:walletCert:connectionModel:orgRecordId:walletHandler:type:routingKey:orgID:didComType:historyModel:)")
    
    func add(
        invitationKey: String = "",
        threadID: String = "",
        label: String = "",
        serviceEndPoint: String = "",
        connectionRecordId: String?,
        myVerKey: String? = "",
        certIssueModel: CertificateIssueModel? = nil,
        imageURL:String = "",
        reciepientKey: String? = "",
        presentationExchangeModel: PresentationRequestWalletRecordModel? = PresentationRequestWalletRecordModel.init(),
        walletCert: CustomWalletRecordCertModel? = nil,
        connectionModel: CloudAgentConnectionWalletModel? = CloudAgentConnectionWalletModel(),
        orgRecordId: String? = "",
        walletHandler: IndyHandle,
        type: AddWalletType,
        routingKey: String = "",
        orgID: String? = "",
        didComType: String? = "",
        historyModel: History? = nil,
        EBSI_Model: EBSIConnectionNaturalPersonWalletModel? = nil,
        completion: @escaping (Bool, String, Error?) -> Void) {
            //Success,connectionRecordId,error
            var value = [String : Any?]()
            var recordType = ""
            var tagJson = [String : Any?]()
            let recordId = AgentWrapper.shared.generateRandomId_BaseUID4()
            
            switch type {
            case .mediatorConnection,.connection,.registryConnection:
                value = [
                    "invitation_key": invitationKey,// - recipientkey
                    "created_at": AgentWrapper.shared.getCurrentDateTime(),
                    "updated_at": AgentWrapper.shared.getCurrentDateTime(),//"2020-10-22 12:20:23.188047Z",
                    "initiator": "external",
                    "their_role": nil,
                    "inbound_connection_id": nil,
                    "routing_state": "none",
                    "accept": "manual",
                    "invitation_mode": "once",
                    "alias": nil,
                    "error_msg": nil,
                    "their_label": label, //- label in inv
                    "state": "invitation",
                    "imageURL" : imageURL,
                    "routing_key" : routingKey,
                    "orgID": orgID ?? ""
                ] as [String : Any?]
                
                tagJson = [
                    "invitation_key": invitationKey,
                    "routing_key" : routingKey,
                    "orgID": orgID ?? "",
                    "myVerKey": myVerKey
                ] as [String : Any?]
                
                switch type {
                case .mediatorConnection:
                    recordType = AriesAgentFunctions.mediatorConnection
                case .registryConnection:
                    recordType = AriesAgentFunctions.registryConnection
                default:
                    recordType = AriesAgentFunctions.cloudAgentConnection
                }
            case .mediatorInvitation,.invitation, .registryInvitation:
                value = [
                    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/invitation",
                    "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),// - random
                    "serviceEndpoint": serviceEndPoint ,
                    "imageURL" : imageURL,
                    "recipientKeys": [
                        reciepientKey
                    ],
                    "label": label,
                    "routing_key" : routingKey
                ] as [String : Any]
                
                tagJson = [
                    "connection_id": connectionRecordId,
                    "request_id": connectionRecordId,
                    "invitation_key": invitationKey,
                    "routing_key" : routingKey
                ]
                switch type {
                case .mediatorConnection:
                    recordType = AriesAgentFunctions.mediatorConnectionInvitation
                case .registryConnection:
                    recordType = AriesAgentFunctions.registryConnectionInvitation
                default:
                    recordType = AriesAgentFunctions.cloudAgentConnectionInvitation
                }
            case .offerCredential:
                var attributeDict: [[String: Any]] = []
                for attr in certIssueModel?.credentialPreview?.attributes ?? []{
                    attributeDict.append([
                        "name": attr.name,
                        "value": attr.value
                    ])
                }
                let base64Content = certIssueModel?.offersAttach?.first?.data?.base64?.decodeBase64() ?? ""
                let base64ContentDict = UIApplicationUtils.shared.convertToDictionary(text: base64Content) ?? [String: Any]()
                value = [
                    "thread_id": certIssueModel?.id,
                    "created_at":  AgentWrapper.shared.getCurrentDateTime(),
                    "updated_at":  AgentWrapper.shared.getCurrentDateTime(),
                    "connection_id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                    "credential_proposal_dict": [
                        "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/propose-credential",
                        "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                        "comment": "string",
                        "cred_def_id": base64ContentDict["cred_def_id"],
                        "schema_id": base64ContentDict["schema_id"],
                        "credential_proposal": [
                            "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/credential-preview",
                            "attributes": attributeDict
                        ]
                    ],
                    "credential_offer_dict": nil,
                    "credential_offer": base64ContentDict,
                    "credential_request": nil,
                    "credential_request_metadata": nil,
                    "error_msg": nil,
                    "auto_offer": false,
                    "auto_issue": false,
                    "auto_remove": true,
                    "raw_credential": nil,
                    "credential": nil,
                    "parent_thread_id": nil,
                    "initiator": "external",
                    "credential_definition_id": base64ContentDict["cred_def_id"],
                    "schema_id": base64ContentDict["schema_id"],
                    "credential_id": nil,
                    "revoc_reg_id": nil,
                    "revocation_id": nil,
                    "role": "holder",
                    "state": "offer_received",
                    "trace": false
                ]
                
                tagJson = [
                    "thread_id" : threadID,
                    "request_id": connectionRecordId,
                    "state": "offer_received"
                ]
                recordType = AriesAgentFunctions.certType
            case .presentationRequest:
                value = presentationExchangeModel?.dictionary ?? [String:Any]()
                tagJson = ["thread_id": presentationExchangeModel?.threadID]
                recordType = AriesAgentFunctions.presentationExchange
            case .walletCert:
                value = walletCert?.dictionary ?? [String:Any]()
                tagJson = [
                    "connection_id": walletCert?.connectionInfo?.value?.requestID ?? "",
                    "request_id": walletCert?.referent?.referent ?? recordId,
                    "invitation_key": walletCert?.connectionInfo?.value?.invitationKey ?? "",
                    "type": walletCert?.type ?? "",
                    "sub_type": walletCert?.subType ?? ""
                ]
                recordType = AriesAgentFunctions.walletCertificates
            case .inbox:
                var attributes: [SearchCertificateAttribute] = []
                for attr in certIssueModel?.credentialPreview?.attributes ?? [] {
                    attributes.append(
                        SearchCertificateAttribute.init(name:  attr.name, value: attr.value)
                    )
                }
                let base64Content = certIssueModel?.offersAttach?.first?.data?.base64?.decodeBase64() ?? ""
                let base64ContentDict = UIApplicationUtils.shared.convertToDictionary(text: base64Content) ?? [String: Any]()
                let searchPresentationModel = SearchPresentationExchangeValueModel.init(type: didComType, id: orgRecordId, value: presentationExchangeModel)
                let cred_def_id = base64ContentDict["cred_def_id"] as? String ?? ""
                let schema_id =  base64ContentDict["schema_id"] as? String ?? ""
                let searchCertificateCredentialProposalDict =  SearchCertificateCredentialProposalDict.init(
                    type: "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/propose-credential",
                    id: AgentWrapper.shared.generateRandomId_BaseUID4(),
                    comment: "string",
                    credDefID: cred_def_id,
                    schemaID: schema_id,
                    credentialProposal:SearchCertificateCredentialProposal.init(type:"did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/credential-preview", attributes: attributes))
                let searchCertificateRecord = SearchCertificateRecord.init()
                searchCertificateRecord.type =  didComType ?? ""
                searchCertificateRecord.id =  orgRecordId ?? ""
                searchCertificateRecord.tags = SearchCertificateTags.init()
                searchCertificateRecord.value = SearchCertificateValue.init(
                    threadID: certIssueModel?.id,
                    createdAt: AgentWrapper.shared.getCurrentDateTime(),
                    updatedAt: AgentWrapper.shared.getCurrentDateTime(),
                    connectionID: AgentWrapper.shared.generateRandomId_BaseUID4(),
                    credentialProposalDict: searchCertificateCredentialProposalDict,
                    credentialOfferDict: nil,
                    credentialOffer: SearchCertificateCredentialOffer.decode(withDictionary: base64ContentDict as NSDictionary? ?? NSDictionary()) as? SearchCertificateCredentialOffer,
                    credentialRequest: nil,
                    credentialRequestMetadata: nil,
                    errorMsg: nil,
                    credDefJson: nil,
                    rawCredential: nil,
                    credential: nil,
                    parentThreadID: nil,
                    credentialDefinitionID: cred_def_id,
                    schemaID: schema_id,
                    credentialID: nil,
                    revocRegID: nil,
                    revocationID: nil,
                    role: "holder",
                    state: "offer_received")
                let model = InboxModelRecordValue.init(connectionModel: connectionModel, presentationRequest: searchPresentationModel, offerCredential: searchCertificateRecord, dataAgreement: certIssueModel?.dataAgreement ?? presentationExchangeModel?.dataAgreement, type: presentationExchangeModel?.threadID != nil ? InboxType.certRequest.rawValue : InboxType.certOffer.rawValue, orgRecordId: orgRecordId ?? "")
                value = model.dictionary ?? [String:Any]()
                tagJson = [
                    "type" : presentationExchangeModel?.threadID != nil ? InboxType.certRequest.rawValue : InboxType.certOffer.rawValue,
                    "thread_id": presentationExchangeModel?.threadID ?? threadID,
                    "request_id": connectionRecordId,
                    "state": "offer_received"
                ]
                recordType = AriesAgentFunctions.inbox
                
            case .dataHistory:
                value = [
                    "@type": AriesAgentFunctions.history,
                    "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),// - random
                    "history": historyModel?.dictionary ?? [String:Any](),
                ] as [String : Any]
                let tagModel = HistoryWalletTags.init(type: historyModel?.type, organisationID: historyModel?.connectionModel?.value?.orgDetails?.orgId ?? "", threadID: historyModel?.threadID ?? "", instanceID: historyModel?.dataAgreementModel?.message?.body?.id ?? "", isThirdPartyDataShare: ((historyModel?.dataAgreementModel?.message?.body?.dataPolicy?.thirdPartyDataSharing ?? false) ? "True" : "False"))
                tagJson = tagModel.dictionary ?? [:]
                recordType = AriesAgentFunctions.history
            case .generic:
                value = walletCert?.dictionary ?? [String:Any]()
                tagJson = [
                    "connection_id": walletCert?.connectionInfo?.value?.requestID ?? "",
                    "request_id": walletCert?.referent?.referent ?? recordId,
                    "invitation_key": walletCert?.connectionInfo?.value?.invitationKey ?? "",
                    "type": walletCert?.type ?? "",
                    "sub_type": walletCert?.subType ?? ""
                ]
                recordType = AriesAgentFunctions.walletCertificates
            case .ebsi_connection_natural_person:
                value = EBSI_Model?.dictionary ?? [String:Any]()
                tagJson = [
                    "connection_id": walletCert?.connectionInfo?.value?.requestID ?? "",
                    "request_id": walletCert?.referent?.referent ?? recordId,
                    "invitation_key": walletCert?.connectionInfo?.value?.invitationKey ?? "",
                    "type": walletCert?.type ?? "",
                    "sub_type": walletCert?.subType ?? ""
                ]
                recordType = AriesAgentFunctions.walletCertificates
            case .inbox_EBSIOffer:
                let model = InboxModelRecordValue.init(connectionModel: connectionModel, presentationRequest: nil, offerCredential: nil, dataAgreement: nil, type: InboxType.EBSIOffer.rawValue, orgRecordId: "", walletRecordCertModel: walletCert)
                value = model.dictionary ?? [String:Any]()
                tagJson = [
                    "type" : InboxType.EBSIOffer.rawValue,
                    "thread_id": "",
                    "request_id": connectionRecordId,
                    "state": "offer_received"
                ]
                recordType = AriesAgentFunctions.inbox
            case .expiredCertificate:
                value = walletCert?.dictionary ?? [String:Any]()
                tagJson = [
                    "connection_id": walletCert?.connectionInfo?.value?.requestID ?? "",
                    "request_id": walletCert?.referent?.referent ?? recordId,
                    "invitation_key": walletCert?.connectionInfo?.value?.invitationKey ?? "",
                    "type": walletCert?.type ?? "",
                    "sub_type": walletCert?.subType ?? ""
                ]
                recordType = AriesAgentFunctions.expiredCertificate
            case .walletUnitAttestation:
                value = walletCert?.dictionary ?? [String:Any]()
                recordType = AriesAgentFunctions.walletUnitAttestation
            }
            
            AgentWrapper.shared.addWalletRecord(inWallet: walletHandler, type: recordType, id: recordId , value: UIApplicationUtils.shared.getJsonString(for: value), tagsJson: UIApplicationUtils.shared.getJsonString(for: tagJson)) { (error) in
                if(error?._code == 0) {
                    debugPrint("connection record saved")
                    completion(true,recordId ,error)
                } else {
                    completion(false,recordId ,error)
                }
            }
        }
    
    func add(
        invitationKey: String = "",
        threadID: String = "",
        label: String = "",
        serviceEndPoint: String = "",
        connectionRecordId: String?,
        myVerKey: String? = "",
        certIssueModel: CertificateIssueModel? = nil,
        imageURL:String = "",
        reciepientKey: String? = "",
        presentationExchangeModel: PresentationRequestWalletRecordModel? = PresentationRequestWalletRecordModel.init(),
        walletCert: CustomWalletRecordCertModel? = nil,
        connectionModel: CloudAgentConnectionWalletModel? = CloudAgentConnectionWalletModel(),
        orgRecordId: String? = "",
        walletHandler: IndyHandle,
        type: AddWalletType,
        routingKey: String = "",
        orgID: String? = "",
        didComType: String? = "",
        EBSI_Model: EBSIConnectionNaturalPersonWalletModel? = nil,
        historyModel: History? = nil) async throws -> (Bool, String) {
            return try await withCheckedThrowingContinuation { continuation in
                add(invitationKey: invitationKey, threadID: threadID, label: label, serviceEndPoint: serviceEndPoint, connectionRecordId: connectionRecordId, myVerKey: myVerKey, certIssueModel: certIssueModel, imageURL: imageURL, reciepientKey: reciepientKey, presentationExchangeModel: presentationExchangeModel, walletCert: walletCert, connectionModel: connectionModel, orgRecordId: orgRecordId, walletHandler: walletHandler, type: type, routingKey: routingKey, orgID: orgID, didComType: didComType, historyModel: historyModel) { result1, result2, error in
                    if let error = error,error._code != 0 {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: (result1, result2))
                }
            }
        }
    
    //MARK: Get
    @available(*, renamed: "get(walletHandler:connectionRecordId:type:)")
    func get(walletHandler: IndyHandle, connectionRecordId: String,type: String, completion: @escaping (Bool,String?, Error?) -> Void) {
        let optionJson = [
            "retrieveType": false,
            "retrieveValue": true,
            "retrieveTags": false
        ] as [String : Any?]
        
        AgentWrapper.shared.getWalletRecord(walletHandle: walletHandler, type: type, id: connectionRecordId, optionsJson: UIApplicationUtils.shared.getJsonString(for: optionJson)) { (error, response) in
            //            debugPrint("get wallet records -- \(response)")
            if error?._code != 0 {
                completion(false,response, error)
                return
            }
            completion(true,response, error)
        }
    }
    
    func get(walletHandler: IndyHandle, connectionRecordId: String,type: String) async throws -> (Bool,String?) {
        return try await withCheckedThrowingContinuation { continuation in
            get(walletHandler: walletHandler, connectionRecordId: connectionRecordId, type: type) { result,response, error  in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result,response))
            }
        }
    }
    
    //MARK: Update
    @available(*, renamed: "update(walletHandler:recordId:type:value:)")
    func update(walletHandler: IndyHandle, recordId: String,type: String,value: String, completion: @escaping (Bool, Error?) -> Void) {
        AgentWrapper.shared.updateWalletRecord(inWallet: walletHandler, type: type, id: recordId, value: value) { error in
            if error?._code != 0 {
                completion(false, error)
                return
            }
            completion(true, error)
        }
    }
    
    func update(walletHandler: IndyHandle, recordId: String,type: String,value: String) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            update(walletHandler: walletHandler, recordId: recordId, type: type, value: value) { result, error in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }
    
    //MARK: Fetch All Certificates/Credentials
    @available(*, renamed: "fetchAllCert()")
    func fetchAllCert(completion: @escaping((Search_CustomWalletRecordCertModel?) -> Void)){
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates,searchType: .withoutQuery) {[weak self] (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [weak self](fetched, response, error) in
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let certSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                completion(certSearchModel)
            }
        }
    }
    
    func fetchAllCert() async -> Search_CustomWalletRecordCertModel? {
        return await withCheckedContinuation { continuation in
            fetchAllCert() { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    //MARK: Fetch Notification
    @available(*, renamed: "fetchNotifications()")
    func fetchNotifications(completion: @escaping (SearchInboxModel?) -> Void) {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, searchType:.withoutQuery) { [weak self](success, prsntnExchngSearchWallet, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: prsntnExchngSearchWallet, count: 100) { [weak self] (success, response, error) in
                let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: response)
                let searchInboxModel = SearchInboxModel.decode(withDictionary: recordResponse ?? [String:Any]()) as? SearchInboxModel
                completion(searchInboxModel)
            }
        }
    }
    
    func fetchNotifications() async -> SearchInboxModel? {
        return await withCheckedContinuation { continuation in
            fetchNotifications() { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func getCertFromThreadID(threadId: String) async -> SearchItems_CustomWalletRecordCertModel?  {
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        do{
            let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, searchType: .searchWithThreadId, searchValue: threadId)
            let (_, certRecords) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
          
                    let certCecordResponse = UIApplicationUtils.shared.convertToDictionary(text: certRecords)
                    let certSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: certCecordResponse as? NSDictionary ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                    let tempCert = certSearchModel?.records?.first
                    return tempCert
        } catch{
            debugPrint(error.localizedDescription)
            return nil
        }
       
    }
    
//    //MARK: ADD EBSI Credential
//    func addEBSI_V2_Credential( walletHandler: IndyHandle, attributes: [IDCardAttributes]) async -> (Bool){
//        let customWalletModel = CustomWalletRecordCertModel.init()
//        customWalletModel.EBSI_v2 = EBSI_V2_WalletModel.init(id: "", attributes: attributes)
//        customWalletModel.referent = nil
//        customWalletModel.schemaID = nil
//        customWalletModel.certInfo = nil
//        customWalletModel.connectionInfo = nil
//        customWalletModel.type = CertType.idCards.rawValue
//        customWalletModel.subType = CertType.EBSI.rawValue
//        customWalletModel.searchableText = CertType.EBSI.rawValue
//
//        let (success,_) = try? await
//        add(connectionRecordId: "", walletCert: customWalletModel, walletHandler: walletHandler, type: .walletCert)
//        return success
//    }
    
    //MARK: ADD EBSI_Connection_Natural_Person
    func addToWallet_EBSI_Connection_Natural_Person(connectionRecordId: String, walletHandler: IndyHandle, type: AddWalletType, model: EBSIConnectionNaturalPersonWalletModel) async throws -> (Bool, String){
        return try await withCheckedThrowingContinuation { continuation in
            add(connectionRecordId: connectionRecordId, walletHandler: walletHandler, type: .ebsi_connection_natural_person, EBSI_Model: model) { result1, result2, error in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
            
        }
    }
    
    func addPullDataNotificationRecord(model: PullDataNotificationModel?) async -> Bool {
        do{
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            let history = await WalletFetchUtils.getShareHistoryFromInstanceId(id: model?.daInstanceID ?? "")
            guard var historyModel = history?.value?.history else {return false}
            historyModel.pullDataNotification = model
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            historyModel.date = dateFormat.string(from: Date())
            historyModel.type = HistoryType.exchange.rawValue
            let (success, _) = try await WalletRecord.shared.add(connectionRecordId: "", walletHandler: walletHandler, type: .dataHistory, historyModel: historyModel)
            return success
        } catch{
            debugPrint(error.localizedDescription)
            return false
        }
    }
    
    func addReceiptRecord(model: ReceiptModel?) async -> Bool {
        do{
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            let history = await WalletFetchUtils.getShareHistoryFromInstanceId(id: model?.instanceID ?? "")
            guard var historyModel = history?.value?.history else {return false}
            historyModel.dataAgreementModel?.receipt = model
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            historyModel.date = dateFormat.string(from: Date())
            historyModel.type = HistoryType.exchange.rawValue
            let success = try await self.update(walletHandler: walletHandler, recordId: history?.id ?? "", type: AriesAgentFunctions.history, value:  UIApplicationUtils.shared.getJsonString(for:history?.value?.dictionary ?? [:]))
            return success
        } catch{
            debugPrint(error.localizedDescription)
            return false
        }
    }
}
