//
//  ValidateCredential.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 22/02/22.
//

import Foundation
import IndyCWrapper

struct ValidateCredential {
    static var shared = ValidateCredential()
    private init(){}
    
    fileprivate func verifyCredential(_ recordId: String, _ newDataAgreemnt: DataAgreementContext, _ proof_chain: Bool, _ new_proof: Proof?, _ walletHandler: IndyHandle,connectionModel: CloudAgentConnectionWalletModel?) async -> Bool{
        do{
            var connectionModel = connectionModel
            var myDid = connectionModel?.value?.myDid
            if myDid == nil {
                connectionModel = await AriesCloudAgentHelper.shared.getConnectionFromRecordId(recordId: recordId)
                myDid = connectionModel?.value?.myDid
            }
            let myVerKey = await AriesCloudAgentHelper.shared.getMyVerKeyFromConnectionMetadata(myDid: myDid ?? "")
            
            let jsonLD =  [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/json-ld/1.0/processed-data",
                "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "from": RegistryHelper.shared.convertDidSovToDidMyData(didSov: connectionModel?.value?.myDid ?? ""),
                "created_time": Date().epochTime,
                "to": RegistryHelper.shared.convertDidSovToDidMyData(didSov: connectionModel?.value?.theirDid ?? ""),
                "body": [
                    "data_base64": newDataAgreemnt.message?.body.dictionary?.toString()?.encodeBase64() ?? "",
                    "signature_options_base64": proof_chain ? (new_proof.dictionary?.toString()?.encodeBase64() ?? "") : (newDataAgreemnt.message?.body?.proof?.dictionary?.toString()?.encodeBase64() ?? ""),
                    "proof_chain": proof_chain
                ],
                "~transport": [
                    "return_route": "all"
                ]
            ] as [String : Any]
            
            let (_, packedData) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connectionModel?.value?.reciepientKey ?? "", didCom: "", myVerKey: myVerKey ?? "", type: .rawDataBody, isRoutingKeyEnabled: connectionModel?.value?.routingKey?.isNotEmpty ?? false, externalRoutingKey: connectionModel?.value?.routingKey, rawDict: jsonLD)
            let (serviceEndPoint, _) = await AriesCloudAgentHelper.shared.getServiceEndPointAndRoutingKeryFromInvitiation(reqId: recordId)
            let (statuscode,responseData) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData, url: serviceEndPoint ?? "")
            if statuscode != 200 { debugPrint("Sign JsonLD send msg failed")}
            
            //json-ld/1.0/processed-data-response
            let (_, unpackedData) = try await AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responseData ?? Data())
            let messageModel = try? JSONSerialization.jsonObject(with: unpackedData , options: []) as? [String : Any]
            print("unpackmsg -- \(messageModel)")
            let msgString = messageModel?["message"] as? String
            let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
            let bodyDict =  msgDict?["body"] as? [String: Any]
            let hex_hash = bodyDict?["combined_hash_base64"] as? String ?? ""
            
            // framed
            let framed_base64 = bodyDict?["framed_base64"] as? String ?? ""
            let framed = framed_base64.decodeBase64() ?? ""
            let framedDict = UIApplicationUtils.shared.convertToDictionary(text: framed)
            let framed_proof_dict = framedDict?["proof"] as? [String: Any] ?? [String: Any]()
            let framed_proof = Proof.decode(withDictionary: framed_proof_dict) as? Proof
            
            //construct bytes from hex_hash
            let hex_hash_decoded = hex_hash.decodeBase64() ?? ""
            let bytes_hex_hash = hex_hash_decoded.hexadecimal ?? Data() //try Base64.decode(hex_hash)
            
            let proofValue = (proof_chain ? new_proof?.proofValue : framed_proof?.proofValue) ?? ""
            
            //split JWS using " . . " delimiter to obtain encoded header and signature.
            //since swift only support split with character we are replacing .. with ~
            let modified_proofValue = proofValue.replacingOccurrences(of: "..", with: "~")
            let encoded_header = String(modified_proofValue.split(separator: "~").first ?? "")
            let signature = String(modified_proofValue.split(separator: "~").last ?? "")
            
            //encoded header is "eyJiNjQiOmZhbHNlLCJjcml0IjpbImI2NCJdLCJhbGciOiJFZERTQSJ9" as mentioned in sign in section.
            debugPrint(encoded_header)
            let headerString = encoded_header.decodeBase64() ?? ""
            let headerDict = UIApplicationUtils.shared.convertToDictionary(text: headerString) ?? [String: Any]()
            let headerModel = SignatureHeader.decode(withDictionary: headerDict as [String : Any]) as? SignatureHeader
            
            if headerModel?.alg == nil || headerModel?.crit == nil || headerModel?.b64 == nil{
                return false
            }
            
            //base64 decode signature
            let payload = signature
            let payload_padding = payload.padding(toLength: ((payload.count+3)/4)*4,withPad: "=",startingAt: 0)
            //let payloadData = payload_padding.data(using: .ascii) ?? Data()
            let decoded_sign = try Base64.decode(payload_padding)//Base64FS.decode(data: [UInt8](payloadData))
            let signature_data = Data.init(bytes: decoded_sign, count: decoded_sign.count)
            
            //construct JWS payload = encoded_header + “.” + bytes_hex_hash
            let JWS_payload = ((encoded_header + ".").data(using: .utf8) ?? Data()) + bytes_hex_hash
                       
            let verificationMethod = proof_chain ? new_proof?.verificationMethod : newDataAgreemnt.message?.body?.proof?.verificationMethod
            let recipientKey = RegistryHelper.shared.convertDidMyDataToDidSov(didMyData: verificationMethod ?? "")
            
            //indy SDK wallet.verify_message(jws, decoded_signature, verkey)
            let (error,verified) = await AgentWrapper.shared.verifySignature(signature: signature_data, message: JWS_payload, key:recipientKey , walletHandle: walletHandler)
            
            return verified
            
        } catch {
            debugPrint(error.localizedDescription)
            return false
        }
    }
    
    func validateCredential(dataAgreement: DataAgreementContext, recordId: String,connectionModel: CloudAgentConnectionWalletModel?) async -> Bool{
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
       
        guard let newDataAgreemnt = dataAgreement.copy() as? DataAgreementContext else {return false}
            let drop_proof_chain = true
            var proof_chain = false
            var old_proof: Proof?
            var new_proof: Proof?
            
            if let proofChain = newDataAgreemnt.message?.body?.proofChain, proofChain.isNotEmpty {
                proof_chain = true
                if drop_proof_chain {
                    old_proof = proofChain[0]
                    new_proof = proofChain[1]
                    newDataAgreemnt.message?.body?.proofChain = nil
                    newDataAgreemnt.message?.body?.proof = old_proof
                } else {
                    new_proof = proofChain.last
                    newDataAgreemnt.message?.body?.proofChain?.removeLast()
                }
            } else {
                proof_chain = false
            }
        return await verifyCredential(recordId, newDataAgreemnt, proof_chain, new_proof, walletHandler, connectionModel: connectionModel)
    }
    
    func validateCredentialFromHistory(dataAgreement: DataAgreementContext, recordId: String, connectionModel: CloudAgentConnectionWalletModel?) async -> Bool{
        let proofChain = dataAgreement.message?.body?.proofChain
        let genesis_proof = proofChain?.first
        
        //construct genesis_data_agreement
        guard let genesis_data_agreement = dataAgreement.copy() as? DataAgreementContext, let original_data_agreement = dataAgreement.copy() as? DataAgreementContext else {return false}
        genesis_data_agreement.message?.body?.proof = genesis_proof
        genesis_data_agreement.message?.body?.proofChain = nil
        //genesis_data_agreement[“event”] = data_agreement[“event”][0]
        if let event = dataAgreement.message?.body?.event?.first {
            genesis_data_agreement.message?.body?.event = [event]
        }
        
        let valid_genesis = await validateCredential(dataAgreement: genesis_data_agreement, recordId: recordId, connectionModel: connectionModel)
        let valid_original = await validateCredential(dataAgreement: dataAgreement, recordId: recordId, connectionModel: connectionModel)
        return valid_genesis && valid_original
    }
}
