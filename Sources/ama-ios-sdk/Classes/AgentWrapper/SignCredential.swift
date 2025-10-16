//
//  SignCredential.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 21/02/22.
//

import Foundation
import JSONSchema
import IndyCWrapper

struct SignatureHeader: Codable {
    let alg: String
    let b64: Bool
    let crit: [String]
}

struct SignCredential {
    static var shared = SignCredential()
    private init(){}
    func signCredential(dataAgreement: DataAgreementContext, recordId: String) async -> ([String : Any]?,DataAgreementContext?){
        do {
            let connectionModel = await AriesCloudAgentHelper.shared.getConnectionFromRecordId(recordId: recordId)
            if connectionModel?.value?.isThirdPartyShareSupported != "true" {
                return await signCredentialForConnectionWithoutThirdPartySupport(dataAgreement: dataAgreement, recordId: recordId, connectionModel: connectionModel)
            }
        let reqId = recordId
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        //if ‘proof’ node in the data agreement.
        let proof_chain = dataAgreement.message?.body?.proof != nil
        
        //modified_proof
        var modified_proof = dataAgreement.message?.body?.proof
        modified_proof?.jws = dataAgreement.message?.body?.proof?.proofValue
        modified_proof?.proofValue = nil
        modified_proof?.context = "https://w3id.org/security/v2"
        let copy_dataAgreementContext = dataAgreement
       
            let myVerKey = await AriesCloudAgentHelper.shared.getMyVerKeyFromConnectionMetadata(myDid: connectionModel?.value?.myDid ?? "")
            
            // Add a new “event” to the existing data agreement
//            let new_event = Event.init(state: "accept", did: (RegistryHelper.shared.convertDidSovToDidMyData(didSov: myVerKey ?? "")), id: "\(RegistryHelper.shared.convertDidSovToDidMyData(didSov: myVerKey ?? ""))#2", timeStamp: AgentWrapper.shared.getCurrentDateTime(format: "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"))
//            copy_dataAgreementContext.message?.body?.event?.append(new_event)
           // let signature_option_id = "urn:uuid:\(AgentWrapper.shared.generateRandomId_BaseUID4())"
            let signature_option_id = "did:sov:\(connectionModel?.value?.myDid ?? "")#2"
            let signature_option = SignatureOption.init(
                id: signature_option_id,
                type: "Ed25519Signature2018",
                created: AgentWrapper.shared.getCurrentDateTime(format: "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"),
                verificationMethod: myVerKey ?? "",
                proofPurpose: "authentication")
           
//            let trace_initiate = Performance.sharedInstance().trace(name: "Sign -- processed-data")
//            trace_initiate?.start()
            // json-ld/1.0/processed-data
            let jsonLD = [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/json-ld/1.0/processed-data",
                    "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                    "body": [
                        "data_base64": modified_proof.dictionary?.toString()?.encodeBase64() ?? "",
                        "signature_options_base64": signature_option.dictionary?.toString()?.encodeBase64() ?? "",
                    ],
                "~transport": [
                  "return_route": "all"
                ]
            ] as [String : Any]
            
            let (_, packedData) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connectionModel?.value?.reciepientKey ?? "", didCom: "", myVerKey: myVerKey ?? "", type: .rawDataBody, isRoutingKeyEnabled: connectionModel?.value?.routingKey?.isNotEmpty ?? false, externalRoutingKey: connectionModel?.value?.routingKey, rawDict: jsonLD)
            let (serviceEndPoint, _) = await AriesCloudAgentHelper.shared.getServiceEndPointAndRoutingKeryFromInvitiation(reqId: reqId ?? "")
            let (statuscode,responseData) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData, url: serviceEndPoint ?? "")
            if statuscode != 200 { debugPrint("Sign JsonLD send msg failed")}
//            trace_initiate?.stop()
            //json-ld/1.0/processed-data-response
            let (_, unpackedData) = try await AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responseData ?? Data())
            let messageModel = try? JSONSerialization.jsonObject(with: unpackedData , options: []) as? [String : Any]
            print("unpackmsg -- \(messageModel)")
            let msgString = (messageModel)?["message"] as? String
            let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
            let bodyDict =  msgDict?["body"] as? [String: Any]
            let hex_hash = bodyDict?["combined_hash_base64"] as? String ?? ""
            
            //construct bytes from hex_hash
            let hex_hash_decoded = hex_hash.decodeBase64() ?? ""
            let bytes_hex_hash = hex_hash_decoded.hexadecimal ?? Data() //try Base64.decode(hex_hash)
            
            // 8.2.2 Sign JWS
            //construct jws using jws_sign(bytes_hex_hash, verkey
            let jws = await self.createJWS(verKey: myVerKey ?? "", bytes_hex_hash: bytes_hex_hash) ?? ""
            
            var newDataAgreement = copy_dataAgreementContext
            //if ‘proofChain’ not in data agreement.
            if dataAgreement.message?.body?.proofChain == nil{
                if !proof_chain {
                    let newProof = Proof.init(created: signature_option.created, proofPurpose: signature_option.proofPurpose, id: signature_option.id, verificationMethod: signature_option.verificationMethod, proofValue: jws, type: signature_option.type)
                    newDataAgreement.message?.body?.proof = newProof
                } else {
                    //old_proof = pop ‘proof’ from data agreement
                    if let old_proof = dataAgreement.message?.body?.proof{
                        let newProof = Proof.init(created: signature_option.created, proofPurpose: signature_option.proofPurpose, id: signature_option.id, verificationMethod: signature_option.verificationMethod, proofValue: jws, type: signature_option.type)
                        //pop ‘proof’ from data agreement
                        newDataAgreement.message?.body?.proof = nil
                        newDataAgreement.message?.body?.proofChain = [old_proof,newProof]
                    }
                }
            } else {
                let newProof = Proof.init(created: signature_option.created, proofPurpose: signature_option.proofPurpose, id: signature_option.id, verificationMethod: signature_option.verificationMethod, proofValue: jws, type: signature_option.type)
                newDataAgreement.message?.body?.proofChain?.append(newProof)
            }
            
            return (createDataAgreemntContextForCertificateRequest(dataAgreement: newDataAgreement),newDataAgreement)
        } catch {
            debugPrint(error.localizedDescription)
            return (nil,nil)
        }
    }
    
    func createJWS(verKey: String, bytes_hex_hash: Data) async -> String?{
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        do {
            //JWS header
//            let JWSHeader: KeyValuePairs<String,Any> = [
//                "b64": false,
//                "alg": "EdDSA",
//                "crit": [
//                    "b64"
//                ]
//            ]
            
            //encoded_header = base64 encode the header
            let encoded_header = "eyJiNjQiOmZhbHNlLCJjcml0IjpbImI2NCJdLCJhbGciOiJFZERTQSJ9"//JWSHeader.toString()?.encodeBase64() ?? ""

            //construct JWS payload = utf8_encode(encoded_header + “.”) + bytes_hex_hash
            let JWS_payload = ((encoded_header + ".").data(using: .utf8) ?? Data()) + bytes_hex_hash
            debugPrint([UInt8](JWS_payload))

            //sign JWS payload (indy SDK wallet.sign(payload, verkey(did:mydata identifier with multi codec prefix ?)))
            let (error,signature) = await AgentWrapper.shared.signMessage(message: JWS_payload, key: verKey, walletHandle: walletHandler)
            debugPrint("Error --- \(error?.localizedDescription)")
            //encode signature
            let encodeSignature = RegistryHelper.shared.signEncode(data: [UInt8](signature ?? Data()))
            
            //Construct JWS = encoded_header + ".." + encoded_signature
            let JWS = encoded_header + ".." + encodeSignature
            
            return JWS
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    private func createDataAgreemntContextForCertificateRequest(dataAgreement: DataAgreementContext) -> [String: Any]{
        return [
            "message_type": "protocol",
            "message": [
              "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/data-agreement-negotiation/1.0/accept",
              "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
              "body": dataAgreement.message?.body.dictionary ?? [:],
            ]
          ]
    }
}


extension SignCredential {
    //Old protocol
    func signCredentialForConnectionWithoutThirdPartySupport(dataAgreement: DataAgreementContext, recordId: String, connectionModel: CloudAgentConnectionWalletModel?) async -> ([String : Any]?,DataAgreementContext?){
        let reqId = recordId
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        //if ‘proof’ node in the data agreement.
        let proof_chain = dataAgreement.message?.body?.proof != nil
        var copy_dataAgreementContext = dataAgreement
        do {
            let myVerKey = await AriesCloudAgentHelper.shared.getMyVerKeyFromConnectionMetadata(myDid: connectionModel?.value?.myDid ?? "")
            
            // Add a new “event” to the existing data agreement
            let new_event = Event.init(state: "accept", did: (RegistryHelper.shared.convertDidSovToDidMyData(didSov: myVerKey ?? "")), id: "\(RegistryHelper.shared.convertDidSovToDidMyData(didSov: myVerKey ?? ""))#2", timeStamp: AgentWrapper.shared.getCurrentDateTime(format: "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"))
            copy_dataAgreementContext.message?.body?.event?.append(new_event)
            let signature_option = SignatureOption.init(id: "\(RegistryHelper.shared.convertDidSovToDidMyData(didSov: myVerKey ?? ""))#2", type: "Ed25519Signature2018", created: AgentWrapper.shared.getCurrentDateTime(format: "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"), verificationMethod: (RegistryHelper.shared.convertDidSovToDidMyData(didSov: myVerKey ?? "")), proofPurpose: "contractAgreement")
           
//            let trace_initiate = Performance.sharedInstance().trace(name: "Sign -- processed-data")
//            trace_initiate?.start()
            // json-ld/1.0/processed-data
            let jsonLD = [
                "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/json-ld/1.0/processed-data",
                    "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "from": RegistryHelper.shared.convertDidSovToDidMyData(didSov: connectionModel?.value?.myDid ?? ""),
                "created_time": Date().epochTime,
                    "to": RegistryHelper.shared.convertDidSovToDidMyData(didSov: connectionModel?.value?.theirDid ?? ""),
                    "body": [
                        "data_base64": copy_dataAgreementContext.message?.body.dictionary?.toString()?.encodeBase64() ?? "",
                        "signature_options_base64": signature_option.dictionary?.toString()?.encodeBase64() ?? "",
                        "proof_chain": true
                    ],
                "~transport": [
                  "return_route": "all"
                ]
            ] as [String : Any]
            
            let (_, packedData) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connectionModel?.value?.reciepientKey ?? "", didCom: "", myVerKey: myVerKey ?? "", type: .rawDataBody, isRoutingKeyEnabled: connectionModel?.value?.routingKey?.isNotEmpty ?? false, externalRoutingKey: connectionModel?.value?.routingKey, rawDict: jsonLD)
            let (serviceEndPoint, _) = await AriesCloudAgentHelper.shared.getServiceEndPointAndRoutingKeryFromInvitiation(reqId: reqId ?? "")
            let (statuscode,responseData) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData, url: serviceEndPoint ?? "")
            if statuscode != 200 { debugPrint("Sign JsonLD send msg failed")}
//            trace_initiate?.stop()
            //json-ld/1.0/processed-data-response
            let (_, unpackedData) = try await AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responseData ?? Data())
            let messageModel = try? JSONSerialization.jsonObject(with: unpackedData , options: []) as? [String : Any]
            print("unpackmsg -- \(messageModel)")
            let msgString = (messageModel)?["message"] as? String
            let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
            let bodyDict =  msgDict?["body"] as? [String: Any]
            let hex_hash = bodyDict?["combined_hash_base64"] as? String ?? ""
            
            //construct bytes from hex_hash
            let hex_hash_decoded = hex_hash.decodeBase64() ?? ""
            let bytes_hex_hash = hex_hash_decoded.hexadecimal ?? Data() //try Base64.decode(hex_hash)
            
            // 8.2.2 Sign JWS
            //construct jws using jws_sign(bytes_hex_hash, verkey
            let jws = await self.createJWS(verKey: myVerKey ?? "", bytes_hex_hash: bytes_hex_hash) ?? ""
            
            var newDataAgreement = copy_dataAgreementContext
            //if ‘proofChain’ not in data agreement.
            if dataAgreement.message?.body?.proofChain == nil{
                if !proof_chain {
                    let newProof = Proof.init(created: signature_option.created, proofPurpose: signature_option.proofPurpose, id: signature_option.id, verificationMethod: signature_option.verificationMethod, proofValue: jws, type: signature_option.type)
                    newDataAgreement.message?.body?.proof = newProof
                } else {
                    //old_proof = pop ‘proof’ from data agreement
                    if let old_proof = dataAgreement.message?.body?.proof{
                        let newProof = Proof.init(created: signature_option.created, proofPurpose: signature_option.proofPurpose, id: signature_option.id, verificationMethod: signature_option.verificationMethod, proofValue: jws, type: signature_option.type)
                        //pop ‘proof’ from data agreement
                        newDataAgreement.message?.body?.proof = nil
                        newDataAgreement.message?.body?.proofChain = [old_proof,newProof]
                    }
                }
            } else {
                let newProof = Proof.init(created: signature_option.created, proofPurpose: signature_option.proofPurpose, id: signature_option.id, verificationMethod: signature_option.verificationMethod, proofValue: jws, type: signature_option.type)
                newDataAgreement.message?.body?.proofChain?.append(newProof)
            }
            
            return (createDataAgreemntContextForCertificateRequestForConnectionWithoutThirdPartySupport(verKey: myVerKey ?? "", jws: jws, recipientKey: connectionModel?.value?.reciepientKey ?? "", event: new_event, signature_option: signature_option),newDataAgreement)
        } catch {
            debugPrint(error.localizedDescription)
            return (nil,nil)
        }
    }
    
    private func createDataAgreemntContextForCertificateRequestForConnectionWithoutThirdPartySupport(verKey: String, jws: String, recipientKey: String, event: Event, signature_option: SignatureOption) -> [String: Any]{
        return [
            "message_type": "protocol",
            "message": [
              "@type": "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/data-agreement-negotiation/1.0/accept",
              "@id": AgentWrapper.shared.generateRandomId_BaseUID4(),
              "body": [
                "id": AgentWrapper.shared.generateRandomId_BaseUID4(),
                "event":  event.dictionary ?? [String: Any](),
                "proof": [
                    "id": "\(RegistryHelper.shared.convertDidSovToDidMyData(didSov: verKey ))#2",
                  "type": "Ed25519Signature2018",
                    "created": signature_option.created ?? AgentWrapper.shared.getCurrentDateTime(format: "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"),
                    "verificationMethod": (RegistryHelper.shared.convertDidSovToDidMyData(didSov: verKey )),
                  "proofPurpose": "contractAgreement",
                  "proofValue": jws
                ]
              ],
              "from": (RegistryHelper.shared.convertDidSovToDidMyData(didSov: verKey )),
              "created_time": Date().epochTime,
              "to": (RegistryHelper.shared.convertDidSovToDidMyData(didSov: recipientKey )),
            ]
          ]
    }
}
