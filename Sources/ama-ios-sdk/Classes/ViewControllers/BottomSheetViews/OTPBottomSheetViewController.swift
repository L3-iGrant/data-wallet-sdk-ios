//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 08/10/25.
//

import Foundation
import AEOTPTextField
import IQKeyboardManagerSwift
import UIKit
import eudiWalletOidcIos


class OTPBottomSheetViewController: UIViewController, AEOTPTextFieldDelegate {
    
    @IBOutlet weak var parentView: UIView!
    
    @IBOutlet weak var parentViewheight: NSLayoutConstraint!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    
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
        titleLabel.text = "Pre-Authorized Request".localizedForSDK()
        IQKeyboardManager.shared.disabledToolbarClasses = [OTPBottomSheetViewController.self]
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
            self.navigationItem.title = "developer_options".localizedForSDK()
            lblDescription.text = "developer_options_pin_desc".localizedForSDK()
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
                
                lblDescription.text = label + "need to authorize the request before issuing the certificate. Please enter the PIN to continue and receive the credential".localizedForSDK()
            } else {
                lblDescription.text = "ebsi_pin_required_desc".localizedForSDK()
            }
            
            self.navigationItem.title = "Pre-Authorized Request".localizedForSDK()
            
           
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        let screenHeight = UIScreen.main.bounds.height
//        let sheetHeight = screenHeight * 0.8
//        parentViewheight.constant = sheetHeight
        if transactionCode?.length ?? 0 > 6 {
            textBox.becomeFirstResponder()
        } else {
            txtOtp.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let screenHeight = UIScreen.main.bounds.height
        let sheetHeight = screenHeight * 0.85
        parentViewheight.constant = sheetHeight
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
   
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        let screenHeight = UIScreen.main.bounds.height
        let targetHeight = screenHeight * 0.85
        
        // Shift the bottom sheet up but don't shrink it
        let visibleHeight = screenHeight - keyboardHeight + 134 // add small padding

        // If keyboard would overlap, adjust height slightly smaller
        parentViewheight.constant = min(targetHeight, visibleHeight)
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        let screenHeight = UIScreen.main.bounds.height
        let sheetHeight = screenHeight * 0.85
        parentViewheight.constant = sheetHeight

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
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
                UIApplicationUtils.showErrorSnackbar(message: "developer_options_invalid_pin".localizedForSDK())
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
                            self.dismiss(animated: true)
                            //self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        UIApplicationUtils.showErrorSnackbar(message: "Invalid pin.".localizedForSDK())
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
}

extension OTPBottomSheetViewController: UITextFieldDelegate {
    
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
    
    
