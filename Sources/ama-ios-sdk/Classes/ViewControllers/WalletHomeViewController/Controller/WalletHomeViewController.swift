//
//  WalletHomeViewController.swift
//  dataWallet
//
//  Created by sreelekh N on 31/10/21.
//

import UIKit
import PassKit
import eudiWalletOidcIos
import DeviceCheck

protocol WalletHomeViewControllerDelegate: WalletHomeViewController {
    func notificationTapped()
    func connectTapped()
    func settingsTapped()
    func addCardTapped()
    func filterAction(filterOn: Int)
    func cardTapped(card: Int)
    func searchStarted(value: String)
    func orgTapped()
}

final class WalletHomeViewController: AriesBaseViewController, NavigationHandlerProtocol {
    func leftTapped(tag: Int) {
        if isFromSDK {
            switch tag {
            case 0: self.returnBack()
                default:
                    self.viewModel.pageDelegate?.notificationTapped()
            }
        } else {
            self.viewModel.pageDelegate?.notificationTapped()
        }
    }
    
    func rightTapped(tag: Int) {
        switch tag {
        case 0:
            self.viewModel.pageDelegate?.settingsTapped()
        case 1:
            self.viewModel.pageDelegate?.connectTapped()
        default:
            self.viewModel.pageDelegate?.orgTapped()
        }
    }
    
    let topView = WalletHomeTitle(type: .home)
    let walletContainer = WalletContainer()
    let viewModel = WalletViewModel.shared
    let floatingBtn = ShareDataFloting()
    var errorView = EmptyMessageView()
    var navHandler: NavigationHandler!
    let coreDataManager: CoreDataManager
    let appReview: AppRatingPrompt
    var isFromSDK = true
    var viewMode: ViewMode = .FullScreen
    
    init() {
        coreDataManager = CoreDataManager()
        appReview = AppRatingPrompt()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .appColor(.walletBg)
        view.addSubview(walletContainer)
        walletContainer.addSubview(errorView)
        view.addSubview(topView)
        view.addSubview(floatingBtn)
        if viewMode == .BottomSheet {
            topView.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 130)
        } else {
            topView.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 150)
        }
        walletContainer.addAnchor(top: topView.bottomAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        floatingBtn.addAnchor(bottom: view.bottomAnchor, paddingBottom: 25, width: 190, height: 60, centerX: view.centerXAnchor)
        errorView.addAnchorFull(walletContainer)
        floatingBtn.shareBtn.setTitle("Scan".localizedForSDK(), for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        EBSIWallet.shared.viewMode = viewMode
        //Check for update
        let versionCheck = VersionCheck()
        versionCheck.isUpdateAvailable { updateRequired in
            //Show UI to update
            debugPrint("update required -- \(updateRequired)")
            if updateRequired{
                versionCheck.showAlert()
            }
        }
        // Do any additional setup after loading the view.
        AriesMobileAgent.themeColor = .black
        if viewMode == .BottomSheet {
            
        } else {
            updateLeftbatBtn(status: false)
        }
        self.viewModel.pageDelegate = self
        viewModel.delegate = self
        floatingBtn.delegate = self
        topView.pageDelegate = self
        
        //SDK
        topView.cvHeight.constant = 0
        topView.collectionView.isHidden = true
        ///
        walletContainer.pageDelegate = viewModel.pageDelegate
        topView.viewMode = viewMode
        if viewMode == .BottomSheet {
            //topView.renderView()
        }
        self.walletContainer.loadStackView()
        // self.appReview.showAppReviewAlert()
        self.configNotifications()
        self.viewModel.checkForDBUpdate()
        if EBSIWallet.shared.isWUARequired && EBSIWallet.shared.baseURLForWUA?.isNotEmpty == true {
//            EBSIWallet.shared.keyHandlerKeyID = EBSIWallet.shared.keyIDforWUA
            viewModel.checkForWUA(baseUrl: EBSIWallet.shared.baseURLForWUA ?? "")
            self.viewModel.fetchWUACredentials()
        } else {
            Task {
                var keyId: String = ""
                let keyIDfromKeyChain = WalletUnitAttestationService().retrieveKeyIdFromKeychain()
                if keyIDfromKeyChain == "" || keyIDfromKeyChain == nil {
                    keyId = try await generateKeyId()
                    storeKeyIdInKeychain(keyId)
                } else {
                    keyId = keyIDfromKeyChain ?? ""
                }
//                EBSIWallet.shared.ptivateKeyData = EBSIWallet.shared.handlePrivateKey()
//                EBSIWallet.shared.didGlobal = EBSIWallet.shared.createDIDKeyIdentifierForV3(privateKey: EBSIWallet.shared.ptivateKeyData!) ?? ""
                EBSIWallet.shared.keyHandlerKeyID = keyId
                EBSIWallet.shared.keyIDforWUA = keyId
                let did = await EBSIWallet.shared.getDIDFromWalletUnitAttestation()
                EBSIWallet.shared.DIDforWUA = did
            }
        }
        self.viewModel.checkForAutoBackup()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkNewNotif()
        self.viewModel.getSavedCertificates()
        checkShared()
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    func updateLeftbatBtn(status: Bool) {
        if isFromSDK {
            updateLeftBarButtonForSDK(status: status)
            return
        }
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(left: status ? [.notificationBadge] : [.notification], right: [])
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
    
    func updateLeftBarButtonForSDK(status: Bool){
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(left: [.back])
    }
    
    @objc func startPolling(){
        debugPrint("polling start")
        WalletViewModel.poolingEnabled = true
        PollingFunction.reCall()
    }
    
    @objc func stopPolling(){
        debugPrint("polling stop")
        WalletViewModel.poolingEnabled = false
    }
    
    override func localizableValues() {
        super.localizableValues()
        topView.lbl.text = "Data Wallet".localizedForSDK()
        topView.searchField.placeholder = "Search".localizedForSDK()
        topView.collectionView.reloadData()
        floatingBtn.shareBtn.setTitle("Scan".localizedForSDK(), for: .normal)
    }
    
    @objc func checkNewNotif() {
        self.viewModel.fetchNotifications { [weak self] status in
            if self?.viewMode == .FullScreen {
                self?.updateLeftbatBtn(status: status)
            }
        }
    }
    
    func configNotifications(){
        let ND = NotificationCenter.default
        ND.addObserver(self, selector: #selector(reloadWallet), name: Constants.reloadWallet, object: nil)
        ND.addObserver(self, selector: #selector(checkNewNotif), name: Constants.didRecieveCertOffer, object: nil)
        ND.addObserver(self, selector: #selector(startPolling), name: UIScene.willEnterForegroundNotification, object: nil)
        ND.addObserver(self, selector: #selector(stopPolling), name: UIScene.didEnterBackgroundNotification, object: nil)
        ND.addObserver(self, selector: #selector(handleSharedQR), name: Constants.handleSharedQR, object: nil)
    }
    
    private func checkShared() {
//        if let dynamicLinkURL = (UIApplication.shared.delegate as? AppDelegate)?.dynamicLink {
//            DynamicLinks.dynamicLinks().handleUniversalLink(dynamicLinkURL) { dynamicLink, error in
//                Task {
//                    _ = await QRCodeUtils.handleQRDataUsingURL(url: dynamicLink?.url?.absoluteString ?? "")
//                    (UIApplication.shared.delegate as? AppDelegate)?.dynamicLink = nil
//                }
//            }
//        }
//        handleSharedQR()
    }
    
    @objc func reloadWallet() {
        self.viewModel.fetchWUACredentials()
        self.viewModel.getSavedCertificates()
        self.checkNewNotif()
    }
    
    @objc func handleSharedQR() {
        let userDefaults = UserDefaults.init(suiteName: "group.Y9726WB7V8.io.iGrant.DataWallet")
        if let imgData = userDefaults?.value(forKey: Constants.sharedExtensionImageData) as? Data {
            SharedQRCodeReader.shared.getQRCodeDetails(imgData: imgData)
            userDefaults?.removeObject(forKey: Constants.sharedExtensionImageData)
        }
        if let pdfData = userDefaults?.value(forKey: Constants.sharedExtensionPDF) as? Data {
            SharedQRCodeReader.shared.getQRCodeDataFromPDF(data: pdfData)
            userDefaults?.removeObject(forKey: Constants.sharedExtensionPDF)
        }
        if let pkPassData = userDefaults?.value(forKey: Constants.sharedExtensionPKPassData) as? Data {
            if (try? PKPass.init(data: pkPassData)) != nil{
                PKPassUtils.shared.getDictionaryFromPKPassData(data: pkPassData , completion: { (dict,imageData) in
                    let vc = CertificateViewController(pageType: .pkPass(isScan: true))
                    if let meta = self.coreDataManager.getPKPassMetaData() {
                        vc.viewModel.pkPass = PKPassStateViewModel(pkPassDict: dict, pkPassData: pkPassData, recordId: "", imageData: imageData, orgName: dict?["organizationName"] as? String ?? "")
                        vc.viewModel.pkPass?.PKPassMeta = meta
                        vc.viewModel.pkPass?.subTitleKeys = (meta["PKPASS BoardingPass Flight Number"] ?? []).map({ e in
                            e.lowercased()
                        })
                        self.push(vc: vc)
                    } else {
                        MetaDataUtils.shared.updatePKPassMetaData {
                            if let meta = self.coreDataManager.getPKPassMetaData() {
                                vc.viewModel.pkPass = PKPassStateViewModel(pkPassDict: dict, pkPassData: pkPassData, recordId: "", imageData: imageData, orgName: dict?["organizationName"] as? String ?? "")
                                vc.viewModel.pkPass?.PKPassMeta = meta
                                vc.viewModel.pkPass?.subTitleKeys = (meta["PKPASS BoardingPass Flight Number"] ?? []).map({ e in
                                    e.lowercased()
                                })
                                self.push(vc: vc)
                            }
                        }
                    }
                })
            }
            userDefaults?.removeObject(forKey: Constants.sharedExtensionPKPassData)
        }
    }
    
    func setEmptyMessage() {
        if self.viewModel.searchCert.isEmpty {
            errorView.isHidden = false
            self.errorView.setValues(value: .label(value: "No data available. Click '+' next to Data Wallet to begin adding data".localizedForSDK()))
        } else {
            errorView.isHidden = true
        }
    }
}

extension WalletHomeViewController: WalletDelegate {
    func walletDataUpdated(itemCount: Int) {
        checkNewNotif()
        if self.viewModel.shouldFetch != nil {
            guard self.viewModel.shouldFetch != viewModel.searchCert.count else {
                if !viewModel.isFirst {
                    self.viewModel.shouldFetch = nil
                    viewModel.isFirst = true
                } else {
                    viewModel.isFirst = false
                }
                return
            }
        } else {
            self.viewModel.shouldFetch = nil
        }
        setEmptyMessage()
        self.walletContainer.loadStackContent(content: viewModel.searchCert)
        self.floatingBtn.isHidden = itemCount == 0 ? true : false
    }
}
