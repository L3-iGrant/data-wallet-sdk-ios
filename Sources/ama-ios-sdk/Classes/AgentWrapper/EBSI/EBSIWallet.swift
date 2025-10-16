//
//  EBSIWallet.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 21/03/22.
//

import Foundation
import web3swift
import Base58Swift
import JOSESwift
import CryptoKit
import CommonCrypto
import CoreMedia
import secp256k1
import KeychainSwift
import Web3Core
import IndyCWrapper
import UIKit
import eudiWalletOidcIos
import AuthenticationServices

public class EBSIWallet {
    
    public static let shared = EBSIWallet()
    let accessTokenClient: AccessTokenEBSI
    enum EBSI_Version{
        case v1
        case v2
        case v3
        case dynamic
    }
    
    var keyIDforWUA: String = ""
    var otpVal : String? = nil
    var baseURLForWUA: String? = nil
    var privateKeyData: P256.Signing.PrivateKey?
    var issueHandler : IssueService?
    var verificationHandler : VerificationService?
    var version: EBSI_Version = .v1
    let baseURL = "https://api.test.intebsi.xyz/"
    static let baseURL_V2 = "https://api-conformance.ebsi.eu/"
    let redirect_uri = "https://localhost:3000"
    var orgId = "EBSI_V2"
    
//    lazy var ptivateKeyData: P256.Signing.PrivateKey = {
//            return handlePrivateKey()
//        }()
//    
//    lazy var didGlobal: String = {
//        return createDIDKeyIdentifierForV3(privateKey: ptivateKeyData) ?? ""
//    }()
    var ptivateKeyData: P256.Signing.PrivateKey?
    var didGlobal: String = ""
    var keyHandlerKeyID: String = ""
    public var otpFlowHandler: AriesMobileAgent.OTPFlowHandler?
    public var otpCallBack: AriesMobileAgent.OTPFlowCallback?
    public var verificationFlowHandler: AriesMobileAgent.VerificationFlowHandler?
    var isFromPushNotification: Bool = false

    
    private init() {
        let keyHandler = SecureEnclaveHandler(keyID: keyHandlerKeyID)
        switch version {
        case .v1:
            orgId = "EBSI_V1"
        case .v2:
            orgId = "EBSI_V2"
        case .v3:
            orgId = "EBSI_V3"
        case .dynamic:
            orgId = "EBSI_dynamic"
        }
        accessTokenClient = AccessTokenEBSI()
        verificationHandler = VerificationService(keyhandler: keyHandler)
        issueHandler = IssueService(keyHandler: keyHandler)
    }
    private var wallet: Wallet?
    private let walletPassword = "igrant_datawallet"
    private var getP256_privateKey: Data?
    let keychain = KeychainSwift()
    var viewMode: ViewMode = .FullScreen
    
    var jwksUrlString: String? = nil
    public var webRedirectURI = "datawallet://callback"
    public var authConfigData: AuthorisationServerWellKnownConfiguration? = nil
    public var codeVerifierCreated = String()
    public var authServerUrlString: String? = nil
    public var globalDID = ""
    var credentialTypes = [String]()
    var tokenEndpointForConformanceFlow: String? = nil
    var credentialIssuer = String()
    var exchangeClientID = String()
    var issuerState = String()
    var openIdIssuerResponseData : IssuerWellKnownConfiguration? = nil
    var credentialEndPointUrl = String()
    var defferedCredentialEndPointUrl = String()
    var preAuthCode = String()
    var dynamicCredentialCount: Int = 0
    var isDynamicCredentialRequest = false
    public var credentialOffer : CredentialOffer? = nil
    public var issuerConfig : IssuerWellKnownConfiguration? = nil
    public var isWUARequired: Bool = false
    var revokedList: [String] = []
    var dcqlQuery: DCQLQuery? = nil
    var presentationDefinitionModel: PresentationDefinitionModel?
    var connectionModel = CloudAgentConnectionWalletModel()
    var exchangeDataRecordsdModel = [[SearchItems_CustomWalletRecordCertModel]]()
    var exchangeCredentialRecordsdModel = [SearchItems_CustomWalletRecordCertModel]()
    var pwaDataRecords = [SearchItems_CustomWalletRecordCertModel]()
    var pwaExchangeDataRecordsdModel = [SearchItems_CustomWalletRecordCertModel]()
    var presentationRequestJwt = String()
    var enoughCredentials = false
    var vpTokenRedirectUri = String()
    var authSessionToken = "eyJhbGciOiJFUzI1NksiLCJ0eXAiOiJKV1QifQ.eyJleHAiOjE2NTY5MzE0MTMsImlhdCI6MTY1NjkzMDUxMywiaXNzIjoiZGlkOmVic2k6emNHdnFnWlRIQ3Rramd0Y0tSTDdIOGsiLCJvbmJvYXJkaW5nIjoicmVjYXB0Y2hhIiwidmFsaWRhdGVkSW5mbyI6eyJhY3Rpb24iOiJsb2dpbiIsImNoYWxsZW5nZV90cyI6IjIwMjItMDctMDRUMTA6Mjg6MzFaIiwiaG9zdG5hbWUiOiJhcHAucHJlcHJvZC5lYnNpLmV1Iiwic2NvcmUiOjAuOSwic3VjY2VzcyI6dHJ1ZX19.ZZ-jycgaEcrleBfa-vXblnq4Jxx91OSiLeHgupHL4xl4Kf8LJHHM3IT4yNIrHL39pDcEpusOVAC8Lb1HpbsInw"
    var presentationDefinition = ""
    var uri = ""
    var clientMetaData = ""
    var vpTokenResponseForConformanceFlow: Data? = nil
    var transactionData: [String] = []
    var isPinRequired = 0
    var credentialDisplay: Display?
    var transactionCode: TransactionCode? = nil
    var DIDforWUA: String = ""
    public var webAuthSession: ASWebAuthenticationSession?
    
    func setupWallet(version: EBSI_Version, token: String = "") async -> Bool{
        authSessionToken = token
        self.version = version
        let password = walletPassword
        let bitsOfEntropy: Int = 128 // Entropy is a measure of password strength. Usually used 128 or 256 bits.
        let name = "Ethereum wallet"
        
        if let mnemonics = keychain.get(walletPassword), let keystore = try? BIP32Keystore(
            mnemonics: mnemonics,
            password: password,
            mnemonicsPassword: "",
            language: .english), let keyData = try? JSONEncoder().encode(keystore.keystoreParams) {
            let address = keystore.addresses!.first!.address
            wallet = Wallet(address: address, data: keyData, name: name, isHD: true)
        } else {
            let bitsOfEntropy: Int = 128 // Entropy is a measure of password strength. Usually used 128 or 256 bits.
            if let mnemonics = try? BIP39.generateMnemonics(bitsOfEntropy: bitsOfEntropy),let keystore = try? BIP32Keystore(
                mnemonics: mnemonics,
                password: password,
                mnemonicsPassword: "",
                language: .english), let keyData = try? JSONEncoder().encode(keystore.keystoreParams) {
                let address = keystore.addresses!.first!.address
                keychain.set(mnemonics, forKey: walletPassword)
                wallet = Wallet(address: address, data: keyData, name: name, isHD: true)
            }
        }
        
        if version == .v2 {
            return true
        }
        
        let did = createRandomEbsiDid()
        let didDoc = createDIDDOC(did: did)
        
        // 2.6 - 2.7  authentication Requests:
        let authenticateRequestURL = baseURL + "users-onboarding/v1/authentication-requests"
        let (AuthRequest_statusCode, AuthRequest_response) = await NetworkManager.shared.EBSI_sendMsg(param: ["scope":"ebsi users onboarding"], url: authenticateRequestURL, accessToken: authSessionToken)
        guard let responseModel = try? JSONSerialization.jsonObject(with: AuthRequest_response ?? Data(), options: []) as? [String : Any] else { return false}
        debugPrint(responseModel)
        let session_token = responseModel["session_token"] as? String ?? ""
        let openidURL = URL.init(string: session_token)
        let request = openidURL?.queryParameters?["request"] ?? ""
        let requestItems = request.split(separator: ".")
        var redirect_uri = ""
        var exp: Double = 0
        if requestItems.count > 2 {
            let secondData = "\(requestItems[1])".decodeBase64() ?? ""
            if let dict = UIApplicationUtils.shared.convertToDictionary(text: secondData) as? [String: Any]{
                redirect_uri = dict["redirect_uri"] as? String ?? ""
                exp = Double(dict["exp"] as? Int ?? 0) ?? 0
            }
        }
        
        // Construct token
        let id_token = constructToken(redirect_uri: redirect_uri, did: did, exp: exp) ?? ""
        
        //authentication Response
        let authenticateResponseURL = baseURL + "users-onboarding/v1/authentication-responses"
        let (_, AuthResponse_response) = await NetworkManager.shared.EBSI_sendMsg(param: ["id_token": id_token], url: authenticateResponseURL, accessToken: request, contentType: "application/x-www-form-urlencoded")
        
        
        guard let responseData = AuthResponse_response else { return false}
        let decoder = JSONDecoder()
        dump(responseData.prettyPrintedJSONString())
        do {
            let object = try decoder.decode(VerifiableModel.self, from: responseData)
            let accessData = FormJwtPass(did: did,
                                         iss: object.verifiableCredential?.issuer,
                                         verifiableCredential: object.verifiableCredential,
                                         redirectUri: redirect_uri,
                                         wallet: wallet,
                                         token: authSessionToken
            )
            accessTokenClient.formJwtSignature(data: accessData)
            return true
        } catch {
            debugPrint("VerifiableModel decode error -- " + error.localizedDescription)
            return false
        }
    }
    
    private func createRandomEbsiDid() -> String {
        let methodPrefix = "did:ebsi:";
        var version = 0x01;
        let byteLength = 16;
        var bytesArray: Data = Data() //  Uint8Array(1 + byteLength);
        bytesArray.append(Data(bytes: &version,
                               count: 1));
        bytesArray.append(generateRandomBytes() ?? Data());
        let methodSpecificIdentifier = Base58.base58Encode([UInt8](bytesArray))//  base58btc.encode(bytesArray);
        let did =  methodPrefix + "z" + methodSpecificIdentifier
        debugPrint("Generated DID ---- > \(did)")
        return did
    }
    
    func getPrivateKey() -> Data? {
        guard let wallet = wallet else {return nil}
        let data = wallet.data
        let keystoreManager: KeystoreManager
        if wallet.isHD {
            let keystore = BIP32Keystore(data)!
            keystoreManager = KeystoreManager([keystore])
        } else {
            let keystore = EthereumKeystoreV3(data)!
            keystoreManager = KeystoreManager([keystore])
        }
        let password = walletPassword
        guard let ethereumAddress = EthereumAddress(wallet.address) else {return nil}
        do {
            let pkData = try keystoreManager.UNSAFE_getPrivateKeyData(password: password, account: ethereumAddress)
            return pkData
        } catch {
            debugPrint(error.localizedDescription)
            return nil
        }
    }
    
    func getPublicKey() -> Data?{
        let privateKey = getPrivateKey() ?? Data()
        let publicKey: Data? = nil
        return publicKey
    }
        
    func getDisplayFromIssuerConfig(config:IssuerWellKnownConfiguration?) -> Display?{
        var display : Display?
       
        if config?.display?.isEmpty == true {
            display = nil
        } else {
            display = config?.display?[0]
        }
       
        return display
    }
    
    func getDIDFromWalletUnitAttestation() async -> String{
        let keyHandler = SecureEnclaveHandler(keyID: self.keyIDforWUA)
        let wuaDid = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
        return wuaDid
    }
    
    func createCredentialDisplay(credDisplay: Display?) -> Display? {
        return Display(mName: credDisplay?.name, mLocation: credDisplay?.location, mLocale: credDisplay?.locale, mDescription: (credDisplay?.description), mCover: credDisplay?.bgImage, mLogo: credDisplay?.logo, mBackgroundColor: credDisplay?.backgroundColor, mTextColor: credDisplay?.textColor)
    }
    
    
    @available(iOS 14.0, *)
    func checkDisplayAndAddConnectionIfNeeded(displayData: Display?, issuerOrVerifierID: String?, vpExchange: Bool? = false, credentialOffer: CredentialOffer? = nil, issuerConfig: IssuerWellKnownConfiguration? = nil, credentialDisplay: Display?) {
        Task {
            var display = displayData
            var tempDisplay: Display? = nil
            if display == nil {
                tempDisplay = Display(mName: "Unknown Org", mLocation: "Not Discoverable", mLocale: "en", mDescription: "", mCover: DisplayCover(mUrl: nil, mAltText: nil), mLogo: DisplayCover(mUrl: "https://storage.googleapis.com/data4diabetes/unknown.png", mAltText: nil), mBackgroundColor: nil, mTextColor: nil)
                display = tempDisplay
            }
            if credentialOffer?.credentials?.first?.trustFramework != nil && issuerConfig?.display?.isEmpty == true {
                goToVPExchangeOrOtpFlow(vpExchange: vpExchange, issuerConfig: issuerConfig, credentialOffer: credentialOffer)
            } else if (issuerOrVerifierID != nil && display?.name != nil) {
                let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
                let (_, searchHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithOrgId,searchValue: EBSIWallet.shared.orgId)
                let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
                let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: response)
                let jsonDecoder = JSONDecoder()
                
                let searchModel = CloudAgentSearchConnectionModel.decode(withDictionary: (recordResponse ?? [:]) as [String : Any]) as? CloudAgentSearchConnectionModel
                EBSIWallet.shared.version = .dynamic
                var orgDetail = OrganisationInfoModel.init()
                let records = searchModel?.records?.filter({ $0.value?.orgDetails?.orgId == issuerOrVerifierID })
                var existingConnections: [CloudAgentConnectionWalletModel]? = []
                if display?.name == "Unknown Org" {
                    existingConnections = []
                } else {
                    existingConnections = searchModel?.records?.filter( { $0.value?.orgDetails?.name == display?.name})
                }
                if records?.count ?? 0  < 1 {
                        orgDetail.orgId = issuerOrVerifierID
                        orgDetail.logoImageURL = display?.logo?.url ?? display?.logo?.uri
                        orgDetail.location = display?.location ?? ""
                        orgDetail.organisationInfoModelDescription = display?.description ?? ""
                        orgDetail.name = display?.name ?? ""
                        orgDetail.coverImageURL = display?.cover?.url ?? nil
                    if credentialDisplay?.name == "WalletUnitAttestation" || credentialDisplay?.name == "Wallet Unit Attestation" || isFromPushNotification {
                            saveConnectionWithoutPopup(vpExchange: false, issuerConfig: issuerConfig, credentialOffer: credentialOffer)
                        } else {
                            if vpExchange ?? false && transactionData.first != nil || isFromPushNotification{
                                let transactionDataBase64 = transactionData.first?.decodeBase64()
                                guard let transactionDataJson = transactionDataBase64?.data(using: .utf8) else { return }
                                let transactionDataModel = try? JSONDecoder().decode(eudiWalletOidcIos.TransactionData.self, from: transactionDataJson)
                                saveConnectionWithoutPopup(vpExchange: vpExchange ?? false, transactionData: transactionDataModel, issuerConfig: issuerConfig, credentialOffer: credentialOffer)
                            } else if vpExchange ?? false {
                                saveConnectionWithoutPopup(vpExchange: vpExchange ?? false, issuerConfig: issuerConfig, credentialOffer: credentialOffer)
                            } else {
                            let (_,_,_) = await ConnectionPopupViewController.showConnectionPopupForDynamicOrg(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), orgName: orgDetail.name , orgImageURL: orgDetail.logoImageURL, orgId: orgDetail.orgId, orgDetails: orgDetail, isVerification: vpExchange ?? false, issuerConfig: issuerConfig, credentialOffer: credentialOffer)
                            }
                        }
                } else {
                    //
                    if display?.name != "Unknown Org" {
                        var orgDetail = records?.first?.value?.orgDetails
                        var logoImageURL = display?.logo?.url ?? display?.logo?.uri
                        if orgDetail?.logoImageURL != logoImageURL || orgDetail?.location != display?.location || orgDetail?.organisationInfoModelDescription != display?.description {
                            let imageURL =  display?.cover?.url ?? ""
                            orgDetail?.logoImageURL = display?.logo?.url ?? display?.logo?.uri
                            orgDetail?.location = display?.location
                            orgDetail?.organisationInfoModelDescription = display?.description
                            orgDetail?.name = display?.name
                            let (_, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),recipientKey: "",label: display?.name ?? "", type: UpdateWalletType.trusted, id: records?.first?.value?.requestID ?? "", theirDid: records?.first?.value?.theirDid ?? "", myDid: records?.first?.value?.myDid ?? "",imageURL: imageURL,invitiationKey: "", isIgrantAgent: false, routingKey: nil, orgDetails: orgDetail, orgID: orgDetail?.orgId)
                        }
                    }
                    goToVPExchangeOrOtpFlow(vpExchange: vpExchange, issuerConfig: issuerConfig, credentialOffer: credentialOffer)
                }
            } else {
                goToVPExchangeOrOtpFlow(vpExchange: vpExchange, issuerConfig: issuerConfig, credentialOffer: credentialOffer)            }
        }
    }
    
    func saveConnectionWithoutPopup(vpExchange: Bool, transactionData: TransactionData? = nil, issuerConfig: IssuerWellKnownConfiguration?, credentialOffer: CredentialOffer?) {
        EBSIWallet.shared.EBSI_V3_store_dynamic_organisation_details(responseData: issuerConfig, isVerification: vpExchange, transactionData: transactionData, credentialOffer: credentialOffer) { success in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                NotificationCenter.default.post(name: Constants.reloadOrgList, object: nil)
                if vpExchange {
                    EBSIWallet.shared.processDataForVPExchange()
                } else {
                    let privateKey = EBSIWallet.shared.handlePrivateKey()
                    let responseModel = issuerConfig
                    let authServerUrl = AuthorizationServerUrlUtil().getAuthorizationServerUrl(issuerConfig: responseModel, credentialOffer: credentialOffer)
                    let authServer = EBSIWallet.shared.getAuthorizationServerFromCredentialOffer(credential: credentialOffer) ?? authServerUrl
                    EBSIWallet.shared.openIdAuthorisation(authServerUrl: (authServer?.isEmpty == true ? credentialOffer?.credentialIssuer : authServer) ?? "", privateKey: privateKey, credentialOffer: credentialOffer, issuerConfig: issuerConfig) { success in
                        if success! {
                            UIApplicationUtils.hideLoader()
//                            DispatchQueue.main.async {
//                                self.navigationController?.popViewController(animated: true)
//                            }
                        }
                    }
                }
            }
        }
    }
    
    @available(iOS 14.0, *)
    func goToVPExchangeOrOtpFlow(vpExchange: Bool? = false, issuerConfig: IssuerWellKnownConfiguration?, credentialOffer: CredentialOffer?) {
        if vpExchange ?? false {
            processDataForVPExchange()
        } else {
            if credentialOffer?.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.txCode != nil {
                UIApplicationUtils.hideLoader()
                if isFromPushNotification {
                    guard let otpHandler = otpCallBack else {
                        return
                    }
                    let continueFlow = { [weak self] in
                        guard let self = self else { return }
                        Task {
                            self.handleOTPFlow()
                        }
                    }
                    
                    otpHandler(.PinEntryDuringIssuance, continueFlow)
                } else {
                    Task {@MainActor in
                        if viewMode == .BottomSheet {
                            
                            let vc = OTPBottomSheetViewController(nibName: "OTPBottomSheetViewController", bundle: UIApplicationUtils.shared.getResourcesBundle())
                            vc.modalPresentationStyle = .overFullScreen
                            vc.modalTransitionStyle = .crossDissolve
                            vc.data = EBSIWallet.shared.issuerConfig
                            vc.transactionCode = credentialOffer?.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.txCode
                            if let topVC = UIApplicationUtils.shared.getTopVC() {
                                topVC.present(vc, animated: true, completion: nil)
                            }
                            
                        } else  {
                            let storyBoard : UIStoryboard = UIStoryboard(name: "ama-ios-sdk", bundle: UIApplicationUtils.shared.getResourcesBundle())
                            let nextVC = storyBoard.instantiateViewController(withIdentifier: "OTPViewController") as! OTPViewController
                            nextVC.data = EBSIWallet.shared.issuerConfig
                            nextVC.transactionCode = credentialOffer?.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.txCode
                            if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                                navVC.pushViewController(nextVC, animated: true)
                            } else {
                                UIApplicationUtils.shared.getTopVC()?.present(vc: nextVC)
                            }
                        }
                    }
                }
            } else {
            let privateKey = EBSIWallet.shared.handlePrivateKey()
                let authServerUrl = AuthorizationServerUrlUtil().getAuthorizationServerUrl(issuerConfig: issuerConfig, credentialOffer: credentialOffer)
                let authServer = EBSIWallet.shared.getAuthorizationServerFromCredentialOffer(credential: credentialOffer) ?? authServerUrl
            EBSIWallet.shared.openIdAuthorisation(authServerUrl: (authServer?.isEmpty == nil ? credentialOffer?.credentialIssuer : authServer) ?? "" , privateKey: privateKey, credentialOffer: credentialOffer, issuerConfig: issuerConfig) { _ in
                }
            }
        }
    }
    
    func handleOTPFlow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
                let vc = OTPBottomSheetViewController(nibName: "OTPBottomSheetViewController", bundle: UIApplicationUtils.shared.getResourcesBundle())
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                vc.data = EBSIWallet.shared.issuerConfig
                vc.transactionCode = self.credentialOffer?.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.txCode
                if let topVC = UIApplicationUtils.shared.getTopVC() {
                    topVC.present(vc, animated: false)
                }
            } else  {
                let storyBoard : UIStoryboard = UIStoryboard(name: "ama-ios-sdk", bundle: UIApplicationUtils.shared.getResourcesBundle())
                let nextVC = storyBoard.instantiateViewController(withIdentifier: "OTPViewController") as! OTPViewController
                nextVC.data = EBSIWallet.shared.issuerConfig
                nextVC.transactionCode = self.credentialOffer?.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.txCode
                if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                    navVC.pushViewController(nextVC, animated: true)
                } else {
                    UIApplicationUtils.shared.getTopVC()?.present(vc: nextVC)
                }
            }
        }
    }

    
    func getECPublicKey(did: String) -> ECPublicKey? {
        let publicKeyData = getPublicKey() ?? Data()
        let jwk = try? ECPublicKey.init(publicKey: publicKeyData,additionalParameters: [
            "kid": "\(did)#key-1",
        ])
        debugPrint(jwk)
        return jwk
    }
    
    func getThumbprint() -> String? {
        let publicKeyData = getPublicKey() ?? Data()
        let jwk = try? ECPublicKey.init(publicKey: publicKeyData)
        var param = jwk?.requiredParameters
        param?["crv"] = "secp256k1"
        guard let json = try? JSONSerialization.data(withJSONObject: param, options: .sortedKeys) else {
            return nil
        }
        let thumbprint = try? Thumbprint.calculate(from: json, algorithm: .SHA256)
        debugPrint("ThumbPrint ---- \(thumbprint ?? "error")")
        return thumbprint
    }
    
    
    // Create Authentication Response
    ///            {
    ///               "aud": "https://api.test.intebsi.xyz/users-onboarding/v1/authentication-responses",
    ///                "did": "did:ebsi:zfR92uoToGwTx8ijQuHfKKr",
    ///                "iss": "https://self-issued.me",
    ///                "nonce": "843516d0-5040-43b8-bd46-ee5338f18c34",
    ///                "sub": "0JmAu_13EZJ_1zW72sds-mEqQtpWlN3ej16avfEWH3I",
    ///                "sub_jwk": {
    ///                    "crv":'secp256k1',
    ///                    "kid":'did:ebsi:zfR92uoToGwTx8ijQuHfKKr#key-1',
    ///                    "kty":'EC',
    ///                    "x":'QiwC95S8tSAaOl6_7cdBfLNY8FB4SbHiQPUh901B6ig',
    ///                    "y":'iqgOqH5Kqrte5lH2sTPMUccoF7yhlu0bu20eBrET1BQ'
    ///                }
    ///            }
    private func createAuthenticationResponse(redirect_uri: String, did: String) -> JWTPayload {
        var jwk = getECPublicKey(did: did)?.parameters
        jwk?["crv"] = "secp256k1"
        /*
         "crv":'secp256k1',
         "kid":'did:ebsi:zfR92uoToGwTx8ijQuHfKKr#key-1',
         "kty":'EC',
         "x":'QiwC95S8tSAaOl6_7cdBfLNY8FB4SbHiQPUh901B6ig',
         "y":'iqgOqH5Kqrte5lH2sTPMUccoF7yhlu0bu20eBrET1BQ'
         
         */
        let jwt_thumbprint = getThumbprint() ?? ""
        let authResponse = [
            "aud": redirect_uri,
            "did": did,
            "iss": "https://self-issued.me",
            "nonce": NSUUID().uuidString.lowercased(),
            "sub":  jwt_thumbprint,
            "sub_jwk": jwk ?? [:]
        ] as [String : Any]
        
        let subJWKModel = SubJwk.init(crv: jwk?["crv"], kid: jwk?["kid"], kty: jwk?["kty"], x: jwk?["x"], y: jwk?["y"])
        let authResponseModel = JWTPayload.init(aud: redirect_uri, did: did, exp: nil, iat: nil, iss: "https://self-issued.me", nonce: NSUUID().uuidString.lowercased(), sub: jwt_thumbprint, subJwk: subJWKModel)
        return authResponseModel
    }
    
    func constructToken(redirect_uri: String,did: String, exp: Double) -> String?{
        //Header
        ///{
        ///"alg": "ES256K",
        ///"typ": "JWT",
        ///"kid": "did:ebsi:zfR92uoToGwTx8ijQuHfKKr#key-1"
        ///}
        ///
        
        ///////////////////
        //        let header = JWTHeader.init(alg: "ES256", typ: "JWT", kid: "\(did)#key-1")
        let header = JWTHeader.init(alg: "ES256K", typ: "JWT", kid: "\(did)#key-1")
        //        [
        //            "alg": "ES256K",
        //            "typ": "JWT",
        //            "kid": "\(did)#key-1"
        //        ]
        //        var header = JWSHeader(algorithm: .ES256)
        //        header.kid = "\(did)#key-1"
        //        header.typ = "JWT"
        
        // Create authentication Response
        let authenticationResponseModel = createAuthenticationResponse(redirect_uri: redirect_uri, did: did)
        
        //Payload
        var payloadDict = authenticationResponseModel
        let iat = Date().epochTime
        payloadDict.iat = iat
        payloadDict.exp = exp + (Double(iat) ?? 0)
        
        //signing
        return EBSIUtils.signAndCreateJWTToken(payloadDict: payloadDict, header: header, privateKey: getPrivateKey())
        
    }
    
    private func generateRandomBytes() -> Data? {
        var keyData = Data(count: 16)
        let result = keyData.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!)
        }
        if result == errSecSuccess {
            return keyData
        } else {
            print("Problem generating random bytes")
            return nil
        }
    }
    
    private func createDIDDOC(did: String) -> [String: Any]{
        return [
            "@context": "https://w3id.org/did/v1",
            "id": did,
            "verificationMethod": [
                [
                    "id": "\(did)#keys-1",
                    "type": "EcdsaSecp256k1VerificationKey2019",
                    "controller": did,
                    "publicKeyJwk": [
                        "kty": "EC",
                        "crv": "secp256k1",
                        "x": "n03trG-1sWidluyYQ2gcKrgYE94rMkLIArZCHjv2GpI",
                        "y": "6__x_vqe0nBGYf7azbQ1_VvvuCafG5MhhUPNvYp-Mak"
                    ]
                ]
            ],
            "authentication": [
                "\(did)#keys-1"
            ],
            "assertionMethod": [
                "\(did)#keys-1"
            ]
        ]
    }
}


//MARK: Models
struct Wallet {
    let address: String
    let data: Data
    let name: String
    let isHD: Bool
}

struct HDKey {
    let name: String?
    let address: String
}

enum ThumbprintError: Error {
    case inputMustBeGreaterThanZero
}

fileprivate extension JWKThumbprintAlgorithm {
    var outputLenght: Int {
        switch self {
        case .SHA256:
            return Int(CC_SHA256_DIGEST_LENGTH)
        }
    }
    
    func calculate(input: UnsafeRawBufferPointer, output: UnsafeMutablePointer<UInt8>) {
        switch self {
        case .SHA256:
            CC_SHA256(input.baseAddress, CC_LONG(input.count), output)
        }
    }
}

internal struct Thumbprint {
    /// Calculates a hash of an input with a specific hash algorithm.
    ///
    /// - Parameters:
    ///   - input: The input to calculate a hash for.
    ///   - algorithm: The algorithm used to calculate the hash.
    /// - Returns: The calculated hash in base64URLEncoding.
    static func calculate(from input: Data, algorithm: JWKThumbprintAlgorithm) throws -> String {
        guard input.count > 0 else {
            throw ThumbprintError.inputMustBeGreaterThanZero
        }
        
        let hashBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: algorithm.outputLenght)
        defer { hashBytes.deallocate() }
        
        input.withUnsafeBytes { buffer in
            algorithm.calculate(input: buffer, output: hashBytes)
        }
        
        return Data(bytes: hashBytes, count: algorithm.outputLenght).base64URLEncodedString()
    }
}

struct JWTHeader: Codable {
    var alg,typ,kid: String?
    
    init(alg: String, typ: String, kid: String) {
        self.alg = alg
        self.typ = typ
        self.kid = kid
    }
    
    func orderedString() -> String{
        var string = "{"
        string += "\"alg\": \(alg ?? "")"
        string += "\"typ\": \(typ ?? "")"
        string += "\"kid\": \(kid ?? "")"
        string += "}"
        
        return string
    }
}

class JWTPayload: Codable {
    var aud: String?
    var did: String?
    var exp: Double?
    var iat: String?
    var iss: String?
    var nonce, sub: String?
    var subJwk: SubJwk?
    var claims: Claims?
    
    enum CodingKeys: String, CodingKey {
        case aud, did, exp, iat, iss, nonce, sub,claims
        case subJwk = "sub_jwk"
    }
    
    init(aud: String?, did: String?, exp: Double?, iat: String?, iss: String?, nonce: String?, sub: String?, subJwk: SubJwk?) {
        self.aud = aud
        self.did = did
        self.exp = exp
        self.iat = iat
        self.iss = iss
        self.nonce = nonce
        self.sub = sub
        self.subJwk = subJwk
        self.claims = nil
    }
    
    init(aud: String?, did: String?, exp: Double?, iat: String?, iss: String?, nonce: String?, sub: String?, subJwk: SubJwk?, claims: Claims?) {
        self.aud = aud
        self.did = did
        self.exp = exp
        self.iat = iat
        self.iss = iss
        self.nonce = nonce
        self.sub = sub
        self.subJwk = subJwk
        self.claims = claims
    }
    
    func orderedString() -> String{
        var string = "{"
        string += "\"aud\": \(aud ?? "")"
        string += "\"did\": \(did ?? "")"
        string += "\"exp\": \(exp ?? 0)"
        string += "\"iat\": \(iat ?? "")"
        string += "\"iss\": \(iss ?? "")"
        string += "\"nonce\": \(nonce ?? "")"
        string += "\"sub\": \(sub ?? "")"
        string += "\"sub_jwk\": \(subJwk?.orderedString() ?? "")"
        string += "}"
        
        return string
    }
}

class Claims: Codable {
    var encryption_key: SubJwk?
    var verified_claims: String?
    
    init(encryption_key: SubJwk?, verified_claims: String?){
        self.encryption_key = encryption_key
        self.verified_claims = verified_claims
    }
    
    enum CodingKeys: String, CodingKey {
        case encryption_key, verified_claims
    }
}


// MARK: - SubJwk
class SubJwk: Codable {
    var crv, kid, kty, x: String?
    var y: String?
    
    init(crv: String?, kid: String?, kty: String?, x: String?, y: String?) {
        self.crv = crv
        self.kid = kid
        self.kty = kty
        self.x = x
        self.y = y
    }
    
    func orderedString() -> String{
        var string = "{"
        string += "\"crv\": \(crv ?? "")"
        string += "\"kid\": \(kid ?? "")"
        string += "\"kty\": \(kty ?? "")"
        string += "\"x\": \(x ?? "")"
        string += "\"y\": \(y ?? "")"
        string += "}"
        
        return string
    }
}
