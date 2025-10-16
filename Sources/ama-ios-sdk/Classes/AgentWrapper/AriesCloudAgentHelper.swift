//
//  AriesAgentHelper.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 18/12/20.
//

import Foundation
import SVProgressHUD
import IndyCWrapper

struct AriesCloudAgentHelper{
    static var shared = AriesCloudAgentHelper()
    static var onTrustPingSuccessBlock : ((CloudAgentConnectionWalletModel?,String?,String?)-> Void)?
    private init(){}
    private static var routerKey:[String]?
    private static var OrgID: String?
    private static var orgDetails: OrganisationInfoModel?
    private static var didCom: String?
}

//MARK: CloudAgentConnection

extension AriesCloudAgentHelper {
    
    func newConnectionConfigCloudAgent(walletHandler: IndyHandle, label: String, theirVerKey: String,serviceEndPoint: String, routingKey: [String]?, imageURL: String,pollingEnabled: Bool = true, orgId: String?, orgDetails: OrganisationInfoModel? ,didCom: String,completion: @escaping((CloudAgentConnectionWalletModel?,String?,String?) -> Void)){
        AriesCloudAgentHelper.onTrustPingSuccessBlock = completion
        AriesCloudAgentHelper.routerKey = routingKey
        AriesCloudAgentHelper.OrgID = orgId
        AriesCloudAgentHelper.orgDetails = orgDetails
        AriesCloudAgentHelper.didCom = didCom
        
        //        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .checkExistingConnection, invitationKey: theirVerKey) { (success, searchInvitationHandler, error) in
        //            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchInvitationHandler) { (fetchSuccess, results, error) in
        //                let resultDict = UIApplicationUtils.shared.convertToDictionary(text: results)
        //                let count = resultDict?["totalCount"] as? Int ?? 0
        //                if (count > 0){
        //                    UIApplicationUtils.showSuccessSnackbar(message: "Connection already existing".localizedForSDK())
        //                    completion(CloudAgentConnectionWalletModel.init(),"","")
        //                    return
        //                }
        
        WalletRecord.shared.add(invitationKey: theirVerKey, label: label, serviceEndPoint: serviceEndPoint, connectionRecordId: "",imageURL: imageURL, walletHandler: walletHandler,type: .connection, orgID:orgId, completion: { (addRecord_Connection_Completed, connectionRecordId, error) in
            if addRecord_Connection_Completed{
                WalletRecord.shared.add(invitationKey:theirVerKey,label: label, serviceEndPoint: serviceEndPoint,connectionRecordId: connectionRecordId, reciepientKey: theirVerKey, walletHandler: walletHandler,type: .invitation) { (addWalletRecord_ConnectionInvitation_Completed, connectionInvitationRecordId, error) in
                    if (addWalletRecord_ConnectionInvitation_Completed){
                        WalletRecord.shared.get(walletHandler: walletHandler,connectionRecordId: connectionRecordId, type: AriesAgentFunctions.cloudAgentConnection, completion: { (getWalletRecordSuccessfully, _,error) in
                            if getWalletRecordSuccessfully {
                                AriesAgentFunctions.shared.createAndStoreId(walletHandler: walletHandler) { (createDidSuccess, myDid, verKey,error) in
                                    let myDid = myDid
                                    let myVerKey = verKey
                                    debugPrint("verKey \(verKey)")
                                    AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: theirVerKey, didCom: "", myVerKey: myVerKey ?? "", type: .queryIgrantAgent, isRoutingKeyEnabled: false) { (success, data, error) in
                                        NetworkManager.shared.sendMsg(isMediator: false, msgData: data ?? Data(), url:serviceEndPoint) { (statuscode,responseData) in
                                            //                                                    if statuscode != 200 {
                                            //                                                        if let trustPingSuccess = AriesCloudAgentHelper.onTrustPingSuccessBlock {
                                            //                                                            trustPingSuccess(nil,nil,nil)
                                            //                                                           UIApplicationUtils.hideLoader()
                                            //                                                            return
                                            //                                                        }
                                            //                                                    }
                                            if statuscode == 200 {
                                                AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responseData ?? Data()) { (success, unpackedData, error) in
                                                    if let messageModel = try? JSONSerialization.jsonObject(with: unpackedData ?? Data(), options: []) as? [String : Any] {
                                                        let msgString = (messageModel)["message"] as? String
                                                        let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                                        let queryAgentResponseModel = QueryAgentResponseModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? QueryAgentResponseModel
                                                        if (queryAgentResponseModel?.protocols?.count ?? 0) > 0 {
                                                            var isThirdPartySharingEnabled = "false"
                                                            if ((queryAgentResponseModel?.protocols?.contains(where: { e in
                                                                e.pid?.contains("spec/third-party-data-sharing/1.0") ?? false
                                                            })) != nil) {
                                                                isThirdPartySharingEnabled = "true"
                                                            }
                                                            self.updateWalletRecords(walletHandler: walletHandler, myDid: myDid, verKey: verKey, imageURL: imageURL, isIgrantAgent: (queryAgentResponseModel?.protocols?.count ?? 0 > 0), label: label, recipientKey: theirVerKey, connectionRecordId: connectionRecordId,serviceEndPoint: serviceEndPoint,routingKey: routingKey,pollingEnabled: pollingEnabled, isThirdPartyShareSupported: isThirdPartySharingEnabled)
                                                        } else{
                                                            let query_data_controller = AriesPackMessageTemplates.queryDataControllerProtocol()
                                                            Task {
                                                                do {
                                                                    let (pack_success, query_pack_data)  =  try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: theirVerKey , didCom: "", myVerKey: myVerKey ?? "", type: .rawDataBody, isRoutingKeyEnabled: false, rawDict: query_data_controller)
                                                                    
                                                                    let (statuscode,orgServerResponseData) = await   NetworkManager.shared.sendMsg(isMediator: false, msgData: query_pack_data ?? Data(),url: serviceEndPoint)
                                                                    let (unpackedSuccessfully, orgDetailsData) = try await     AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: orgServerResponseData ?? Data())
                                                                    if let messageModel = try? JSONSerialization.jsonObject(with: orgDetailsData ?? Data(), options: []) as? [String : Any] {
                                                                        debugPrint("unpackmsg -- \(messageModel)")
                                                                        let msgString = (messageModel)["message"] as? String
                                                                        let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                                                        let queryAgentResponseModel = QueryAgentResponseModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? QueryAgentResponseModel
                                                                        debugPrint("Org details received")
                                                                        let orgDetail = OrganisationInfoModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? OrganisationInfoModel
                                                                        var isThirdPartySharingEnabled = "false"
                                                                        if ((queryAgentResponseModel?.protocols?.contains(where: { e in
                                                                            e.pid?.contains("spec/third-party-data-sharing/1.0") ?? false
                                                                        })) != nil) {
                                                                            isThirdPartySharingEnabled = "true"
                                                                        }
                                                                            self.updateWalletRecords(walletHandler: walletHandler, myDid: myDid, verKey: verKey, imageURL: imageURL, isIgrantAgent: (queryAgentResponseModel?.protocols?.count ?? 0 > 0), label: label, recipientKey: theirVerKey, connectionRecordId: connectionRecordId,serviceEndPoint: serviceEndPoint,routingKey: routingKey,pollingEnabled: pollingEnabled,isThirdPartyShareSupported: isThirdPartySharingEnabled)
                                                                        }
                                                                } catch {
                                                                    debugPrint(error.localizedDescription)
                                                                }
                                                            }
                                                        }
                                                }
                                            }
                                        }else {
                                            self.updateWalletRecords(walletHandler: walletHandler, myDid: myDid, verKey: verKey, imageURL: imageURL, isIgrantAgent: false, label: label, recipientKey: theirVerKey, connectionRecordId: connectionRecordId,serviceEndPoint: serviceEndPoint,routingKey: routingKey,pollingEnabled: pollingEnabled,isThirdPartyShareSupported: "false")
                                        }
                                    }
                                    }
                                }
                            }
                        })
                    }
                }
            }
        })
        //            }
        //        }
    }
    
    func updateWalletRecords(walletHandler: IndyHandle, myDid:String?, verKey:String?, imageURL:String,isIgrantAgent:Bool,label: String, recipientKey: String,connectionRecordId:String,serviceEndPoint: String,routingKey: [String]?,pollingEnabled:Bool,isThirdPartyShareSupported: String ){
        AriesAgentFunctions.shared.setMetadata(walletHandler: walletHandler, myDid: myDid ?? "",verKey:verKey ?? "", completion: { (metaAdded) in
            if(metaAdded){
                AriesAgentFunctions.shared.updateWalletRecord(walletHandler: walletHandler,recipientKey: recipientKey,label: label, type: UpdateWalletType.initialCloudAgent, id: connectionRecordId, theirDid: "", myDid: myDid ?? "",imageURL: imageURL,invitiationKey: recipientKey, isIgrantAgent: isIgrantAgent, routingKey: routingKey,orgID:AriesCloudAgentHelper.OrgID, completion: { (updateWalletRecordSuccess,updateWalletRecordId ,error) in
                    if(updateWalletRecordSuccess){
                        AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler, id: connectionRecordId, myDid: myDid ?? "", theirDid: "",recipientKey: recipientKey,serviceEndPoint: serviceEndPoint, invitiationKey: recipientKey, type: .initialCloudAgent,isIgrantAgent: isIgrantAgent,orgID: AriesCloudAgentHelper.OrgID ?? "",myVerKey: verKey, completion: { (updateWalletTagSuccess, error) in
                            if(updateWalletTagSuccess){
                                self.registerRouter(walletHandler: walletHandler,connectionRecordId: connectionRecordId, verKey: verKey ?? "", myDid: myDid ?? "", recipientKey: recipientKey, label: label,serviceEndPoint: serviceEndPoint, routingKey: routingKey,mediatorVerKey: WalletViewModel.mediatorVerKey ?? "",pollingEnabled: pollingEnabled,isIgrantAgent: isIgrantAgent)
                            }
                        })
                    }
                })
            }
        })
    }
    
    func registerRouter(walletHandler: IndyHandle,connectionRecordId: String,verKey: String, myDid: String, recipientKey: String, label: String,serviceEndPoint: String, routingKey: [String]?, mediatorVerKey: String,pollingEnabled: Bool = true,isIgrantAgent: Bool = false){
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type:
                                                            DidDocTypes.mediatorDidDoc.rawValue,searchType: .withoutQuery, completion: { (success, searchWalletHandler, error) in
            if (success) {
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler, completion: {
                    (fetchedSuccessfully,results,error) in
                    if (fetchedSuccessfully){
                        let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                        let docModel = SearchDidDocModel.decode(withDictionary: resultsDict as NSDictionary? ?? NSDictionary()) as? SearchDidDocModel
                        let mediatorRoutingKey = docModel?.records?.first?.value?.service?.first?.routingKeys?.first ?? ""
                        let mediatorRecipientKey = docModel?.records?.first?.value?.service?.first?.recipientKeys?.first ?? ""
                        //let routerKey =
                        AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, label: label, recipientKey: mediatorRecipientKey, id: connectionRecordId,  didCom: AriesCloudAgentHelper.didCom ?? "", myDid: myDid, myVerKey: mediatorVerKey , serviceEndPoint: serviceEndPoint, routingKey: mediatorRoutingKey , routedestination: verKey, deleteItemId: "", type: .addRoute,isRoutingKeyEnabled: false, externalRoutingKey: []) { (packedSuccessfully, packedData, error) in
                            if packedSuccessfully {
                                NetworkManager.shared.sendMsg(isMediator: true, msgData: packedData ?? Data()) { (statuscode,receivedData) in
                                    if statuscode != 200 {
                                        if let trustPingSuccess = AriesCloudAgentHelper.onTrustPingSuccessBlock {
                                            trustPingSuccess(nil,nil,nil)
                                            UIApplicationUtils.hideLoader()
                                            return
                                        }
                                    }
                                    let registerRouterResponse = try? JSONSerialization.jsonObject(with: receivedData ?? Data() , options: [.allowFragments]) as? [String : Any]
                                    
                                    self.getRecordAndConnectForCloudAgent(walletHandler: walletHandler,connectionRecordId: connectionRecordId, verKey: verKey, myDid: myDid, recipientKey: recipientKey, label: label, packageMsgType: .initialCloudAgent, routingKey: mediatorRoutingKey,serviceEndPoint: serviceEndPoint,pollingEnabled: pollingEnabled)
                                }
                            }
                        }
                    }
                })
            }
        })
    }
    
    func getRecordAndConnectForCloudAgent(walletHandler: IndyHandle,connectionRecordId: String,verKey: String, myDid: String, recipientKey: String, label: String, packageMsgType: PackMessageType,routingKey: String, serviceEndPoint: String,pollingEnabled: Bool = true){//routingKey: String,
        AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler,label: label, recipientKey: recipientKey,  id: connectionRecordId,  didCom: AriesCloudAgentHelper.didCom ?? "", myDid: myDid , myVerKey: verKey ,serviceEndPoint: serviceEndPoint, routingKey: routingKey, deleteItemId: "", type: .initialCloudAgent,isRoutingKeyEnabled: AriesCloudAgentHelper.routerKey?.count ?? 0 > 0, externalRoutingKey: AriesCloudAgentHelper.routerKey ?? [], completion:{ (packMsgSuccess, messageData, error) in
            if (packMsgSuccess){
                debugPrint("Cloud Agent Request Sending ...")
                NetworkManager.shared.sendMsg(isMediator:false,msgData: messageData ?? Data(),url: serviceEndPoint) { (statuscode,receivedData) in
                    if statuscode != 200 {
                        if let trustPingSuccess = AriesCloudAgentHelper.onTrustPingSuccessBlock {
                            trustPingSuccess(nil,nil,nil)
                            UIApplicationUtils.hideLoader()
                            return
                        }
                    }
                    debugPrint("Cloud Agent Request Send")
                    AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: receivedData ?? Data(), completion: { (unpackedSuccessfully, unpackedData, error) in
                        if let messageModel = try? JSONSerialization.jsonObject(with: unpackedData ?? Data(), options: []) as? [String : Any] {
                            let msgString = (messageModel)["message"] as? String
                            let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                            //connection~sig
                            let itemType = (msgDict?["@type"] as? String)?.split(separator: "/").last ?? ""
                            let connSigDict = (msgDict)?["connection~sig"] as? [String:Any]
                            
                            let sigDataBase64String = (connSigDict)?["sig_data"] as? String
                            let sigDataString = sigDataBase64String?.decodeBase64_first8bitRemoved()
                            let sigDataDict = UIApplicationUtils.shared.convertToDictionary(text: sigDataString ?? "") ?? [String:Any]()
                            let recipient_verkey = (messageModel)["recipient_verkey"] as? String ?? ""
                            let sender_verkey = (messageModel)["sender_verkey"] as? String ?? ""
                            AriesCloudAgentHelper.shared.addWalletRecord_CloudAgent(walletHandle: walletHandler, connectionRecordId: connectionRecordId,verKey: recipient_verkey, recipientKey: sender_verkey,  packageMsgType: .initialCloudAgent, sigDataDict:sigDataDict as [String : Any], type: AriesCloudAgentHelper.didCom)
                        }
                    })
                }
            }
        })
    }
    
    func addWalletRecord_CloudAgent(walletHandle: IndyHandle?,connectionRecordId: String,verKey: String, recipientKey: String, packageMsgType: PackMessageType, sigDataDict: [String:Any]?,type: String?){
        let walletHandler = walletHandle ?? 0
        
        if let sigDataDict = sigDataDict {
            
            let theirDid = sigDataDict["DID"] as? String ?? ""
            let dataDic = ((sigDataDict["DIDDoc"] as? [String:Any])?["service"] as? [[String:Any]])?.first
            let senderVerKey = (dataDic?["recipientKeys"] as? [String])?.first ?? ""
            let serviceEndPoint = (dataDic?["serviceEndpoint"] as? String) ?? ""
            let routingKey = (dataDic?["serviceEndpoint"] as? String) ?? ""
            if let externalRoutingKey = (dataDic?["routingKeys"] as? [String]) {
                AriesCloudAgentHelper.routerKey = externalRoutingKey
            }
            
            AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithMyVerKey, searchValue: verKey) { (searchCompleted, searchedWalletHandler, error) in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchedWalletHandler) { (searchCompleted, results, error) in
                    if let messageModel = UIApplicationUtils.shared.convertToDictionary(text: results) {
                        let requestArray = messageModel["records"] as? [[String:Any]] ?? []
                        let requestDict = requestArray.first?["value"] as? [String:Any]
                        let request_id = requestDict?["request_id"] as? String ?? ""
                        let myDid_cloudAgent =  requestDict?["my_did"] as? String ?? ""
                        let label_cloudAgent =  requestDict?["their_label"] as? String ?? ""
                        let isIgrantAgent = requestDict?["isIgrantAgent"] as? String ?? "0"
                        let invitationKey = requestDict?["invitation_key"] as? String ?? ""
                        let imageUrl = requestDict?["imageURL"] as? String ?? ""
                        let isThirdPartyShareSupported = requestDict?["isThirdPartyShareSupported"] as? String ?? "false"
                        
                        
                        AriesAgentFunctions.shared.addWalletRecord_DidDoc(walletHandler: walletHandler, invitationKey: invitationKey, theirDid: theirDid , recipientKey: senderVerKey , serviceEndPoint: serviceEndPoint, routingKey: routingKey , type: DidDocTypes.cloudAgentDidDoc, completion: { (didDocRecordAdded, didDocRecordId, error) in
                            if (didDocRecordAdded){
                                AriesAgentFunctions.shared.addWalletRecord_DidKey(walletHandler: walletHandler, theirDid: theirDid, recipientKey: senderVerKey, type: DidKeyTypes.cloudAgentDidKey, completion: { (didKeyRecordAdded, didKeyRecordId, error) in
                                    
                                    AriesAgentFunctions.shared.updateWalletRecord(walletHandler: walletHandler,recipientKey: senderVerKey,label: label_cloudAgent, type: .updateCloudAgentRecord, id: request_id, theirDid: theirDid, myDid: myDid_cloudAgent ,imageURL: imageUrl,invitiationKey: invitationKey, isIgrantAgent: isIgrantAgent == "1", routingKey: AriesCloudAgentHelper.routerKey ?? [],orgID: AriesCloudAgentHelper.OrgID ,isThirdPartyShareSupported: isThirdPartyShareSupported,completion: { (updatedSuccessfully, updatedRecordId, error) in
                                        if(updatedSuccessfully){
                                            AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler, id: request_id, myDid: myDid_cloudAgent ,
                                                                                        theirDid: theirDid, recipientKey: senderVerKey, serviceEndPoint: serviceEndPoint,invitiationKey: invitationKey, type: .updateCloudAgentTag,isIgrantAgent: isIgrantAgent == "1",orgID: AriesCloudAgentHelper.OrgID ?? "",myVerKey: verKey, completion: { (updatedSuccessfully, error) in
                                                if (updatedSuccessfully){
                                                    debugPrint("Cloud Agent Added")
                                                    AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid: myDid_cloudAgent) { (getMetaSuccessfully, metadata, error) in
                                                        let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata ?? "")
                                                        if let cloud_verKey = metadataDict?["verkey"] as? String{
                                                            self.trustPing(walletHandle: walletHandle, connectionRecordId: request_id, verKey: cloud_verKey, myDid: myDid_cloudAgent, recipientKey: senderVerKey, label: label_cloudAgent, packageMsgType: .trustPing, routingKey: routingKey, serviceEndPoint: serviceEndPoint)
                                                        }
                                                    }
                                                }
                                            })
                                        }
                                    })
                                })
                                
                            }
                        })
                    }
                }
            }
        }
    }
    
    func trustPing(walletHandle: IndyHandle?,connectionRecordId: String,verKey: String, myDid: String, recipientKey: String, label: String, packageMsgType: PackMessageType, routingKey: String, serviceEndPoint: String){
        let walletHandler = walletHandle ?? 0
        debugPrint("recipientKey - ping send \(recipientKey)")
        debugPrint("verKey - ping send \(verKey)")
        AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, label: label, recipientKey: recipientKey, id: connectionRecordId, didCom: AriesCloudAgentHelper.didCom ?? "", myDid: myDid, myVerKey: verKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey,deleteItemId: "", type: .trustPing,isRoutingKeyEnabled: AriesCloudAgentHelper.routerKey?.count ?? 0 > 0, externalRoutingKey: AriesCloudAgentHelper.routerKey ?? []) { (packedSuccessfully, packedData, error) in
            NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData ?? Data(),url: serviceEndPoint) { (statuscode,responseData) in
                if statuscode != 200 {
                    if let trustPingSuccess = AriesCloudAgentHelper.onTrustPingSuccessBlock {
                        //                        trustPingSuccess(nil,nil,nil)
                        //                       UIApplicationUtils.hideLoader()
                        pingResponseHandler(walletHandle: walletHandler, verKey: verKey, recipientKey: recipientKey, type: AriesCloudAgentHelper.didCom ?? "")
                        return
                    }
                }
                debugPrint("Ping send")
            }
        }
    }
    
    func pingResponseHandler(walletHandle: IndyHandle?, verKey: String, recipientKey: String, type: String) {
        let walletHandler = walletHandle ?? 0
        
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithReciepientKey, searchValue: recipientKey) { (searchCompleted, searchedWalletHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchedWalletHandler) { (searchCompleted, results, error) in
                if let messageModel = UIApplicationUtils.shared.convertToDictionary(text: results){
                    let records = messageModel["records"] as? [[String:Any]]
                    let firstRecord = records?.first
                    let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord as NSDictionary? ?? NSDictionary()) as? CloudAgentConnectionWalletModel
                    self.getiGrantOrgDetails(walletHandle: walletHandler, reqId: connectionModel?.id ?? "") { (success, orgModel) in
                        AriesAgentFunctions.shared.updateWalletRecord(walletHandler: walletHandler,recipientKey: recipientKey,label: connectionModel?.value?.theirLabel ?? "", type: .trusted, id: connectionModel?.value?.requestID ?? "", theirDid: connectionModel?.value?.theirDid ?? "", myDid: connectionModel?.value?.myDid ?? "" ,imageURL: connectionModel?.value?.imageURL ?? "",invitiationKey: connectionModel?.value?.invitationKey, isIgrantAgent: connectionModel?.value?.isIgrantAgent == "1",orgDetails: orgModel,orgID: AriesCloudAgentHelper.OrgID,isThirdPartyShareSupported: connectionModel?.value?.isThirdPartyShareSupported, completion: { (updatedSuccessfully, updatedRecordId, error) in
                            if(updatedSuccessfully){
                                AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler, id: updatedRecordId, myDid: connectionModel?.value?.myDid ?? "", theirDid: connectionModel?.value?.theirDid ?? "", recipientKey: recipientKey, serviceEndPoint: "", invitiationKey: connectionModel?.value?.invitationKey, type: .cloudAgentActive,orgID: AriesCloudAgentHelper.OrgID, myVerKey: connectionModel?.tags?.myVerKey) { (tagUpdated, error) in
                                    if (tagUpdated){
                                        debugPrint("Cloud Agent Trusted")
                                        Task {
                                            await AriesCloudAgentHelper.shared.checkThirdPartyShared(connectionModel: connectionModel)
                                        }
                                        if let trustPingSuccess = AriesCloudAgentHelper.onTrustPingSuccessBlock,let connctnModel = connectionModel {
                                            trustPingSuccess(connctnModel,recipientKey,verKey)
                                        }else{
                                            debugPrint("No Popup completion method available")
                                        }
                                    }
                                }}
                        })
                    }
                }
            }
        }
    }
    
    func getiGrantOrgDetails(walletHandle: IndyHandle?, reqId: String, completion:@escaping((Bool,OrganisationInfoModel?) -> Void)) {
        
        if let details = AriesCloudAgentHelper.orgDetails {
            completion(true,details)
            return
        }
        let walletHandler = walletHandle ?? 0
        
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithId, searchValue: reqId ) { (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (success, invResult, error) in
                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: invResult)
                let searchConnModel = CloudAgentSearchConnectionModel.decode(withDictionary: resultsDict as NSDictionary? ?? NSDictionary()) as? CloudAgentSearchConnectionModel
                let connModel = searchConnModel?.records?.first
                AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid: connModel?.value?.myDid ?? "", completion: { (metadataReceived,metadata, error) in
                    let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata ?? "")
                    if let verKey = metadataDict?["verkey"] as? String{
                        
                        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnectionInvitation, searchType: .searchWithId,searchValue: connModel?.value?.requestID ?? "") { (success, searchHandler, error) in
                            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (searchSuccess, records, error) in
                                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: records)
                                let invitationRecord = (resultsDict?["records"] as? [[String: Any]])?.first
                                let serviceEndPoint = (invitationRecord?["value"] as? [String: Any])?["serviceEndpoint"] as? String ?? ""
                                let externalRoutingKey = (invitationRecord?["value"] as? [String: Any])?["routing_key"] as? String ?? ""
                                AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connModel?.value?.reciepientKey ?? "", didCom: "", myVerKey: verKey, type: .getIgrantOrgDetail,isRoutingKeyEnabled: false) { (success, orgPackedData, error) in
                                    NetworkManager.shared.sendMsg(isMediator: false, msgData: orgPackedData ?? Data(), url: serviceEndPoint) { (statuscode,orgServerResponseData) in
                                        if statuscode != 200 {
                                            completion(false,nil)
                                            return
                                        }
                                        AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: orgServerResponseData ?? Data()) { (unpackedSuccessfully, orgDetailsData, error) in
                                            if let messageModel = try? JSONSerialization.jsonObject(with: orgDetailsData ?? Data(), options: []) as? [String : Any] {
                                                debugPrint("unpackmsg -- \(messageModel)")
                                                let msgString = (messageModel)["message"] as? String
                                                let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                                let recipient_verkey = (messageModel)["recipient_verkey"] as? String ?? ""
                                                let sender_verkey = (messageModel)["sender_verkey"] as? String ?? ""
                                                debugPrint("Org details received")
                                                let orgInfoModel = OrganisationInfoModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? OrganisationInfoModel
                                                completion(true,orgInfoModel)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                })
            }
        }
    }
    
    
    @available(*, renamed: "checkConnectionWithSameOrgExist(walletHandler:label:theirVerKey:serviceEndPoint:routingKey:imageURL:pollingEnabled:isFromDataExchange:)")
    func checkConnectionWithSameOrgExist(walletHandler: IndyHandle, label: String, theirVerKey: String,serviceEndPoint: String, routingKey: [String]?, imageURL: String,pollingEnabled: Bool = true,isFromDataExchange: Bool,completion: @escaping((Bool,OrganisationInfoModel?,CloudAgentConnectionWalletModel?, String? ) -> Void)){
        AriesCloudAgentHelper.orgDetails = nil
        AriesCloudAgentHelper.OrgID = nil
        let messgeFailure = "Unexpected error. Please try again.".localizedForSDK()
        var messgeSuccess = "Connection success".localizedForSDK()
        
        AriesAgentFunctions.shared.createAndStoreId(walletHandler: walletHandler) { (createDidSuccess, myDid, verKey,error) in
            //            let myDid = myDid
            let myVerKey = verKey
            debugPrint("verKey \(verKey)")

            AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: theirVerKey, didCom: "", myVerKey: myVerKey ?? "", type: .queryIgrantAgent, isRoutingKeyEnabled: false) { (success, data, error) in
                NetworkManager.shared.sendMsg(isMediator: false, msgData: data ?? Data(),url: serviceEndPoint) { (statuscode,responseData) in
                    if statuscode != 200 {
                        completion(false,nil,nil,messgeFailure)
                        UIApplicationUtils.hideLoader()
                        return
                    }
                    if statuscode == 200 {
                        AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responseData ?? Data()) { (success, unpackedData, error) in
                            if let messageModel = try? JSONSerialization.jsonObject(with: unpackedData ?? Data(), options: []) as? [String : Any] {
                                let msgString = (messageModel)["message"] as? String
                                let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                let queryAgentResponseModel = QueryAgentResponseModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? QueryAgentResponseModel
                                if (queryAgentResponseModel?.protocols?.count ?? 0 > 0){
                                    var isThirdPartySharingEnabled = false
                                    if ((queryAgentResponseModel?.protocols?.contains(where: { e in
                                        e.pid?.contains("spec/third-party-data-sharing/1.0") ?? false
                                    })) != nil) {
                                        isThirdPartySharingEnabled = true
                                    }
                                    // TODO: their did is missing here need to discuss
                                    AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey:theirVerKey, didCom: "", myVerKey: myVerKey ?? "", type: .getIgrantOrgDetail,isRoutingKeyEnabled: false) { (success, orgPackedData, error) in
                                        NetworkManager.shared.sendMsg(isMediator: false, msgData: orgPackedData ?? Data(),url: serviceEndPoint) { (statuscode,orgServerResponseData) in
                                            if statuscode != 200 {
                                                completion(false,nil,nil,messgeFailure)
                                                UIApplicationUtils.hideLoader()
                                                return
                                            }
                                            AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: orgServerResponseData ?? Data()) { (unpackedSuccessfully, orgDetailsData, error) in
                                                if let messageModel = try? JSONSerialization.jsonObject(with: orgDetailsData ?? Data(), options: []) as? [String : Any] {
                                                    debugPrint("unpackmsg -- \(messageModel)")
                                                    let msgString = (messageModel)["message"] as? String
                                                    let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                                    let recipient_verkey = (messageModel)["recipient_verkey"] as? String ?? ""
                                                    let sender_verkey = (messageModel)["sender_verkey"] as? String ?? ""
                                                    debugPrint("Org details received")
                                                    let orgDetail = OrganisationInfoModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? OrganisationInfoModel
                                                    
                                                    AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithOrgId,searchValue: orgDetail?.orgId ?? "") { (success, searchHandler, error) in
                                                        AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (success, response, error) in
                                                            if let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response){
                                                                let records = messageModel["records"] as? [[String:Any]]
                                                                let count = messageModel["totalCount"] as? Int ?? 0
                                                                let firstRecord = records?.first
                                                                let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord as NSDictionary? ?? NSDictionary()) as? CloudAgentConnectionWalletModel
                                                                connectionModel?.value?.isThirdPartyShareSupported = isThirdPartySharingEnabled ? "true" : "false"
//                                                                AriesAgentFunctions.shared.updateConnectionModel(walletHandler: walletHandler, id: connectionModel?.value?.requestID ?? "", connectionModel: connectionModel) { success, connection, error in }
                                                                if (count > 0){
                                                                    if !isFromDataExchange {
                                                                        messgeSuccess = "Connection already existing".localizedForSDK()
                                                                    }
                                                                    AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: theirVerKey, didCom: "", myVerKey: myVerKey ?? "", type: .informDuplicateConnection, isRoutingKeyEnabled: false,theirDid: connectionModel?.value?.theirDid ?? "") { (success, data, error) in
                                                                        //                                                            debugPrint("Informed duplicate connection to server")
                                                                        //                                                            completion(false,nil,connectionModel)
                                                                        NetworkManager.shared.sendMsg(isMediator: false, msgData: data ?? Data(),url: serviceEndPoint) { (statuscode,responseData) in
                                                                            if statuscode != 200 {
                                                                                completion(false,nil,nil,messgeFailure)
                                                                                UIApplicationUtils.hideLoader()
                                                                                return
                                                                            }
                                                                            if statuscode == 200 {
                                                                                debugPrint("Informed duplicate connection to server")
                                                                                completion(true,nil,connectionModel,messgeSuccess)
                                                                                return
                                                                            }
                                                                        }
                                                                    }
                                                                } else {
                                                                    completion(false,orgDetail,connectionModel,messgeSuccess)
                                                                    return
                                                                }
                                                            } else {
                                                                completion(false,nil,nil,messgeFailure)
                                                                return
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    //Query Data controller protocol
                                    let query_data_controller = AriesPackMessageTemplates.queryDataControllerProtocol()
                                    Task {
                                        let messgeFailureTwo = "Unexpected error. Please try again.".localizedForSDK()
                                        var messgeSuccessTwo = "Connection success".localizedForSDK()
                                        
                                        do {
                                            let (_, query_pack_data)  =  try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: theirVerKey , didCom: "", myVerKey: myVerKey ?? "", type: .rawDataBody, isRoutingKeyEnabled: false, rawDict: query_data_controller)
                                            
                                            let (statuscode,queryServerResponseData) = await   NetworkManager.shared.sendMsg(isMediator: false, msgData: query_pack_data ,url: serviceEndPoint)
                                            if statuscode != 200 {
                                                completion(false,nil,nil,messgeFailure)
                                                UIApplicationUtils.hideLoader()
                                                return
                                            }
                                            let (_, queryData) = try await     AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: queryServerResponseData ?? Data())
                                            if let messageModel = try? JSONSerialization.jsonObject(with: queryData , options: []) as? [String : Any] {
                                                
                                                let msgString = (messageModel)["message"] as? String
                                                let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                                let queryAgentResponseModel = QueryAgentResponseModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? QueryAgentResponseModel
                                                if (queryAgentResponseModel?.protocols?.count ?? 0 > 0){
                                                    debugPrint(queryAgentResponseModel?.protocols?.description)
                                                    var isThirdPartySharingEnabled = false
                                                    if ((queryAgentResponseModel?.protocols?.contains(where: { e in
                                                        e.pid?.contains("spec/third-party-data-sharing/1.0") ?? false
                                                    })) ?? false) {
                                                        isThirdPartySharingEnabled = true
                                                    }
                                                    let getDataControllerOrg = AriesPackMessageTemplates.getDataControllerOrgDetail(from_myDataDid: RegistryHelper.shared.convertDidSovToDidMyData(didSov: ""), to_myDataDid: RegistryHelper.shared.convertDidSovToDidMyData(didSov:myVerKey ?? ""), isThirdPartyShareSupported: isThirdPartySharingEnabled)
                                                    
                                                    let (pack_success, org_data)  =  try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: theirVerKey , didCom: "", myVerKey: myVerKey ?? "", type: .rawDataBody, isRoutingKeyEnabled: false, rawDict: getDataControllerOrg)
                                                    
                                                    let (statuscode,orgServerResponseData) = await   NetworkManager.shared.sendMsg(isMediator: false, msgData: org_data ?? Data(),url: serviceEndPoint)
                                                    if statuscode != 200 {
                                                        completion(false,nil,nil,messgeFailure)
                                                        UIApplicationUtils.hideLoader()
                                                        return
                                                    }
                                                    let (unpackedSuccessfully, queryData) = try await     AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: orgServerResponseData ?? Data())
                                                    if let messageModel = try? JSONSerialization.jsonObject(with: queryData ?? Data(), options: []) as? [String : Any] {
                                                        
                                                //Org details
                                                debugPrint("unpackmsg -- \(messageModel)")
                                                let msgString = (messageModel)["message"] as? String
                                                let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                                let recipient_verkey = (messageModel)["recipient_verkey"] as? String ?? ""
                                                let sender_verkey = (messageModel)["sender_verkey"] as? String ?? ""
                                                debugPrint("Org details received")
                                                let detail = DataControllerConnectionDetail.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? DataControllerConnectionDetail
                                                var orgDetail: OrganisationInfoModel?
                                                if let det = detail {
                                                    orgDetail  = OrganisationInfoModel.init(dataControllerModel: det)
                                                }
                                                let (open_wallet_success, searchHandler) =  try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithOrgId,searchValue: orgDetail?.orgId ?? "")
                                                let (fetch_success, response) = try await  AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
                                                if let messageModel = UIApplicationUtils.shared.convertToDictionary(text: response) {
                                                    let records = messageModel["records"] as? [[String:Any]]
                                                    let count = messageModel["totalCount"] as? Int ?? 0
                                                    let firstRecord = records?.first
                                                    let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord as NSDictionary? ?? NSDictionary()) as? CloudAgentConnectionWalletModel
//                                                    connectionModel?.value?.isThirdPartyShareSupported = isThirdPartySharingEnabled ? "true" : "false"
//                                                    AriesAgentFunctions.shared.updateConnectionModel(walletHandler: walletHandler, id: connectionModel?.value?.requestID ?? "", connectionModel: connectionModel) { success, connection, error in
//                                                        debugPrint("Third party enbled")
//                                                    }
                                                    if (count > 0){
                                                        if !isFromDataExchange {
                                                            messgeSuccessTwo = "Connection already existing".localizedForSDK()
                                                        }
                                                        
                                                        // Inform duplicate to server
                                                        
                                                        let duplicate_inform_payload = AriesPackMessageTemplates.informDuplicateConnection_new(myVerKey: myVerKey ?? "", recipientKey: theirVerKey, theirDid: connectionModel?.value?.theirDid ?? "", isThirdPartyShareSupported: isThirdPartySharingEnabled)
                                                        let (duplicate_success, duplicate_data) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: theirVerKey , didCom: "", myVerKey: myVerKey ?? "", type: .rawDataBody, isRoutingKeyEnabled: false, rawDict: duplicate_inform_payload)
                                                        
                                                        let (duplicate_statuscode,duplicate_responseData) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: duplicate_data ?? Data(),url: serviceEndPoint)
                                                        if statuscode != 200 {
                                                            completion(false,nil,nil,messgeFailure)
                                                            UIApplicationUtils.hideLoader()
                                                            return
                                                        }
                                                        if statuscode == 200 {
                                                            debugPrint("Informed duplicate connection to server")
                                                            completion(true,nil,connectionModel,messgeSuccessTwo)
                                                            return
                                                        }
                                                    } else {
                                                        completion(false,orgDetail,connectionModel,messgeSuccessTwo)
                                                        return
                                                    }
                                                } else {
                                                    completion(false,nil,nil,messgeFailureTwo)
                                                    return
                                                }
                                                
                                                }else {
                                                    completion(false,nil,nil,messgeFailureTwo)
                                                    return
                                                }
                                                }else {
                                                    completion(false,nil,nil,messgeFailureTwo)
                                                    return
                                                }
                                            }else {
                                                completion(false,nil,nil,messgeFailureTwo)
                                                return
                                            }
                                        } catch {
                                            debugPrint(error.localizedDescription)
                                            completion(false,nil,nil,messgeFailureTwo)
                                            return
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func checkConnectionWithSameOrgExist(walletHandler: IndyHandle, label: String, theirVerKey: String,serviceEndPoint: String, routingKey: [String]?, imageURL: String,pollingEnabled: Bool = true,isFromDataExchange: Bool) async -> (Bool, OrganisationInfoModel?, CloudAgentConnectionWalletModel?) {
        return await withCheckedContinuation { continuation in
            checkConnectionWithSameOrgExist(walletHandler: walletHandler, label: label, theirVerKey: theirVerKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey, imageURL: imageURL, pollingEnabled: pollingEnabled, isFromDataExchange: isFromDataExchange) { result1, result2, result3, message  in
                continuation.resume(returning: (result1, result2, result3))
            }
        }
    }
    
    
    func getConnectionFromRecordId(recordId: String) async -> CloudAgentConnectionWalletModel? {
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        do {
            let (success, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection,searchType: .searchWithId, searchValue: recordId)
            let (fetchedSuccessfully,results) =  try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler)
            if (fetchedSuccessfully){
                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                let resultModel = CloudAgentSearchConnectionModel.decode(withDictionary: resultsDict as NSDictionary? ?? NSDictionary()) as? CloudAgentSearchConnectionModel
                return resultModel?.records?.first ?? nil
            }
            return nil
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    func getConnectionFromVerificationKey(verKey: String) async -> CloudAgentConnectionWalletModel? {
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        do {
            let (success, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection,searchType: .searchWithMyVerKey, searchValue: verKey)
            let (fetchedSuccessfully,results) =  try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler)
            if (fetchedSuccessfully){
                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                let resultModel = CloudAgentSearchConnectionModel.decode(withDictionary: resultsDict as NSDictionary? ?? NSDictionary()) as? CloudAgentSearchConnectionModel
                return resultModel?.records?.first ?? nil
            }
            return nil
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    func getMyVerKeyFromConnectionMetadata(myDid: String) async -> String?{
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        do {
            let (_,metadata) = await try AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid:myDid)
            let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata )
            return metadataDict?["verkey"] as? String
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    func getServiceEndPointAndRoutingKeryFromInvitiation(reqId: String) async -> (String?, [String]?){
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        do {
            let (_, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler,type:AriesAgentFunctions.cloudAgentConnectionInvitation,searchType: .searchWithId, searchValue: reqId)
            let (_,results) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler)
            let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: results)
            let invitationRecord = (resultsDict?["records"] as? [[String: Any]])?.first
            let serviceEndPoint = (invitationRecord?["value"] as? [String: Any])?["serviceEndpoint"] as? String ?? ""
            let externalRoutingKey = (invitationRecord?["value"] as? [String: Any])?["routing_key"] as? [String] ?? []
            return (serviceEndPoint, externalRoutingKey)
        } catch {
            debugPrint(error.localizedDescription)
            return (nil,nil)
        }
    }
    
    func addEBSI_V2_connection(walletHandle: IndyHandle){
        
    }
    
    func checkThirdPartyShared(connectionModel: CloudAgentConnectionWalletModel?) async{
        let query = AriesPackMessageTemplates.queryThirdPartySharingProtocol()
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()

        let myVerKey = await getMyVerKeyFromConnectionMetadata(myDid: connectionModel?.value?.myDid ?? "")
        let (serviceEndPoint,routingKey) = await getServiceEndPointAndRoutingKeryFromInvitiation(reqId: connectionModel?.value?.requestID ?? "")
        guard var connectionModel = connectionModel else {return}
        do{
            let (_, query_pack_data)  =  try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connectionModel.value?.reciepientKey ?? "" , didCom: "", myVerKey: myVerKey ?? "", type: .rawDataBody, isRoutingKeyEnabled: false, rawDict: query)
            
            let (statuscode,queryServerResponseData) = await   NetworkManager.shared.sendMsg(isMediator: false, msgData: query_pack_data ,url: serviceEndPoint)
            if statuscode != 200 {
                UIApplicationUtils.hideLoader()
                return
            }
            let (_, queryData) = try await     AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: queryServerResponseData ?? Data())
            if let messageModel = try? JSONSerialization.jsonObject(with: queryData , options: []) as? [String : Any] {
                let msgString = (messageModel)["message"] as? String
                let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                let queryAgentResponseModel = QueryAgentResponseModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? QueryAgentResponseModel
                if (queryAgentResponseModel?.protocols?.count ?? 0 > 0){
                    debugPrint(queryAgentResponseModel?.protocols?.description)
                    var isThirdPartySharingEnabled = false
                    if ((queryAgentResponseModel?.protocols?.contains(where: { e in
                        e.pid?.contains("spec/third-party-data-sharing/1.0") ?? false
                    })) ?? false) {
                        isThirdPartySharingEnabled = true
                    }
                    connectionModel.value?.isThirdPartyShareSupported = isThirdPartySharingEnabled ? "true" : "false"
                    AriesAgentFunctions.shared.updateConnectionModel(walletHandler: walletHandler, id: connectionModel.value?.requestID ?? "", connectionModel: connectionModel) { success, connection, error in
                        debugPrint("Third party enbled")
                    }
                }
            }
        } catch{
            debugPrint(error.localizedDescription)
        }
    }
}


