//
//  SplashViewController.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 19/01/21.
//

import UIKit
import LocalAuthentication
import Reachability
import IndyCWrapper

struct AuthIdModel {
    var config: String
    var cred: String
    
    init() {
        let deviceID = UIDevice.current.identifierForVendor!.uuidString
        config = "{\"id\": \"\(deviceID)\"}"
        cred = "{\"key\": \"\(deviceID)\"}"
    }
}

class SplashViewController: AriesBaseViewController {
    
    @IBOutlet weak var loadingStatus: UILabel!
    let reachability = try! Reachability()

    //For maintanining min 2 sec screen time for splash screen in some high end device
    private var startTime: Double!
    private var endTime: Double!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    var isFromWelcome: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        self.loadingStatus.text = "Authenticating...".localizedForSDK()
        openWalletRoot()
        startTime = Date().timeIntervalSince1970
    }
    
    func createWallet(model: WalletViewModel,completion: @escaping (Bool?) -> Void) {
        let auth = AuthIdModel()
        AgentWrapper.shared.createWallet(withConfig: auth.config, credentials: auth.cred, completion: { [weak self](error) in
            if (error != nil) {
                print("wallet created")
                self?.openWallet(model: model,completion: completion)
            }
        })
    }
    
    func openWallet(model: WalletViewModel,completion: @escaping (Bool?) -> Void) {
        if !isFromWelcome {
            self.loadingStatus.text = "Configuring wallet...".localizedForSDK()
        } else {
            UIApplicationUtils.showLoader()
        }
        let auth = AuthIdModel()
        AgentWrapper.shared.openWallet(withConfig: auth.config, credentials: auth.cred) { [weak self] (error, indyHandle) in
            if (indyHandle == 0) {
                self?.createWallet(model: model,completion: completion)
            } else {
                QuickActionNavigation.shared.walletHandle = indyHandle
                QuickActionNavigation.shared.mediatorVerKey = WalletViewModel.mediatorVerKey
                model.walletHandle = indyHandle
                print("wallet opened")
                self?.endTime = Date().timeIntervalSince1970
                let differenceInSeconds = Int(self?.endTime ?? 0) - Int(self?.startTime ?? 0)
                if differenceInSeconds > 2 {
                    completion(true)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        completion(true)
                    }
                }
               
                if self?.reachability.connection != .unavailable {
                    WalletViewModel.shared.checkMediatorConnectionAvailable()
    //                if !(self?.isFromWelcome ?? false) {
    //                    self?.loadingStatus.text = "Configuring pool...".localizedForSDK()
    //                }
                    
                    AriesPoolHelper.shared.configurePool(walletHandler: indyHandle,completion: {_ in
                        UIApplicationUtils.shared.hideLedgerConfigToast()
                        MetaDataUtils.shared.checkForMetaDataUpdate()
                    })
                    UIApplicationUtils.shared.showLedgerConfigToast()
                }
                
            }
        }
    }
    
    func openWalletRoot() {
        //debug gng on
        //                    let vc = WalletHomeViewController()
        //                            self.gotoRootTab(vc)
        
//        let launchedBefore = UserDefaults.standard.launchedBefore
//        if launchedBefore ?? false  {
            let vc = WalletHomeViewController()
            self.openWallet(model: vc.viewModel) { success in
                UIApplicationUtils.hideLoader()
                QuickActionNavigation.shared.shouldNavigate = true
                self.gotoRootTab(vc)
            }
//        } else {
//            let vc = OnBoardMainViewController()
//            self.gotoRootTab(vc)
//        }
    }
}

extension SplashViewController {
    
    func authenticationWithTouchID() {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = "Use Passcode"
        
        var authError: NSError?
        let reasonString = "To access the secure data"
        
        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
            
            localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reasonString) { success, evaluateError in
                
                if success {
                    self.openWalletRoot()
                } else {
                    //TODO: User did not authenticate successfully, look at error and take appropriate action
                    guard let error = evaluateError else {
                        return
                    }
                    
                    debugPrint(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code))
                    
                    //TODO: If you have choosen the 'Fallback authentication mechanism selected' (LAError.userFallback). Handle gracefully
                    
                }
            }
        } else {
            
            guard let error = authError else {
                return
            }
            //TODO: Show appropriate alert if biometry/TouchID/FaceID is lockout or not enrolled
            debugPrint(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error.code))
        }
    }
    
    func evaluatePolicyFailErrorMessageForLA(errorCode: Int) -> String {
        var message = ""
        if #available(iOS 11.0, macOS 10.13, *) {
            switch errorCode {
            case LAError.biometryNotAvailable.rawValue:
                message = "Authentication could not start because the device does not support biometric authentication."
                
            case LAError.biometryLockout.rawValue:
                message = "Authentication could not continue because the user has been locked out of biometric authentication, due to failing authentication too many times."
                
            case LAError.biometryNotEnrolled.rawValue:
                message = "Authentication could not start because the user has not enrolled in biometric authentication."
                
            default:
                message = "Did not find error code on LAError object"
            }
        } else {
            switch errorCode {
            case LAError.touchIDLockout.rawValue:
                message = "Too many failed attempts."
                
            case LAError.touchIDNotAvailable.rawValue:
                message = "TouchID is not available on the device"
                
            case LAError.touchIDNotEnrolled.rawValue:
                message = "TouchID is not enrolled on the device"
                
            default:
                message = "Did not find error code on LAError object"
            }
        }
        return message;
    }
    
    func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
        var message = ""
        switch errorCode {
        case LAError.authenticationFailed.rawValue:
            message = "The user failed to provide valid credentials"
            
        case LAError.appCancel.rawValue:
            message = "Authentication was cancelled by application"
            
        case LAError.invalidContext.rawValue:
            message = "The context is invalid"
            
        case LAError.notInteractive.rawValue:
            message = "Not interactive"
            
        case LAError.passcodeNotSet.rawValue:
            message = "Passcode is not set on the device"
            
        case LAError.systemCancel.rawValue:
            message = "Authentication was cancelled by the system"
            showAuthenticationError()
        case LAError.userCancel.rawValue:
            message = "The user did cancel"
            showAuthenticationError()
            
        case LAError.userFallback.rawValue:
            message = "The user chose to use the fallback"
        default:
            message = evaluatePolicyFailErrorMessageForLA(errorCode: errorCode)
        }
        return message
    }
    
    func showAuthenticationError() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Data Wallet locked", message: "Please authenticate to continue", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Authenticate", style: UIAlertAction.Style.default, handler: { _ in
                DispatchQueue.main.async {
                    self.authenticationWithTouchID()
                }
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
