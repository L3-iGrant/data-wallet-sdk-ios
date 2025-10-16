//
//  OrganizationHeaderView.swift
//  dataWallet
//
//  Created by sreelekh N on 12/12/21.
//

import UIKit
protocol OrganizationHeaderDelegate: AnyObject {
    func getHeaderFetchedImage(image: UIImage)
    func updatePageTitle(title: String)
}

final class OrganizationHeaderView: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var iconImgView: UIImageView!
    @IBOutlet weak var topImgView: UIImageView!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    
    @IBOutlet weak var trustServiceProviderStackView: UIStackView!
    
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    @IBOutlet weak var trustedServiceLabel: UILabel!
    
    weak var delegate: OrganizationHeaderDelegate?
    var modelData: Any?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerView()
        addView(subview: view)
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
            iconImgView.loadFromUrl(connModel.imageURL ?? "")
            topImgView.loadFromUrl(connModel.orgDetails?.coverImageURL ?? "", placeHolder: "00_Default_CoverImage_02-min", completion: { [weak self] image in
                guard let image = image else {
                    return
                }
                self?.delegate?.getHeaderFetchedImage(image: image)
            })
            let title = connModel.theirLabel ?? ""
            titleLbl.text = title
            locationLbl.text = connModel.orgDetails?.location ?? ""
            self.delegate?.updatePageTitle(title: title)
        }
    }
    
    func setData(model: PaymentDataConfirmationMySharedDataViewModel) {
        modelData = model
        let data = model.history?.value?.history?.transactionData
        if let value = model.history?.value?.history?.connectionModel?.value?.orgDetails {
            let imageURL = value.logoImageURL
            let orgName = value.name
            let bgColour = model.history?.value?.history?.display?.backgroundColor
            ImageUtils.shared.setRemoteImage(for: iconImgView, imageUrl: imageURL, orgName: orgName, bgColor: bgColour)
            topImgView.loadFromUrl(model.history?.value?.history?.connectionModel?.value?.imageURL ?? model.history?.value?.history?.display?.cover ?? (value.coverImageURL ?? model.history?.value?.history?.connectionModel?.value?.imageURL ?? ""), placeHolder: "00_Default_CoverImage_02-min", completion: { [weak self] (image) in
                guard let image = image else {
                    return
                }
                self?.delegate?.getHeaderFetchedImage(image: image)
            })
            let title = value.name
            titleLbl.text = title
            locationLbl.text = value.location ?? ""
            self.delegate?.updatePageTitle(title: title ?? "")
            if let isValidOrganization = model.history?.value?.history?.connectionModel?.value?.orgDetails?.isValidOrganization {
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
                    verifiedImageView.tintColor = .red
                    trustedServiceLabel.textColor = .red
                    trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
                }
            } else {
                trustServiceProviderStackView.isHidden = true
                locationLbl.isHidden = false
            }
        }
    }
    
    func setData(model: OrganizationDetailViewModel) {
        modelData = model
        switch model.loadUIFor {
        case .history, .receiptHistory:
            if let value = model.history?.value?.history?.connectionModel?.value?.orgDetails {
               // iconImgView.loadFromUrl(value.logoImageURL ?? model.history?.value?.history?.connectionModel?.value?.imageURL ?? "")
                let imageURL = model.history?.value?.history?.display?.logo ?? value.logoImageURL
                let orgName = value.name
                var bgColour = model.history?.value?.history?.display?.backgroundColor
                let firstLetter = model.history?.value?.history?.connectionModel?.value?.orgDetails?.name?.first ?? "U"
                let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
                ImageUtils.shared.setRemoteImage(for: iconImgView, imageUrl: imageURL, orgName: orgName, bgColor: bgColour, placeHolderImage: profileImage)
                topImgView.loadFromUrl(value.coverImageURL ?? "", placeHolder: "00_Default_CoverImage_02-min", completion: { [weak self] image in
                    guard let image = image else {
                        return
                    }
                    self?.delegate?.getHeaderFetchedImage(image: image)
                })
                let title = value.name ?? model.history?.value?.history?.connectionModel?.value?.theirLabel ?? ""
                titleLbl.text = title
                locationLbl.text = value.location ?? ""
                self.delegate?.updatePageTitle(title: title)
                if let isValidOrganization = model.history?.value?.history?.connectionModel?.value?.orgDetails?.isValidOrganization {
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
                        verifiedImageView.tintColor = .red
                        trustedServiceLabel.textColor = .red
                        trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
                    }
                } else {
                    trustServiceProviderStackView.isHidden = true
                    locationLbl.isHidden = false
                }
            }
        case .orgDetail:
            iconImgView.loadFromUrl(model.orgInfo?.logoImageURL ?? model.connectionModel?.value?.imageURL ?? "")
            topImgView.loadFromUrl(model.orgInfo?.coverImageURL ?? model.connectionModel?.value?.orgDetails?.coverImageURL ?? "", placeHolder: "00_Default_CoverImage_02-min", completion: { [weak self] image in
                guard let image = image else {
                    return
                }
                self?.delegate?.getHeaderFetchedImage(image: image)
            })
            
            let title = model.orgInfo?.name ?? model.connectionModel?.value?.theirLabel ?? ""
            titleLbl.text = title
            locationLbl.text = model.orgInfo?.location ?? ""
            self.delegate?.updatePageTitle(title: title)
        case .genericCard(model: let model):
            iconImgView.loadFromUrl(model.attributes?.logo?.value ?? "", placeHolder: "00_Default_CoverImage_02-min")
            topImgView.loadFromUrl(model.attributes?.coverImage?.value ?? "", placeHolder: "00_Default_CoverImage_02-min")
            titleLbl.text = model.headerFields?.title ?? ""
            locationLbl.text = model.headerFields?.subTitle ?? ""
        case .EBSI:
            let imageURL = model.connectionModel?.value?.orgDetails?.logoImageURL
            let orgName = model.connectionModel?.value?.orgDetails?.name
            let bgColour = model.history?.value?.history?.display?.backgroundColor
            let firstLetter = orgName?.first ?? "U"
            let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
            ImageUtils.shared.setRemoteImage(for: iconImgView, imageUrl: imageURL, orgName: orgName, bgColor: bgColour, placeHolderImage: profileImage)
            topImgView.loadFromUrl(model.connectionModel?.value?.orgDetails?.coverImageURL ?? "", placeHolder: "00_Default_CoverImage_02-min",  completion: { [weak self] (image) in
                guard let image = image else {
                    return
                }
                self?.delegate?.getHeaderFetchedImage(image: image)
            })
            titleLbl.text = model.connectionModel?.value?.orgDetails?.name ?? ""
            locationLbl.text = model.connectionModel?.value?.orgDetails?.location  ?? ""
            
            if let isValidOrganization = model.connectionModel?.value?.orgDetails?.isValidOrganization {
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
                    verifiedImageView.tintColor = .red
                    trustedServiceLabel.textColor = .red
                    trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
                }
            } else {
                trustServiceProviderStackView.isHidden = true
                locationLbl.isHidden = false
            }
        }
    }
    
    @objc func trustServicetapped() {
        var credential: String?
        var jwks: String?
        if let data = modelData as? OrganizationDetailViewModel {
            credential = data.history?.value?.history?.connectionModel?.value?.orgDetails?.x5c ?? data.connectionModel?.value?.orgDetails?.x5c
            jwks = data.history?.value?.history?.connectionModel?.value?.orgDetails?.jwksURL ?? data.connectionModel?.value?.orgDetails?.jwksURL
        }
        TrustMechanismManager().trustProviderInfo(credential: credential, format: "", jwksURI: jwks) { data in
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
