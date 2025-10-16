//
//  ConnectionPopupViewController.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 18/12/20.
//

import UIKit
import Loady
import SVProgressHUD
import SwiftUI
import IndyCWrapper
import eudiWalletOidcIos


class ConnectionPopupViewController: AriesBaseViewController {
    
    @IBOutlet weak var orgImage: UIImageView!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var connectButton: LoadyButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var shadowView: UIView!
    var viewModel: ConnectionPopupViewModel?
    var completion: ((CloudAgentConnectionWalletModel?,String?,String?,String?) -> Void)?
    var completionDynamic: ((CloudAgentConnectionWalletModel?,String?,String?) -> Void)?
    var mode: CertificatePreviewVC_Mode = .other
    var orgName: String? {
        didSet{
            //            self.descriptionLabel.attributedText = NSMutableAttributedString().normal("Allow".localizedForSDK()).bold(" " + (orgName ?? "")).normal(" ").normal("to connect with you".localizedForSDK())
            self.descriptionLabel.text = orgName ?? ""
        }
    }
    var isVerification: Bool = false
   var issuerConfig: IssuerWellKnownConfiguration? = nil
   var credentialOffer: CredentialOffer? = nil
    var viewMode: ViewMode = .FullScreen

    
    @available(*, renamed: "showConnectionPopup(orgName:orgImageURL:walletHandler:recipientKey:serviceEndPoint:routingKey:isFromDataExchange:didCom:)")
    func showConnectionPopup(orgName: String?,orgImageURL: String?,walletHandler: IndyHandle?,recipientKey: String?,serviceEndPoint: String?,routingKey: [String]?,isFromDataExchange: Bool,didCom: String, completion: @escaping ((CloudAgentConnectionWalletModel?,String?,String?,String?) -> Void)){ //connmodel,recipeintkey,myverkey
        UIApplicationUtils.showLoader()
        
        //check connection with same Org Exist
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
            DispatchQueue.main.async {
                if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "ConnectionPopupViewController") as? ConnectionPopupViewController {
                    controller.viewModel = ConnectionPopupViewModel.init(orgName: orgName, orgImageURL: orgImageURL, walletHandler: walletHandler, recipientKey: recipientKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey,orgId:orgDetails?.orgId ,orgDetails: orgDetails, didCom: didCom)
                    controller.modalPresentationStyle = .overFullScreen
                    controller.completion = completion
                    
                        let VC = UIApplicationUtils.shared.getTopVC()
                        if let navVC = VC as? UINavigationController {
                            let firstVC = navVC.viewControllers.first ?? navVC
                            firstVC.present(controller, animated: false, completion: nil)
                            return
                        }
                        VC?.present(controller, animated: false, completion: nil)
                }
            }
        }
    }
    
    func showConnectionPopup(orgName: String?,orgImageURL: String?,walletHandler: IndyHandle?,recipientKey: String?,serviceEndPoint: String?,routingKey: [String]?,isFromDataExchange: Bool,didCom: String) async -> (CloudAgentConnectionWalletModel?, String?, String?, String?) {
        return await withCheckedContinuation { continuation in
            let connectionVC = ConnectionPopupViewController()
            connectionVC.showConnectionPopup(orgName: orgName, orgImageURL: orgImageURL, walletHandler: walletHandler, recipientKey: recipientKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey, isFromDataExchange: isFromDataExchange, didCom: didCom) { result1, result2, result3,message  in
                continuation.resume(returning: (result1, result2, result3, message))
            }
        }
    }
    
    static func showConnectionPopupForDynamicOrg(walletHandler: IndyHandle, orgName: String?, orgImageURL: String?, orgId: String? ,orgDetails: OrganisationInfoModel?, isVerification: Bool = false, issuerConfig: IssuerWellKnownConfiguration?, credentialOffer: CredentialOffer?) async -> (CloudAgentConnectionWalletModel?, String?, String?) {
        return await withCheckedContinuation { continuation in
            showConnectionPopupForDynamicOrg(walletHandler: walletHandler, orgName: orgName, orgImageURL: orgImageURL, orgId: orgId, orgDetails: orgDetails, isVerification: isVerification, issuerConfig: issuerConfig, credentialOffer: credentialOffer) { result1, result2, result3 in
                continuation.resume(returning: (result1, result2, result3))
            }
        }
    }
    
    static func showConnectionPopupForDynamicOrg(walletHandler: IndyHandle, orgName: String?, orgImageURL: String?, orgId: String? ,orgDetails: OrganisationInfoModel?, isVerification: Bool = false, issuerConfig: IssuerWellKnownConfiguration?, credentialOffer: CredentialOffer?, completion: @escaping ((CloudAgentConnectionWalletModel?, String?, String?) -> Void)) {
        if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "ConnectionPopupViewController") as? ConnectionPopupViewController {
            controller.viewModel = ConnectionPopupViewModel.init(orgName: orgName, orgImageURL: orgImageURL, walletHandler: walletHandler, recipientKey: nil, serviceEndPoint: nil, routingKey: nil,orgId: orgId ,orgDetails: orgDetails, didCom: "")
            controller.completionDynamic = completion
            controller.issuerConfig = issuerConfig
            controller.credentialOffer = credentialOffer
            controller.mode = .dynamicOrg
            controller.viewMode = EBSIWallet.shared.viewMode
            controller.modalPresentationStyle = .overFullScreen
            controller.isVerification = isVerification
            let VC = UIApplicationUtils.shared.getTopVC()
            if let navVC = VC as? UINavigationController {
                let firstVC = navVC.viewControllers.first ?? navVC
                DispatchQueue.main.async {
                    firstVC.present(controller, animated: false, completion: nil)
                }
                return
            }
            DispatchQueue.main.async {
                VC?.present(controller, animated: false, completion: nil)
            }
        }
    }
    
    @available(*, renamed: "showConnectionPopupForEBSI(walletHandler:orgName:orgImageURL:orgId:orgDetails:)")
    static func showConnectionPopupForEBSI(walletHandler: IndyHandle, orgName: String?, orgImageURL: String?, orgId: String? ,orgDetails: String?, completion: @escaping ((CloudAgentConnectionWalletModel?, String?, String?, String?) -> Void)) {
        if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "ConnectionPopupViewController") as? ConnectionPopupViewController {
            controller.viewModel = ConnectionPopupViewModel.init(orgName: orgName, orgImageURL: orgImageURL, walletHandler: walletHandler, recipientKey: nil, serviceEndPoint: nil, routingKey: nil,orgId: orgId ,orgDetails: nil, didCom: "")
            controller.completion = completion
            controller.mode = .EBSI_V2
            controller.modalPresentationStyle = .overFullScreen
            let VC = UIApplicationUtils.shared.getTopVC()
            if let navVC = VC as? UINavigationController {
                let firstVC = navVC.viewControllers.first ?? navVC
                DispatchQueue.main.async {
                    firstVC.present(controller, animated: false, completion: nil)
                }
                return
            }
            DispatchQueue.main.async {
                VC?.present(controller, animated: false, completion: nil)
            }
        }
    }
    
    static func showConnectionPopupForEBSI(walletHandler: IndyHandle, orgName: String?, orgImageURL: String?, orgId: String? ,orgDetails: String?) async -> (CloudAgentConnectionWalletModel?, String?, String?) {
        return await withCheckedContinuation { continuation in
            showConnectionPopupForEBSI(walletHandler: walletHandler, orgName: orgName, orgImageURL: orgImageURL, orgId: orgId, orgDetails: orgDetails) { result1, result2, result3, message in
                continuation.resume(returning: (result1, result2, result3))
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.delegate = self
        connectButton.setAnimation(LoadyAnimationType.android())
        self.orgName = viewModel?.orgName ?? ""
        UIApplicationUtils.shared.setRemoteImageOn(self.orgImage, url: viewModel?.orgImageURL)
        self.connectButton.layer.cornerRadius = 15
        self.rejectButton.layer.cornerRadius = 15
        self.orgImage.layer.cornerRadius = 40
        self.baseView.layer.cornerRadius = 20
        self.shadowView.setShadowWithColor(color: .gray, opacity: 0.5, offset: CGSize.zero, radius: 5, viewCornerRadius: 40)
        connectButton.backgroundColor = AriesMobileAgent.themeColor
        //        rejectButton.backgroundColor = AriesMobileAgent.themeColor.withAlphaComponent(0.7)
        connectButton.loadingColor = AriesMobileAgent.themeColor
        connectButton.backgroundFillColor = AriesMobileAgent.themeColor
        self.view.backgroundColor = .clear
    }
    
    override func localizableValues() {
        super.localizableValues()
        self.connectButton.setTitle("Connect".localizedForSDK(), for: .normal)
        self.orgName = viewModel?.orgName ?? ""
    }
    
    @IBAction func declineButtonTapped(_ sender: Any) {
        UIApplicationUtils.hideLoader()
        completion?(nil,nil,nil,nil)
        self.dismiss(animated: false, completion: nil)
    }
    
    @available(iOS 14.0, *)
    @IBAction func connectButtonTapped(_ sender: Any) {
            self.connectButton.isUserInteractionEnabled = false
            self.connectButton.startLoading()
        //        rejectButton.isHidden = true
        switch mode {
        case .EBSI_V2,.EBSI_PDA1, .PhotoIDWithAgeBadge:
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                Task{
                    await self.viewModel?.EBSI_V2_connection_configure()
                }
            }
        case .Receipt:
            self.viewModel?.startConnection()
        case .other:
            self.viewModel?.startConnection()
        case .dynamicOrg:
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.5) {
                EBSIWallet.shared.EBSI_V3_store_dynamic_organisation_details(responseData: self.issuerConfig, isVerification: self.isVerification, credentialOffer: self.credentialOffer) { success in
                    self.connectButton.stopLoading()
                    self.connectButton.isUserInteractionEnabled = true
                    self.orgImage.isHidden = true
                    self.descriptionLabel.isHidden = true
                    self.connectButton.isHidden = true
                    self.shadowView.isHidden = true
                    self.rejectButton.isHidden = true
                    self.dismiss(animated: false, completion: nil)
                    UIApplicationUtils.showSuccessSnackbar(message: "Connection success".localizedForSDK())
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
                        self.dismiss(animated: false, completion: nil)
                        NotificationCenter.default.post(name: Constants.reloadOrgList, object: nil)
                        if self.isVerification {
                            EBSIWallet.shared.processDataForVPExchange()
                        } else if (EBSIWallet.shared.transactionCode != nil) {
                            UIApplicationUtils.hideLoader()
                            if viewMode == .BottomSheet {
                                let vc = OTPBottomSheetViewController(nibName: "OTPBottomSheetViewController", bundle: UIApplicationUtils.shared.getResourcesBundle())
                                vc.modalPresentationStyle = .overFullScreen
                                vc.modalTransitionStyle = .crossDissolve
                                vc.data = EBSIWallet.shared.issuerConfig
                                vc.transactionCode = credentialOffer?.grants?.urnIETFParamsOauthGrantTypePreAuthorizedCode?.txCode
                                if let topVC = UIApplicationUtils.shared.getTopVC() {
                                    topVC.present(vc, animated: true, completion: nil)
                                }
                                
                            } else {
                                let storyBoard : UIStoryboard = UIStoryboard(name: "ama-ios-sdk", bundle: UIApplicationUtils.shared.getResourcesBundle())
                                let nextVC = storyBoard.instantiateViewController(withIdentifier: "OTPViewController") as! OTPViewController
                                nextVC.data = EBSIWallet.shared.openIdIssuerResponseData
                                nextVC.transactionCode = EBSIWallet.shared.transactionCode
                                if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController{
                                    navVC.pushViewController(nextVC, animated: true)
                                } else{
                                    UIApplicationUtils.shared.getTopVC()?.push(vc: nextVC)
                                }
                            }
                        } else {
                            let privateKey = EBSIWallet.shared.handlePrivateKey()
                        let responseModel = self.issuerConfig
                        let authServerUrl = AuthorizationServerUrlUtil().getAuthorizationServerUrl(issuerConfig: self.issuerConfig, credentialOffer: self.credentialOffer)
                        let authServer = EBSIWallet.shared.getAuthorizationServerFromCredentialOffer(credential: self.credentialOffer) ?? authServerUrl
                        EBSIWallet.shared.openIdAuthorisation(authServerUrl: (authServer == nil ? self.credentialOffer?.credentialIssuer : authServer) ?? "", privateKey: privateKey, credentialOffer: credentialOffer, issuerConfig: issuerConfig) { success in
                                if success! {
                                    DispatchQueue.main.async {
                                        self.navigationController?.popViewController(animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension ConnectionPopupViewController: ConnectionPopupViewModelDelegate{
    func tappedOnConnect() {}
    
    func connectionEstablised(connModel:CloudAgentConnectionWalletModel, recipientKey: String, myVerKey:String) {
        connectButton.stopLoading()
        connectButton.isUserInteractionEnabled = true
        self.dismiss(animated: false, completion: nil)
        connModel.value?.orgDetails = viewModel?.orgDetails
        let message = "Connection success".localizedForSDK()
        NotificationCenter.default.post(name: Constants.reloadOrgList, object: nil)
        if let completionBlock = completion {
            completionBlock(connModel,recipientKey,myVerKey,message)
        }
    }
    
    func dismissPopup(){
        self.dismiss(animated: false, completion: nil)
    }
}
