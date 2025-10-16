//
//  PWAPreviewViewController.swift
//  dataWallet
//
//  Created by iGrant on 04/02/25.
//

import Foundation
import eudiWalletOidcIos
import UIKit

class PWAPreviewViewController: UIViewController {
    
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var infoText: UILabel!
    @IBOutlet weak var companyLogo: UIImageView!
    @IBOutlet weak var companyName: UILabel!
    @IBOutlet weak var companyLocation: UILabel!
    
    @IBOutlet weak var cardView: UIView!
        
    @IBOutlet weak var cardVerifierLogo: UIImageView!
    @IBOutlet weak var cardTypeLabel: UILabel!
    
    @IBOutlet weak var cardLogo: UIImageView!
    
    @IBOutlet weak var cardNumber: UILabel!
    
    @IBOutlet weak var cardBgImageView: UIImageView!
    
    @IBOutlet weak var blurredTextView: BlurredTextView!
    
    @IBOutlet weak var verifierLogoWidth: NSLayoutConstraint!
    
    
    @IBOutlet weak var verifierLogoHeight: NSLayoutConstraint!
    
    @IBOutlet weak var trustServiceProviderStackView: UIStackView!
    
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    @IBOutlet weak var trustedServiceLabel: UILabel!
    
    var viewModel: PWAPreviewViewModel?
    var showValues = false
    private var didAccept = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        acceptButton.layer.cornerRadius = 25
        rejectButton.layer.cornerRadius = 25
        companyLogo.layer.cornerRadius = 35
        acceptButton.backgroundColor = AriesMobileAgent.themeColor
        rejectButton.backgroundColor = AriesMobileAgent.themeColor.withAlphaComponent(0.7)
        self.companyName.numberOfLines = 0
        self.companyLocation.text = viewModel?.connectionModel?.value?.orgDetails?.location ??  viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.location ?? ""
        self.companyLocation.numberOfLines = 2
        self.companyName.text = viewModel?.connectionModel?.value?.orgDetails?.name ??
        self.viewModel?.certModel?.value?.attributes?["name"]?.value ?? ""
        self.companyLocation.text = viewModel?.connectionModel?.value?.orgDetails?.location ??  (self.viewModel?.certModel?.value?.attributes?["address"]?.value?.split(separator: " ").last ?? "") + ", European Union"
        addRightBarButton()
        viewModel?.delegate = self
        cardView.layer.cornerRadius = 15
        cardBgImageView.layer.cornerRadius = 15
        self.title = "general_data_agreement".localizedForSDK()
        if viewModel?.certModel?.value?.subType == EBSI_CredentialType.PWA.rawValue {
            self.infoText.text = EBSIWallet.shared.credentialDisplay?.description ?? "You requested the following data to be issued. By choosing accept you agree to add the data to your Data Wallet.".localizedForSDK()
        } else {
            self.infoText.text = LocalizationSheet.agree_add_data_to_wallet.localizedForSDK()
        }
        self.acceptButton.setTitle("general_accept".localizedForSDK(), for: .normal)
        let imageUrl = viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.logoImageURL
        let orgName = viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.name
        let bgColor = viewModel?.certModel?.value?.backgroundColor
        ImageUtils.shared.setRemoteImage(for: companyLogo, imageUrl: imageUrl, orgName: orgName, bgColor: bgColor)
        setCredentialBranding()
        cardView.layer.shadowColor = UIColor.gray.cgColor
        cardView.layer.shadowOpacity = 0.5
        cardView.layer.shadowRadius = 8
        cardView.layer.masksToBounds = false
        cardView.layer.shadowOffset = CGSize(width: 0, height: 0)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(trustServicetapped))
        self.trustServiceProviderStackView.addGestureRecognizer(tapGesture)
        setTrustedOrganization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCardDetailsFromFundingSource()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        Task {
            if !(viewModel?.isRejectOrAcceptTapped ?? false) && viewModel?.inboxId?.isEmpty ?? false {
                    if let accept = viewModel?.onAccept {
                        accept(true)
                    }

                if let notificationEndPont = viewModel?.certModel?.value?.notificationEndPont, let notificationID = viewModel?.certModel?.value?.notificationID {
                    let accessTokenParts = viewModel?.certModel?.value?.accessToken?.split(separator: ".")
                    var accessTokenData: String? =  nil
                    var refreshTokenData: String? =  nil
                    if accessTokenParts?.count ?? 0 > 1 {
                        let accessTokenBody = "\(accessTokenParts?[1] ?? "")".decodeBase64()
                        let dict = UIApplicationUtils.shared.convertToDictionary(text: String(accessTokenBody ?? "{}")) ?? [:]
                        let exp = dict["exp"] as? Int ?? 0
                        let expiryDate = TimeInterval(exp)
                        let currentTimestamp = Date().timeIntervalSince1970
                        if expiryDate < currentTimestamp {
                            accessTokenData = await NotificationService().refreshAccessToken(refreshToken: viewModel?.certModel?.value?.refreshToken ?? "", endPoint: viewModel?.certModel?.value?.tokenEndPoint ?? "").0
                            refreshTokenData = await NotificationService().refreshAccessToken(refreshToken: viewModel?.certModel?.value?.refreshToken ?? "", endPoint: viewModel?.certModel?.value?.tokenEndPoint ?? "").1
                        } else {
                            accessTokenData = viewModel?.certModel?.value?.accessToken
                            refreshTokenData = viewModel?.certModel?.value?.refreshToken
                        }
                    }
                    viewModel?.certModel?.value?.refreshToken = refreshTokenData
                    viewModel?.certModel?.value?.accessToken = accessTokenData
                    await NotificationService().sendNoticationStatus(endPoint: viewModel?.certModel?.value?.notificationEndPont, event: NotificationStatus.credentialDeleted.rawValue, notificationID: viewModel?.certModel?.value?.notificationID, accessToken: viewModel?.certModel?.value?.accessToken ?? "", refreshToken: viewModel?.certModel?.value?.refreshToken ?? "", tokenEndPoint: viewModel?.certModel?.value?.tokenEndPoint ?? "")
                }
            }
        }
    }
    
    func setTrustedOrganization() {
        if let isValidOrganization = viewModel?.connectionModel?.value?.orgDetails?.isValidOrganization {
            if isValidOrganization {
                trustServiceProviderStackView.isHidden = false
                companyLocation.isHidden = true
                verifiedImageView.image = "gpp_good".getImage()
                verifiedImageView.tintColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.textColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.text = "general_trusted_service_provider".localizedForSDK()
            } else {
                trustServiceProviderStackView.isHidden = false
                companyLocation.isHidden = true
                verifiedImageView.image = "gpp_bad".getImage()
                verifiedImageView.tintColor = .systemRed
                trustedServiceLabel.textColor = .systemRed
                trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
            }
        } else {
            trustServiceProviderStackView.isHidden = true
            companyLocation.isHidden = false
        }
    }
    
    @objc func trustServicetapped() {
        let credential = viewModel?.certModel?.value?.EBSI_v2?.credentialJWT
        TrustMechanismManager().trustProviderInfo(credential: credential, format: viewModel?.certModel?.value?.format, jwksURI: viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.jwksURL) { data in
            if let data = data {
                DispatchQueue.main.async {
                    let vc = TrustServiceProviersBottomSheetVC(nibName: "TrustServiceProviersBottomSheetVC", bundle: nil)
                    vc.modalPresentationStyle = .overFullScreen
                    vc.modalTransitionStyle = .crossDissolve
                    vc.viewModel.data = data
                    vc.viewModel.credential = credential
                    if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                        navVC.present(vc, animated: true, completion: nil)
                    } else {
                        UIApplicationUtils.shared.getTopVC()?.push(vc: vc)
                    }
                }
            }
        }
    }
    
    func setCardDetailsFromFundingSource() {
        guard let fundingSource = viewModel?.fundingSource else { return }
        blurredTextView.blurStatus = showValues
        blurredTextView.blurLbl.textAlignment = .left
        blurredTextView.blurLbl.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        blurredTextView.text = "****" + " " + (fundingSource.panLastFour ?? "")
        if let cover = viewModel?.certModel?.value?.cover {
            UIApplicationUtils.shared.setRemoteImageOn(cardBgImageView, url: cover)
        } else {
            cardBgImageView.backgroundColor = UIColor(hex: viewModel?.certModel?.value?.backgroundColor ?? "")
        }
        cardLogo.image = getLogoDetails(cardScheme: fundingSource.scheme)
        ImageUtils.shared.loadImage(from: fundingSource.icon ?? "", imageIcon: cardVerifierLogo, logoWidth: verifierLogoWidth, logoHeight: verifierLogoHeight)
    }
    
    func setCredentialBranding() {
        if let textColor = viewModel?.certModel?.value?.textColor  {
            blurredTextView.blurLbl.textColor = UIColor(hex: textColor)
            cardLogo.tintColor = UIColor(hex: textColor)
        }
    }
    
    func getLogoDetails(cardScheme: String?) -> UIImage {
            guard let cardScheme = cardScheme, !cardScheme.isEmpty else {
                return UIImage(named: "visa")!
            }
        if cardScheme.contains("visa") {
            return "visa".getImage()
            } else if  cardScheme.contains("Mastercard"){
                return "mastercard".getImage()
            } else if  cardScheme.contains("American Express"){
                return "american_express".getImage()
            } else if cardScheme.contains("JCB") {
                return "jcb".getImage()
            } else if cardScheme.contains("Discover") {
                return "discover".getImage()
            } else if cardScheme.contains("RuPay") {
                return "RuPay".getImage()
            } else if cardScheme.contains("maestro") {
                return "maestro".getImage()
            } else {
                return "visa".getImage()
            }
    }
    
    func addRightBarButton() {
        let eyeButton = UIButton(type: .custom)
        eyeButton.setImage(!showValues ? "eye".getImage() : "eye.slash".getImage(), for: .normal)
        eyeButton.frame = CGRect(x: 15, y: 0, width: 40, height: 25)
        eyeButton.imageView?.contentMode = .scaleAspectFit
        eyeButton.imageView?.layer.masksToBounds = true
        eyeButton.addTarget(self, action: #selector(tappedOnEyeButton), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: eyeButton)
        let currWidth = barButton.customView?.widthAnchor.constraint(equalToConstant: 30)
        currWidth?.isActive = true
        let currHeight = barButton.customView?.heightAnchor.constraint(equalToConstant: 25)
        currHeight?.isActive = true
        
        let deleteButton = UIButton(type: .custom)
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.frame = CGRect(x: 15, y: 0, width: 40, height: 25)
        deleteButton.imageView?.contentMode = .scaleAspectFit
        deleteButton.imageView?.layer.masksToBounds = true
        deleteButton.addTarget(self, action: #selector(rejectButtonTapped), for: .touchUpInside)
        let barButton2 = UIBarButtonItem(customView: deleteButton)
        let currWidth2 = barButton2.customView?.widthAnchor.constraint(equalToConstant: 30)
        currWidth2?.isActive = true
        let currHeight2 = barButton2.customView?.heightAnchor.constraint(equalToConstant: 25)
        currHeight2?.isActive = true
        
        self.navigationItem.rightBarButtonItems = [barButton2,barButton]
    }
    
    @objc func tappedOnEyeButton(){
        showValues = !showValues
        addRightBarButton()
        setCardDetailsFromFundingSource()
    }
    
    @objc func rejectButtonTapped(sender: Any) {
        let alert = UIAlertController(title: "Data Wallet", message: "connect_are_you_sure_you_want_to_delete_this_item".localizedForSDK(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "general_yes".localizedForSDK(), style: .default, handler: { [self] action in
                viewModel?.rejectCertificate()
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "general_no".localizedForSDK(), style: .default, handler: { action in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func acceptButtonTapped(_ sender: Any) {
        guard !didAccept else { return }
        didAccept = true
        Task {
            await self.viewModel?.acceptEBSI_V2_Certificate()

            dismiss(animated: true)
        }
    }
    
}

extension PWAPreviewViewController: CertificatePreviewDelegate {
    
    func popVC() {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func reloadData() {
    }
    
    
}
