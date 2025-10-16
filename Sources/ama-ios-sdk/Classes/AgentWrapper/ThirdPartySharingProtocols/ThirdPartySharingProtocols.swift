//
//  ThirdPartySharingProtocols.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 18/09/22.
//

import Foundation
import IndyCWrapper

struct ThirdPartySharingProtocols {
    
    static func fetchPreferences(connectionModel: CloudAgentConnectionWalletModel) async -> ThirdPartyDecodable?{
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        let msg = [
            "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/third-party-data-sharing/1.0/fetch-preferences",
            "@id": connectionModel.value?.orgDetails?.orgId ?? "",
            "~transport": [
                "return_route": "all"
            ]
        ] as [String : Any]
        do {
            let myVer = await AriesCloudAgentHelper.shared.getMyVerKeyFromConnectionMetadata(myDid: connectionModel.value?.myDid ?? "") ?? ""
            let (serviceEndPoint, _) = await AriesCloudAgentHelper.shared.getServiceEndPointAndRoutingKeryFromInvitiation(reqId: connectionModel.value?.requestID ?? "")
            
            let (_, packedData) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connectionModel.value?.reciepientKey ?? "", didCom: "", myVerKey: myVer, type: .rawDataBody, isRoutingKeyEnabled: false, rawDict: msg)
            let (_,responseData) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData, url: serviceEndPoint)
            let (_, unpackedData) = try await AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responseData ?? Data())
            if let messageModel = try JSONSerialization.jsonObject(with: unpackedData , options: []) as? [String : Any] {
                print("unpackmsg fetchPreferences -- \(messageModel)")
                let msgString = (messageModel)["message"] as? String
                let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                let body = msgDict?["body"] as? [String: Any?]
                let model = ThirdPartyDecodable.decode(withDictionary: body as NSDictionary? ?? NSDictionary()) as? ThirdPartyDecodable
                return model
            } else {
                return nil
            }
            
        } catch{
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    static func updatePreferences(connectionModel: CloudAgentConnectionWalletModel, ddaInstanceId: String, daInstanceId: String, state:String) async -> Bool{
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        let msg = [
            "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/third-party-data-sharing/1.0/update-preferences",
            "@id": connectionModel.value?.orgId ?? "",
            "body": [
              "dda_instance_id": ddaInstanceId,
              "da_instance_id": daInstanceId,
              "state": state
            ]
        ] as [String : Any]
        
        do {
            let myVer = await AriesCloudAgentHelper.shared.getMyVerKeyFromConnectionMetadata(myDid: connectionModel.value?.myDid ?? "") ?? ""
            let (serviceEndPoint, _) = await AriesCloudAgentHelper.shared.getServiceEndPointAndRoutingKeryFromInvitiation(reqId: connectionModel.value?.requestID ?? "")
            
            let (_, packedData) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connectionModel.value?.reciepientKey ?? "", didCom: "", myVerKey: myVer, type: .rawDataBody, isRoutingKeyEnabled: false, rawDict: msg)
            let (statusCode,_) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData, url: serviceEndPoint ?? "")
            if statusCode == 200 {
                return true
            } else {
                return false
            }
        } catch{
            debugPrint(error.localizedDescription)
            return false
        }
    }
    
    static func updateAgreementLevel(connectionModel: CloudAgentConnectionWalletModel, instanceId: String, state:String) async -> Bool{
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        let msg = [
            "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/data-agreement/1.0/permissions",
            "@id": connectionModel.value?.orgId ?? "",
            "body": [
              "instance_id": instanceId,
              "state": state
            ]
          ] as [String : Any]
        
        do {
            let myVer = await AriesCloudAgentHelper.shared.getMyVerKeyFromConnectionMetadata(myDid: connectionModel.value?.myDid ?? "") ?? ""
            let (serviceEndPoint, _) = await AriesCloudAgentHelper.shared.getServiceEndPointAndRoutingKeryFromInvitiation(reqId: connectionModel.value?.requestID ?? "")
            
            let (_, packedData) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connectionModel.value?.reciepientKey ?? "", didCom: "", myVerKey: myVer, type: .rawDataBody, isRoutingKeyEnabled: false, rawDict: msg)
            let (statusCode,unpackedData) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData, url: serviceEndPoint ?? "")
            if statusCode == 200 {
                return true
            } else {
                return false
            }
        } catch{
            debugPrint(error.localizedDescription)
            return false
        }
    }
}
