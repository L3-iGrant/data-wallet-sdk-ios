//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 06/10/25.
//

import Foundation
import UIKit

protocol BottomSheetHeaderViewDelegate: AnyObject {
    func closeAction()
    func eyeButtonAction(showValue: Bool)
}

class BottomSheetHeaderView: UIView {
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet var view: UIView!
    
    @IBOutlet weak var orgImageView: UIImageView!
    
    @IBOutlet weak var orgNameLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var trustServiceProviderStackView: UIStackView!
    
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    @IBOutlet weak var trustedServiceLabel: UILabel!
    
    @IBOutlet weak var certificatenameView: UIView!
    
    @IBOutlet weak var certNameLabel: UILabel!
    
    @IBOutlet weak var eyeButton: UIButton!
    
    weak var delegate: OrganizationHeaderDelegate?
    weak var bottomSheetDelegate: BottomSheetHeaderViewDelegate?
    var modelData: Any?
    var shouldShowEyeIcon: Bool = false
    var showValues = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerView()
        addView(subview: view)
        updateEyeButtonImage()
        trustServiceProviderStackView.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(trustServicetapped))
        self.trustServiceProviderStackView.addGestureRecognizer(tapGesture)
    }
    
    required init(title: String) {
        super.init(frame: .zero)
        registerView()
        addView(subview: view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setData(model: CertificateListViewModel) {
        if let connModel = model.connectionModel {
            orgImageView.loadFromUrl(connModel.imageURL ?? "")
            let title = connModel.theirLabel ?? ""
            orgNameLabel.text = title
            locationLabel.text = connModel.orgDetails?.location ?? ""
            self.delegate?.updatePageTitle(title: title)
        }
    }
    
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        bottomSheetDelegate?.closeAction()
    }
    
    @IBAction func eyeButtonTapped(_ sender: Any) {
        showValues.toggle()
        bottomSheetDelegate?.eyeButtonAction(showValue: showValues)
        updateEyeButtonImage()
    }
    
    private func updateEyeButtonImage() {
        let config = UIImage.SymbolConfiguration(scale: .small)
        let imageName = showValues ? "eye.slash" : "eye"
        let image = UIImage(systemName: imageName, withConfiguration: config)
        eyeButton.setImage(image, for: .normal)
    }
    
    func setData(model: PWACertViewModel) {
        modelData = model
        let alphabet =  model.orgInfo?.name?.first ?? "X"
        let placeHolderImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: alphabet , size: CGSize(width: 100, height: 100))
        
        let firstLetter = model.orgInfo?.name?.first ?? "U"
        let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
        self.orgNameLabel.text = model.orgInfo?.name ?? (model.certModel?.value?.connectionInfo?.value?.theirLabel ?? "")
        let logoImagrURL = model.certModel?.value?.connectionInfo?.value?.orgDetails?.logoImageURL ?? (model.orgInfo?.logoImageURL ?? (model.certModel?.value?.connectionInfo?.value?.orgDetails?.logoImageURL))
        let coverImageURL = model.certModel?.value?.connectionInfo?.value?.imageURL ?? model.certModel?.value?.cover ?? (model.orgInfo?.coverImageURL ?? (model.certModel?.value?.connectionInfo?.value?.imageURL ?? ""))
        self.locationLabel.text = model.orgInfo?.location ?? ""
        let bgColour = model.certModel?.value?.backgroundColor
        ImageUtils.shared.setRemoteImage(for: orgImageView, imageUrl: logoImagrURL, orgName: model.orgInfo?.name, bgColor: bgColour, placeHolderImage: profileImage)
        
        //PDA1
        if model.certModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue || model.certModel?.value?.subType == EBSI_CredentialType.PWA.rawValue{
//            self.locationLbl.text = (model.certModel?.value?.attributes?["address"]?.value?.split(separator: " ").last ?? "") + ", European Union"
            if model.certModel?.value?.subType == EBSI_CredentialType.PWA.rawValue {
                self.certNameLabel.isHidden = true
                self.certificatenameView.isHidden = true
                //stackviewBottomSpace.constant = 0
            } else {
                //stackviewBottomSpace.constant = 5
                self.certNameLabel.text = model.certModel?.value?.searchableText ?? EBSI_CredentialSearchText.PDA1.rawValue
                self.certificatenameView.isHidden = false
            }
            self.locationLabel.numberOfLines = 2
//            self.nameLbl.text = model.certModel?.value?.attributes?["name"]?.value ?? ""
        } else if model.certModel?.value?.subType == EBSI_CredentialType.Diploma.rawValue{
            self.locationLabel.text = "European Union"
            self.locationLabel.numberOfLines = 2
            self.certificatenameView.isHidden = false
            self.certNameLabel.text = EBSI_CredentialSearchText.Diploma.rawValue
            self.orgNameLabel.text = model.certModel?.value?.EBSI_v2?.attributes?.first(where: { attr in
                    attr.name == "Awarding Body"
                })?.value ?? model.certModel?.value?.connectionInfo?.value?.orgDetails?.name
        }
        if let isValidOrganization = model.certModel?.value?.connectionInfo?.value?.orgDetails?.isValidOrganization {
            if isValidOrganization {
                trustServiceProviderStackView.isHidden = false
                locationLabel.isHidden = true
                verifiedImageView.image = "gpp_good".getImage()
                verifiedImageView.tintColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.textColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.text = "general_trusted_service_provider".localizedForSDK()
            } else {
                trustServiceProviderStackView.isHidden = false
                locationLabel.isHidden = true
                verifiedImageView.image = "gpp_bad".getImage()
                verifiedImageView.tintColor = .systemRed
                trustedServiceLabel.textColor = .systemRed
                trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
            }
        } else {
            trustServiceProviderStackView.isHidden = true
            locationLabel.isHidden = false
        }
        //setCredentialColor(model: model)
    }
    
    func setData(model: PaymentDataConfirmationMySharedDataViewModel) {
        modelData = model
        let data = model.history?.value?.history?.transactionData
        if let value = model.history?.value?.history?.connectionModel?.value?.orgDetails {
            let imageURL = value.logoImageURL
            let orgName = value.name
            let bgColour = model.history?.value?.history?.display?.backgroundColor
            ImageUtils.shared.setRemoteImage(for: orgImageView, imageUrl: imageURL, orgName: orgName, bgColor: bgColour)
            let title = value.name
            orgNameLabel.text = title
            locationLabel.text = value.location ?? ""
            self.delegate?.updatePageTitle(title: title ?? "")
            if let isValidOrganization = model.history?.value?.history?.connectionModel?.value?.orgDetails?.isValidOrganization {
                if isValidOrganization {
                    trustServiceProviderStackView.isHidden = false
                    locationLabel.isHidden = true
                    verifiedImageView.image = "gpp_good".getImage()
                    verifiedImageView.tintColor = UIColor(hex: "1EAA61")
                    trustedServiceLabel.textColor = UIColor(hex: "1EAA61")
                    trustedServiceLabel.text = "general_trusted_service_provider".localizedForSDK()
                } else {
                    trustServiceProviderStackView.isHidden = false
                    locationLabel.isHidden = true
                    verifiedImageView.image = "gpp_bad".getImage()
                    verifiedImageView.tintColor = .red
                    trustedServiceLabel.textColor = .red
                    trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
                }
            } else {
                trustServiceProviderStackView.isHidden = true
                locationLabel.isHidden = false
            }
        }
    }
    
    func setData(model: OrganizationDetailViewModel) {
        modelData = model
        switch model.loadUIFor {
        case .history, .receiptHistory:
            if let value = model.history?.value?.history?.connectionModel?.value?.orgDetails {
                let imageURL = model.history?.value?.history?.display?.logo ?? value.logoImageURL
                let orgName = value.name
                var bgColour = model.history?.value?.history?.display?.backgroundColor
                let firstLetter = model.history?.value?.history?.connectionModel?.value?.orgDetails?.name?.first ?? "U"
                let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
                ImageUtils.shared.setRemoteImage(for: orgImageView, imageUrl: imageURL, orgName: orgName, bgColor: bgColour, placeHolderImage: profileImage)
                let title = value.name ?? model.history?.value?.history?.connectionModel?.value?.theirLabel ?? ""
                orgNameLabel.text = title
                locationLabel.text = value.location ?? ""
                self.delegate?.updatePageTitle(title: title)
                if let isValidOrganization = model.history?.value?.history?.connectionModel?.value?.orgDetails?.isValidOrganization {
                    if isValidOrganization {
                        trustServiceProviderStackView.isHidden = false
                        locationLabel.isHidden = true
                        verifiedImageView.image = "gpp_good".getImage()
                        verifiedImageView.tintColor = UIColor(hex: "1EAA61")
                        trustedServiceLabel.textColor = UIColor(hex: "1EAA61")
                        trustedServiceLabel.text = "general_trusted_service_provider".localizedForSDK()
                    } else {
                        trustServiceProviderStackView.isHidden = false
                        locationLabel.isHidden = true
                        verifiedImageView.image = "gpp_bad".getImage()
                        verifiedImageView.tintColor = .red
                        trustedServiceLabel.textColor = .red
                        trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
                    }
                } else {
                    trustServiceProviderStackView.isHidden = true
                    locationLabel.isHidden = false
                }
            }
        case .orgDetail:
            orgImageView.loadFromUrl(model.orgInfo?.logoImageURL ?? model.connectionModel?.value?.imageURL ?? "")
            
            let title = model.orgInfo?.name ?? model.connectionModel?.value?.theirLabel ?? ""
            orgNameLabel.text = title
            locationLabel.text = model.orgInfo?.location ?? ""
            self.delegate?.updatePageTitle(title: title)
        case .genericCard(model: let model):
            orgImageView.loadFromUrl(model.attributes?.logo?.value ?? "", placeHolder: "00_Default_CoverImage_02-min")
            orgNameLabel.text = model.headerFields?.title ?? ""
            locationLabel.text = model.headerFields?.subTitle ?? ""
        case .EBSI:
            let imageURL = model.connectionModel?.value?.orgDetails?.logoImageURL
            let orgName = model.connectionModel?.value?.orgDetails?.name
            let bgColour = model.history?.value?.history?.display?.backgroundColor
            let firstLetter = orgName?.first ?? "U"
            let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
            ImageUtils.shared.setRemoteImage(for: orgImageView, imageUrl: imageURL, orgName: orgName, bgColor: bgColour, placeHolderImage: profileImage)
            orgNameLabel.text = model.connectionModel?.value?.orgDetails?.name ?? ""
            locationLabel.text = model.connectionModel?.value?.orgDetails?.location  ?? ""
            
            if let isValidOrganization = model.connectionModel?.value?.orgDetails?.isValidOrganization {
                if isValidOrganization {
                    trustServiceProviderStackView.isHidden = false
                    locationLabel.isHidden = true
                    verifiedImageView.image = "gpp_good".getImage()
                    verifiedImageView.tintColor = UIColor(hex: "1EAA61")
                    trustedServiceLabel.textColor = UIColor(hex: "1EAA61")
                    trustedServiceLabel.text = "general_trusted_service_provider".localizedForSDK()
                } else {
                    trustServiceProviderStackView.isHidden = false
                    locationLabel.isHidden = true
                    verifiedImageView.image = "gpp_bad".getImage()
                    verifiedImageView.tintColor = .red
                    trustedServiceLabel.textColor = .red
                    trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
                }
            } else {
                trustServiceProviderStackView.isHidden = true
                locationLabel.isHidden = false
            }
        }
    }
    
    func setData(model: GeneralStateViewModel) {
        modelData = model
        let alphabet =  model.orgInfo?.name?.first ?? "X"
        let placeHolderImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: alphabet , size: CGSize(width: 100, height: 100))
        self.orgNameLabel.text = model.orgInfo?.name ?? (model.certModel?.value?.connectionInfo?.value?.theirLabel ?? "")
        self.locationLabel.text = model.orgInfo?.location ?? ""
        UIApplicationUtils.shared.setRemoteImageOn(self.orgImageView, url: model.orgInfo?.logoImageURL ?? (model.certModel?.value?.connectionInfo?.value?.imageURL ?? ""), placeholderImage: placeHolderImage)
        
        //PDA1
        if model.certModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue {
            self.certificatenameView.isHidden = false
            self.certNameLabel.text = model.certModel?.value?.searchableText ?? EBSI_CredentialSearchText.PDA1.rawValue
            self.locationLabel.numberOfLines = 2
        } else if model.certModel?.value?.subType == EBSI_CredentialType.Diploma.rawValue{
            self.locationLabel.text = "European Union"
            self.locationLabel.numberOfLines = 2
            self.certificatenameView.isHidden = false
            self.certNameLabel.text = EBSI_CredentialSearchText.Diploma.rawValue
            self.orgNameLabel.text = model.certModel?.value?.EBSI_v2?.attributes?.first(where: { attr in
                    attr.name == "Awarding Body"
                })?.value ?? model.certModel?.value?.connectionInfo?.value?.orgDetails?.name
        }
        setCredentialColor(model: model)
        if let isValidOrganization = model.certModel?.value?.connectionInfo?.value?.orgDetails?.isValidOrganization {
            if isValidOrganization {
                trustServiceProviderStackView.isHidden = false
                locationLabel.isHidden = true
                verifiedImageView.image = "gpp_good".getImage()
                verifiedImageView.tintColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.textColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.text = "general_trusted_service_provider".localizedForSDK()
            } else {
                trustServiceProviderStackView.isHidden = false
                locationLabel.isHidden = true
                verifiedImageView.image = "gpp_bad".getImage()
                verifiedImageView.tintColor = .systemRed
                trustedServiceLabel.textColor = .systemRed
                trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
            }
        } else {
            trustServiceProviderStackView.isHidden = true
            locationLabel.isHidden = false
        }
    }
    
    func setCredentialColor(model: GeneralStateViewModel) {
        if let textColor = model.certModel?.value?.textColor {
            orgNameLabel.textColor = UIColor(hex: textColor)
            locationLabel.textColor = UIColor(hex:textColor)
           // certificateName.textColor = UIColor(hex:textColor)
        }
    }
    
    @objc func trustServicetapped() {
        var credential: String?
        var jwks: String?
        if let data = modelData as? PaymentDataConfirmationMySharedDataViewModel {
            credential = data.history?.value?.history?.connectionModel?.value?.orgDetails?.x5c
            jwks = data.history?.value?.history?.connectionModel?.value?.orgDetails?.jwksURL
        } else if let data = modelData as? OrganizationDetailViewModel {
            credential = data.history?.value?.history?.connectionModel?.value?.orgDetails?.x5c ?? data.connectionModel?.value?.orgDetails?.x5c
            jwks = data.history?.value?.history?.connectionModel?.value?.orgDetails?.jwksURL ?? data.connectionModel?.value?.orgDetails?.jwksURL
        } else if let data = modelData as? GeneralStateViewModel {
            credential = data.certModel?.value?.EBSI_v2?.credentialJWT
            jwks = data.certModel?.value?.connectionInfo?.value?.orgDetails?.jwksURL
        } else if let data = modelData as? PWACertViewModel {
            credential = data.certModel?.value?.EBSI_v2?.credentialJWT
            jwks = data.certModel?.value?.connectionInfo?.value?.orgDetails?.jwksURL
        }
        TrustMechanismManager().trustProviderInfo(credential: credential, format: "", jwksURI: jwks) { data in
            if let data = data {
                DispatchQueue.main.async {
                    let vc = TrustServiceProviersBottomSheetVC(nibName: "TrustServiceProviersBottomSheetVC", bundle: Bundle.module)
                    vc.modalPresentationStyle = .overCurrentContext
                    vc.viewModel.data = data
                    vc.clearAlpha = true
                    vc.viewModel.credential = credential
                    if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                        navVC.present(vc, animated: true, completion: nil)
                    } else {
                        UIApplicationUtils.shared.getTopVC()?.present(vc, animated: true)
                    }
                }
            }
        }
    }

    
}
