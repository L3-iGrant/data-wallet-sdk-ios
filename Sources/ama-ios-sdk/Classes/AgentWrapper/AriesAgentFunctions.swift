//
//  AriesAgentHelper.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 16/11/20.
//

import Foundation
import UIKit
import IndyCWrapper

enum UpdateWalletType {
    case initial
    case updateTheirDid
    case inboxCreated
    case initialCloudAgent
    case updateCloudAgentRecord
    case trusted
    case credentialExchange
    case issueCredential
    case initialRegistry
    case updateRegistry
}

enum UpdateWalletTagType {
    case initial
    case updateTheirDid
    case initialCloudAgent
    case updateCloudAgentTag
    case mediatorActive
    case cloudAgentActive
    case issueCredential
    case credentialExchange
    case inbox
    case initialRegistry
    case updateRegistry
}

enum PackMessageType {
    case initialMediator
    case initialCloudAgent
    case initialRegistry
    case pollingMediator
    case addRoute
    case createInbox
    case trustPing
    case deleteInboxItem
    case credentialAck
    case proposePresentation
    case queryIgrantAgent
    case getIgrantOrgDetail
    case getIgrantCertTypeResponse
    case presentation
    case informDuplicateConnection
    case fetchDataAgreement
    case fetchDataAgreement_issue_cert
    case createMyDataDid
    case rawDataBody
}

enum WalletSearch {
    case withoutQuery
    case searchWithInvitationKey
    case searchWithId
    case searchtWithDidKey
    case searchWithThreadId
    case searchWithTheirDid
    case searchWithReciepientKey
    case offerReceived
    case getActiveConnections
    case checkExistingConnection
    case inbox_offerReceived
    case selfAttestedCert
    case oldSelfAttestedCert
    case searchWithOrgId
    case searchWithMyVerKey
    case getAllInboxOfferReceived
    case passport
    case aadhar
    case idCards
    case PKPass
    case EBSI
    case history_instanceID
    case history_thirdPartyShare
    //    case dataSharedHistory
}

enum DidKeyTypes: String{
    case mediatorDidKey = "mediator_didKey"
    case cloudAgentDidKey = "did_Key"
    case registryDidKey = "registry_didKey"
}

enum DidDocTypes: String{
    case mediatorDidDoc = "mediator_didDoc"
    case registryDidDoc = "registry_didDoc"
    case cloudAgentDidDoc = "did_doc"
}


class AriesAgentFunctions {
    static var shared = AriesAgentFunctions()
    
    private init(){}
    
    static var mediatorConnection = "mediator_connection"
    static var mediatorConnectionInvitation = "mediator_connection_invitation"
    static var registryConnection = "registry_connection"
    static var registryConnectionInvitation = "registry_connection_invitation"
    static var cloudAgentConnection = "connection"
    static var cloudAgentConnectionInvitation = "invitation"
    static var certType = "credential_exchange_v10"
    static var presentationExchange = "presentationexchange_v10"
    static var walletCertificates = "wallet_cert"
    static var inbox = "inbox"
    static var history = "data_history"
    static var walletUnitAttestation = "walletUnitAttestation"
    static var expiredCertificate = "expired_cert"
    
    @available(*, renamed: "createAndStoreId(walletHandler:)")
    func createAndStoreId(walletHandler: IndyHandle,completion: @escaping(Bool,String?,String?,Error?) -> Void){ //Success,did,verkey,error
        AgentWrapper.shared.createAndStoreDid(did: "{}", walletHandle: walletHandler) { (error, did, verKey) in
            debugPrint("Create and store did")
            if(error?._code != 0){
                completion(false,did,verKey,error)
                return;
            }
            completion(true,did,verKey,error)
        }
    }
    
    func createAndStoreId(walletHandler: IndyHandle) async throws -> (Bool, String, String) {
        return try await withCheckedThrowingContinuation { continuation in
            createAndStoreId(walletHandler: walletHandler) { result1, result2, result3, error in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result2 = result2 else {
                    fatalError("Expected non-nil result 'result2' for nil error")
                }
                guard let result3 = result3 else {
                    fatalError("Expected non-nil result 'result3' for nil error")
                }
                continuation.resume(returning: (result1, result2, result3))
            }
        }
    }
    
    
    @available(*, renamed: "setMetadata(walletHandler:myDid:verKey:)")
    func setMetadata(walletHandler: IndyHandle, myDid: String,verKey: String, completion: @escaping (Bool) -> Void){
        let metadata = [
            "did" : myDid,
            "verkey" : verKey,
            "tempVerkey" : nil,
            "metadata" : nil
        ] as [String : Any?]
        
        AgentWrapper.shared.setMetadata(metadata: UIApplicationUtils.shared.getJsonString(for: metadata), forDid: myDid, walletHandle: walletHandler) { (error) in
            debugPrint("set meta")
            if(error?._code != 0){
                completion(false)
                return;
            }
            completion(true)
        }
    }
    
    func setMetadata(walletHandler: IndyHandle, myDid: String,verKey: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            setMetadata(walletHandler: walletHandler, myDid: myDid, verKey: verKey) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    func openWalletSearch(walletHandler: IndyHandle,type:String, query: [String: Any], searchValue: String = "", completion: @escaping(Bool,IndyHandle,Error?) -> Void) {
        let optionDict = [
            "retrieveRecords": true,
            "retrieveTotalCount": true,
            "retrieveType": false,
            "retrieveValue": true,
            "retrieveTags": true
        ]
        
        AgentWrapper.shared.openWalletSearch(inWallet: walletHandler, type: type, queryJson: UIApplicationUtils.shared.getJsonString(for: query), optionsJson: UIApplicationUtils.shared.getJsonString(for: optionDict)) { (error, indyHandle) in
            debugPrint("Open wallet search -- \(type)")
            if(error?._code != 0){
                completion(false,indyHandle,error)
                return;
            }
            completion(true,indyHandle,error)
        }
    }
    
    
    @available(*, renamed: "updateWalletRecord(walletHandler:recipientKey:label:type:id:theirDid:myDid:imageURL:invitiationKey:isIgrantAgent:certModel:routingKey:presentationReqModel:orgDetails:orgID:)")
    func updateWalletRecord(walletHandler: IndyHandle,recipientKey: String = "", label: String = "",type: UpdateWalletType, id: String,theirDid: String = "", myDid: String = "",imageURL: String = "", invitiationKey: String? = "",isIgrantAgent: Bool? = false,certModel: SearchCertificateRecord = SearchCertificateRecord.init(),routingKey: [String]? = [], presentationReqModel: PresentationRequestWalletRecordModel? = nil,orgDetails:OrganisationInfoModel? = nil, orgID: String? = "",isThirdPartyShareSupported: String? = "", completion: @escaping(Bool,String,Error?) -> Void) {
        //let updateAndWalletId = AgentWrapper.shared.generateRandomId_BaseUID4()
        var updateWalletRecord = [String : Any?]()
        var walletType = AriesAgentFunctions.mediatorConnection
        
        switch type {
        case .initial, .initialRegistry:
            updateWalletRecord = [
                "request_id": id,
                "my_did": myDid,
                "invitation_key": recipientKey ,
                "routing_key" : routingKey,
                "created_at":  AgentWrapper.shared.getCurrentDateTime(),
                "updated_at":  AgentWrapper.shared.getCurrentDateTime(),
                "initiator": "external",
                "their_role": nil,
                "inbound_connection_id": nil,
                "routing_state": "none",
                "accept": "manual",
                "invitation_mode": "once",
                "alias": nil,
                "error_msg": nil,
                "their_label": label ,
                "state": "request"
            ] as [String : Any?]
            if type == .initialRegistry{
                walletType = AriesAgentFunctions.registryConnection
            }
        case .updateTheirDid, .updateRegistry:
            updateWalletRecord = [
                "their_did": "\(theirDid)",
                "request_id": id,
                "my_did": myDid,
                "invitation_key": recipientKey,
                "routing_key" : routingKey,
                "created_at":  AgentWrapper.shared.getCurrentDateTime(),
                "updated_at":  AgentWrapper.shared.getCurrentDateTime(),
                "initiator": "external",
                "their_role": nil,
                "inbound_connection_id": nil,
                "routing_state": "none",
                "accept": "manual",
                "invitation_mode": "once",
                "alias": nil,
                "error_msg": nil,
                "their_label": label ,
                "state": "response",
            ] as [String : Any?]
            if type == .updateRegistry{
                walletType = AriesAgentFunctions.registryConnection
            }
        case .inboxCreated:
            updateWalletRecord = [
                "their_did": "\(theirDid)",
                "request_id": id,
                "my_did": myDid,
                "invitation_key": invitiationKey,
                "routing_key" : routingKey,
                "reciepientKey" : recipientKey,
                "created_at":  AgentWrapper.shared.getCurrentDateTime(),
                "updated_at":  AgentWrapper.shared.getCurrentDateTime(),
                "initiator": "external",
                "their_role": nil,
                "inbound_connection_id": nil,
                "routing_state": "none",
                "accept": "manual",
                "invitation_mode": "once",
                "alias": nil,
                "error_msg": nil,
                "their_label": label ,
                "state": "active",
                "inbox_id": "",
                "inbox_Key": "",
            ] as [String : Any?]
            
        case .updateCloudAgentRecord:
            updateWalletRecord = [
                "their_did": "\(theirDid)",
                "request_id": id,
                "my_did": myDid,
                "invitation_key": invitiationKey,
                "reciepientKey" : recipientKey,
                "routing_key" : routingKey,
                "created_at":  AgentWrapper.shared.getCurrentDateTime(),
                "updated_at":  AgentWrapper.shared.getCurrentDateTime(),
                "initiator": "external",
                "their_role": nil,
                "inbound_connection_id": nil,
                "routing_state": "none",
                "accept": "manual",
                "invitation_mode": "once",
                "alias": nil,
                "error_msg": nil,
                "their_label": label ,
                "state": "response",
                "isIgrantAgent": (isIgrantAgent ?? false) ? "1" : "0",
                "imageURL" : imageURL,
                "orgID": orgID ?? "",
                "isThirdPartyShareSupported": isThirdPartyShareSupported ?? "false"
            ] as [String : Any?]
            walletType = "connection"
        case .initialCloudAgent:
            updateWalletRecord = [
                "request_id": id,
                "my_did": myDid,
                "invitation_key": invitiationKey ,
                "reciepientKey" : recipientKey,
                "routing_key" : routingKey,
                "created_at":  AgentWrapper.shared.getCurrentDateTime(),
                "updated_at":  AgentWrapper.shared.getCurrentDateTime(),
                "initiator": "external",
                "their_role": nil,
                "inbound_connection_id": nil,
                "routing_state": "none",
                "accept": "manual",
                "invitation_mode": "once",
                "alias": nil,
                "error_msg": nil,
                "their_label": label ,
                "state": "request",
                "isIgrantAgent": (isIgrantAgent ?? false) ? "1" : "0",
                "imageURL" : imageURL,
                "orgID": orgID ?? "",
                "isThirdPartyShareSupported": isThirdPartyShareSupported ?? "false"
            ] as [String : Any?]
            walletType = "connection"
        case .trusted:
            updateWalletRecord = [
                "their_did": "\(theirDid)",
                "request_id": id,
                "my_did": myDid,
                "invitation_key": invitiationKey,
                "routing_key" : routingKey,
                "reciepientKey" : recipientKey,
                "created_at":  AgentWrapper.shared.getCurrentDateTime(),
                "updated_at":  AgentWrapper.shared.getCurrentDateTime(),
                "initiator": "external",
                "their_role": nil,
                "inbound_connection_id": nil,
                "routing_state": "none",
                "accept": "manual",
                "invitation_mode": "once",
                "alias": nil,
                "error_msg": nil,
                "their_label": label ,
                "state": "active",
                "inbox_id": "",
                "inbox_Key": "",
                "isIgrantAgent": (isIgrantAgent ?? false) ? "1" : "0",
                "imageURL" : imageURL,
                "orgDetails" : orgDetails?.dictionary ?? [String:Any](),
                "orgID": orgID ?? "",
                "isThirdPartyShareSupported": isThirdPartyShareSupported ?? "false"
            ] as [String : Any?]
            walletType = "connection"
        case .credentialExchange:
            let tempCertModel = presentationReqModel ?? PresentationRequestWalletRecordModel.init()
            updateWalletRecord = tempCertModel.dictionary ?? [String:Any]()
            walletType = AriesAgentFunctions.presentationExchange
        case .issueCredential:
            let tempCertModel = certModel.value ?? SearchCertificateValue.init()
            updateWalletRecord = tempCertModel.dictionary ?? [String:Any]()
            walletType = AriesAgentFunctions.certType
        }
        
        AgentWrapper.shared.updateWalletRecord(inWallet: walletHandler, type: walletType, id: id, value: UIApplicationUtils.shared.getJsonString(for: updateWalletRecord)) { (error) in
            debugPrint("update wallet records")
            if(error?._code != 0){
                completion(false,id,error)
                return;
            }
            completion(true,id,error)
        }
    }
    
    func updateConnectionModel(walletHandler: IndyHandle, id: String, connectionModel: CloudAgentConnectionWalletModel?, completion: @escaping(Bool,String,Error?) -> Void) {
        let tempCertModel = connectionModel?.value ?? CloudAgentConnectionWalletModel().value
        let updateWalletRecord = tempCertModel.dictionary ?? [String:Any]()
        let walletType = AriesAgentFunctions.cloudAgentConnection
        AgentWrapper.shared.updateWalletRecord(inWallet: walletHandler, type: walletType, id: id, value: UIApplicationUtils.shared.getJsonString(for: updateWalletRecord)) { (error) in
            debugPrint("update wallet records")
            if(error?._code != 0){
                completion(false,id,error)
                return;
            }
            completion(true,id,error)
        }
    }
    
    func updateWalletRecord(walletHandler: IndyHandle,recipientKey: String = "", label: String = "",type: UpdateWalletType, id: String,theirDid: String = "", myDid: String = "",imageURL: String = "", invitiationKey: String? = "",isIgrantAgent: Bool? = false,certModel: SearchCertificateRecord = SearchCertificateRecord.init(),routingKey: [String]? = [], presentationReqModel: PresentationRequestWalletRecordModel? = nil,orgDetails:OrganisationInfoModel? = nil, orgID: String? = "") async throws -> (Bool, String) {
        return try await withCheckedThrowingContinuation { continuation in
            updateWalletRecord(walletHandler: walletHandler, recipientKey: recipientKey, label: label, type: type, id: id, theirDid: theirDid, myDid: myDid, imageURL: imageURL, invitiationKey: invitiationKey, isIgrantAgent: isIgrantAgent, certModel: certModel, routingKey: routingKey, presentationReqModel: presentationReqModel, orgDetails: orgDetails, orgID: orgID) { result1, result2, error in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    @available(*, renamed: "updateWalletTags(walletHandler:id:myDid:theirDid:recipientKey:serviceEndPoint:invitiationKey:type:threadId:isIgrantAgent:state:routingKey:orgID:myVerKey:)")
    func updateWalletTags(walletHandler: IndyHandle,id: String?, myDid: String? = "", theirDid: String? = "",recipientKey: String? = "",
                          serviceEndPoint: String? = "",invitiationKey: String? = "",type: UpdateWalletTagType,threadId: String? = "",isIgrantAgent: Bool? = false, state: String? = "",routingKey: String? = "",orgID: String? = "",myVerKey:String? = "", completion: @escaping(Bool,Error?) -> Void){
        var tagsJson = [String:Any?]()
        var walletType = AriesAgentFunctions.mediatorConnection
        
        switch type {
        case .initial, .initialRegistry:
            tagsJson = [
                "request_id": id ?? "",
                "my_did": myDid ?? "",
                "invitation_key": invitiationKey ?? "",
                "routing_key" : routingKey,
                "orgID": orgID ?? ""
            ]
            if type == .initialRegistry{
                walletType = AriesAgentFunctions.registryConnection
            }
        case .updateTheirDid, .updateRegistry:
            tagsJson = [
                "their_did": "\(theirDid ?? "")",
                "request_id": id ?? "",
                "my_did": myDid ?? "",
                "invitation_key": invitiationKey ?? "",
                "reciepientKey": recipientKey ?? "",
                "routing_key" : routingKey,
                "orgID": orgID ?? ""
            ]
            if type == .updateRegistry{
                walletType = AriesAgentFunctions.registryConnection
            }
        case .updateCloudAgentTag:
            tagsJson = [
                "their_did": "\(theirDid ?? "")",
                "request_id": id ?? "",
                "my_did": myDid ?? "",
                "invitation_key": invitiationKey ?? "",
                "reciepientKey": recipientKey ?? "",
                "routing_key" : routingKey,
                "orgID": orgID ?? "",
                "myVerKey": myVerKey
            ]
            walletType = AriesAgentFunctions.cloudAgentConnection
        case .initialCloudAgent:
            tagsJson = [
                "request_id": id ?? "",
                "my_did": myDid ?? "",
                "invitation_key": invitiationKey ?? "",
                "routing_key" : routingKey,
                "serviceEndPoint": serviceEndPoint ?? "",
                "reciepientKey" : recipientKey ?? "",
                "isIgrantAgent": (isIgrantAgent ?? false) ? "1" : "0",
                "state": "request",
                "orgID": orgID ?? "",
                "myVerKey": myVerKey
            ]
            walletType = AriesAgentFunctions.cloudAgentConnection
        case .mediatorActive:
            tagsJson = [
                "their_did": "\(theirDid ?? "")",
                "request_id": id ?? "",
                "my_did": myDid ?? "",
                "invitation_key": invitiationKey ?? "",
                "reciepientKey" : recipientKey ?? "",
                "state": "active",
            ]
        case .cloudAgentActive:
            tagsJson = [
                "their_did": "\(theirDid ?? "")",
                "request_id": id ?? "",
                "my_did": myDid ?? "",
                "invitation_key": invitiationKey ?? "",
                "reciepientKey" : recipientKey ?? "",
                "state": "active",
                "routing_key" : routingKey,
                "isIgrantAgent": (isIgrantAgent ?? false) ? "1" : "0",
                "orgID": orgID ?? "",
                "myVerKey": myVerKey
            ]
            walletType = AriesAgentFunctions.cloudAgentConnection
        case .issueCredential:
            tagsJson = [
                "thread_id": threadId ?? "",
                "request_id": id ?? "",
                "state": state
            ]
            walletType = AriesAgentFunctions.certType
        case .inbox:
            tagsJson = [
                "thread_id": threadId ?? "",
                "request_id": id ?? "",
                "state": state,
                "type" : InboxType.certOffer.rawValue
            ]
            walletType = AriesAgentFunctions.inbox
        case .credentialExchange:
            tagsJson = [
                "thread_id": threadId ?? "",
                "request_id": id ?? "",
                "state": state
            ]
            walletType = AriesAgentFunctions.presentationExchange
        }
        AgentWrapper.shared.updateWalletTags(inWallet: walletHandler, type: walletType, id: id, tagsJson: UIApplicationUtils.shared.getJsonString(for: tagsJson)) { (error) in
            debugPrint("Update wallet tags")
            if(error?._code != 0){
                completion(false,error)
                return;
            }
            completion(true,error)
        }
    }
    
    func updateWalletTags(walletHandler: IndyHandle,id: String?, myDid: String? = "", theirDid: String? = "",recipientKey: String? = "",
                          serviceEndPoint: String? = "",invitiationKey: String? = "",type: UpdateWalletTagType,threadId: String? = "",isIgrantAgent: Bool? = false, state: String? = "",routingKey: String? = "",orgID: String? = "",myVerKey:String? = "") async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            updateWalletTags(walletHandler: walletHandler, id: id, myDid: myDid, theirDid: theirDid, recipientKey: recipientKey, serviceEndPoint: serviceEndPoint, invitiationKey: invitiationKey, type: type, threadId: threadId, isIgrantAgent: isIgrantAgent, state: state, routingKey: routingKey, orgID: orgID, myVerKey: myVerKey) { result, error in
                if let error = error,error._code != 0 {
                    continuation.resume(returning: false)
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }
    
    
    @available(*, renamed: "getMyDidWithMeta(walletHandler:myDid:)")
    func getMyDidWithMeta(walletHandler: IndyHandle, myDid: String,completion: @escaping (Bool,String?, Error?) -> Void){
        AgentWrapper.shared.getMyDidWithMeta(did: myDid, walletHandle: walletHandler) { (error, response) in
            debugPrint("get Did meta --- \(response ?? "")")
            if(error?._code != 0){
                completion(false,response,error)
                return;
            }
            completion(true,response,error)
        }
    }
    
    func getMyDidWithMeta(walletHandler: IndyHandle, myDid: String) async throws -> (Bool, String) {
        return try await withCheckedThrowingContinuation { continuation in
            getMyDidWithMeta(walletHandler: walletHandler, myDid: myDid) { result1, result2, error in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result2 = result2 else {
                    fatalError("Expected non-nil result 'result2' for nil error")
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    
    @available(*, renamed: "openWalletSearch(walletHandler:id:)")
    func openWalletSearch(walletHandler: IndyHandle, id: String, completion: @escaping(Bool,IndyHandle,Error?) -> Void){
        let queryDic = [
            "connection_id": id,
            "request_id" : id
        ]
        let optionDict = [
            "retrieveRecords": true,
            "retrieveTotalCount": false,
            "retrieveType": false,
            "retrieveValue": true,
            "retrieveTags": true
        ]
        
        AgentWrapper.shared.openWalletSearch(inWallet: walletHandler, type:AriesAgentFunctions.mediatorConnectionInvitation, queryJson: UIApplicationUtils.shared.getJsonString(for: queryDic), optionsJson: UIApplicationUtils.shared.getJsonString(for: optionDict)) { (error, indyHandle) in
            debugPrint("Open wallet search")
            if(error?._code != 0){
                completion(false,indyHandle,error)
                return;
            }
            completion(true,indyHandle,error)
        }
    }
    
    func openWalletSearch(walletHandler: IndyHandle, id: String) async throws -> (Bool, IndyHandle) {
        return try await withCheckedThrowingContinuation { continuation in
            openWalletSearch(walletHandler: walletHandler, id: id) { result1, result2, error in
                if let error = error, error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    
    //MARK: Search - open wallet - create search handler
    @available(*, renamed: "openWalletSearch_type(walletHandler:type:searchType:invitationKey:serviceEndPoint:record_id:didKey:threadId:myDid:theirDid:reciepientKey:orgID:myVerKey:)")
    func openWalletSearch_type(walletHandler: IndyHandle,type:String, searchType: WalletSearch, searchValue: String = "", completion: @escaping(Bool,IndyHandle,Error?) -> Void){
        var queryDic = [String:Any]()
        switch searchType {
        case .withoutQuery: break
        case .searchWithInvitationKey:
            queryDic = [
                "invitation_key" : searchValue
            ]
        case .searchWithId:
            queryDic = [
                "request_id": searchValue
            ]
        case .searchtWithDidKey:
            queryDic = [
                "key": searchValue
            ]
        case .searchWithThreadId:
            queryDic = [
                "thread_id": searchValue
            ]
        case .searchWithTheirDid:
            queryDic = [
                "did" : searchValue
            ]
        case .searchWithReciepientKey:
            queryDic = [
                "reciepientKey" : searchValue
            ]
        case .offerReceived:
            queryDic = [
                "request_id": searchValue,
                "state": "offer_received"
            ]
        case .getActiveConnections:
            queryDic = [
                "state": "active",
            ]
        case .checkExistingConnection:
            queryDic = [
                "invitation_key" : searchValue,
                "state": "active",
            ]
        case .inbox_offerReceived:
            queryDic = [
                "type" : InboxType.certOffer.rawValue,
                "request_id": searchValue
            ]
        case .searchWithOrgId:
            queryDic = [
                "orgID" : searchValue ,
                "state": "active",
            ]
        case .searchWithMyVerKey:
            queryDic = [
                "myVerKey": searchValue
            ]
        case .selfAttestedCert:
            queryDic = [
                "type" : CertType.selfAttestedRecords.rawValue,
            ]
        case .oldSelfAttestedCert:
            queryDic = [
                "type" : CertType.oldSelfAttestedRecords.rawValue,
            ]
        case .getAllInboxOfferReceived:
            queryDic = [
                "type" : InboxType.certOffer.rawValue,
            ]
        case .passport:
            queryDic = [
                "type" : CertType.selfAttestedRecords.rawValue,
                "sub_type" : SelfAttestedCertTypes.passport.rawValue
            ]
        case .aadhar:
            queryDic = [
                "type" : CertType.idCards.rawValue,
                "sub_type" : SelfAttestedCertTypes.aadhar.rawValue
            ]
        case .idCards:
            queryDic = [
                "type" : CertType.idCards.rawValue,
            ]
        case .PKPass:
            queryDic = [
                "type" : CertType.selfAttestedRecords.rawValue,
                "sub_type" : SelfAttestedCertTypes.pkPass.rawValue
            ]
        case .EBSI:
            queryDic = [ "type" : CertType.EBSI.rawValue]
        case .history_instanceID:
            queryDic = [ "instanceID" : searchValue]
        case .history_thirdPartyShare:
            queryDic = [ "isThirdPartyDataShare" : searchValue]
        }
        
        let optionDict = [
            "retrieveRecords": true,
            "retrieveTotalCount": true,
            "retrieveType": false,
            "retrieveValue": true,
            "retrieveTags": true
        ]
        
        AgentWrapper.shared.openWalletSearch(inWallet: walletHandler, type: type, queryJson: UIApplicationUtils.shared.getJsonString(for: queryDic), optionsJson: UIApplicationUtils.shared.getJsonString(for: optionDict)) { (error, indyHandle) in
            debugPrint("Open wallet search -- \(type)")
            if(error?._code != 0){
                completion(false,indyHandle,error)
                return;
            }
            completion(true,indyHandle,error)
        }
    }
    
    func openWalletSearch_type(walletHandler: IndyHandle,type:String,
                               searchType: WalletSearch, searchValue: String = "") async throws -> (Bool, IndyHandle) {
        return try await withCheckedThrowingContinuation { continuation in
            openWalletSearch_type(walletHandler: walletHandler, type: type, searchType: searchType, searchValue: searchValue) { result1, result2, error in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    //MARK: Search - fetch
    @available(*, renamed: "fetchWalletSearchNextRecords(walletHandler:searchWalletHandler:count:)")
    func fetchWalletSearchNextRecords(walletHandler: IndyHandle, searchWalletHandler: IndyHandle,count: Int? = 1000, completion: @escaping (Bool,String,Error?) -> Void){
        AgentWrapper.shared.fetchNextRecords(fromSearch: searchWalletHandler, walletHandle: walletHandler, count: NSNumber.init(value: count ?? 1)) { (error, response) in
            //            debugPrint("fetch next records -- \(response ?? "")")
            if(error?._code != 0){
                completion(false,"",error)
                return;
            }
            if var dict = UIApplicationUtils.shared.convertToDictionary(text: response ?? ""), var records = dict["records"] as? [[String:Any]] {
                var newRecords: [[String:Any]] = []
                for var record in records {
                    if let strValue = record["value"] as? String, let value = UIApplicationUtils.shared.convertStringToDictionary(text: strValue) {
                        record["value"] = value
                        newRecords.append(record)
                    }
                }
                dict["records"] = newRecords
                completion(true,dict.toString() ?? "", error)
            } else {
                completion(true,response ?? "",error)
            }
            //Close wallet search handle after use
        }
    }
    
    func fetchWalletSearchNextRecords(walletHandler: IndyHandle, searchWalletHandler: IndyHandle,count: Int? = 1000) async throws -> (Bool, String) {
        return try await withCheckedThrowingContinuation { continuation in
            fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler, count: count) { result1, result2, error in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    //MARK: Pack
    @available(*, renamed: "packMessage(walletHandler:label:recipientKey:id:didCom:myDid:myVerKey:serviceEndPoint:routingKey:routedestination:deleteItemId:threadId:credReq:attributes:type:isRoutingKeyEnabled:externalRoutingKey:presentation:theirDid:QR_ID:)")
    func packMessage(walletHandler: IndyHandle,
                     label: String = "",
                     recipientKey: String,
                     id: String = "",
                     didCom: String,
                     myDid: String = "",
                     myVerKey: String,
                     serviceEndPoint: String = "",
                     routingKey: String = "",
                     routedestination: String? = "",
                     deleteItemId: String = "",
                     threadId: String? = "",
                     credReq: String? = "",
                     attributes: ProofExchangeAttributesArray? = nil,
                     type: PackMessageType,
                     isRoutingKeyEnabled:Bool,
                     externalRoutingKey: [String]? = [],
                     presentation: PRPresentation? = nil,
                     theirDid: String? = "",
                     QR_ID:String? = "",
                     to_myDataDid: String = "",
                     from_myDataDid: String = "",
                     bodySig: [String: String] = [:],
                     rawDict: [String: Any?] = [:],
                     completion: @escaping (Bool,Data?,Error?) -> Void){
        var messageDict = [String : Any?]()
        switch type {
        case .initialMediator:
            messageDict = [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/request",
                "@id": id,
                "label": label ,
                "connection": [
                    "DID": myDid,
                    "DIDDoc": [
                        "@context": "https://w3id.org/did/v1",
                        "id": "did:sov:\(myDid)",
                        "publicKey": [
                            [
                                "id": "did:sov:\(myDid)#1",
                                "type": "Ed25519VerificationKey2018",
                                "controller": "did:sov:\(myDid)",
                                "publicKeyBase58": myVerKey  // - verkey
                            ]
                        ],
                        "authentication": [
                            [
                                "type": "Ed25519SignatureAuthentication2018",
                                "publicKey": "did:sov:\(myDid)#1"
                            ]
                        ],
                        "service": [
                            [
                                "id": "did:sov:\(myDid);indy",
                                "type": "IndyAgent",
                                "priority": 0,
                                "recipientKeys": [
                                    myVerKey
                                ],
                                "serviceEndpoint": ""
                            ]
                        ]
                    ]
                ],
                "~transport" : [
                    "return_route": "all"
                ]
            ] as [String : Any?]
            
        case .initialCloudAgent, .initialRegistry :
            messageDict = [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/connections/1.0/request",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "label": UIDevice.current.name,
                "connection": [
                    "DID": myDid,
                    "DIDDoc": [
                        "@context": "https://w3id.org/did/v1",
                        "id": "did:sov:\(myDid)",
                        "publicKey": [
                            [
                                "id": "did:sov:\(myDid)#1",
                                "type": "Ed25519VerificationKey2018",
                                "controller": "did:sov:\(myDid)",
                                "publicKeyBase58": myVerKey  // - verkey
                            ]
                        ],
                        "authentication": [
                            [
                                "type": "Ed25519SignatureAuthentication2018",
                                "publicKey": "did:sov:\(myDid)#1"
                            ]
                        ],
                        "service": [
                            [
                                "id": "did:sov:\(myDid);indy",
                                "type": "IndyAgent",
                                "priority": 0,
                                "routingKeys": routingKey.isNotEmpty ? [
                                    routingKey
                                ] : [],
                                "recipientKeys": [
                                    myVerKey
                                ],
                                "serviceEndpoint": NetworkManager.shared.mediatorEndPoint
                            ]
                        ],
                    ]
                ],
                "~transport" : [
                    "return_route": "all"
                ]
            ] as [String : Any?]
            
        case .pollingMediator:
            
            messageDict = [
                "@id": id,
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/basic-routing/1.0/get-inbox-items",
                "~transport": [
                    "return_route": "all"
                ]
            ]
            
        case .addRoute:
            messageDict = [
                "@id" : AgentWrapper.shared.generateRandomId_BaseUID4(),
                "@type" : "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/basic-routing/1.0/add-route",
                "routedestination": routedestination,
                "~transport": [
                    "return_route" : "all"
                ]
            ] as [String : Any]
        case .createInbox:
            messageDict = [
                "@id": id,
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/basic-routing/1.0/create-inbox",
                "~transport": [
                    "return_route": "all"
                ]
            ]
        case .trustPing:
            messageDict = [
                "@type": "https://didcomm.org/trust_ping/1.0/ping",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "comment": "ping",
                "response_requested": true
            ]
        case .deleteInboxItem:
            messageDict = [
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/basic-routing/1.0/delete-inbox-items",
                "inboxitemids": [
                    deleteItemId
                ],
                "~transport": [
                    "return_route": "all"
                ]
            ]
        case .credentialAck:
            messageDict = [
                "@type": "\(didCom);spec/issue-credential/1.0/ack",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "~thread": [
                    "thid": threadId ?? ""
                ],
                "status": "OK"
            ]
        case .proposePresentation:
            messageDict = [
                "@type": "\(didCom);spec/present-proof/1.0/propose-presentation",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "qr_id":QR_ID,
                "presentation_proposal": [
                    "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/present-proof/1.0/presentation-preview",
                    "attributes": attributes?.dictionary?["items"] ?? [String:Any](),
                    "predicates": []
                ],
                "comment": "Proposing credentials",
                "~transport": [
                    "return_route": "all"
                ]
            ]
        case .queryIgrantAgent:
            messageDict = [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/discover-features/1.0/query",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "query": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/igrantio-operator/*",
                "comment": "Querying features available.",
                "~transport": [
                    "return_route": "all"
                ]
            ]
        case .getIgrantOrgDetail:
            
            messageDict = [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/igrantio-operator/1.0/organization-info",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "~transport": [
                    "return_route": "all"
                ]
            ]
        case .getIgrantCertTypeResponse:
            messageDict = [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/igrantio-operator/1.0/list-data-certificate-types",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "~transport": [
                    "return_route": "all"
                ]
            ]
        case .presentation:
            let modelDict = presentation?.dictionary ?? [String:Any]()
            let base64 = modelDict.toString()?.encodeBase64()
            messageDict = [
                "@type": "\(didCom);spec/present-proof/1.0/presentation",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "~thread": [
                    "thid": threadId
                ],
                "presentations~attach": [
                    [
                        "@id": "libindy-presentation-0",
                        "mime-type" : "application/json",
                        "data" : ["base64" : base64]
                    ]
                ],
                "comment": "auto-presented for proof request nonce=1234567890"
            ]
        case .informDuplicateConnection:
            messageDict = [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/igrantio-operator/1.0/org-multiple-connections",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "theirdid": theirDid ?? "",
                //                    "~transport": [
                //                        "return_route": "all"
                //                    ]
            ]
            
        case .fetchDataAgreement:
            messageDict = [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/igrantio-operator/1.0/fetch-data-agreement",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "exchange_template_id": QR_ID,
                "exchange_mode": "verify",
                "~transport": [
                    "return_route": "all"
                ]
            ]
        case .fetchDataAgreement_issue_cert:
            messageDict = [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/igrantio-operator/1.0/fetch-data-agreement",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "exchange_template_id": QR_ID,
                "exchange_mode": "issue",
                "~transport": [
                    "return_route": "all"
                ]
            ]
        case .createMyDataDid:
            messageDict = [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/mydata-did/1.0/create-did",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "created_time": Date().epochTime,
                "to": to_myDataDid,
                "from": from_myDataDid,
                "body~sig": bodySig,
                "~transport": [
                    "return_route": "all"
                ]
            ]
        case .rawDataBody:
            messageDict = rawDict
        }
        
        let messageJsonString = UIApplicationUtils.shared.getJsonString(for: messageDict)
        let messageData = Data(messageJsonString.utf8)
        
        //Note: the message is posted to responders service endpoint with header `{'Content-Type': 'application/ssi-agent-wire'}`
        
        if isRoutingKeyEnabled {
            AgentWrapper.shared.packMessage(message: messageData, myKey: myVerKey, recipientKey: "[\"\(recipientKey)\"]", walletHandle: walletHandler) { (error, data) in
                debugPrint("pack message")
                self.forwardMessagePack(walletHandler: walletHandler, message: data ?? Data(), recipient_key: recipientKey, routingKey: externalRoutingKey ?? [], myVerKey: myVerKey, type: didCom, completion: completion)
            }
        } else {
            AgentWrapper.shared.packMessage(message: messageData, myKey: myVerKey, recipientKey: "[\"\(recipientKey)\"]", walletHandle: walletHandler) { (error, data) in
                debugPrint("pack message")
                if(error?._code != 0){
                    completion(false,data,error)
                    return;
                }
                completion(true,data,error)
            }
        }
    }
    
    func packMessage(walletHandler: IndyHandle,label: String = "",recipientKey: String,id: String = "",didCom: String, myDid: String = "", myVerKey: String,serviceEndPoint: String = "",routingKey: String = "",routedestination: String? = "",deleteItemId: String = "",threadId: String? = "",credReq: String? = "",attributes: ProofExchangeAttributesArray? = nil, type: PackMessageType,isRoutingKeyEnabled:Bool, externalRoutingKey: [String]? = [],presentation: PRPresentation? = nil,theirDid: String? = "",QR_ID:String? = "",  to_myDataDid: String = "",
                     from_myDataDid: String = "",
                     bodySig: [String: String] = [:],
                     rawDict: [String: Any?] = [:]) async throws -> (Bool, Data) {
        return try await withCheckedThrowingContinuation { continuation in
            packMessage(walletHandler: walletHandler, label: label, recipientKey: recipientKey, id: id, didCom: didCom, myDid: myDid, myVerKey: myVerKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey, routedestination: routedestination, deleteItemId: deleteItemId, threadId: threadId, credReq: credReq, attributes: attributes, type: type, isRoutingKeyEnabled: isRoutingKeyEnabled, externalRoutingKey: externalRoutingKey, presentation: presentation, theirDid: theirDid, QR_ID: QR_ID, to_myDataDid: to_myDataDid, from_myDataDid: from_myDataDid, bodySig: bodySig, rawDict: rawDict) { result1, result2, error in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result2 = result2 else {
                    fatalError("Expected non-nil result 'result2' for nil error")
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    
    @available(*, renamed: "unpackMessage(walletHandler:messageData:)")
    func unpackMessage(walletHandler: IndyHandle,messageData: Data, completion: @escaping (Bool,Data?,Error?) -> Void){
        AgentWrapper.shared.unpackMessage(message: messageData, walletHandle: walletHandler) { (error, data) in
            if(error?._code != 0){
                completion(false,data,error)
                return;
            }
            
            if let data = data, let processedData = UIApplicationUtils.shared.processUnpaackedMessage(unpackedData: data){
                completion(true,processedData,error)
            }
            else {
                completion(true,data,error)
            }
        }
    }
    
    func unpackMessage(walletHandler: IndyHandle,messageData: Data) async throws -> (Bool, Data) {
        return try await withCheckedThrowingContinuation { continuation in
            unpackMessage(walletHandler: walletHandler, messageData: messageData) { result1, result2, error in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                guard let result2 = result2 else {
                    fatalError("Expected non-nil result 'result2' for nil error")
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    
    @available(*, renamed: "addWalletRecord_DidDoc(walletHandler:invitationKey:theirDid:recipientKey:serviceEndPoint:routingKey:isMediator:)")
    func addWalletRecord_DidDoc(walletHandler: IndyHandle,invitationKey: String, theirDid: String, recipientKey: String, serviceEndPoint: String,routingKey:String,type: DidDocTypes, completion: @escaping (Bool,String,Error?) -> Void){ //Success,didDocRecordId,error
        let value = [
            "@context" : "https://w3id.org/did/v1",
            "id": "did:sov:\(theirDid)",
            "publicKey": [
                [
                    "id" : "did:sov:\(theirDid)#1",
                    "type": "Ed25519VerificationKey2018",
                    "controller": "did:sov:\(theirDid)",
                    "publicKeyBase58": "\(recipientKey)"
                ]
            ],
            "authentication": [
                [
                    "type" : "Ed25519SignatureAuthentication2018",
                    "publicKey": "did:sov:\(theirDid)#1"
                ]
            ],
            "service": [
                [
                    "id" : "did:sov:\(theirDid);indy",
                    "type": "IndyAgent",
                    "priority": 0,
                    "routingKeys":[
                        "\(routingKey)"
                    ],
                    "recipientKeys": [
                        "\(recipientKey)"
                    ],
                    "serviceEndpoint": "\(serviceEndPoint)"
                ]
            ]
        ] as [String : Any?]
        
        let tagJson = [
            "did": "\(theirDid)",
            "invitation_key": invitationKey
        ] as [String : Any?]
        
        let didDocRecordId = AgentWrapper.shared.generateRandomId_BaseUID4()
        AgentWrapper.shared.addWalletRecord(inWallet: walletHandler, type: type.rawValue, id: didDocRecordId , value: UIApplicationUtils.shared.getJsonString(for: value), tagsJson: UIApplicationUtils.shared.getJsonString(for: tagJson)) { (error) in
            if(error?._code == 0){
                debugPrint("did doc record saved")
                completion(true,didDocRecordId,error)
            } else {
                completion(false,didDocRecordId,error)
            }
            
        }
    }
    
    func addWalletRecord_DidDoc(walletHandler: IndyHandle,invitationKey: String, theirDid: String, recipientKey: String, serviceEndPoint: String,routingKey:String,type: DidDocTypes) async throws -> (Bool, String) {
        return try await withCheckedThrowingContinuation { continuation in
            addWalletRecord_DidDoc(walletHandler: walletHandler, invitationKey: invitationKey, theirDid: theirDid, recipientKey: recipientKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey, type: type) { result1, result2, error in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    
    @available(*, renamed: "addWalletRecord_DidKey(walletHandler:theirDid:recipientKey:isMediator:)")
    func addWalletRecord_DidKey(walletHandler: IndyHandle, theirDid: String, recipientKey: String,type: DidKeyTypes, completion: @escaping (Bool,String,Error?) -> Void){ //Success,didDocRecordId,error
        let value = [
            "their_did": "\(theirDid)", "their_Key": "\(recipientKey)"
        ] as [String : Any?]
        let tagJson = [
            "did": "\(theirDid)", "key": "\(recipientKey)"
        ] as [String : Any?]
        
        let didDocRecordId = AgentWrapper.shared.generateRandomId_BaseUID4()
        
        AgentWrapper.shared.addWalletRecord(inWallet: walletHandler, type: type.rawValue, id: didDocRecordId , value:  UIApplicationUtils.shared.getJsonString(for: value), tagsJson: UIApplicationUtils.shared.getJsonString(for: tagJson)) { (error) in
            if(error?._code == 0){
                debugPrint("did doc record saved")
                completion(true,didDocRecordId,error)
            } else {
                completion(false,didDocRecordId,error)
            }
        }
    }
    
    func addWalletRecord_DidKey(walletHandler: IndyHandle, theirDid: String, recipientKey: String,type: DidKeyTypes) async throws -> (Bool, String) {
        return try await withCheckedThrowingContinuation { continuation in
            addWalletRecord_DidKey(walletHandler: walletHandler, theirDid: theirDid, recipientKey: recipientKey, type: type) { result1, result2, error in
                if let error = error,error._code != 0 {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (result1, result2))
            }
        }
    }
    
    
    func deleteWalletRecord(walletHandler: IndyHandle,type: String, id: String,completion: @escaping(Bool,Error?) -> Void) {
        AgentWrapper.shared.deleteWalletRecord(inWallet: walletHandler, type: type, id: id, completion: { (error) in
            if(error?._code == 0) {
                debugPrint("did doc record saved")
                completion(true,error)
            } else {
                completion(false,error)
            }
        })
    }
    
    func forwardMessagePack(walletHandler: IndyHandle,message: Data,recipient_key: String,routingKey: [String], myVerKey:String,count:Int = 0,type: String, completion: @escaping (Bool,Data?,Error?) -> Void) {
        
        var messageDict = [String : Any?]()
        let message = String(decoding: message, as: UTF8.self)
        messageDict = [
            "@type": "\(type);spec/routing/1.0/forward",
            "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
            "to": count == 0 ? recipient_key : routingKey[count - 1],
            "msg": UIApplicationUtils.shared.convertToDictionary(text: message)
        ]
        let messageJsonString = UIApplicationUtils.shared.getJsonString(for: messageDict)
        let messageData = Data(messageJsonString.utf8)
        
        AgentWrapper.shared.packMessage(message: messageData, myKey: myVerKey, recipientKey: "[\"\(routingKey[count])\"]", walletHandle: walletHandler) { (error, data) in
            debugPrint("pack message")
            
            if count == routingKey.count - 1 {
                if(error?._code != 0) {
                    completion(false,data,error)
                    return;
                }
                completion(true,data,error)
            } else {
                self.forwardMessagePack(walletHandler: walletHandler, message: data ?? Data(), recipient_key: recipient_key, routingKey: routingKey, myVerKey: myVerKey,count: count + 1, type: type, completion: completion)
            }
        }
    }
}
