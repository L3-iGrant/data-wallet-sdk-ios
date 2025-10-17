//
//  AcceptCertificateViewController.swift
//  Alamofire
//
//  Created by Mohamed Rebin on 06/12/20.
//

import UIKit
import Foundation
import eudiWalletOidcIos

final class CertificatePreviewBottomSheet: UIViewController, NavigationHandlerProtocol, CustomNavigationBarIconViewDelegate {
    func cusNavtappedAction(tag: Int) {
        returnBack()
    }
    
    func rightTapped(tag: Int) {
        debugPrint("Tag:\(tag)")
    }
    
    @IBOutlet weak var certificateNameBaseView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var certificateName: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    var viewModel: CertificatePreviewViewModel?
    var isCertDetail: Bool = false
    var inboxCertState: String?
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var infoText: UILabel!
    @IBOutlet weak var companyLogo: UIImageView!
    @IBOutlet weak var companyName: UILabel!
    @IBOutlet weak var companyLocation: UILabel!
    @IBOutlet weak var trustedIssuerStackView: UIStackView!
    
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    @IBOutlet weak var trustedServiceLabel: UILabel!
    @IBOutlet weak var tableViewStack: UIStackView!
    
    @IBOutlet weak var parentView: UIView!
    
    @IBOutlet weak var parentViewHeight: NSLayoutConstraint!
    
    
    var showValues = false
    let dataAgreementHeaderHeight: CGFloat = 50
    var mode: CertificatePreviewVC_Mode = .other
    var dataAgreementButton = UIButton.init(type: .custom)
    var certificateNameValue: String?
    var isFromSDK = false
    var navHandler: NavigationHandler!
    let backNavIcon = CustomNavigationBarIconView()
    var onAccept: ((Bool) -> Void)?
    private var hasCalledAccept = false
    var viewMode: ViewMode = .FullScreen
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        viewModel?.delegate = self
        self.certificateNameBaseView.isHidden = true
        self.tableView.estimatedRowHeight(40)
        setUpColor()
        self.tableView.rowHeight = UITableView.automaticDimension
        //        certificateName.text = "\(viewModel?.certDetail?.value?.schemaID?.split(separator: ":")[2] ?? "")"
        acceptButton.layer.cornerRadius = 25
        rejectButton.layer.cornerRadius = 25
        companyLogo.layer.cornerRadius = 35
        acceptButton.backgroundColor = AriesMobileAgent.themeColor
        rejectButton.backgroundColor = AriesMobileAgent.themeColor.withAlphaComponent(0.7)
        self.companyName.numberOfLines = 0
       
        self.configureTableView()
        
        if isFromSDK {
            updateLeftbatBtn(status: isFromSDK)
        }
        
        if isCertDetail {
            buttonView.isHidden = true
            infoText.isHidden = true
        }
        updateEyeButtonImage()
        let imageUrl = viewModel?.certModel?.value?.logo ?? viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.logoImageURL
        let orgName = viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.name
        let bgColor = viewModel?.certModel?.value?.backgroundColor
        let firstLetter = orgName?.first ?? "U"
        let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
        ImageUtils.shared.setRemoteImage(for: companyLogo, imageUrl: imageUrl, orgName: orgName, bgColor: bgColor, placeHolderImage: profileImage)
        self.companyName.text = viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.name ??
        (viewModel?.connectionModel?.value?.theirLabel ?? "")
        self.companyLocation.text = viewModel?.connectionModel?.value?.orgDetails?.location ??  viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.location ?? ""
        if self.inboxCertState != nil && self.inboxCertState != "offer_received" {
            self.acceptButton.isHidden = true
        }
        
        //EBSI doesn't have data agreement
        tableView.tableFooterView = footerView()
        navigationController?.navigationBar.barTintColor = UIColor.black
        switch mode {
        case .EBSI_V2:
            self.certificateNameBaseView.isHidden = false
            print("hhhhh: \(viewModel?.certModel?.value?.searchableText)")
            self.certificateName.text = viewModel?.certModel?.value?.searchableText ?? ""
            self.companyLocation.text = "European Union"
            if viewModel?.certModel?.value?.subType == EBSI_CredentialType.Diploma.rawValue {
                self.companyName.text = viewModel?.certModel?.value?.EBSI_v2?.attributes?.first(where: { attr in
                    attr.name == "Awarding Body"
                })?.value ?? viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.name
            }
            self.tableView.reloadData()
        case .Receipt:
            self.viewModel?.fetchDataAgreement()
        case .other:
            self.viewModel?.fetchDataAgreement()
        case .EBSI_PDA1:
            self.certificateNameBaseView.isHidden = false
            self.certificateName.text = viewModel?.certModel?.value?.subType
            self.companyLocation.text = "Member state: " +  (self.viewModel?.certModel?.value?.attributes?["address"]?.value?.split(separator: " ").last ?? "") + "\n" + "European Union"
            self.companyLocation.numberOfLines = 2
            self.companyName.text = viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.name ??
            self.viewModel?.certModel?.value?.attributes?["name"]?.value ?? ""
            self.tableView.reloadData()
        case .PhotoIDWithAgeBadge:
            self.certificateNameBaseView.isHidden = true
            certificateNameValue = viewModel?.certModel?.value?.searchableText
            self.companyLocation.numberOfLines = 2
            self.companyName.text = viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.name ??
            self.viewModel?.certModel?.value?.attributes?["name"]?.value ?? ""
            self.companyLocation.text = viewModel?.connectionModel?.value?.orgDetails?.location ?? ""
            companyLogo.backgroundColor = .clear
            self.tableView.reloadData()
        case .dynamicOrg:
            break
        }
        addCustomBackTabIcon()
        addRightBarButton()
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(trustServicetapped))
        self.trustedIssuerStackView.addGestureRecognizer(tapGesture)
        checkForVerifiedIssuer()
        tableView.estimatedSectionHeaderHeight = 20
        tableView.estimatedSectionHeaderHeight = 20
        self.updateDataAgreementButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let screenHeight = UIScreen.main.bounds.height
        let sheetHeight = screenHeight * 0.85
        //parentViewHeight.constant = sheetHeight
        navigationController?.navigationBar.tintColor = viewModel?.certModel?.value?.textColor != nil ? UIColor(hex: viewModel!.certModel!.value!.textColor!) : UIColor.darkGray
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: viewModel?.certModel?.value?.textColor != nil ? UIColor(hex: viewModel!.certModel!.value!.textColor!) : UIColor.darkGray
        ]
    }
    
    @IBAction func closetapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func eyeButtonAction(_ sender: Any) {
        showValues = !showValues
        updateEyeButtonImage()
        self.tableView.reloadData()
    }
    
    private func updateEyeButtonImage() {
        let config = UIImage.SymbolConfiguration(scale: .small)
        let imageName = showValues ? "eye.slash" : "eye"
        let image = UIImage(systemName: imageName, withConfiguration: config)
        showButton.setImage(image, for: .normal)
    }
    
    
    @IBAction func deleteCredentialAction(_ sender: Any) {
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Task {
            if !(viewModel?.isRejectOrAcceptTapped ?? false) && viewModel?.inboxId?.isEmpty ?? false {
                if !hasCalledAccept {
                    hasCalledAccept = true
                    if let accept = onAccept {
                        accept(true)
                    }
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
        navigationController?.navigationBar.tintColor =  UIColor.darkGray
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor:  UIColor.darkGray
        ]
    }
    
    func updateLeftbatBtn(status: Bool) {
        if isFromSDK {
            updateLeftBarButtonForSDK(status: status)
            return
        }
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(left: status ? [.notificationBadge] : [.notification], right: [])
    }
    
    func updateLeftBarButtonForSDK(status: Bool){
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(left: [.back])
    }
    
    @objc func trustServicetapped() {
        let credential = viewModel?.certModel?.value?.EBSI_v2?.credentialJWT
        TrustMechanismManager().trustProviderInfo(credential: credential, format: viewModel?.certModel?.value?.format, jwksURI: viewModel?.certModel?.value?.connectionInfo?.value?.orgDetails?.jwksURL) { data in
            if let data = data {
                DispatchQueue.main.async {
                    let vc = TrustServiceProviersBottomSheetVC(nibName: "TrustServiceProviersBottomSheetVC", bundle: Bundle.module)
                    vc.modalPresentationStyle = .overCurrentContext
                    vc.clearAlpha = true
                    vc.viewModel.data = data
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
    
    // Setting card color based on credential branding
    func setUpColor() {
        if let bgColor = viewModel?.certModel?.value?.backgroundColor {
            view.backgroundColor = UIColor(hex: bgColor)
        }
        if let textColor = viewModel?.certModel?.value?.textColor {
            certificateName.textColor = UIColor(hex: textColor)
            companyName.textColor = UIColor(hex: textColor)
            companyLocation.textColor = UIColor(hex: textColor)
            infoText.textColor = UIColor(hex: textColor)
            acceptButton.layer.borderWidth = 1
            acceptButton.layer.borderColor = UIColor(hex: textColor).cgColor
        }
        let imageUrl = viewModel?.certModel?.value?.logo ?? (viewModel?.connectionModel?.value?.orgDetails?.logoImageURL ?? "")
        let orgName = viewModel?.connectionModel?.value?.orgDetails?.name ?? ""
        let firstLetter = orgName.first ?? "U"
        let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: firstLetter, size: CGSize(width: 100, height: 100))
        ImageUtils.shared.setRemoteImage(for: companyLogo, imageUrl: imageUrl, orgName: orgName, placeHolderImage: profileImage)
    }
    
    func checkForVerifiedIssuer() {
        if let isValidOrganization = viewModel?.connectionModel?.value?.orgDetails?.isValidOrganization {
            if isValidOrganization {
                trustedIssuerStackView.isHidden = false
                companyLocation.isHidden = true
                verifiedImageView.image = "gpp_good".getImage()
                verifiedImageView.tintColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.textColor = UIColor(hex: "1EAA61")
                trustedServiceLabel.text = "Trusted Service Provider".localized()
            } else {
                trustedIssuerStackView.isHidden = false
                companyLocation.isHidden = true
                verifiedImageView.image = "gpp_bad".getImage()
                verifiedImageView.tintColor = .systemRed
                trustedServiceLabel.textColor = .systemRed
                trustedServiceLabel.text = "Untrusted Service Provider".localized()
            }
        } else {
            if viewModel?.certDetail != nil {
                trustedIssuerStackView.isHidden = true
                companyLocation.isHidden = false
            }
        }
    }
    
    func configureTableView(){
        switch mode {
        case .EBSI_V2:
            tableView.register(cellType: CertificateWithDataTableViewCell.self)
            tableView.register(cellType: CovidValuesRowTableViewCell.self)
        case .Receipt:
            self.registerCellsForReceipt(tableView: self.tableView)
        case .other:
            tableView.register(cellType: CertificateWithDataTableViewCell.self)
            tableView.register(cellType: CovidValuesRowTableViewCell.self)
        case .EBSI_PDA1, .PhotoIDWithAgeBadge:
            self.registerCellsForGenericAttributeStructure(tableView: self.tableView)
        default:
            tableView.register(cellType: CertificateWithDataTableViewCell.self)
            tableView.register(cellType: CovidValuesRowTableViewCell.self)
            tableView.register(cellType: ValuesRowImageTableViewCell.self)
        }
    }
    
    private func addCustomBackTabIcon() {
        backNavIcon.tag = 0
        backNavIcon.frame = CGRect(x: 0, y: 0, width: self.topAreaHeight, height: self.topAreaHeight)
        let barbtnItem = UIBarButtonItem(customView: backNavIcon)
        backNavIcon.delegate = self
        backNavIcon.containerView.isHidden = true
        backNavIcon.iconImg.tintColor = viewModel?.certModel?.value?.textColor != nil ? UIColor(hex: viewModel!.certModel!.value!.textColor!) : UIColor.darkGray
        self.navigationItem.leftBarButtonItem = barbtnItem
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
        deleteButton.addTarget(self, action: #selector(rejectButtonTapped(sender:)), for: .touchUpInside)
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
        self.tableView.reloadData()
    }
    
//    override func localizableValues() {
//        super.localizableValues()
//        self.title = "Data agreement".localizedForSDK()
//        if isCertDetail {
//            self.title = "Certificate Detail".localizedForSDK()
//        }
//        self.infoText.text = LocalizationSheet.agree_add_data_to_wallet.localizedForSDK()
//        self.acceptButton.setTitle("Accept".localizedForSDK(), for: .normal)
//    }
    
    @IBAction func acceptButtonTapped(sender: Any) {
        Task {
            switch mode {
            case .EBSI_V2,.EBSI_PDA1: await self.viewModel?.acceptEBSI_V2_Certificate()
                if viewModel?.isRejectOrAcceptTapped ?? false {
                    if let accept = onAccept {
                        accept(true)
                    }
                }
            case .Receipt:
                await self.viewModel?.acceptCertificate(mode: mode)
            case .other:
                await self.viewModel?.acceptCertificate()
            default:
                await self.viewModel?.acceptEBSI_V2_Certificate()
                if viewModel?.isRejectOrAcceptTapped ?? false {
                    if let accept = onAccept {
                        accept(true)
                    }
                }
          
            }
        }
    }
    
    @IBAction func rejectButtonTapped(sender: Any) {
        let alert = UIAlertController(title: "Data Wallet", message: "delete_item_message".localizedForSDK(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes".localizedForSDK(), style: .default, handler: { [self] action in
            if isCertDetail {
                self.viewModel?.deleteCredentialWith(id: self.viewModel?.certModel?.value?.referent?.referent ?? "", walletRecordId: viewModel?.certModel?.id)
            }else{
                viewModel?.rejectCertificate()
            }
            
            Task {
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
                    viewModel?.isRejectOrAcceptTapped = true
                    if let accept = onAccept {
                        accept(true)
                    }
                    await NotificationService().sendNoticationStatus(endPoint: viewModel?.certModel?.value?.notificationEndPont, event: NotificationStatus.credentialDeleted.rawValue, notificationID: viewModel?.certModel?.value?.notificationID, accessToken: viewModel?.certModel?.value?.accessToken ?? "", refreshToken: viewModel?.certModel?.value?.refreshToken ?? "", tokenEndPoint: viewModel?.certModel?.value?.tokenEndPoint ?? "")
                }
            }
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "No".localizedForSDK(), style: .default, handler: { action in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func tappedOnDataAgreement() {
        if viewModel?.dataAgreement == nil {
            return
        }
        let vm = DataAgreementViewModel(dataAgreement: viewModel?.dataAgreement,
                                        connectionRecordId: viewModel?.connectionModel?.id ?? "",
                                        mode: .issueCredential)
        vm.inboxId = viewModel?.inboxId
        vm.inboxModel = viewModel?.inboxModel
        
        let vc = DataAgreementViewController(vm: vm)
        self.push(vc: vc)
    }
    
    func footerView() -> UIView {
        let width = (self.navigationController?.view.frame.width ?? self.tableView.frame.width)
        let view  = UIView.init(frame: CGRect.init(x: 0, y: 0, width: width, height: 60))
        view.backgroundColor = .clear
        dataAgreementButton.frame = CGRect.init(x: 15, y: 0, width: width - 45, height: 50)
        dataAgreementButton.backgroundColor = .white
        dataAgreementButton.layer.cornerRadius = 10
        dataAgreementButton.setTitle("Data Agreement Policy".localizedForSDK(), for: .normal)
        dataAgreementButton.setTitleColor(.darkGray, for: .normal)
        dataAgreementButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        dataAgreementButton.contentHorizontalAlignment = .left
        dataAgreementButton.titleEdgeInsets.left = 20
        let rightArrow = UIImageView.init(frame: CGRect.init(x: width - 60, y: 15, width: 20, height: 20))
        rightArrow.image = UIImage(systemName: "chevron.right")
        rightArrow.tintColor = .darkGray
        rightArrow.contentMode = .center
        dataAgreementButton.addTarget(self, action:#selector(self.tappedOnDataAgreement), for: .touchUpInside)
        view.addSubview(dataAgreementButton)
        view.addSubview(rightArrow)
        
        if viewModel?.dataAgreement == nil {
            if let textColor = viewModel?.certModel?.value?.textColor {
                let color = UIColor(hex: textColor)
                rightArrow.tintColor = color.withAlphaComponent(0.5)
                dataAgreementButton.backgroundColor = color.withAlphaComponent(0.1)
                dataAgreementButton.setTitleColor(color.withAlphaComponent(0.5), for: .normal)
            } else {
                rightArrow.tintColor = .darkGray
                dataAgreementButton.alpha = 0.5
            }
        } else {
            if let textColor = viewModel?.certModel?.value?.textColor {
                let color = UIColor(hex: textColor)
                rightArrow.tintColor = color
                dataAgreementButton.backgroundColor = color.withAlphaComponent(0.1)
                dataAgreementButton.setTitleColor(color, for: .normal)
            } else {
                rightArrow.tintColor = .darkGray
                dataAgreementButton.backgroundColor = .white
                dataAgreementButton.setTitleColor(.darkGray, for: .normal)
            }
        }
        return view
    }
       
    func updateDataAgreementButton(){
        if viewModel?.dataAgreement == nil {
            dataAgreementButton.isUserInteractionEnabled = false
            dataAgreementButton.alpha = 0.5
        } else {
            dataAgreementButton.isUserInteractionEnabled = true
            dataAgreementButton.alpha = 1
        }
    }
}

extension CertificatePreviewBottomSheet: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch mode{
        case .EBSI_V2:
            return EBSIWallet.shared.getEBSI_V2_attributes(section: section,certModel: viewModel?.certModel).count
        case .other:
            let attrArray = viewModel?.certDetail?.value?.credentialProposalDict?.credentialProposal?.attributes?.map({ (item) -> IDCardAttributes in
                return IDCardAttributes.init(type: CertAttributesTypes.string, name: item.name ?? "", value: item.value)
            }) ?? []
            return attrArray.count
        case .Receipt(let model):
            return self.receiptViewNumberOfRowsInSection(section: section, model: model)
        case .EBSI_PDA1:
            return self.genericAttributeStructureViewNumberOfRowsInSection(section: section, model: viewModel?.certModel?.value?.attributes, headerKey: viewModel?.certModel?.value?.sectionStruct?[section].key ?? "")
        case .PhotoIDWithAgeBadge:
            if viewModel?.certModel?.value?.sectionStruct?[section].type == "photoIDwithImageBadge" {
                return 1
            } else {
                return self.genericAttributeStructureViewNumberOfRowsInSection(section: section, model: viewModel?.certModel?.value?.attributes, headerKey: viewModel?.certModel?.value?.sectionStruct?[section].key ?? "")
            }
        default:
            return EBSIWallet.shared.getEBSI_V2_attributes(section: section,certModel: viewModel?.certModel).count
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch mode{
        case .EBSI_V2:
            switch viewModel?.certModel?.value?.subType {
            case EBSI_CredentialType.Diploma.rawValue: return 3
            default: return 1
            }
        case .other: return 1
        case .Receipt:
            return self.receiptViewNumberOfSections(mode: .issue)
        case .EBSI_PDA1, .PhotoIDWithAgeBadge:
            return self.genericAttributeStructureViewNumberOfSections(mode: .issue,headers: viewModel?.certModel?.value?.sectionStruct ?? [])
        default:
            switch viewModel?.certModel?.value?.subType {
            case EBSI_CredentialType.Diploma.rawValue: return 3
            default: return 1
            }
      
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch mode{
        case .EBSI_V2:
            switch viewModel?.certModel?.value?.subType {
            case EBSI_CredentialType.Diploma.rawValue:
                let view = GeneralTitleView()
                switch section {
                case 0: view.value = "Identifier".uppercased()
                case 1: view.value = "Specified by".uppercased()
                case 2: view.value = "was awarded by".uppercased()
                default: view.value = "Identifier".uppercased()
                }
                view.btnNeed = false
                return view
            default:
                return nil
            }
            
        case .other:
            let view = GeneralTitleView()
            let schemeSeperated = viewModel?.certDetail?.value?.schemaID?.split(separator: ":")
            view.value = "\(schemeSeperated?[2] ?? "")".uppercased()
            view.btnNeed = false
            return view
        case .Receipt(let model):
            return self.receiptViewForHeaderInSection(section: section, model: model)
        case .EBSI_PDA1, .PhotoIDWithAgeBadge:
            return self.genericAttributeStructureViewForHeaderInSection(section: section, model: viewModel?.certModel?.value?.sectionStruct?[section])
        case .dynamicOrg:
            return nil
        
        }
        
    }
    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        switch mode{
//        case .EBSI_V2: return UITableView.automaticDimension
//        case .other: return UITableView.automaticDimension
//        case .Receipt:
//            return self.receiptViewHeightForHeaderInSection(section: section)
//        case .EBSI_PDA1:
//            return self.genericAttributeStructureViewHeightForHeaderInSection(section: section)
//        case .dynamicOrg:
//            return 0
//        case .PhotoIDWithAgeBadge:
//            return 0
//        }
//    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerView = self.tableView(tableView, viewForHeaderInSection: section) as? GeneralTitleView else {
            return CGFloat.leastNormalMagnitude
        }
        
        let headerTitle = headerView.value
        if !headerTitle.isEmpty {
            let font = UIFont.systemFont(ofSize: 17)
            let width = tableView.frame.width - 40
            let height = calculateHeightForText(text: headerTitle, font: font, width: width)
            return height
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func calculateHeightForText(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch mode{
            case .EBSI_V2: return 15
            case .other: return 15
            case .Receipt:
                return self.receiptViewHeightForFooterInSection(mode: .issue, section: section)
        case .EBSI_PDA1, .PhotoIDWithAgeBadge:
            return self.genericAttributeStructureViewHeightForFooterInSection(mode: .issue, section: section)
        case .dynamicOrg:
            return 0
        
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch mode{
            case .EBSI_V2: return nil
            case .other: return nil
            case .Receipt:
            return self.receiptViewForFooterInSection(mode: .issue, section: section, deleteAction: {})
        case .EBSI_PDA1, .PhotoIDWithAgeBadge:
            return self.genericAttributeStructureViewForFooterInSection(mode: .issue, section: section, deleteAction: {})
        default:  return nil
      
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var attrArray: [IDCardAttributes] = []
        switch mode {
        case .other:
            attrArray = viewModel?.certDetail?.value?.credentialProposalDict?.credentialProposal?.attributes?.map({ (item) -> IDCardAttributes in
                return IDCardAttributes.init(type: CertAttributesTypes.string, name: item.name ?? "", value: item.value)
            }) ?? []
        case .EBSI_V2:
            attrArray = EBSIWallet.shared.getEBSI_V2_attributes(section: indexPath.section,certModel: viewModel?.certModel)
        case .Receipt(let model):
            return receiptTableView(tableView, cellForRowAt: indexPath, model: model, blurStatus: showValues)
        case .EBSI_PDA1:
            let cell =  genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: viewModel?.certModel?.value?.attributes ?? [:], blurStatus: showValues,headerKey: viewModel?.certModel?.value?.sectionStruct?[indexPath.section].key ?? "")
            cell.layoutIfNeeded()
            return cell
        case .PhotoIDWithAgeBadge:
            if viewModel?.certModel?.value?.sectionStruct?[indexPath.section].type == "photoIDwithImageBadge" {
                let cell = tableView.dequeueReusableCell(with: PhotoIdWithImageCell.self, for: indexPath)
                cell.delegate = self
                cell.configureCell(model: viewModel?.certModel?.value?.attributes ?? [:], blureStatus: showValues)
                return cell
            } else {
                let cell =  genericAttributeStructureTableView(tableView, cellForRowAt: indexPath, model: viewModel?.certModel?.value?.attributes ?? [:], blurStatus: showValues,headerKey: viewModel?.certModel?.value?.sectionStruct?[indexPath.section].key ?? "", textColor: viewModel?.certModel?.value?.textColor)
                cell.layoutIfNeeded()
                return cell
            }
        default:
            attrArray = EBSIWallet.shared.getEBSI_V2_attributes(section: indexPath.section,certModel: viewModel?.certModel)
        
        }
        
        let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
        if let data = attrArray[safe: indexPath.row] {
            cell.setData(model: data, blurStatus: showValues)
            cell.renderUI(index: indexPath.row, tot: attrArray.count)
        }
        cell.arrangeStackForDataAgreement()
        if let textColor = viewModel?.certModel?.value?.textColor {
            cell.renderForCredentialBranding(clr: UIColor(hex: textColor))
        }
        cell.layoutIfNeeded()
        return cell
    }
}

extension CertificatePreviewBottomSheet: CertificatePreviewDelegate {
    
    func reloadData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.updateDataAgreementButton()
        }
    }
    
    func popVC() {
        DispatchQueue.main.async {
            if  !self.isFromSDK {
                if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
                    self.dismiss(animated: true)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                self.dismiss(animated: true)
            }
        }
    }
}

extension CertificatePreviewBottomSheet: ValuesRowImageTableViewCellDelegate {
    
    func showImageDetail(image: UIImage?) {
        if let vc = ShowQRCodeViewController().initialize() as? ShowQRCodeViewController {
            vc.QRCodeImage = image
            self.present(vc: vc, transStyle: .crossDissolve, presentationStyle: .overCurrentContext)
        }
    }
    
    
}
