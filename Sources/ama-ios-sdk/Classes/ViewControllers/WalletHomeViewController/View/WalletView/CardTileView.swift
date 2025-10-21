//
//  CardTileView.swift
//  dataWallet
//
//  Created by sreelekh N on 03/11/21.
//

import Foundation
import UIKit
import Localize_Swift

class CardTileView: CardView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var whiteShadeView: UIView!
    @IBOutlet weak var certName: UILabel!
    @IBOutlet weak var gotoBtn: UIButton!
    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var orgName: UILabel!
    @IBOutlet weak var certLogo: UIImageView!
    @IBOutlet weak var rightArrow: UIImageView!
    
    var index: Int = 0
    var cardAction: ((_ index: Int) -> Void)?
    var certificates: SearchItems_CustomWalletRecordCertModel? {
        didSet {
            loadValues()
        }
    }
    
    func addlocalizeObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(localizableValues), name: NSNotification.Name(LCLLanguageChangeNotification), object: nil)
    }
    
    @objc func localizableValues() {
        loadValues()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerView()
        addView(subview: view)
        addlocalizeObserver()
    }
    
    required init(title: String) {
        super.init(frame: .zero)
        registerView()
        addView(subview: view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override var presented: Bool { didSet { presentedDidUpdate() } }
    
    @IBAction func gotoAction(_ sender: Any) {
        cardAction?(self.index)
    }
    
    func presentedDidUpdate() {
        contentView.addTransitionFade()
        if presented {
            whiteShadeView.isHidden = false
            gotoBtn.isHidden = false
        } else {
            whiteShadeView.isHidden = true
            gotoBtn.isHidden = true
        }
    }
    
    func loadValues() {
        switch certificates?.value?.type {
        case CertType.isCredential(type: certificates?.value?.type):
            let schemeSeperated = certificates?.value?.schemaID?.split(separator: ":")
            certName.text = "\(schemeSeperated?[2] ?? "")".uppercased()
            orgName.text = certificates?.value?.connectionInfo?.value?.theirLabel?.trim
            locationName.text = certificates?.value?.connectionInfo?.value?.orgDetails?.location ?? ""
            UIApplicationUtils.shared.setRemoteImageOn((certLogo)!, url: certificates?.value?.connectionInfo?.value?.imageURL ?? "")
        case CertType.isSelfAttested(type: certificates?.value?.type), CertType.idCards.rawValue:
            switch certificates?.value?.subType {
            case SelfAttestedCertTypes.aadhar.rawValue:
                certName.text = "Aadhar".localizedForSDK().uppercased()
                certLogo.image =  "Aadhaar_Logo.svg".getImage()
                orgName.text = certificates?.value?.aadhar?.name?.value?.uppercased().trim
                locationName.text = "India".localizedForSDK()
            case SelfAttestedCertTypes.passport.rawValue:
                certName.text = certificates?.value?.subType?.localizedForSDK().uppercased() ?? ""
                if let image = UIApplicationUtils.shared.convertBase64StringToImage(imageBase64String: certificates?.value?.passport?.profileImage?.value ?? "") {
                    certLogo.image =  image
                } else {
                    certLogo.image =  "id-card".getImage()
                }
                let org = (certificates?.value?.passport?.firstName?.value ?? "") + " " + (certificates?.value?.passport?.surName?.value  ?? "")
                orgName.text = org.trim
                locationName.text = certificates?.value?.passport?.issuingCountry?.value ?? ""
            case SelfAttestedCertTypes.pkPass.rawValue:
                certName.text = (certificates?.value?.pkPass?.type ?? "").uppercased()
                certLogo.image = PKPassUtils.shared.getImageofTransit(transit: certificates?.value?.pkPass?.transitType).withTintColor(.darkGray).withAlignmentRectInsets(UIEdgeInsets(top: -5, left: -5, bottom: -5,right: -5))
                certLogo.layer.cornerRadius = 0
                orgName.text = certificates?.value?.pkPass?.walletTitle?.trim
                locationName.text = certificates?.value?.pkPass?.walletSubTitle ?? ""
            case SelfAttestedCertTypes.generic.rawValue:
                certName.text = LocalizationSheet.ticket.localize
                certLogo.loadFromUrl(certificates?.value?.generic?.attributes?.logo?.value ?? "")
                certLogo.layer.cornerRadius = 0
                orgName.text = certificates?.value?.generic?.headerFields?.title ?? ""
                locationName.text = certificates?.value?.generic?.headerFields?.subTitle ?? ""
            case SelfAttestedCertTypes.profile.rawValue:
                certName.text = "MyData Profile".localizedForSDK().uppercased()
                certLogo.image = "MyDataProfile".getImage()
                orgName.text = certificates?.value?.getCardName().uppercased()
                locationName.text = certificates?.value?.getMyDataProfileCardNationality() ?? ""
            default:
                let alphabet =  certificates?.value?.connectionInfo?.value?.orgDetails?.name?.first ?? "X"
                let placeHolderImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: alphabet , size: CGSize(width: 100, height: 100))
                certName.text = certificates?.value?.searchableText?.uppercased()
                orgName.text = certificates?.value?.connectionInfo?.value?.theirLabel?.trim
                locationName.text = certificates?.value?.connectionInfo?.value?.orgDetails?.location ?? ""
                UIApplicationUtils.shared.setRemoteImageOn((certLogo)!, url: certificates?.value?.connectionInfo?.value?.imageURL ?? "", placeholderImage: placeHolderImage)
            }
        case CertType.EBSI.rawValue:
            certName.text = certificates?.value?.searchableText?.uppercased() ?? ""
//            orgName.text = "ESSPASS (EBSI)" //cirtificates?.value?.connectionInfo?.value?.theirLabel?.trim
            orgName.text = certificates?.value?.connectionInfo?.value?.theirLabel ?? certificates?.value?.attributes?["name"]?.value ?? certificates?.value?.EBSI_v2?.attributes?.first(where: { e in
                e.name == "Awarding Body"
            })?.value ?? "EBSI".localize
            orgName.numberOfLines = 3
            locationName.text = certificates?.value?.connectionInfo?.value?.orgDetails?.location ?? "European Union".localize
            var logoImageUrl: String? = nil
            if certificates?.value?.vct == "PaymentWalletAttestation" {
                logoImageUrl = certificates?.value?.connectionInfo?.value?.orgDetails?.logoImageURL
            } else {
                logoImageUrl = certificates?.value?.logo ??  certificates?.value?.connectionInfo?.value?.orgDetails?.logoImageURL
            }
            let orgName = certificates?.value?.connectionInfo?.value?.orgDetails?.name
            let bgColour = certificates?.value?.backgroundColor
            let firstLetter = certificates?.value?.connectionInfo?.value?.orgDetails?.name?.first ?? "U"
            let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
            ImageUtils.shared.setRemoteImage(for: certLogo, imageUrl: logoImageUrl, orgName: orgName, bgColor: bgColour, placeHolderImage: profileImage)
        default:
            break
        }
    }
}
