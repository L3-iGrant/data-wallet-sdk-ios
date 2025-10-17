//
//  AriesMobileAgent.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 11/11/20.
//

import Foundation
import SVProgressHUD
import WXNavigationBar
import IQKeyboardManagerSwift
//import FirebaseCore
import Localize_Swift
import IndyCWrapper
import eudiWalletOidcIos
import DeviceCheck

public protocol AriesMobileAgentDelegate {
    func notificationReceived(message: String)
}

public enum ViewMode: String {
    case BottomSheet
    case FullScreen
}

public enum NotificationType: String {
    case PinEntryDuringIssuance
    case Verification
}

public struct AriesMobileAgent {
    public static var shared = AriesMobileAgent()
    private var hideBackButton = false
    private init() { }
    var delegate: AriesMobileAgentDelegate?
    static var themeColor = UIColor.AriesDefaultThemeColor()
    public static var isAutoAcceptIssuanceEnabled: Bool? = false
    public typealias OTPFlowHandler = () -> Bool
    //public typealias OTPFlowCallback = (_ continueFlow: @escaping () -> Void) -> Void
    public typealias OTPFlowCallback = (_ type: NotificationType, _ continueFlow: @escaping () -> Void) -> Void


    public typealias VerificationFlowHandler = () -> Bool
    
    //    public func getDataWalletViewController(themeColor: UIColor? = nil, navBarItemTintColor: UIColor? = nil) {
    //        if #available(iOS 13.0, *) {
    //           let appearance = UIView.appearance()
    //           appearance.overrideUserInterfaceStyle = .light
    //        }
    //        WXNavigationBar.setup()
    //        WXNavigationBar.NavBar.backgroundColor = .clear
    //        IQKeyboardManager.shared.enable = true
    //        let controller = UIStoryboard(name:"ama-ios-sdk", bundle:UIApplicationUtils.shared.getResourcesBundle()).instantiateInitialViewController() as? UINavigationController
    //        
    //        AriesMobileAgent.themeColor = themeColor ?? UIColor.AriesDefaultThemeColor()
    //        SVProgressHUD.setDefaultMaskType(.black)
    //        controller?.navigationBar.barTintColor = themeColor ?? UIColor.AriesDefaultThemeColor()
    //        controller?.navigationBar.tintColor = navBarItemTintColor ?? .white
    //        controller?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: navBarItemTintColor ?? .white]
    //        SVProgressHUD.setDefaultMaskType(.black)
    //        navigateTo(controller?.viewControllers.first ?? UIViewController())
    //    }
    
    @MainActor public func configureWallet(delegate: AriesMobileAgentDelegate, isAriesEnabled: Bool = false, viewMode: ViewMode, completion:  @escaping (Bool?) -> Void){
        UserDefaults.standard.set(isAriesEnabled, forKey: "isAriesRequired")
        if checkIfWalletIsConfigured() {
            debugPrint("Wallet already configured")
            completion(true)
            return
        }
        if #available(iOS 13.0, *) {
            let appearance = UIView.appearance()
            appearance.overrideUserInterfaceStyle = .light
        }
        SVProgressHUD.setDefaultMaskType(.black)
        UserDefaults.standard.set(viewMode.rawValue, forKey: "viewModeValue")
        setupGlobalBackButtonAppearance()
        Task {
            var keyId: String = ""
            let keyIDfromKeyChain = WalletUnitAttestationService().retrieveKeyIdFromKeychain()
            if keyIDfromKeyChain == "" || keyIDfromKeyChain == nil {
                keyId = try await generateKeyId()
                storeKeyIdInKeychain(keyId)
            } else {
                keyId = keyIDfromKeyChain ?? ""
            }
            EBSIWallet.shared.keyHandlerKeyID = keyId
            EBSIWallet.shared.keyIDforWUA = keyId
            let did = await EBSIWallet.shared.getDIDFromWalletUnitAttestation()
            EBSIWallet.shared.DIDforWUA = did
        }
        IQKeyboardManager.shared.isEnabled = true
        let vc = WalletHomeViewController()
        AriesMobileAgent.themeColor = .black
        AriesMobileAgent.shared.delegate = delegate
        openWallet(model: vc.viewModel, completion: completion)
    }
    
    func generateKeyId() async throws -> String {
        let service = DCAppAttestService.shared
        return try await withCheckedThrowingContinuation { continuation in
            service.generateKey { keyId, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let keyId = keyId {
                    continuation.resume(returning: keyId)
                } else {
                    continuation.resume(throwing: NSError(domain: "AppAttest", code: -1, userInfo: [NSLocalizedDescriptionKey: "Key generation failed"]))
                }
            }
        }
    }
    
    func storeKeyIdInKeychain(_ keyId: String) {
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "AppAttestationKeyId",
            kSecValueData as String: keyId.data(using: .utf8)!
        ]
        
        SecItemDelete(keychainQuery as CFDictionary)
        
        // Add the new keyId
        let status = SecItemAdd(keychainQuery as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("KeyId successfully stored in Keychain.")
        } else {
            print("Failed to store KeyId in Keychain: \(status)")
        }
    }
    
    func getViewMode() -> ViewMode {
        if let rawValue = UserDefaults.standard.string(forKey: "viewModeValue"),
           let mode = ViewMode(rawValue: rawValue) {
            return mode
        }
        return .FullScreen
    }
    
    func openWallet(model: WalletViewModel,completion: @escaping (Bool?) -> Void) {
        let auth = AuthIdModel()
        AgentWrapper.shared.openWallet(withConfig: auth.config, credentials: auth.cred) { (error, indyHandle) in
            if (indyHandle == 0) {
                createWallet(model: model,completion: completion)
            } else {
                QuickActionNavigation.shared.walletHandle = indyHandle
                QuickActionNavigation.shared.mediatorVerKey = WalletViewModel.mediatorVerKey
                model.walletHandle = indyHandle
                debugPrint("wallet opened")
                var isAriesRequired = UserDefaults.standard.bool(forKey: "isAriesRequired")
                if  UserDefaults.standard.object(forKey: "isAriesRequired") == nil {
                    isAriesRequired = true
                }
                if isAriesRequired {
                    WalletViewModel.shared.checkMediatorConnectionAvailable()
                    AriesPoolHelper.shared.configurePool(walletHandler: indyHandle,completion: {_ in
                        UIApplicationUtils.shared.hideLedgerConfigToast()
                        MetaDataUtils.shared.checkForMetaDataUpdate()
                        completion(true)
                    })
                } else {
                    IndyCredentialsToSelfAttestedOpenIDCredentials().migrate()
                    completion(true)
                }
                //                    UIApplicationUtils.shared.showLedgerConfigToast()
            }
        }
    }
    
    func createWallet(model: WalletViewModel,completion: @escaping (Bool?) -> Void) {
        let auth = AuthIdModel()
        AgentWrapper.shared.createWallet(withConfig: auth.config, credentials: auth.cred, completion: { (error) in
            if (error != nil) {
                print("wallet created")
                openWallet(model: model,completion: completion)
            }
        })
    }
    
    public func deleteWallet(completion: @escaping (Bool?) -> Void) {
        let auth = AuthIdModel()
        closeWallet { success in
            if success ?? false {
                AgentWrapper.shared.deleteWallet(withConfig: auth.config, credentials: auth.cred, completion: { (error) in
                    if (error != nil) {
                        WalletViewModel.openedWalletHandler = nil
                        print("wallet deleted")
                        DataPodsUtils.shared.clearData()
                        completion(true)
                    }else{
                        completion(false)
                    }
                })
            } else {
                completion(false)
            }
        }
    }
    
    public func handlePushNotification(data: [AnyHashable : Any], otpHandler: OTPFlowCallback? = nil) {
        EBSIWallet.shared.clearCredentialRequestCache()
        var type: String = ""
        var payload: String = ""
        EBSIWallet.shared.otpCallBack = otpHandler
        EBSIWallet.shared.isFromPushNotification = true
        if let payloadValue = data["payload"] as? String {
            payload = payloadValue
        }
        
        if let typeValue = data["type"] as? String {
            type = typeValue
        }
        
        switch type {
        case "openid4vci":
            Task {
                EBSIWallet.shared.processCredentialOffer(uri: payload)
            }
        case "openid4vp":
            Task {
                await EBSIWallet.shared.processVerification(payload: payload)
            }
        default:
            break
        }
        
    }
    
    
    func closeWallet(completion: @escaping (Bool?) -> Void) {
        AgentWrapper.shared.closeWallet(withHandle: WalletViewModel.openedWalletHandler ?? IndyHandle()) { error in
            if (error != nil) {
                print("wallet closed")
                completion(true)
            }
        }
    }
    
    public func we(){
        if !checkIfWalletIsConfigured() {
            UIApplicationUtils.showErrorSnackbar(message: "Wallet not initialised")
            return
        }
        if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:Bundle.module).instantiateViewController( withIdentifier: "NotificationListViewController") as? NotificationListViewController {
            controller.modalPresentationStyle = .fullScreen
            navigateTo(controller)
        }
    }
    
    public func showDataWalletNofificationViewController(){
        if !checkIfWalletIsConfigured() {
            UIApplicationUtils.showErrorSnackbar(message: "Wallet not initialised")
            return
        }
        
        if getViewMode() == .FullScreen {
            if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:Bundle.module).instantiateViewController( withIdentifier: "NotificationListViewController") as? NotificationListViewController {
                controller.modalPresentationStyle = .fullScreen
                navigateTo(controller)
            }
        } else {            
            if let walletVC = UIStoryboard(name:"ama-ios-sdk", bundle:Bundle.module).instantiateViewController( withIdentifier: "NotificationListViewController") as? NotificationListViewController {
                //let navContent = UINavigationController(rootViewController: walletVC)
                //navContent.navigationBar.isHidden = true
                walletVC.viewMode = .BottomSheet
                let sheetVC = WalletHomeBottomSheetViewController(contentViewController: walletVC)
                sheetVC.modalPresentationStyle = .overCurrentContext
                sheetVC.modalTransitionStyle = .crossDissolve
                
                if let topVC = UIApplicationUtils.shared.getTopVC() {
                    topVC.present(sheetVC, animated: false, completion: nil)
                }
            }
        }
    }
    
    public mutating func enableAutoAcceptForIssuance(withouDataAgreement: Bool) {
        AriesMobileAgent.isAutoAcceptIssuanceEnabled = withouDataAgreement
    }
    
    public func showNotificationDetails() {
        if !checkIfWalletIsConfigured() {
            UIApplicationUtils.showErrorSnackbar(message: "Wallet not initialised")
            return
        }
        
        var viewModel: NotificationsListViewModel?
        viewModel = NotificationsListViewModel.init(walletHandle: WalletViewModel.openedWalletHandler)
        var notification: InboxModelRecord?
        WalletRecord.shared.fetchNotifications { searchInboxModel in
            if let records = searchInboxModel?.records {
                let orderedRecords = records.sorted(by: {
                    $0.value?.dataAgreement?.message?.createdTime?.toInt ?? 0 > $1.value?.dataAgreement?
                        .message?.createdTime?.toInt ?? 0
                })
                notification = orderedRecords.first
                let inboxData = notification
                let type = inboxData?.value?.type
                
                if type == InboxType.certOffer.rawValue {
                    if let controller = UIStoryboard(
                        name: "ama-ios-sdk", bundle: UIApplicationUtils.shared.getResourcesBundle()
                    ).instantiateViewController(withIdentifier: "CertificatePreviewViewController")
                        as? CertificatePreviewViewController
                    {
                        let offer = inboxData?.value?.offerCredential
                        if let model = offer,
                           let receiptModel = ReceiptCredentialModel.isReceiptCredentialModel(certModel: model)
                        {
                            //Show Receipt UI
                            controller.mode = .Receipt(model: receiptModel)
                        }
                        controller.viewModel = CertificatePreviewViewModel.init(
                            walletHandle: viewModel?.walletHandle,
                            reqId: inboxData?.value?.connectionModel?.id ?? "",
                            certDetail: offer, inboxId: inboxData?.id,
                            connectionModel: inboxData?.value?.connectionModel,
                            dataAgreement: inboxData?.value?.dataAgreement)
                        controller.viewModel?.inboxModel = inboxData
                        controller.inboxCertState = inboxData?.tags?.state
                        controller.isFromSDK = true
                        navigateTo(controller)
                    }
                } else if type == InboxType.certRequest.rawValue {
                    let req = inboxData?.value?.presentationRequest
                    if let controller = UIStoryboard(
                        name: "ama-ios-sdk", bundle: UIApplicationUtils.shared.getResourcesBundle()
                    ).instantiateViewController(withIdentifier: "ExchangeDataPreviewViewController")
                        as? ExchangeDataPreviewViewController
                    {
                        controller.viewModel = ExchangeDataPreviewViewModel.init(
                            walletHandle: viewModel?.walletHandle, reqDetail: req, inboxId: inboxData?.id,
                            connectionModel: inboxData?.value?.connectionModel, QR_ID: req?.value?.QR_ID ?? "",
                            dataAgreementContext: inboxData?.value?.dataAgreement)
                        controller.isFromSDK = true
                        navigateTo(controller)
                    }
                } else {
                    if let controller = UIStoryboard(name:"ama-ios-sdk", bundle: Bundle.module).instantiateViewController( withIdentifier: "CertificatePreviewViewController") as? CertificatePreviewViewController {
                        var searchModel = SearchItems_CustomWalletRecordCertModel.init()
                        searchModel.value = inboxData?.value?.walletRecordCertModel
                        controller.viewModel = CertificatePreviewViewModel.init(walletHandle: viewModel?.walletHandle, reqId: inboxData?.value?.connectionModel?.id ?? "", certDetail: nil, inboxId: inboxData?.id, certModel: searchModel, connectionModel: inboxData?.value?.connectionModel, dataAgreement: nil)
                        controller.mode = .EBSI_V2
                        if inboxData?.value?.walletRecordCertModel?.subType == EBSI_CredentialType.PDA1.rawValue {
                            controller.mode = .EBSI_PDA1
                        }
                        controller.viewModel?.inboxModel = inboxData
                        controller.inboxCertState = inboxData?.tags?.state
                        controller.isFromSDK = true
                        navigateTo(controller)
                    }
                }
            } else {
                UIApplicationUtils.showErrorSnackbar(message: "No notifications available!")
                return
            }
        }
    }
    
    public func saveConnection(withPopup: Bool, url: String) async -> (Bool, ExchangeDataQRCodeModel?, String?, String?){
        let (success, data, message, id) = await QRCodeUtils.handleQRDataUsingURL(url: url, isConnectionPopNeeded: withPopup)
        return (success, data, message, id)
    }
    
    public func showDataWalletHomeViewController(showBackButton: Bool){
        if !checkIfWalletIsConfigured() {
            UIApplicationUtils.showErrorSnackbar(message: "Wallet not initialised")
            return
        }
        if getViewMode() == .BottomSheet {
            let walletVC = WalletHomeViewController()
            walletVC.isFromSDK = true
            walletVC.viewMode = .BottomSheet
            let sheetVC = WalletHomeBottomSheetViewController(contentViewController: walletVC)
            sheetVC.modalPresentationStyle = .overCurrentContext
            if let topVC = UIApplicationUtils.shared.getTopVC() {
                topVC.present(sheetVC, animated: false, completion: nil)
            }
        } else {
            let controller = WalletHomeViewController()
            controller.isFromSDK = showBackButton
            controller.modalPresentationStyle = .fullScreen
            navigateTo(controller)
        }
    }
    
    public func showDataWalletShareDataHistoryViewController(){
        if !checkIfWalletIsConfigured() {
            UIApplicationUtils.showErrorSnackbar(message: "Wallet not initialised")
            return
        }
        if getViewMode() == .BottomSheet {
            let vc = DataHistoryBottomSheetVC(nibName: "DataHistoryBottomSheetVC", bundle: UIApplicationUtils.shared.getResourcesBundle())
            vc.viewMode = .BottomSheet
            let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
            sheetVC.modalTransitionStyle = .crossDissolve
            
            if let topVC = UIApplicationUtils.shared.getTopVC() {
                topVC.present(sheetVC, animated: true, completion: nil)
            }
        } else {
            if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:Bundle.module).instantiateViewController( withIdentifier: "DataHistoryViewController") as? DataHistoryViewController {
                controller.modalPresentationStyle = .fullScreen
                navigateTo(controller)
            }
        }
        
        
//        if let walletVC = UIStoryboard(name:"ama-ios-sdk", bundle:Bundle.module).instantiateViewController( withIdentifier: "DataHistoryViewController") as? DataHistoryViewController {
//            let navContent = UINavigationController(rootViewController: walletVC)
//            navContent.navigationBar.isHidden = true
//            walletVC.viewMode = .BottomSheet
//            let sheetVC = WalletHomeBottomSheetViewController(contentViewController: navContent)
//            sheetVC.modalPresentationStyle = .overFullScreen
//            sheetVC.modalTransitionStyle = .crossDissolve
//            
//            if let topVC = UIApplicationUtils.shared.getTopVC() {
//                topVC.present(sheetVC, animated: false, completion: nil)
//            }
//        }
    }
    
    public func initiateBackup(){
        if !checkIfWalletIsConfigured() {
            UIApplicationUtils.showErrorSnackbar(message: "Wallet not initialised")
            return
        }
        if getViewMode() == .BottomSheet {
            let walletVC = BackUpViewController()
            let navContent = UINavigationController(rootViewController: walletVC)
            let sheetVC = WalletHomeBottomSheetViewController(contentViewController: navContent)
            navContent.setNavigationBarHidden(true, animated: false)
            sheetVC.modalPresentationStyle = .overFullScreen
            sheetVC.modalTransitionStyle = .crossDissolve
            if let topVC = UIApplicationUtils.shared.getTopVC() {
                topVC.present(sheetVC, animated: false, completion: nil)
            }
        } else {
            let controller = BackUpViewController()
            navigateTo(controller)
        }
    }
    
    public func initiateRestore(completion: @escaping (Bool) -> Void) {
       
        let dataPodVC = RestoreDataPodViewController()
        dataPodVC.onRestoreCompleted = { [self] success in
            DispatchQueue.main.async {
                completion(success)
            }
        }
        navigateTo(dataPodVC)
    }
    
    public func showDataWalletConnectionsViewController(){
        if !checkIfWalletIsConfigured() {
            UIApplicationUtils.showErrorSnackbar(message: "Wallet not initialised")
            return
        }
        if getViewMode() == .BottomSheet {
            let walletVC = ConnectionsViewController()
            walletVC.viewModel = OrganisationListViewModel.init(walletHandle: WalletViewModel.openedWalletHandler, mediatorVerKey: WalletViewModel.mediatorVerKey)
           // let navContent = UINavigationController(rootViewController: walletVC)
            //navContent.setNavigationBarHidden(true, animated: false)
            walletVC.viewMode = .BottomSheet
            let sheetVC = WalletHomeBottomSheetViewController(contentViewController: walletVC)
            sheetVC.modalPresentationStyle = .overCurrentContext
            sheetVC.modalTransitionStyle = .crossDissolve
            
            if let topVC = UIApplicationUtils.shared.getTopVC() {
                topVC.present(sheetVC, animated: false, completion: nil)
            }
        } else {
            let vc = ConnectionsViewController()
            vc.viewModel = OrganisationListViewModel.init(walletHandle: WalletViewModel.openedWalletHandler, mediatorVerKey: WalletViewModel.mediatorVerKey)
            self.navigateTo(vc)
        }
    }
    
    public func showDataWalletScannerViewController(){
        if !checkIfWalletIsConfigured() {
            UIApplicationUtils.showErrorSnackbar(message: "Wallet not initialised")
            return
        }
        
        if getViewMode() == .BottomSheet {
            let walletVC = WalletHomeViewController()
            walletVC.isFromSDK = true
            let navContent = UINavigationController(rootViewController: walletVC)
            navContent.setNavigationBarHidden(true, animated: false)
            walletVC.viewMode = .BottomSheet
            let sheetVC = WalletHomeBottomSheetViewController(contentViewController: navContent)
            sheetVC.modalPresentationStyle = .overFullScreen
            sheetVC.modalTransitionStyle = .crossDissolve
            
            if let topVC = UIApplicationUtils.shared.getTopVC() {
                topVC.present(sheetVC, animated: false, completion: nil)
            }
        } else {
            let controller = WalletHomeViewController()
            controller.isFromSDK = true
            controller.modalPresentationStyle = .fullScreen
            navigateTo(controller)
        }
    }
    
    public func enableWUA(baseURL: String?){
        EBSIWallet.shared.isWUARequired = true
        EBSIWallet.shared.baseURLForWUA = baseURL
    }
    
    public func showDataAgreementScreen(dataAgreementID: String, apiKey: String, orgId: String){
        NetworkManager.shared.get(service: .getDataAgreements(dataAgreementID: dataAgreementID, apiKey: apiKey, orgID: orgId)) { jsonData in
            let dataAgreementQueryResponse = try? JSONDecoder().decode(DataAgreementQueryResponse.self, from: jsonData ?? Data())
            if let dataAgreementModel = dataAgreementQueryResponse?.results?.first, let body = dataAgreementModel.dataAgreement {
                let model = DataAgreementContext.init(message: DataAgreementMessage(body: body, id: dataAgreementModel.dataAgreementID, from: "", to: "", createdTime: "", type: ""), messageType: "")
                let vm = DataAgreementViewModel(dataAgreement: model,
                                                connectionRecordId: "",
                                                mode: .issueCredential)
                let vc = DataAgreementViewController(vm: vm)
                navigateTo(vc)
            }
        }
    }
    
    public func queryCredentials(CredDefId: String,SchemaId: String) async -> String?{
        if !checkIfWalletIsConfigured() {
            UIApplicationUtils.showErrorSnackbar(message: "Wallet not initialised")
            return nil
        }
        var filterDict: [String: String] = [:]
        if CredDefId.isNotEmpty {
            filterDict["cred_def_id"] = CredDefId
        }
        if SchemaId.isNotEmpty {
            filterDict["schema_id"] = SchemaId
        }
        
        let response = try? await AriesPoolHelper.shared.pool_prover_get_credentials(forFilter: filterDict.toString(), walletHandle: WalletViewModel.openedWalletHandler ?? IndyHandle())
        
        return response
    }
    
    public func changeSDKLanguage(languageCode: String){
        Localize.setCurrentLanguage(languageCode)
    }
    
    fileprivate func navigateToScan(_ controller: WalletHomeViewController) {
        if let vc = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
            vc.pushViewController(viewController: controller, animated: false) {
                controller.shareDataTapped()
            }
        } else {
            let nvc = UINavigationController.init(rootViewController: controller)
            let vc = UIApplicationUtils.shared.getTopVC()
            nvc.modalPresentationStyle = .fullScreen
            vc?.present(nvc, animated: false) {
                controller.shareDataTapped()
            }
        }
    }
    
    fileprivate func navigateTo(_ controller: UIViewController) {
        if let vc = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
            vc.pushViewController(viewController: controller, animated: false, completion: nil)
        } else {
            let nvc = UINavigationController.init(rootViewController: controller)
            let vc = UIApplicationUtils.shared.getTopVC()
            nvc.navigationBar.tintColor = .black
            nvc.modalPresentationStyle = .fullScreen
            vc?.present(nvc, animated: false, completion: nil)
        }
    }
    
    func checkIfWalletIsConfigured() -> Bool {
        if WalletViewModel.openedWalletHandler != nil {
            return true
        }
        return false
    }
    
    func checkIfWUAEnabled() -> Bool {
        return WalletViewModel.isWUAEnabled
    }
    
    //    func addBackButton(to viewController: UIViewController) {
    //        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: viewController, action: #selector(viewController.returnBack))
    //        backButton.tintColor = .black
    //        viewController.navigationItem.leftBarButtonItem = backButton
    //    }
    
    func setupGlobalBackButtonAppearance() {
        let backButtonImage = UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysOriginal)
        let backButton = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationController.self])
        let backIndicatorImage = backButtonImage?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0))
        UINavigationBar.appearance().backIndicatorImage = backIndicatorImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backIndicatorImage
        backButton.tintColor = .black
        backButton.title = ""
    }
}
