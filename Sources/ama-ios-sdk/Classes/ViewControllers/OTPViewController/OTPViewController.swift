//
//  OTPViewController.swift
//  ama-ios-sdk
//
//  Created by iGrant on 01/08/25.
//

import Foundation
import AEOTPTextField
import IQKeyboardManagerSwift
import UIKit
import eudiWalletOidcIos

class OTPViewController : AriesBaseViewController, AEOTPTextFieldDelegate {
    @IBOutlet weak var imageViewLogo: UIImageView!
    @IBOutlet weak var btnNext: UIButton!
    @IBOutlet weak var txtOtp: AEOTPTextField!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var textBox: UITextField!
    
    @IBOutlet weak var shadowView: UIView!
    //process this data to show logo
    var data : IssuerWellKnownConfiguration? = nil
    var codeReceivedForDeveloperOption = ""
    var transactionCode: TransactionCode? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
    func setUpUI() {
        IQKeyboardManager.shared.disabledToolbarClasses = [OTPViewController.self]
        btnNext.layer.cornerRadius = 25
        self.shadowView.setShadowWithColor(color: .gray, opacity: 0.5, offset: CGSize.zero, radius: 5, viewCornerRadius: 65)
        if transactionCode?.length ?? 0 > 6 {
            txtOtp.isHidden = true
            textBox.isHidden = false
            textBox.delegate = self
            textBox.keyboardType = transactionCode?.inputMode == "numeric" ? .numberPad : .default
            textBox.isSecureTextEntry = true
            textBox.layer.borderWidth = 1
            textBox.layer.borderColor = UIColor.black.cgColor
            textBox.layer.cornerRadius = 8
            textBox.isUserInteractionEnabled = true
            textBox.textAlignment = .center
        } else {
            txtOtp.isHidden = false
            textBox.isHidden = true
            txtOtp.otpDelegate = self
            txtOtp.configure(with: transactionCode?.length ?? 4)
            txtOtp.isSecureTextEntry = true
            txtOtp.keyboardType = transactionCode?.inputMode == "numeric" ? .numberPad : .default
        }
        if codeReceivedForDeveloperOption != "" {
            imageViewLogo.contentMode = .scaleAspectFit
            self.navigationItem.title = "developer_options".localized()
            lblDescription.text = "developer_options_pin_desc".localized()
            imageViewLogo.image = UIImage(named: "iGrant_1920_1080_Black_R")
        } else {
            
            let issuerConfig = self.data
            
            let display = EBSIWallet.shared.getDisplayFromIssuerConfig(config: issuerConfig)
            
            if display != nil {
                let url = display?.logo?.url ?? display?.logo?.uri
                let orgName = display?.name
                ImageUtils.shared.setRemoteImage(for: imageViewLogo, imageUrl: url, orgName: orgName)
            } else {
                imageViewLogo.image = UIImage(named: "ic_ebsi")
            }
            if let desc = transactionCode?.description,  desc.isNotEmpty {
                lblDescription.text = desc
            } else if let label = display?.name {
                
                lblDescription.text = label + "need to authorize the request before issuing the certificate. Please enter the PIN to continue and receive the credential".localized()
            } else {
                lblDescription.text = "ebsi_pin_required_desc".localized()
            }
            
            self.navigationItem.title = "Pre-Authorized Request".localizedForSDK()
            
           
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if transactionCode?.length ?? 0 > 6 {
            textBox.becomeFirstResponder()
        } else {
            txtOtp.becomeFirstResponder()
        }
    }
    
    func didUserFinishEnter(the code: String) {
        if codeReceivedForDeveloperOption != "" {
            if code == codeReceivedForDeveloperOption {
//                DispatchQueue.main.async {
//                    self.txtOtp.clearOTP()
//                    let storyBoard : UIStoryboard = UIStoryboard(name: "AriesMobileAgent", bundle:nil)
//                    let developerVC = storyBoard.instantiateViewController(withIdentifier: "DeveloperOptionsViewController") as! DeveloperOptionsViewController
//                    if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
//                        navVC.pushViewController(developerVC, animated: true)
//                    }
//                }
            } else {
                UIApplicationUtils.showErrorSnackbar(message: "developer_options_invalid_pin".localized())
            }
        } else {
            EBSIWallet.shared.otpVal = code
            let privateKey = EBSIWallet.shared.handlePrivateKey()
            let responseModel = self.data
            let authServerUrl = AuthorizationServerUrlUtil().getAuthorizationServerUrl(issuerConfig: EBSIWallet.shared.issuerConfig, credentialOffer: EBSIWallet.shared.credentialOffer)
            let authServer = EBSIWallet.shared.getAuthorizationServerFromCredentialOffer(credential: EBSIWallet.shared.credentialOffer) ?? authServerUrl
            if #available(iOS 14.0, *) {
                EBSIWallet.shared.openIdAuthorisation(authServerUrl: (authServer == nil ? EBSIWallet.shared.credentialOffer?.credentialIssuer : authServer) ?? "" , privateKey: privateKey, credentialOffer: EBSIWallet.shared.credentialOffer, issuerConfig: EBSIWallet.shared.issuerConfig) { isNotAPinError in
                    if isNotAPinError! {
                        DispatchQueue.main.async {
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        UIApplicationUtils.showErrorSnackbar(message: "Invalid pin.".localized())
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
}

extension OTPViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == textBox {
            let currentText = textField.text ?? ""
            let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
            if updatedText.count == (transactionCode?.length ?? 0) {
                textField.resignFirstResponder()
                //didUserFinishEnter(the: updatedText)
                return false
            }
            return updatedText.count <= (transactionCode?.length ?? 6)
        }
        return true
    }
    
}
 
