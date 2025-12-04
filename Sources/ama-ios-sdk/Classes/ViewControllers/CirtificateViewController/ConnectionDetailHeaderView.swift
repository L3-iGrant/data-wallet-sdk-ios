//
//  ConnectionDetailHeaderView.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 22/08/22.
//

import UIKit

class ConnectionDetailHeaderView: UIView {

    @IBOutlet var view: UIView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var orgImageView: UIImageView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var logoBgBtn: UIButton!
    @IBOutlet weak var certificateSubType: UIView!
    @IBOutlet weak var certificateName: UILabel!
    
    @IBOutlet weak var trustServiceProviderStackView: UIStackView!
    
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    @IBOutlet weak var trustedServiceLabel: UILabel!
    var modelData: Any?
    var placeHolderImage: UIImage?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerView()
        addView(subview: view)
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
    
    func setData(model: PWACertViewModel) {
        modelData = model
        let alphabet =  model.orgInfo?.name?.first ?? "X"
        placeHolderImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: alphabet , size: CGSize(width: 100, height: 100))
        
        let firstLetter = model.orgInfo?.name?.first ?? "U"
        let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
        logoImageView.layer.cornerRadius =  logoImageView.frame.size.height/2
        logoBgBtn.layer.cornerRadius =  logoBgBtn.frame.size.height/2
        self.nameLbl.text = model.orgInfo?.name ?? (model.certModel?.value?.connectionInfo?.value?.theirLabel ?? "")
        let logoImagrURL = model.certModel?.value?.connectionInfo?.value?.orgDetails?.logoImageURL ?? (model.orgInfo?.logoImageURL ?? (model.certModel?.value?.connectionInfo?.value?.orgDetails?.logoImageURL))
        let coverImageURL = model.certModel?.value?.connectionInfo?.value?.imageURL ?? model.certModel?.value?.cover ?? (model.orgInfo?.coverImageURL ?? (model.certModel?.value?.connectionInfo?.value?.imageURL ?? ""))
        self.locationLbl.text = model.orgInfo?.location ?? ""
        let bgColour = model.certModel?.value?.backgroundColor
        ImageUtils.shared.setRemoteImage(for: logoImageView, imageUrl: logoImagrURL, orgName: model.orgInfo?.name, bgColor: bgColour, placeHolderImage: profileImage)
        orgImageView.loadFromUrl(coverImageURL, placeHolder: "00_Default_CoverImage_02-min", completion: { [weak self] (image )in
            guard let image = image else {
                return
            }
            //self?.delegate?.getHeaderFetchedImage(image: image)
        })
        
        //PDA1
        if model.certModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue || model.certModel?.value?.subType == EBSI_CredentialType.PWA.rawValue{
//            self.locationLbl.text = (model.certModel?.value?.attributes?["address"]?.value?.split(separator: " ").last ?? "") + ", European Union"
            if model.certModel?.value?.subType == EBSI_CredentialType.PWA.rawValue {
                self.certificateName.isHidden = true
                self.certificateSubType.isHidden = true
                //stackviewBottomSpace.constant = 0
            } else {
                //stackviewBottomSpace.constant = 5
                self.certificateName.text = model.certModel?.value?.searchableText ?? EBSI_CredentialSearchText.PDA1.rawValue
                self.certificateSubType.isHidden = false
            }
            self.locationLbl.numberOfLines = 2
//            self.nameLbl.text = model.certModel?.value?.attributes?["name"]?.value ?? ""
        } else if model.certModel?.value?.subType == EBSI_CredentialType.Diploma.rawValue{
            self.locationLbl.text = "European Union"
            self.locationLbl.numberOfLines = 2
            self.certificateSubType.isHidden = false
            self.certificateName.text = EBSI_CredentialSearchText.Diploma.rawValue
            self.nameLbl.text = model.certModel?.value?.EBSI_v2?.attributes?.first(where: { attr in
                    attr.name == "Awarding Body"
                })?.value ?? model.certModel?.value?.connectionInfo?.value?.orgDetails?.name
        }
        if let isValidOrganization = model.certModel?.value?.connectionInfo?.value?.orgDetails?.isValidOrganization {
            if isValidOrganization {
                trustServiceProviderStackView.isHidden = false
                locationLbl.isHidden = true
                verifiedImageView.image = "gpp_good".getImage()
                verifiedImageView.tintColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.textColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.text = "general_trusted_service_provider".localizedForSDK()
            } else {
                trustServiceProviderStackView.isHidden = false
                locationLbl.isHidden = true
                verifiedImageView.image = "gpp_bad".getImage()
                verifiedImageView.tintColor = .systemRed
                trustedServiceLabel.textColor = .systemRed
                trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
            }
        } else {
            trustServiceProviderStackView.isHidden = true
            locationLbl.isHidden = false
        }
        //setCredentialColor(model: model)
    }
    
    func setData(model: MultipleTypeCards) {
        logoImageView.layer.cornerRadius =  logoImageView.frame.size.height/2
        logoBgBtn.layer.cornerRadius =  logoBgBtn.frame.size.height/2
        
        let organisation = model.orgInfo?.name ?? (model.certModel?[0].value?.connectionInfo?.value?.theirLabel ?? "")
        let locationAndDesc = NSMutableAttributedString().normal( "ebsi_multiple_cards_requested".localizedForSDK() + " " + "connect_by_choosing_confirm_you_agree_to_the_requested_data_to_org_name".localizedForSDK()).bold(" " + organisation + "\n")
        self.locationLbl.numberOfLines = 0
        self.locationLbl.attributedText = locationAndDesc
        
        UIApplicationUtils.shared.setRemoteImageOn(self.logoImageView, url: model.orgInfo?.logoImageURL ?? (model.certModel?[0].value?.connectionInfo?.value?.imageURL ?? ""), placeholderImage: placeHolderImage)
        self.orgImageView.isHidden = true
       // nameLabel2.text = organisation
        //locationLabel2.text = model.orgInfo?.location
        trustServiceProviderStackView.isHidden = true
    }
    
    func setData(model: GeneralStateViewModel) {
        modelData = model
        let alphabet =  model.orgInfo?.name?.first ?? "X"
        let placeHolderImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: alphabet , size: CGSize(width: 100, height: 100))
        logoImageView.layer.cornerRadius =  logoImageView.frame.size.height/2
        logoBgBtn.layer.cornerRadius =  logoBgBtn.frame.size.height/2
        addGradient()
        self.nameLbl.text = model.orgInfo?.name ?? (model.certModel?.value?.connectionInfo?.value?.theirLabel ?? "")
        self.locationLbl.text = model.orgInfo?.location ?? ""
        UIApplicationUtils.shared.setRemoteImageOn(self.logoImageView, url: model.orgInfo?.logoImageURL ?? (model.certModel?.value?.connectionInfo?.value?.imageURL ?? ""), placeholderImage: placeHolderImage)
        UIApplicationUtils.shared.setRemoteImageOn(self.orgImageView, url: model.orgInfo?.coverImageURL ?? (model.certModel?.value?.connectionInfo?.value?.orgDetails?.coverImageURL ?? ""),placeholderImage: "00_Default_CoverImage_02-min".getImage())
        
        //PDA1
        if model.certModel?.value?.subType == EBSI_CredentialType.PDA1.rawValue {
            self.locationLbl.text = "Member state: " +  (model.certModel?.value?.attributes?["address"]?.value?.split(separator: " ").last ?? "") + "\n" + "European Union"
            self.certificateSubType.isHidden = false
            self.certificateName.text = EBSI_CredentialSearchText.PDA1.rawValue
            self.locationLbl.numberOfLines = 2
            self.nameLbl.text = model.certModel?.value?.attributes?["name"]?.value ?? ""
        } else if model.certModel?.value?.subType == EBSI_CredentialType.Diploma.rawValue{
            self.locationLbl.text = "European Union"
            self.locationLbl.numberOfLines = 2
            self.certificateSubType.isHidden = false
            self.certificateName.text = EBSI_CredentialSearchText.Diploma.rawValue
            self.nameLbl.text = model.certModel?.value?.EBSI_v2?.attributes?.first(where: { attr in
                    attr.name == "Awarding Body"
                })?.value ?? model.certModel?.value?.connectionInfo?.value?.orgDetails?.name
        }
        setCredentialColor(model: model)
        if let isValidOrganization = model.certModel?.value?.connectionInfo?.value?.orgDetails?.isValidOrganization {
            if isValidOrganization {
                trustServiceProviderStackView.isHidden = false
                locationLbl.isHidden = true
                verifiedImageView.image = "gpp_good".getImage()
                verifiedImageView.tintColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.textColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.text = "general_trusted_service_provider".localizedForSDK()
            } else {
                trustServiceProviderStackView.isHidden = false
                locationLbl.isHidden = true
                verifiedImageView.image = "gpp_bad".getImage()
                verifiedImageView.tintColor = .systemRed
                trustedServiceLabel.textColor = .systemRed
                trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
            }
        } else {
            trustServiceProviderStackView.isHidden = true
            locationLbl.isHidden = false
        }
    }
    
    func setCredentialColor(model: GeneralStateViewModel) {
        if let textColor = model.certModel?.value?.textColor {
            nameLbl.textColor = UIColor(hex: textColor)
            locationLbl.textColor = UIColor(hex:textColor)
            certificateName.textColor = UIColor(hex:textColor)
        }
    }
    
    func setData(model: ReceiptStateViewModel) {
        logoImageView.layer.cornerRadius =  logoImageView.frame.size.height/2
        logoBgBtn.layer.cornerRadius =  logoBgBtn.frame.size.height/2
        addGradient()
        self.nameLbl.text = model.receiptModel?.accountingSupplierParty?.party?.partyName?.name ?? (model.certModel?.value?.connectionInfo?.value?.theirLabel ?? "")
        let street = model.receiptModel?.accountingSupplierParty?.party?.postaladdress?.streetName ?? ""
        let city = model.receiptModel?.accountingSupplierParty?.party?.postaladdress?.cityName ?? ""
        let country = model.receiptModel?.accountingSupplierParty?.party?.postaladdress?.country?.name ?? ""
        let pin = model.receiptModel?.accountingSupplierParty?.party?.postaladdress?.postalZone ?? ""
        let companyId = model.receiptModel?.accountingSupplierParty?.party?.partyIdentification?.iD ?? ""
        let address = street + ", " + city + "\n" + pin + ", " + country + "\n" + "Company ID" + ": " + companyId
        self.locationLbl.text = address
        self.locationLbl.numberOfLines = 0
        self.locationLbl.textColor = .darkGray
        self.locationLbl.font = .systemFont(ofSize: 14)
        UIApplicationUtils.shared.setRemoteImageOn(self.logoImageView, url: model.orgInfo?.logoImageURL ?? (model.certModel?.value?.connectionInfo?.value?.imageURL ?? ""))
        UIApplicationUtils.shared.setRemoteImageOn(self.orgImageView, url: model.orgInfo?.coverImageURL ?? (model.certModel?.value?.connectionInfo?.value?.orgDetails?.coverImageURL ?? ""),placeholderImage: "00_Default_CoverImage_02-min".getImage())
    }
    
    func addGradient(){
        let statusBarBgView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: UIApplicationUtils.shared.getTopVC()?.view.frame.width ?? self.frame.width, height: 100))
        let gradient:CAGradientLayer = CAGradientLayer()
        gradient.frame.size = statusBarBgView.frame.size
        gradient.colors = [UIColor.white.withAlphaComponent(0.4).cgColor,UIColor.white.withAlphaComponent(0).cgColor] //Or any colors
        statusBarBgView.layer.addSublayer(gradient)
        self.addSubview(statusBarBgView)
    }
    
    @objc func trustServicetapped() {
        var credential: String?
        var format: String?
        var jwks: String?
        if let data = modelData as? GeneralStateViewModel {
            credential = data.certModel?.value?.EBSI_v2?.credentialJWT
            format = data.certModel?.value?.format
            jwks = data.certModel?.value?.connectionInfo?.value?.orgDetails?.jwksURL
        }
        TrustMechanismManager().trustProviderInfo(credential: credential, format: format, jwksURI: jwks) { data in
            if let data = data {
                DispatchQueue.main.async {
                    let vc = TrustServiceProviersBottomSheetVC(nibName: "TrustServiceProviersBottomSheetVC", bundle: Bundle.module)
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
}
