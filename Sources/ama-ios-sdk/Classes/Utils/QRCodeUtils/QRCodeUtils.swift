//
//  QRCodeUtils.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 23/05/21.
//

import Foundation
import SVProgressHUD
import qr_code_scanner_ios
import UIKit
import SwiftUI
import Moya
//import FirebaseDynamicLinks
import IndyCWrapper

final class QRCodeUtils {
    static func processConnectionInvitationFromDictionary(_ newDict: [String : Any?]?, connectionPopup: Bool?) async -> (Bool, CloudAgentConnectionWalletModel?, String?, String?, String?) {
        let newRecipientKey = (newDict?["recipientKeys"] as? [String])?.first ?? ""
        let newLabel = newDict?["label"] as? String ?? ""
        let newServiceEndPoint = newDict?["serviceEndpoint"] as? String ?? ""
        let newRoutingKey = (newDict?["routingKeys"] as? [String]) ?? []
        let newImageURL = newDict?["imageUrl"] as? String ?? (newDict?["image_url"] as? String ?? "")
        let newType = newDict?["@type"] as? String ?? ""
        let newDidcom = newType.split(separator: ";").first ?? ""
        UIApplicationUtils.hideLoader()
        if newServiceEndPoint == "" {
            let message = "Sorry, could not open scan content".localizedForSDK()
            return (false, nil, nil, nil, message)
        }
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        var connectionPopupVC = await ConnectionPopupViewController()
      if connectionPopup ?? true {
            let (connModel, recipientKey, myVerKey, messsage) = await connectionPopupVC.showConnectionPopup(orgName: newLabel, orgImageURL: newImageURL, walletHandler: walletHandler, recipientKey: newRecipientKey, serviceEndPoint: newServiceEndPoint, routingKey: newRoutingKey, isFromDataExchange: false, didCom: String(newDidcom))
            let message = messsage
            return (true, connModel, recipientKey, myVerKey, message)
        } else {
            return await withCheckedContinuation { continuation in
                createConnectionWithoutPopup(orgName: newLabel, orgImageURL: newImageURL, walletHandler: walletHandler, recipientKey: newRecipientKey, serviceEndPoint: newServiceEndPoint, routingKey: newRoutingKey, isFromDataExchange: false, didCom: String(newDidcom)) { model, result1, result2, message in
                    continuation.resume(returning: (true, model, result1, result2, message))
                }
            }
        }
    }

    
    static func createConnectionWithoutPopup(orgName: String?,orgImageURL: String?,walletHandler: IndyHandle?,recipientKey: String?,serviceEndPoint: String?,routingKey: [String]?,isFromDataExchange: Bool,didCom: String, completion: @escaping ((CloudAgentConnectionWalletModel?,String?,String?,String?) -> Void)) {
        
        //Check connection with same Organisation Exist
        AriesCloudAgentHelper.shared.checkConnectionWithSameOrgExist(walletHandler: walletHandler ?? IndyHandle(), label: orgName ?? "", theirVerKey: recipientKey ?? "", serviceEndPoint: serviceEndPoint ?? "", routingKey: routingKey, imageURL: orgImageURL ?? "",isFromDataExchange: isFromDataExchange) { (connectionExist, orgDetails,connModel, message) in
            if !isFromDataExchange{
                UIApplicationUtils.hideLoader()
            }
            
            if let connectionModel = connModel {
                connectionModel.value?.orgDetails = orgDetails
                if connectionExist {
                    AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler ?? IndyHandle(), myDid: connModel?.value?.myDid ?? "", completion: { (metadataReceived,metadata, error) in
                        let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata ?? "")
                        if let verKey = metadataDict?["verkey"] as? String {
                            completion(connectionModel ,connectionModel.value?.reciepientKey ?? "",verKey, message)
                        }
                    })
                    return
                }
            }
            
            AriesCloudAgentHelper.shared.newConnectionConfigCloudAgent(walletHandler: walletHandler ?? IndyHandle(), label: orgName ?? "", theirVerKey: recipientKey ?? "", serviceEndPoint: serviceEndPoint ?? "", routingKey: routingKey, imageURL: orgImageURL ?? "", pollingEnabled: true,orgId: orgDetails?.orgId ,orgDetails: orgDetails,didCom: didCom ?? "") { (connectionModel,recipientKey,myVerKey)  in
                if let connectionModel = connectionModel, let recipientKey = recipientKey, let myVerKey = myVerKey {
                    connectionModel.value?.orgDetails = orgDetails
                    completion(connectionModel, recipientKey, myVerKey, message)
                }
            }
        }
    }
    
    static func processExchangeInvitationFromDictionary(_ newDict: [String : Any?]?,QR_ID : String) async -> (Bool, ExchangeDataQRCodeModel?, String?, String?) {
        let invitationURL = newDict?["dataexchange_url"] as? String ?? ""
        let newValue = "\(invitationURL.split(separator: "=").last ?? "")".decodeBase64() ?? ""
        let newInvDict = UIApplicationUtils.shared.convertToDictionary(text: newValue)
        let newQRModel = ExchangeDataQRCodeModel.decode(withDictionary: newInvDict as NSDictionary? ?? NSDictionary()) as? ExchangeDataQRCodeModel

        UIApplicationUtils.hideLoader()
        if newQRModel?.invitationURL == nil {
            let message = "Sorry, could not open scan content".localizedForSDK()
            return (false, nil, message, nil)
        }
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        DispatchQueue.main.async {
            if let vc = ExchangeDataPreviewViewController().initialize() as? ExchangeDataPreviewViewController {
                vc.viewModel = ExchangeDataPreviewViewModel.init(walletHandle: walletHandler, reqDetail: nil, QRData: newQRModel,isFromQR: true,inboxId: nil,connectionModel: nil,QR_ID: QR_ID)
                if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                    navVC.pushViewController(vc, animated: true)
                } else {
                    UIApplicationUtils.shared.getTopVC()?.push(vc: vc)
                }
            }
        }
        
        let message = "Connection success".localizedForSDK()
        return (true, newQRModel, message, nil)
    }

    static func handleQRDataUsingURL(url: String, isConnectionPopNeeded: Bool?) async -> ( Bool, ExchangeDataQRCodeModel?, String?, String?) {
        if isConnectionPopNeeded == true {
            UIApplicationUtils.showLoader()
        }
        if url.contains("igrantio-operator/connection/qr-link") {
            let newInvitationData = await NetworkManager.shared.get(service: .QRCode(url: url))
            let newInv = String(decoding: newInvitationData ?? Data(), as: UTF8.self)
            debugPrint("QRData ... \(newInv)")
            let newDict = UIApplicationUtils.shared.convertToDictionary(text: newInv)
            let invitationURL = newDict?["invitation_url"] as? String ?? ""
            let newValue = "\(invitationURL.split(separator: "=").last ?? "")".decodeBase64() ?? ""
            let newInvDict = UIApplicationUtils.shared.convertToDictionary(text: newValue)
            let (success, connectionModel, recipientKey, myVerKey, message) =  await QRCodeUtils.processConnectionInvitationFromDictionary(newInvDict, connectionPopup: isConnectionPopNeeded)
            return (success, nil, message, connectionModel?.id)
        } else if url.contains("igrantio-operator/data-exchange/qr-link") {
            let newInvitationData = await NetworkManager.shared.get(service: .QRCode(url: url))
            //                    let newDict = try? JSONSerialization.jsonObject(with: newInvitationData ?? Data(), options: []) as? [String : Any]
            let newInv = String(decoding: newInvitationData ?? Data(), as: UTF8.self)
            debugPrint("QRData ... \(newInv)")
            let newDict = UIApplicationUtils.shared.convertToDictionary(text: newInv)
            return await processExchangeInvitationFromDictionary(newDict,QR_ID: "\(url.split(separator: "/").last ?? "")")
        } else if let url = URL.init(string: url), let base64String =  url.queryParameters?["c_i"] {
            if let connectionString = base64String.decodeBase64() {
                let newDict = UIApplicationUtils.shared.convertToDictionary(text: connectionString)
                let (success, connectionModel, recipientKey, myVerKey, message) =  await QRCodeUtils.processConnectionInvitationFromDictionary(newDict, connectionPopup: isConnectionPopNeeded)
                return (success, nil, message, connectionModel?.id)
            } else {
                let message = "Unexpected error. Please try again.".localizedForSDK()
                return (false, nil, message, nil)
            }
        }
        else if let url = URL.init(string: url), let base64String = url.queryParameters?["qt"], let QR_ID_base64String = url.queryParameters?["qp"] {
//            let trace = Performance.sharedInstance().trace(name: "Data Exchange -- connection and initiate")
//            trace?.start()
            if let connectionString = QR_ID_base64String.decodeBase64() {
//                let trace = Performance.sharedInstance().trace(name: "Data Exchange -- connection and initiate")
//                trace?.start()

                let newDict = UIApplicationUtils.shared.convertToDictionary(text: connectionString)
                let qrId = newDict?["qr_id"] as? String ?? ""
                let newInvDict = newDict?["invitation"] as? [String:Any]
                let serviceEndPoint = newInvDict?["serviceEndpoint"] as? String
                let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
                let newRecipientKey = (newInvDict?["recipientKeys"] as? [String])?.first ?? ""
                let newLabel = newInvDict?["label"] as? String ?? ""
                let newServiceEndPoint = newInvDict?["serviceEndpoint"] as? String ?? ""
                let newRoutingKey = (newInvDict?["routingKeys"] as? [String]) ?? []
                let newImageURL = newInvDict?["imageUrl"] as? String ?? (newInvDict?["image_url"] as? String ?? "")
                let newType = newInvDict?["@type"] as? String ?? ""
                let newDidcom = newType.split(separator: ";").first ?? ""

                var myVerKey: String?
                var recipientKey: String?
                var message: String?

                do{
                    var connectionModel: CloudAgentConnectionWalletModel?
                    let (connectionExist,orgDetail, duplicate_connectionModel) = await AriesCloudAgentHelper.shared.checkConnectionWithSameOrgExist(walletHandler: walletHandler, label: newLabel, theirVerKey: newRecipientKey, serviceEndPoint: serviceEndPoint ?? "", routingKey: newRoutingKey, imageURL: newImageURL, isFromDataExchange: true)
                    if !connectionExist {
                        let (success, new_connectionModel, new_recipientKey, new_myVerKey, new_message) = await QRCodeUtils.processConnectionInvitationFromDictionary(newInvDict, connectionPopup: isConnectionPopNeeded)
                        myVerKey = new_myVerKey
                        recipientKey = new_recipientKey
                        connectionModel = new_connectionModel
                        message = new_message
                    } else {
                        connectionModel = duplicate_connectionModel
                        myVerKey = await AriesCloudAgentHelper.shared.getMyVerKeyFromConnectionMetadata(myDid: duplicate_connectionModel?.value?.myDid ?? "")
                        recipientKey = duplicate_connectionModel?.value?.reciepientKey ?? ""
                    }

                    DispatchQueue.main.async {
                        if isConnectionPopNeeded == true {
                            UIApplicationUtils.showLoader()
                        }
                    }

                    //7.1.1 data-agreement-qr-code/1.0/initiate
                    let initiate_packMessage = AriesPackMessageTemplates.getDataAgreementFromQRID(QR_ID: qrId,fromDid: "", toDid: "", isThirdPartyShareSupported: (connectionModel?.value?.isThirdPartyShareSupported == "true"))

                    //pack
                    let (packedSuccess, packedData) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connectionModel?.value?.reciepientKey ?? "", didCom: "", myVerKey: myVerKey ?? "", type: .rawDataBody, isRoutingKeyEnabled: false,rawDict: initiate_packMessage )
                    //

//                    let trace_initiate = Performance.sharedInstance().trace(name: "Data Exchange -- initiate protocol")
//                    trace_initiate?.start()
                    let (statusCode, receivedData) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData, url: serviceEndPoint)
                    if statusCode != 200 {
//                        trace_initiate?.stop();
                        debugPrint("send msg to mediator Failed");
                        return(false, nil, message, nil)}
//                    trace_initiate?.stop()
                    let (unpackSuccess, unpackedData) = try await AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: receivedData ?? Data())
                    if let messageModel = try? JSONSerialization.jsonObject(with: unpackedData ?? Data(), options: []) as? [String : Any] {
                        print("unpackmsg -- \(messageModel)")
                        let msgString = (messageModel)["message"] as? String
                        let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                        let requestPresentationMessageModel = RequestPresentationMessageModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? RequestPresentationMessageModel
                        if requestPresentationMessageModel == nil {
                            debugPrint("send msg to mediator Failed")
                            let message = "Sorry, could not open scan content".localizedForSDK()
//                            trace?.stop()
                            return(false, nil, message, nil)
                        }

                        let base64String = requestPresentationMessageModel?.requestPresentationsAttach?.first?.data?.base64?.decodeBase64() ?? ""
                        let base64DataDict = UIApplicationUtils.shared.convertToDictionary(text: base64String)
                        let presentationRequestModel = PresentationRequestModel.decode(withDictionary: base64DataDict as NSDictionary? ?? NSDictionary()) as? PresentationRequestModel

                        let didCom = requestPresentationMessageModel?.type?.split(separator: ";").first ?? ""
                        let ExchangeQrModel = ExchangeDataQRCodeModel.init(invitationURL: connectionString, proofRequest: presentationRequestModel, threadId: requestPresentationMessageModel?.id,didCom: String(didCom))
                        if let connectionModel = connectionModel {
                            DispatchQueue.main.async {
                                if requestPresentationMessageModel?.requestPresentationsAttach == nil {
                                    UIApplicationUtils.hideLoader()
                                    return
                                }
//                                trace?.stop()
                                if let vc = ExchangeDataPreviewViewController().initialize() as? ExchangeDataPreviewViewController {
                                    vc.viewModel = ExchangeDataPreviewViewModel.init(walletHandle: walletHandler, reqDetail: nil, QRData: ExchangeQrModel,isFromQR: true,inboxId: nil,connectionModel: connectionModel,QR_ID: qrId, dataAgreementContext: requestPresentationMessageModel?.dataAgreementContext)
                                    if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                                        navVC.pushViewController(vc, animated: true)
                                    } else {
                                        UIApplicationUtils.shared.getTopVC()?.push(vc: vc)
                                    }
                                }
                            }
                            return (true, nil, message, nil)
                        } else {
                            return (false, nil, message, nil)
                        }
//                        trace?.stop()
                    } else {
//                        trace?.stop()
                        return (false, nil, message, nil)
                    }
                    //    QRCodeUtils.processExchangeInvitationFromDictionary(newDict, QR_ID: qrId, completion: completion)
                } catch {
                    UIApplicationUtils.hideLoader()
                    debugPrint(error.localizedDescription)
//                    trace?.stop()
                    return (false, nil, message, nil)
                }
            } else {
//                trace?.stop()
                let message = "Unexpected error. Please try again."
                return (false, nil, message, nil)
            }
        }else if let url = URL.init(string: url), let base64PresentationRequest =  url.queryParameters?["d_m"] {
            let presentationRequestString = base64PresentationRequest.decodeBase64() ?? ""
            let msgDict = UIApplicationUtils.shared.convertToDictionary(text: presentationRequestString)
            let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
            debugPrint(msgDict as? NSDictionary)

            let requestPresentationMessageModel = RequestPresentationMessageModel.decode(withDictionary: msgDict as? NSDictionary ?? NSDictionary()) as? RequestPresentationMessageModel
            debugPrint(requestPresentationMessageModel)

            if requestPresentationMessageModel == nil {
                debugPrint("send msg to mediator Failed")
                let message = "Sorry, could not open scan content".localizedForSDK()
                return(false, nil, message, nil)
            }

            let base64String = requestPresentationMessageModel?.requestPresentationsAttach?.first?.data?.base64?.decodeBase64() ?? ""
            let base64DataDict = UIApplicationUtils.shared.convertToDictionary(text: base64String)
            debugPrint(base64DataDict)

            let presentationRequestModel = PresentationRequestModel.decode(withDictionary: base64DataDict as NSDictionary? ?? NSDictionary()) as? PresentationRequestModel

            let didCom = requestPresentationMessageModel?.type?.split(separator: ";").first ?? ""
            let ExchangeQrModel = ExchangeDataQRCodeModel.init(invitationURL: "", proofRequest: presentationRequestModel, threadId: requestPresentationMessageModel?.id,didCom: String(didCom))
            debugPrint(ExchangeQrModel)

            //Generate model to process connection
            var connectionDataDict = (msgDict)?["~service"] as? [String: Any] ?? [:]
            connectionDataDict["@type"] = requestPresentationMessageModel?.type
            let (connectionSuccess,connectionModel,recpKey,myVerkey, message) = await self.processConnectionInvitationFromDictionary(connectionDataDict, connectionPopup: isConnectionPopNeeded)
            if let connectionModel = connectionModel {
                DispatchQueue.main.async {

                    if let vc = ExchangeDataPreviewViewController().initialize() as? ExchangeDataPreviewViewController {
                        var presentationRequestWalletRecordModel = PresentationRequestWalletRecordModel.init()
                        presentationRequestWalletRecordModel.presentationRequest = presentationRequestModel
                        vc.viewModel = ExchangeDataPreviewViewModel.init(walletHandle: walletHandler, reqDetail: nil, QRData: ExchangeQrModel,isFromQR: true, inboxId: nil,connectionModel: connectionModel,QR_ID: nil, dataAgreementContext: nil)
                        if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                            navVC.pushViewController(vc, animated: true)
                        } else {
                            UIApplicationUtils.shared.getTopVC()?.push(vc: vc)
                        }
                    }
                }

            }
            return (false, nil, message, nil)
        } else {
            if let dynamicLinkURL = URL.init(string: url){
                //Dynamic link not work in SDK. So go with custom API call that we setup
                let urlString = await QRCodeUtils.getLinkStringFromDynamicLinkUsingAPI(dynamicLinkURL: url)
//                let urlString = await QRCodeUtils.getLinkStringFromDynamicLink(dynamicLinkURL: dynamicLinkURL)
                if urlString == "" {
                    UIApplicationUtils.hideLoader()
                    let message = "Invalid QR code".localizedForSDK()
                    return (false, nil, message, nil)
                }
                return await QRCodeUtils.handleQRDataUsingURL(url: urlString ?? "", isConnectionPopNeeded: isConnectionPopNeeded)
            } else {
                UIApplicationUtils.hideLoader()
                let message = "Invalid QR code".localizedForSDK()
                return (false, nil, message, nil)
            }
        }
    }

    @available(*, renamed: "getLinkStringFromDynamicLink(dynamicLinkURL:)")
    static func getLinkStringFromDynamicLink(dynamicLinkURL: URL, completion:  @escaping (String?) -> Void) {
//        DynamicLinks.dynamicLinks().handleUniversalLink(dynamicLinkURL, completion: { dynamicLink, error in
//            debugPrint(dynamicLink ?? "")
//            completion(dynamicLink?.url?.absoluteString ?? "")
//        })
    }

    static func getLinkStringFromDynamicLink(dynamicLinkURL: URL) async -> String? {
        return await withCheckedContinuation { continuation in
            getLinkStringFromDynamicLink(dynamicLinkURL: dynamicLinkURL) { result in
                continuation.resume(returning: result)
            }
        }
    }

    static func getLinkStringFromDynamicLinkUsingAPI(dynamicLinkURL: String) async -> String? {
        let jsonData = await NetworkManager.shared.get(service: .getProcessedFirebaseDynamicLink(challenge: "6165365011", link: dynamicLinkURL))
        guard let data = jsonData else {
            UIApplicationUtils.showErrorSnackbar(message: "Failed to fetch ledger list")
            return nil
        }
        let dict = try? JSONDecoder().decode([String:String].self, from: data)
        return dict?["Content"]
    }

    static func getQRDataFromImage(image: UIImage) -> String?{
        let qrCodeScanner = QRScannerView()
        return qrCodeScanner.getQRCodeDataFromImage(image: image)
    }
}
