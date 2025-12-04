//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 21/08/25.
//

import Foundation
import Crypto
import CryptoKit
import eudiWalletOidcIos
import UIKit

extension EBSIWallet {
    func initAll(){
        vpTokenResponseForConformanceFlow = nil
        tokenEndpointForConformanceFlow = nil
    }
    
    //Handle PrivateKey
    func handlePrivateKey() ->  P256.Signing.PrivateKey {
        var privateKey: P256.Signing.PrivateKey
        if let data = keychain.getData("EBSI_V3_PVTKEY"), let pvtKey = try? P256.Signing.PrivateKey(rawRepresentation: data) {
            privateKey = pvtKey
        } else {
            privateKey = P256.Signing.PrivateKey()
            keychain.set(privateKey.rawRepresentation, forKey: "EBSI_V3_PVTKEY")
        }
        return privateKey
    }
    
    func processVerifiablePresentationExchange(uri: String, presentationDefinition: String, clientMetaData: String, transactionData: [String], authSession: String? = nil) async {
        version = .v3
        self.isPinRequired = 0
        self.presentationDefinition = presentationDefinition
        self.uri = uri
        self.clientMetaData = clientMetaData
        self.transactionData = transactionData
        let code_url = URL.init(string: uri)
        let clientID = code_url?.queryParameters?["client_id"] as? String
        let state = code_url?.queryParameters?["state"] as? String
        let nonce = code_url?.queryParameters?["nonce"] as? String
        let responseType = code_url?.queryParameters?["response_type"] as? String
        let redirectUri = code_url?.queryParameters?["redirect_uri"] as? String
        let responseMode = code_url?.queryParameters?["response_mode"] as? String
        let presentationRequest = eudiWalletOidcIos.PresentationRequest(state: state, clientId: clientID, redirectUri: redirectUri, responseUri: redirectUri, responseType: responseType, responseMode: responseMode, scope: "", nonce: nonce, requestUri: "", presentationDefinition: presentationDefinition, clientMetaData: "", presentationDefinitionUri: "", clientMetaDataUri: "", clientIDScheme: "", transactionData: [], request: "", authSession: authSession)
        if let redirectUri = redirectUri, presentationRequest.responseType == "id_token" {
            
            //let connectionModel = await EBSIWallet.shared.getEBSI_V2_connection()
            let keyHandler = SecureEnclaveHandler(keyID: keyHandlerKeyID)
            let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
            let result = await verificationHandler?.processOrSendAuthorizationResponse(did: did, presentationRequest: presentationRequest, credentialsList: [], wua: "", pop: "")
            if result?.error == nil {
                UIApplicationUtils.showSuccessSnackbar(message: "did_shared_successfully".localizedForSDK())
            }
        } else {
            DispatchQueue.main.async {
                UIApplicationUtils.hideLoader()
                
                self.processQRCodeForVerification()
            }
        }
    }
    
    func processQRCodeForVerification() {
        UIApplicationUtils.showLoader()
        do {
            //TODO: update the display with client menta data details
            var clientDataString = clientMetaData.replacingOccurrences(of: "+", with: " ")
            // Escape inner double-quotes in values
            //clientDataString = clientDataString.replacingOccurrences(of: #"(?<!\\)""#, with: #"\""#, options: .regularExpression)
            let clientMetadataJson = clientDataString.data(using: .utf8)!
           
            let clientMetaDataModel = try? JSONDecoder().decode(eudiWalletOidcIos.ClientMetaData.self, from: clientMetadataJson)
            
            //TODO: while checking if connection already existing no need to update the display details if meta data is empty
            var display : Display? = nil
            if (isDynamicCredentialRequest == false || clientMetaData != "") {
               display = convertClientMetaDataToDisplay(clientMetaData: clientMetaDataModel)
            }
            checkDisplayAndAddConnectionIfNeeded(displayData: display, issuerOrVerifierID: exchangeClientID, vpExchange: true, credentialDisplay: credentialDisplay)
        } catch {
            UIApplicationUtils.hideLoader()
            debugPrint("JSON Serialization error")
        }
    }
    
    func getSortedCredentialsByIssuance(from credentials: [String]) -> [String] {
        var credentialDetails = [(credential: String, iat: Int)]()
        for credential in credentials {
            let split = credential.split(separator: ".")
            if split.count > 1,
               let jsonString = "\(split[1])".decodeBase64(),
               let jsonDict = UIApplicationUtils.shared.convertStringToDictionary(text: jsonString),
               let iat = jsonDict["iat"] as? Int {
                
                credentialDetails.append((credential: credential, iat: iat))
            }
        }
        let sortedCredentials = credentialDetails.sorted { $0.iat > $1.iat }.map { $0.credential }
        return sortedCredentials.count != credentials.count ? credentials : sortedCredentials
    }
    
    func addTypeToJsonPath(data: Data?, queryItem: Any?) -> ([String: Any], String) {
        if queryItem is String || queryItem is PresentationDefinitionModel {
            guard let data = data, var jsonObject2 = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                print("Failed to parse JSON data")
                return ([:], "")
            }
            var type = ""
            if var inputDescriptorArray = jsonObject2["input_descriptors"] as? [[String: Any]] {
                if var inputDescriptor = inputDescriptorArray.first {
                    if var constraints = inputDescriptor["constraints"] as? [String: Any] {
                        if var fieldsArray = constraints["fields"] as? [[String: Any]] {
                            if var field = fieldsArray.first, let filter = field["filter"] as? [String: Any] {
                                if var pathArray = field["path"] as? [String] {
                                    type = filter["type"] as? String ?? ""
                                    if pathArray.contains("$.vc.type") {
                                        pathArray.append("$.type")
                                    } else if pathArray.contains("$.type") {
                                        pathArray.append("$.vc.type")
                                    }
                                    field["path"] = pathArray
                                    fieldsArray[0] = field
                                    constraints["fields"] = fieldsArray
                                    inputDescriptor["constraints"] = constraints
                                    inputDescriptorArray[0] = inputDescriptor
                                    jsonObject2["input_descriptors"] = inputDescriptorArray
                                }
                            }
                        }
                    }
                }
            }
            return (jsonObject2, type)
        } else if let dcql = queryItem as? DCQLQuery {
            guard let firstCredential = dcql.credentials.first else {
                return ([:], "")
            }
            
            switch firstCredential.meta {
            case .dcSDJWT:
                return ([:], "Array")
            case .msoMdoc:
                return ([:], "String")
            case .jwt:
                return ([:], "Array")
            }
        }
        
        return ([:], "")
        
    }
    
    func processVerification(payload: String) {
        guard let otpHandler = otpCallBack else {
            return
        }
        let continueFlow = { [weak self] in
            guard let self = self else { return }
            Task {
                await EBSIWallet.shared.processVerification(code: payload)
            }
        }
        
        otpHandler(.Verification, continueFlow)
    }
    
    func processVerification(code: String) async {
        let presentationRequestData = await self.verificationHandler?.processAuthorisationRequest(data: code)
        let presentationRequest = presentationRequestData?.0
        if presentationRequestData?.1 != nil {
            UIApplicationUtils.hideLoader()
            UIApplicationUtils.showErrorSnackbar(message: presentationRequestData?.1?.message ?? "Invalid QR code")
        } else {
            dcqlQuery = presentationRequest?.dcqlQuery
            let urlString = "openid4vp://?client_id=\(presentationRequest?.clientId ?? "")&response_type=\(presentationRequest?.responseType ?? "")&scope=\(presentationRequest?.scope ?? "")&redirect_uri=\(presentationRequest?.redirectUri ?? presentationRequest?.responseUri ?? "")&request_uri=\(presentationRequest?.requestUri ?? "")&response_mode=\(presentationRequest?.responseMode ?? "")&state=\(presentationRequest?.state ?? "")&nonce=\(presentationRequest?.nonce ?? "")&client_metadata=\(presentationRequest?.clientMetaData ?? "")&client_id_scheme=\(presentationRequest?.clientIDScheme ?? "")"
            var clientID = presentationRequest?.clientId
            
            //                if ((URL(string: code)?.queryParameters?["client_id"]?.isValidURL) != nil){
            //                    clientID = URL(string: code)?.queryParameters?["client_id"] ?? ""
            //                }
            let credIssuer = clientID ?? credentialOffer?.credentialIssuer ?? ""
            let exchageID = clientID ?? ""
            var newOrgID: String = ""
            var newExchangeId : String = ""
            if let isDraft = DraftSuffixProcessor().isDraftID(credIssuer), isDraft {
                newOrgID = DraftSuffixProcessor().removeDraftSuffix(from: credIssuer) ?? ""
            } else {
                newOrgID = credIssuer
            }
            
            if let isDraft = DraftSuffixProcessor().isDraftID(exchageID), isDraft {
                newExchangeId = DraftSuffixProcessor().removeDraftSuffix(from: exchageID) ?? ""
            } else {
                newExchangeId = exchageID
            }
            self.credentialIssuer = newOrgID
            exchangeClientID = newExchangeId
            presentationRequestJwt = presentationRequest?.request ?? ""
            await EBSIWallet.shared.processVerifiablePresentationExchange(uri: urlString, presentationDefinition: presentationRequest?.presentationDefinition ?? "", clientMetaData: presentationRequest?.clientMetaData ?? "", transactionData: presentationRequest?.transactionData ?? [])
        }
    }
    
    func processCredentialOffer(uri: String) {
       // self.initAll()
        
        if uri.contains("credential_offer=") || uri.contains("credential_offer_uri") {
            let privateKey = EBSIWallet.shared.handlePrivateKey()
            Task {
                EBSIWallet.shared.version = .v3
                let credentialOffer = try? await issueHandler?.resolveCredentialOffer(credentialOffer: uri)
                EBSIWallet.shared.credentialOffer = credentialOffer
                if credentialOffer?.error != nil {
                    UIApplicationUtils.hideLoader()
                    return UIApplicationUtils.showErrorSnackbar(message: credentialOffer?.error?.message ?? "error_invalid_qr_code".localize)
                }
                
                self.isPinRequired = credentialOffer?.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.userPinRequired == true ? 1 : 0
                self.transactionCode = credentialOffer?.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.txCode
                let credIssuer = credentialOffer?.credentialIssuer ?? ""
                var newOrgID: String = ""
                if let isDraft = DraftSuffixProcessor().isDraftID(credIssuer), isDraft {
                    newOrgID = DraftSuffixProcessor().removeDraftSuffix(from: credIssuer) ?? ""
                } else {
                    newOrgID = credIssuer
                }
                self.credentialIssuer = newOrgID
                self.issuerState = credentialOffer?.grants?.authorizationCode?.issuerState ?? ""
                self.credentialTypes = credentialOffer?.credentials?[0].types ?? []
                self.preAuthCode = credentialOffer?.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.preAuthorizedCode ?? ""
                self.otpVal = nil
                self.processQRCodeForIssuance(credentialOffer: credentialOffer)
                
            }
        }
    }
    
    func handleLoaderVisibility() {
        if isFromPushNotification {
            UIApplicationUtils.hideLoader()
        } else {
            UIApplicationUtils.showLoader()
        }
    }
    
    func processQRCodeForIssuance(credentialOffer: CredentialOffer?) {
        Task {
            handleLoaderVisibility()
            if credentialOffer?.credentialIssuer?.isValidURL == true {
                do {
                    let issuerConfig = try await DiscoveryService.shared.getIssuerConfig(credentialIssuerWellKnownURI: credentialOffer?.credentialIssuer)
                    EBSIWallet.shared.issuerConfig = issuerConfig
                    let types = issueHandler?.getTypesFromCredentialOffer(credentialOffer: credentialOffer)
                    //self.credentialTypes = types ?? []
                    let isCredentialMetaDataAvailable = issueHandler?.isCredentialMetaDataAvailable(issuerConfig: issuerConfig, type: types?.last)
                    if (isCredentialMetaDataAvailable ?? false || credentialOffer?.credentials?.first?.trustFramework != nil) {
                        self.openIdIssuerResponseData = issuerConfig
                        
                        self.credentialEndPointUrl = issuerConfig?.credentialEndpoint ?? ""
                        self.defferedCredentialEndPointUrl = issuerConfig?.deferredCredentialEndpoint ?? ""
                        let credentialDisplay2 = EBSIWallet.shared.issueHandler?.getCredentialDisplayFromIssuerConfig(issuerConfig: issuerConfig, type: types?.first)
                        
                        let display = getDisplayFromIssuerConfig(config: issuerConfig)
                        
                         credentialDisplay = createCredentialDisplay(credDisplay: credentialDisplay2 ?? nil)
                        
                        checkDisplayAndAddConnectionIfNeeded(displayData: display, issuerOrVerifierID: credentialIssuer, vpExchange: false, credentialOffer: credentialOffer, issuerConfig: issuerConfig, credentialDisplay: credentialDisplay)
                    } else {
                        UIApplicationUtils.hideLoader()
                        return UIApplicationUtils.showErrorSnackbar(message: "error_invalid_qr_code".localize)
                    }
                    
                } catch {
                    UIApplicationUtils.hideLoader()
                    debugPrint("JSON Serialization error")
                }
            } else {
                UIApplicationUtils.hideLoader()
                return UIApplicationUtils.showErrorSnackbar(message: "error_invalid_qr_code".localize)
            }
        }
    }
    
    func getAuthorizationServerFromCredentialOffer(credential: CredentialOffer?) -> String? {
        guard let credential = credential else {
            return nil
        }
        if credential.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode == nil {
            return credential.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.authorizationServer
        } else if credential.grants?.authorizationCode != nil {
            return credential.grants?.authorizationCode?.authorizationServer
        } else {
            return nil
        }
    }


    
}
