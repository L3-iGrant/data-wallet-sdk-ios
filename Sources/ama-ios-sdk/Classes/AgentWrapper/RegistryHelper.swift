//
//  RegistryHelper.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 08/02/22.
//

import Foundation
import Base58Swift
import KeychainSwift
import IndyCWrapper

class RegistryHelper {
    static let shared = RegistryHelper()
    private init() {}
    var myDid: String?
    var myVerKey: String?
    var registryDid: String?
    var registryVerKey: String?
    var didCom: String?
    var routerKey: [String]?
    
    var getMyDataRegistryDid: String {
        let keychain = KeychainSwift()
        return keychain.get("RegistryMyDataDid") ?? ""
    }
    
    func checkForExistingRegistryConnection() async{
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        do {
            if getMyDataRegistryDid.isEmpty{
                await self.createNewRegistryConnection()
            }
        } catch{
            debugPrint(error.localizedDescription)
        }
    }
    
    func createNewRegistryConnection() async {
        if let response = await NetworkManager.shared.getRegistryInvitation() {
            let type = response.invitation?.type ?? ""
            didCom = String(type.split(separator: ";").first ?? "")
            routerKey = response.invitation?.routingKeys ?? []
            await self.newConnectionConfigRegisrtry(label: response.invitation?.label ?? "", recipientKey: response.invitation?.recipientKeys?.first ?? "", serviceEndPoint: response.serviceEndpoint ?? "", routingKey: response.routingKey ?? "")
        }
    }
    
    func newConnectionConfigRegisrtry(label: String, recipientKey: String,serviceEndPoint: String, routingKey: String) async {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        do{
            //Add record - connection
            let (addRecord_Connection_Completed, connectionRecordId) = try await WalletRecord.shared.add(invitationKey: recipientKey, label: label, serviceEndPoint: serviceEndPoint, connectionRecordId: "", walletHandler: walletHandler,type: .registryConnection)
            if !addRecord_Connection_Completed {debugPrint("addRecord Failed"); return}
            
            //Add record - invitation (addWalletRecord_ConnectionInvitation_Completed, connectionInvitationRecordId)
            let (addWalletRecord_ConnectionInvitation_Completed, _) = try await WalletRecord.shared.add(invitationKey: recipientKey, label: label, serviceEndPoint: serviceEndPoint,connectionRecordId: connectionRecordId, walletHandler: walletHandler,type: .registryInvitation)
            if !addWalletRecord_ConnectionInvitation_Completed {debugPrint("addRecord-invitation Failed"); return}
            
            //Get record - connection
            let (getWalletRecordSuccessfully,_) = try await WalletRecord.shared.get(walletHandler: walletHandler,connectionRecordId: connectionRecordId, type: AriesAgentFunctions.registryConnection)
            if !getWalletRecordSuccessfully {debugPrint("getRecord Failed"); return}
            
            //create new did (createDidSuccess, myDid, verKey)
            let (_, myDid, verKey) = try await AriesAgentFunctions.shared.createAndStoreId(walletHandler: walletHandler)
            self.myDid = myDid
            self.myVerKey = verKey
            
            //metadata - metaAdded
            _ = await AriesAgentFunctions.shared.setMetadata(walletHandler: walletHandler, myDid: myDid ,verKey:verKey)
            
            //update connection record (updateWalletRecordSuccess,updateWalletRecordId)
            let (updateWalletRecordSuccess,_) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: walletHandler,recipientKey: recipientKey,label: label, type: UpdateWalletType.initialRegistry, id: connectionRecordId, theirDid: "", myDid: myDid , invitiationKey: recipientKey)
            if !updateWalletRecordSuccess {debugPrint("updateRecord Failed"); return}
            
            //update tags
            let (updateWalletTagSuccess) = try await AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler, id: connectionRecordId, myDid: myDid , theirDid: "",recipientKey: "", serviceEndPoint: "",type: .initialRegistry)
            if !updateWalletTagSuccess {debugPrint("updateTag Failed"); return}
            
            //set search handler for mediator
            let (mediatorSearchHandlerCreated, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: DidDocTypes.mediatorDidDoc.rawValue,searchType: .withoutQuery)
            if !mediatorSearchHandlerCreated {debugPrint("searchHandler Failed"); return}
            
            //fetch record mediator
            let (fetchedSuccessfully,results) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler)
            if !fetchedSuccessfully {debugPrint("fetch record Failed"); return}
            let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: results)
            let docModel = SearchDidDocModel.decode(withDictionary: resultsDict as NSDictionary? ?? NSDictionary()) as? SearchDidDocModel
            let mediatorRoutingKey = docModel?.records?.first?.value?.service?.first?.routingKeys?.first ?? ""
            let mediatorRecipientKey = docModel?.records?.first?.value?.service?.first?.recipientKeys?.first ?? ""
            let mediatorServiceEndPoint = docModel?.records?.first?.value?.service?.first?.serviceEndpoint ?? ""
            //pack (packedSuccessfully, packedData) - to mediator
            let (packedSuccessfully, packedData) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, label: label, recipientKey: mediatorRecipientKey, id: connectionRecordId,  didCom: didCom ?? "", myDid: myDid, myVerKey: WalletViewModel.mediatorVerKey ?? "" , serviceEndPoint: serviceEndPoint, routingKey: mediatorRoutingKey , routedestination: verKey, deleteItemId: "", type: .addRoute,isRoutingKeyEnabled: false, externalRoutingKey: [])
            
            //send msg - (statuscode,receivedData) to mediator
            let (statuscode,_) = await NetworkManager.shared.sendMsg(isMediator: true, msgData: packedData )
            if statuscode != 200 {debugPrint("send msg to mediator Failed"); return}
            
            //pack msg (packMsgSuccess, messageData) to registry
            let (packMsgSuccess, messageData) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler,label: label, recipientKey: recipientKey,  id: connectionRecordId,  didCom: didCom ?? "", myDid: myDid , myVerKey: verKey ,serviceEndPoint: serviceEndPoint, routingKey: mediatorRoutingKey, deleteItemId: "", type: .initialCloudAgent,isRoutingKeyEnabled: routerKey?.count ?? 0 > 0, externalRoutingKey: routerKey ?? [])
            if !packMsgSuccess {debugPrint("pack msg Failed"); return}
            
            //send msg - (statuscode_registry,responsedata_registry) to registry
            let (statuscode_registry,responsedata_registry) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: messageData,url: serviceEndPoint)
            if statuscode_registry != 200 { debugPrint("send msg to registry Failed")}
            
            //unpack - (unpackedSuccessfully, unpackedData)
            let (unpackedSuccessfully, unpackedData) = try await AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responsedata_registry ?? Data())
            guard let messageModel = try? JSONSerialization.jsonObject(with: unpackedData, options: []) as? [String : Any] else {return}
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
            
            let theirDid = sigDataDict["DID"] as? String ?? ""
            var didDoc = sigDataDict["DIDDoc"] as? [String:Any]
            let dataDic = (didDoc?["service"] as? [[String:Any]])?.first
            let senderVerKey = (dataDic?["recipientKeys"] as? [String])?.first ?? ""
            let serviceEndPoint = (dataDic?["serviceEndpoint"] as? String) ?? ""
            let routingKey = (dataDic?["serviceEndpoint"] as? String) ?? ""
            if let externalRoutingKey = (dataDic?["routingKeys"] as? [String]) {
                routerKey = externalRoutingKey
            }
            registryDid = theirDid
            registryVerKey = senderVerKey
                        
            //                        add Diddoc (didDocRecordAdded, didDocRecordId)
            let (didDocRecordAdded, _) = try await AriesAgentFunctions.shared.addWalletRecord_DidDoc(walletHandler: walletHandler, invitationKey: recipientKey, theirDid: theirDid , recipientKey: senderVerKey , serviceEndPoint: serviceEndPoint,routingKey: routingKey, type: DidDocTypes.registryDidDoc)
            if !didDocRecordAdded {debugPrint("add diddoc record Failed"); return}
            
            //add DidKey (updatedSuccessfully, updatedRecordId)
            let (updatedSuccessfully, _) = try await AriesAgentFunctions.shared.addWalletRecord_DidKey(walletHandler: walletHandler, theirDid: theirDid, recipientKey: senderVerKey, type: DidKeyTypes.registryDidKey)
            if !updatedSuccessfully {debugPrint("add didkey record Failed"); return}
            
            //updateWallet record (updateWalletSuccessfully, updatedWalletRecordId)
            let (updateWalletSuccessfully, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: walletHandler,recipientKey: senderVerKey,label: label, type: .updateRegistry, id: connectionRecordId, theirDid: theirDid, myDid: myDid ,invitiationKey: recipientKey)
            if !updateWalletSuccessfully {debugPrint("update record Failed"); return}
            
            //update tags
            let success = try await AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler, id: connectionRecordId, myDid: myDid , theirDid: theirDid, recipientKey: senderVerKey, serviceEndPoint: "", invitiationKey: recipientKey, type: .updateRegistry)
            if !success {debugPrint("updateTag Failed"); return}
            
            //trust ping
            let (packedSuccessfully_trustPing, packedData_trustPing) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, label: label, recipientKey: recipientKey, id: connectionRecordId, didCom: didCom ?? "", myDid: myDid, myVerKey: verKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey,deleteItemId: "", type: .trustPing, isRoutingKeyEnabled: routerKey?.count ?? 0 > 0, externalRoutingKey: routerKey ?? [])
            
            let (statuscode_trustPing,responseData_trustPing) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData_trustPing,url: serviceEndPoint)
            if statuscode_trustPing != 200 { debugPrint("Trust ping failed")}
            debugPrint("////****////  REGISTRY CONNECTED ////****////")
            
            //create new did
            let (_, anchor_myDid, anchor_verKey) = try await AriesAgentFunctions.shared.createAndStoreId(walletHandler: walletHandler)
            
            let didMyData = self.convertDidSovToDidMyData(didSov: anchor_verKey)
            let newDidDoc = createNewDidDoc(myDataDid: didMyData, mediatorEndPoint: mediatorServiceEndPoint)
            let body_sig = await createSignature(payload: newDidDoc.toString() ?? "", verKey: anchor_verKey, walletHandle: walletHandler)
            
            // Create my data did -- pack
            let (packedSuccessfully_createMyDataDid, packedData_createMyDataDid) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: registryVerKey ?? "", didCom: "", myVerKey: myVerKey ?? "", type: .createMyDataDid, isRoutingKeyEnabled: false,to_myDataDid: self.convertDidSovToDidMyData(didSov: registryVerKey ?? ""), from_myDataDid: self.convertDidSovToDidMyData(didSov: myVerKey ?? ""), bodySig: body_sig)
            if !packedSuccessfully_createMyDataDid {debugPrint("pack msg Failed"); return}
            
            let (statuscode_createMyDataDid,responseData_createMyDataDid) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData_createMyDataDid, url: serviceEndPoint)
            if statuscode_createMyDataDid != 200 { debugPrint("createMyDataDid send msg failed")}
            let keychain = KeychainSwift()
            keychain.set(didMyData, forKey: "RegistryMyDataDid")
            
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    func convertDidSovToDidMyData(didSov: String) -> String{
        let decodedBytes = Base58.base58Decode(didSov)
        debugPrint(decodedBytes ?? [])
        // unicode to utf8 "\xed\x01" = [5c 78 65 64 5c 78 30 31]
        let multicodeByreArray: [UInt8] = [237, 1]
        var hexWithMulticode = multicodeByreArray
        hexWithMulticode.append(contentsOf: decodedBytes ?? [])
        let encodedString = Base58.base58Encode(hexWithMulticode)
        let finalString = "z" + encodedString
        debugPrint(finalString)
        return "did:mydata:" + finalString
    }
    
    func convertDidMyDataToDidSov(didMyData: String) -> String {
        
        // remove prefix ‘did:mydata:'
        var myDid = didMyData.replacingOccurrences(of: "did:mydata:", with: "")
        
        // remove prefix ‘z’
        myDid.removeFirst()
        
        // 2. base58 decode
        let encoded = Base58.base58Decode(myDid)
        
        // remove unicode '\xed\x01' ir first two item in array
        let multicodeRemovedArray = encoded?.dropFirst(2)
        
        let didSovByte = Array(multicodeRemovedArray ?? [])
        
        // 3. return base58 encode the did:sov identifier and obtain the public key bytes.
        return Base58.base58Encode(didSovByte)
    }
    
    func createSignature(payload: String, verKey: String, walletHandle: IndyHandle) async -> [String: String]{
        // current time in epoch seconds (UTC timestamp)
        let etime = (Int(Date().timeIntervalSince1970))
        // convert etime to 8 byte, big-endian encoded string.
//        let etimeByte = IntToUnsignedBigEndian.pack(value: etime)
        let etimeByte = withUnsafeBytes(of: etime.bigEndian) { Data($0) }

//        let etimeByte = etime.data(using: .utf8) ?? Data()
        
        //prefix ascii encoded value with etime
        let payloadASCII = payload.data(using: .ascii) ?? Data()
        let combineValue = etimeByte + payloadASCII
        
        do {
            let (_,signature) = try await AgentWrapper.shared.signMessage(message: combineValue, key: verKey, walletHandle: walletHandle)
            let signatureData = [UInt8](signature ?? Data())
            let eSignature = self.signEncode(data: signatureData)
            let ecombined_value = self.signEncode(data: [UInt8](combineValue))
            let bodySig: [String: String] = [
                "@type" : "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/signature/1.0/ed25519Sha512_single",
                "signature": eSignature,
                "sig_data": ecombined_value,
                "signer": verKey
            ]
            return bodySig
            
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    func signEncode(data: [UInt8]) -> String {
        // base64 URL safe encode signature
        let encodedData = Base64FS.encode(data: data)
        //convert bytes to ascii string
        let signString = String(bytes: encodedData, encoding: .ascii)
        //strip = padding characters from right end of the ascii string
        let eSignature = signString?.stringByRemovingAll(subStrings: ["="])
        return eSignature ?? ""
    }
    
    func createNewDidDoc(myDataDid: String, mediatorEndPoint: String) -> [String: Any]{
        return [
            "@context": "https://w3id.org/did/v1",
            "id": myDataDid,
            "verification_method": [
                [
                    "id": myDataDid + "#1",
                    "type": "Ed25519VerificationKey2018",
                    "controller": myDataDid,
                    "publicKeyBase58": "z6Mko3htTeK94jiX4RGAFztRfo65NjWm31y1He1SUn5otY7X"
                ]
            ],
            "authentication": [
                [
                    "type": "Ed25519SignatureAuthentication2018",
                    "publicKey":  myDataDid + "#1"
                ]
            ],
            "service": [
                [
                    "id": myDataDid + ";didcomm",
                    "type": "DIDComm",
                    "priority": 0,
                    "recipientKeys": [
                        myDataDid.replacingOccurrences(of: "did:mydata:", with: "")
                    ],
                    "serviceEndpoint": mediatorEndPoint
                ]
            ]
        ]
    }
}

