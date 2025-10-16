//
//  ExchangeDataPreviewBottomSheetVC.swift
//  dataWallet
//
//  Created by iGrant on 05/05/25.
//

import Foundation
import UIKit
import eudiWalletOidcIos
import IndyCWrapper

class ExchangeDataPreviewBottomSheetVC: UIViewController {
    
    @IBOutlet weak var pageControlView: UIView!
    @IBOutlet weak var dynamicDataStack: UIStackView!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var baseTableView: UITableView!
    @IBOutlet weak var collectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var multipleCardInfoView: UIView!
    @IBOutlet weak var multipleCardAvailabelText: UILabel!
    @IBOutlet weak var certName: UILabel!
    @IBOutlet weak var multipleCardButton: UIButton!
    @IBOutlet weak var infoText: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var companyLogo: UIImageView!
    @IBOutlet weak var companyName: UILabel!
    @IBOutlet weak var companyLocation: UILabel!
//
    @IBOutlet weak var parentView: UIView!
    
    @IBOutlet weak var eyeButton: UIButton!
    @IBOutlet weak var parentViewheight: NSLayoutConstraint!
    
    @IBOutlet weak var trustedServiceProviderStackView: UIStackView!
    @IBOutlet weak var verifiedImageView: UIImageView!
    
    @IBOutlet weak var trustedServiceLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var credentialSetBackButton: UIButton!
    @IBOutlet weak var additionalDataText: UILabel!
    
    @IBOutlet weak var dimmedView: UIView!
    
    var completion: ((Bool) -> Void)?
    var showValues = false
    var viewModel: ExchangeDataPreviewViewModel?
    let dataAgreementHeaderHeight: CGFloat = 50
    var mode = ExchangeDataPreviewMode.other
    var maxHeight: CGFloat = 0
    var dataAgreementButton = UIButton.init(type: .custom)
    var redirectUri = String()
    var presentationDefinition = String()
    var clientMetaData = String()
    var credentialsDict = [[String: Any]]()
    var dataAgreementView = UIView()
    var isLimitedDisclosure: Bool?
    var dcqlQuery: DCQLQuery?
    var name, location, logo: String?
    var isVerification: Bool? = false
    var presentationDefinitionModel: eudiWalletOidcIos.PresentationDefinitionModel? = nil
    var currentlySelectedSection: Int? = nil
    var isCheckBoxSelected: Bool = false
    
    var headerViews: [Int: ExpandableHeaderView] = [:]
    var isValidOrg: Bool?
    var expandedSections: Set<Int> = []
    var filteredCredentials: [[String]] = []
    var selectedCredentialIndexes: [Int: String] = [:]
    var sharedCredentials: [String] = []
    private var headerTitles: [Int: String] = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.bringSubviewToFront(parentView)
        navigationController?.navigationBar.isHidden = true
        //dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
       // parentView.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
//        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
//            dimmedView.backgroundColor = .clear
//        } else {
//            dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
//        }
        additionalDataText.isHidden = true
        self.credentialSetBackButton.isHidden = true
        trustedServiceProviderStackView.isHidden = true
        let jsonData = presentationDefinition.replacingOccurrences(of: "+", with: " ").data(using: .utf8)!
        presentationDefinitionModel = try? JSONDecoder().decode(eudiWalletOidcIos.PresentationDefinitionModel.self, from: jsonData)
        if mode == .EBSIProcessingVPExchange {
                let organisationDetails = EBSIWallet.shared.openIdIssuerResponseData
                
                let jsonData = clientMetaData.data(using: .utf8)!
            Task {
                let connectionModel = await EBSIWallet.shared.getEBSI_V3_connection(orgID: EBSIWallet.shared.exchangeClientID) ?? CloudAgentConnectionWalletModel()
                name = connectionModel.value?.orgDetails?.name
                location = connectionModel.value?.orgDetails?.location
                logo = connectionModel.value?.orgDetails?.logoImageURL
            }
        } else  {
            let organisationDetails = self.viewModel?.connectionModel?.value?.orgDetails
            name = organisationDetails?.name
            location = organisationDetails?.location
            logo = organisationDetails?.logoImageURL
        }
        viewModel?.delegate = self
        self.pageControl.hidesForSinglePage = true
        addRightBarButton()
        withContentOnDidLoad()
                
        if mode == .EBSI {
            viewModel?.populateModelForEBSI(presentationDefinition: presentationDefinitionModel)
        } else if mode == .EBSIMultipleCerts {
            viewModel?.populateModelForEBSI(presentationDefinition: presentationDefinitionModel)
        } else if mode == .EBSIProcessingVPExchange {
            viewModel?.populateModelForEBSI(presentationDefinition: presentationDefinitionModel, dcql: dcqlQuery, completionBlock: { success in
                if success {
                    DispatchQueue.main.async {
                        self.setInfoText()
                        self.expandedSections = self.viewModel?.EBSI_credentialsForSession?.count == 1 ? [0] : []
                        let count = self.dcqlQuery != nil ? self.dcqlQuery?.credentials.count : self.presentationDefinitionModel?.inputDescriptors?.count
                        if count ?? 0 > 1 || self.dcqlQuery?.credentialSets != nil {
                        for (index,data) in self.viewModel?.EBSI_credentialsForSession?.enumerated() ?? [].enumerated() {
                                self.selectedCredentialIndexes[index] = data.first?.value?.EBSI_v2?.credentialJWT
                            }
                            if  self.dcqlQuery?.credentialSets != nil {
                                if self.viewModel?.sessionList.count ?? 0 == 1 {
                                    self.additionalDataText.isHidden = true
                                } else if self.viewModel?.sessionIndex ?? 0 == 0 {
                                    self.additionalDataText.isHidden = false
                                    self.additionalDataText.text = "verification_additional_data_requested_confirm_to_proceed".localizedForSDK()
                                } else {
                                    self.additionalDataText.isHidden = true
                                }
                            }
                            self.tableView.reloadData()
                        } else {
                            self.collectionView.reloadData()
                        }
                        if let sessionList = self.viewModel?.sessionList,
                           let sessionIndex = self.viewModel?.sessionIndex,
                           !sessionList.isEmpty,
                           sessionIndex < sessionList.count {
                            self.updateAcceptButtonState()
                            if sessionIndex == 0 {
                                self.credentialSetBackButton.isHidden = true
                            }
                        }
                        Task {
                            await self.checkForVerifiedOrg()
                        }
                    }
                }
            })
        } else {
            viewModel?.fetchDataAgreement()
            trustedServiceProviderStackView.isHidden = true
            companyLocation.isHidden = false
            fetchAllData()
        }
        
        self.view.subviews.forEach { view in
            view.isHidden = true
        }
        setupTableView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(trustServicetapped))
        self.trustedServiceProviderStackView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let screenHeight = UIScreen.main.bounds.height
        let sheetHeight = screenHeight * 0.85
        //parentViewheight.constant = sheetHeight
            
        
        updateBlurStateForVisibleCells()
    }
    
    func setupTableView() {
        if isMultipleInputDescriptors() ?? false || self.dcqlQuery?.credentialSets != nil {
            baseTableView.isHidden = true
            tableView.isHidden = false
            tableView.dataSource = self
            tableView.delegate = self
            collectionView.isHidden = true
            tableView.register(cellType: ExchangeDataPreviewMultipleInputDescriptorTVC.self)
        } else {
            tableView.isHidden = true
            baseTableView.isHidden = false
            collectionView.isHidden = false
            setupCollectionView()
        }
        
    }
    
    func isMultipleInputDescriptors() -> Bool? {
        if let dcql = dcqlQuery {
            return dcql.credentials.count > 1
        } else if presentationDefinition != "" {
            let jsonData = presentationDefinition.replacingOccurrences(of: "+", with: " ").data(using: .utf8)!
            let presentationDefinitionModel = try? JSONDecoder().decode(eudiWalletOidcIos.PresentationDefinitionModel.self, from: jsonData)
            return presentationDefinitionModel?.inputDescriptors?.count ?? 0 > 1
        } else {
            return false
        }
    }
    
    private func createDataAgreementButtonView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 10
        button.setTitle("certificate_data_agreement_policy".localizedForSDK(), for: .normal)
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        button.isUserInteractionEnabled = false
        button.alpha = 0.5
        let rightArrow = UIImageView()
        rightArrow.image = UIImage(systemName: "chevron.right")
        rightArrow.contentMode = .center
        
        containerView.addSubview(button)
        containerView.addSubview(rightArrow)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        rightArrow.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            button.heightAnchor.constraint(equalToConstant: 45),
            
            
            rightArrow.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            rightArrow.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -10),
            rightArrow.widthAnchor.constraint(equalToConstant: 20),
            rightArrow.heightAnchor.constraint(equalToConstant: 20)
        ])
        
//        if let textColor = viewModel.certModel?.value?.textColor {
//            rightArrow.tintColor = UIColor(hex: textColor).withAlphaComponent(0.5)
//            button.backgroundColor = UIColor(hex: textColor).withAlphaComponent(0.1)
//            button.setTitleColor(UIColor(hex:textColor).withAlphaComponent(0.5), for: .normal)
//        } else if let textColor = viewModel.histories?.value?.history?.display?.textColor {
//            rightArrow.tintColor = UIColor(hex: textColor).withAlphaComponent(0.5)
//            button.backgroundColor = UIColor(hex: textColor).withAlphaComponent(0.1)
//            button.setTitleColor(UIColor(hex:textColor).withAlphaComponent(0.5), for: .normal)
//        } else {
            rightArrow.tintColor = .darkGray
            button.alpha = 0.5
//        }
        return containerView
    }
    
    private func withContentOnDidLoad() {
        setInfoText()
        credentialSetBackButton.backgroundColor = UIColor(hex: "#7A7A7A")
        credentialSetBackButton.tintColor = .white
        acceptButton.layer.cornerRadius = 25
        rejectButton.layer.cornerRadius = 25
        companyLogo.layer.cornerRadius = 30
        self.acceptButton.setTitle("general_confirm".localizedForSDK(), for: .normal)
        acceptButton.backgroundColor = AriesMobileAgent.themeColor
        rejectButton.backgroundColor = AriesMobileAgent.themeColor.withAlphaComponent(0.7)
        
        if mode == .EBSI || mode == .EBSIMultipleCerts || mode == .EBSIProcessingVPExchange{
            self.updateCompanyDetails()
        }
        
    }
    
    @IBAction func tappedOnBackButtonForCredentialSet(_ sender: Any) {
        
        if let dcqlQuery = dcqlQuery {
            viewModel?.sessionIndex = (viewModel?.sessionIndex ?? 0) - 1
            viewModel?.EBSI_credentialsForSession = viewModel?.buildEbsiCredentialForSession(sessionItems: viewModel?.sessionList ?? [], targetIndex: viewModel?.sessionIndex ?? 0, dcqlQuery: dcqlQuery, inputMatrix: viewModel?.EBSI_credentials)
            additionalDataText.isHidden = false
            additionalDataText.text = "verification_additional_data_requested_confirm_to_proceed".localizedForSDK()
            if viewModel?.sessionIndex == 0 {
                credentialSetBackButton.isHidden = true
            } else {
                
                credentialSetBackButton.isHidden = false
            }
            expandedSections = viewModel?.EBSI_credentialsForSession?.count == 1 ? [0] : []
            updateAcceptButtonState()
            tableView?.reloadData()
        }
    }
    
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "ExchangeDataAgreementCollectionViewCell", bundle: Bundle.module), forCellWithReuseIdentifier: "ExchangeDataAgreementCollectionViewCell")
        collectionView.register(UINib(nibName: "ExchangeBottomSheetCollectionViewCell", bundle: Bundle.module), forCellWithReuseIdentifier: "ExchangeBottomSheetCollectionViewCell")
    }
    
    func shouldEnableAcceptButton() -> Bool {
        if let sessionList = viewModel?.sessionList, let sessionIndex = viewModel?.sessionIndex {
            if sessionIndex == sessionList.count - 1 && sessionList[sessionIndex].type != "MandatoryWithOROption"{
                let shouldEnableConfirm = sessionList.contains(where: { !$0.checkedItem.isEmpty})
                return shouldEnableConfirm
            } else {
                let session = sessionList[sessionIndex]
                switch session.type {
                case "MandatoryWithSingleOption", "OptionalWithOrOption", "OptionalWithSingleItem":
                    break
                case "MandatoryWithOROption":
                    if session.checkedItem.isEmpty {
                        return false
                    }
                default:
                    break
                }
            }
        }
        
        return true
    }
    
    func updateAcceptButtonState() {
        acceptButton.isEnabled = shouldEnableAcceptButton()
        if !shouldEnableAcceptButton() {
            acceptButton.backgroundColor = UIColor(hex: "#7A7A7A")
        } else {
            acceptButton.backgroundColor = AriesMobileAgent.themeColor
        }
    }
    
    func checkForVerifiedOrg() async {
        let clientDataString = clientMetaData.replacingOccurrences(of: "+", with: " ")
        let clientMetadataJson = clientDataString.replacingOccurrences(of: "\'", with: "\"").data(using: .utf8)!
        let clientMetaDataModel = try? JSONDecoder().decode(eudiWalletOidcIos.ClientMetaData.self, from: clientMetadataJson)
        let segments = clientMetaDataModel?.legalPidAttestation?.split(separator: ".")
        var issuerOrVerifierID: String? = nil
        if segments?.count ?? 0 > 1 {
            let jsonString = "\(segments?[1] ?? "")".decodeBase64() ?? ""
            let jsonObject = UIApplicationUtils.shared.convertStringToDictionary(text: jsonString)
            issuerOrVerifierID = jsonObject?["iss"] as? String
        }
        
        TrustMechanismManager().isIssuerOrVerifierTrusted(credential: EBSIWallet.shared.presentationRequestJwt, format: "", jwksURI: "") { isValid in
            if let isValid = isValid {
                self.isValidOrg = isValid
                
                self.setTrustService(isValid: isValid)
                self.viewModel?.connectionModel?.value?.orgDetails?.isValidOrganization = self.isValidOrg
                self.viewModel?.connectionModel?.value?.orgDetails?.x5c = EBSIWallet.shared.presentationRequestJwt
                Task {
                    let (_, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),recipientKey: "",label: self.viewModel?.connectionModel?.value?.orgDetails?.name ?? "", type: UpdateWalletType.trusted, id: self.viewModel?.connectionModel?.value?.requestID ?? "", theirDid: "", myDid: self.viewModel?.connectionModel?.value?.myDid ?? "",imageURL: self.viewModel?.connectionModel?.value?.orgDetails?.coverImageURL ?? "" ,invitiationKey: "", isIgrantAgent: false, routingKey: nil, orgDetails: self.viewModel?.connectionModel?.value?.orgDetails, orgID: self.viewModel?.connectionModel?.value?.orgDetails?.orgId)
                }
            }
            
        }
    }
    
    func setTrustService(isValid: Bool?) {
        if let isValidOrg = isValidOrg {
            DispatchQueue.main.async {
                if isValidOrg {
                    self.trustedServiceProviderStackView.isHidden = false
                    self.companyLocation.isHidden = true
                    self.verifiedImageView.image = "gpp_good".getImage()
                    self.verifiedImageView.tintColor = UIColor(hex: "1EAA61")
                    self.trustedServiceLabel.textColor = UIColor(hex: "1EAA61")
                    self.trustedServiceLabel.text = "general_trusted_service_provider".localizedForSDK()
                } else {
                    self.trustedServiceProviderStackView.isHidden = false
                    self.companyLocation.isHidden = true
                    self.verifiedImageView.image = "gpp_bad".getImage()
                    self.verifiedImageView.tintColor = .systemRed
                    self.trustedServiceLabel.textColor = .systemRed
                    self.trustedServiceLabel.text = "general_untrusted_service_provider".localizedForSDK()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.trustedServiceProviderStackView.isHidden = true
                self.companyLocation.isHidden = false
            }
        }
    }
    
    @objc func trustServicetapped() {
        let credential = EBSIWallet.shared.presentationRequestJwt
        
        TrustMechanismManager().trustProviderInfo(credential: credential, format: "", jwksURI: "") { data in
            if let data = data {
                DispatchQueue.main.async {
                    let vc = TrustServiceProviersBottomSheetVC(nibName: "TrustServiceProviersBottomSheetVC", bundle: Bundle.module)
                    vc.modalPresentationStyle = .overFullScreen
                    vc.clearAlpha = true
                    vc.viewModel.data = data
                    vc.viewModel.credential = credential
                    UIApplicationUtils.shared.getTopVC()?.present(vc, animated: true)
                }
            }
        }
    }
    
    private func setInfoText() {
        var cerNameText: String = ""
        if viewModel?.EBSI_credentialsForSession?.first?[pageControl.currentPage].value?.subType == EBSI_CredentialType.PWA.rawValue || dcqlQuery?.credentialSets != nil {
            certName.isHidden = true
        } else {
            if let text = presentationDefinitionModel?.name, !text.isEmpty {
                cerNameText = text.uppercased()
            } else if let text = presentationDefinitionModel?.inputDescriptors?.first?.name, !text.isEmpty {
                cerNameText = text.uppercased()
            } else if let text = viewModel?.EBSI_credentialsForSession?.first?[pageControl.currentPage].value?.searchableText,!text.isEmpty {
                cerNameText = text
            }
            certName.text = viewModel?.isFromQR ?? false ? "\(viewModel?.QRData?.proofRequest?.name ?? "")" : "\(cerNameText)"
        }
       
        if mode == .EBSIMultipleCerts || mode == .EBSIProcessingVPExchange && viewModel?.EBSI_credentials?.first?.count ?? 0 > 1 || mode == .other && viewModel?.allItemsIncludedGroups.count ?? 0 > 1 {
            multipleCardAvailabelText.isHidden = false
            let purpose = getPurposeFromPresentationDefinition()
            if isMultipleInputDescriptors() ?? false || self.dcqlQuery?.credentialSets != nil {
                if let text = presentationDefinitionModel?.purpose, !text.isEmpty {
                    infoText.text = text
                } else {
                    if let dcql = dcqlQuery {
                        if dcql.credentialSets != nil {
                            if viewModel?.sessionList.count ?? 0 == 1 {
                                additionalDataText.isHidden = true
                            } else if viewModel?.sessionIndex ?? 0 == 0 {
                                additionalDataText.isHidden = false
                                additionalDataText.text = "verification_additional_data_requested_confirm_to_proceed".localizedForSDK()
                            } else {
                                additionalDataText.isHidden = true
                            }
                            infoText.text = "verification_by_clicking_confirm_you_agree_to_share_the_selected_data".localizedForSDK() + (name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.orgName ?? "")
                        } else {
                            infoText.text = "verification_by_clicking_confirm_you_agree_to_share_the_below_data".localizedForSDK() + (name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.orgName ?? "")
                        }
                    } else {
                        infoText.attributedText = NSMutableAttributedString().normal("ebsi_multiple_cards_sharing".localizedForSDK() + " " + "connect_by_choosing_confirm_you_agree_to_the_requested_data_to_org_name".localizedForSDK()).bold(" " + (name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.orgName ?? ""))
                    }
                }
            } else {
                if !purpose.isEmpty {
                    infoText.text = presentationDefinitionModel?.purpose ?? presentationDefinitionModel?.inputDescriptors?.first?.purpose
                } else {
                    if let dcql = dcqlQuery {
                        if dcql.credentialSets != nil {
                            infoText.text = "verification_by_clicking_confirm_you_agree_to_share_the_selected_data".localizedForSDK() + (name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.orgName ?? "")
                        } else {
                            infoText.text = "verification_by_clicking_confirm_you_agree_to_share_the_below_data".localizedForSDK() + (name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.orgName ?? "")
                        }
                    } else {
                        infoText.attributedText = NSMutableAttributedString().normal("ebsi_multiple_cards_sharing".localizedForSDK() + " " + "connect_by_choosing_confirm_you_agree_to_the_requested_data_to_org_name".localizedForSDK()).bold(" " + (name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.orgName ?? ""))
                    }
                }
            }
        } else {
            let purpose = getPurposeFromPresentationDefinition()
            if isMultipleInputDescriptors() ?? false || self.dcqlQuery?.credentialSets != nil {
                if let text = presentationDefinitionModel?.purpose, !text.isEmpty {
                    infoText.text = text
                } else {
                    if let dcql = dcqlQuery {
                        if dcql.credentialSets != nil {
                            
                            infoText.text = "verification_by_clicking_confirm_you_agree_to_share_the_selected_data".localizedForSDK() + (name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.orgName ?? "")
                        } else {
                            infoText.text = "verification_by_clicking_confirm_you_agree_to_share_the_below_data".localizedForSDK() + (name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.orgName ?? "")
                        }
                    } else {
                        infoText.attributedText = NSMutableAttributedString().normal("connect_by_choosing_confirm_you_agree_to_the_requested_data_to_org_name".localizedForSDK()).bold(" " + ((name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.connectionModel?.value?.theirLabel ?? viewModel?.orgName) ?? ""))
                    }
                }
            } else {
                if !purpose.isEmpty {
                    infoText.text = presentationDefinitionModel?.purpose ?? presentationDefinitionModel?.inputDescriptors?.first?.purpose
                } else {
                    infoText.attributedText = NSMutableAttributedString().normal("connect_by_choosing_confirm_you_agree_to_the_requested_data_to_org_name".localizedForSDK()).bold(" " + (name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.connectionModel?.value?.theirLabel ?? self.viewModel?.orgName ?? ""))
                }
            }
        }
        showTitleWhenMultipleInputDescriptor()
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func eyeButtonTapped(_ sender: Any) {
        showValues = !showValues
        
        let config = UIImage.SymbolConfiguration(scale: .small)
        let imageName = showValues ? "eye.slash" : "eye"
        let img = UIImage(systemName: imageName, withConfiguration: config)
//        eyeButton.imageView?.contentMode = .scaleAspectFit
        eyeButton.setImage(img, for: .normal)
        self.collectionView.reloadInMain()
        //self.tableView.reloadData()
        updateBlurStateForVisibleCells()
    }
    
    private func updateBlurStateForVisibleCells() {
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows else { return }
        
        for indexPath in visibleIndexPaths {
            if let cell = tableView.cellForRow(at: indexPath) as? ExchangeDataPreviewMultipleInputDescriptorTVC {
                cell.updateBlurState(showValues: showValues)
            }
        }
    }
    
    
    private func showTitleWhenMultipleInputDescriptor(){
//        let jsonData = presentationDefinition.replacingOccurrences(of: "+", with: " ").data(using: .utf8)!
//        let presentationDefinitionModel = try? JSONDecoder().decode(eudiWalletOidcIos.PresentationDefinitionModel.self, from: jsonData)
        
        if isMultipleInputDescriptors() ?? false && dcqlQuery?.credentialSets == nil {
            certName.text = "Credentials requested"
            pageControl.isHidden = true
            multipleCardButton.isHidden = true
            multipleCardAvailabelText.isHidden = true
        }
    }
    
    private func fetchAllData() {
        let group = DispatchGroup()
        group.enter()
        self.self.viewModel?.getConnectionModel(completion: { _ in
            group.leave()
        })
        group.enter()
        self.viewModel?.getCredsForProof(completion: {  (success) in
            group.leave()
        })
        group.notify(queue: .main, execute: { [weak self] in
            guard let self = self else { return }
            self.updateCompanyDetails()
            self.collectionView.reloadData()
            if self.mode == .EBSI {
                let purpose = getPurposeFromPresentationDefinition()
                               if !purpose.isEmpty {
                    infoText.text = presentationDefinitionModel?.purpose ?? presentationDefinitionModel?.inputDescriptors?.first?.purpose
                } else {
                    self.infoText.attributedText = NSMutableAttributedString().normal("connect_by_choosing_confirm_you_agree_to_the_requested_data_to_org_name".localizedForSDK()).bold(" " + (self.viewModel?.orgName ??  "" ))
                }
            } else if self.mode == .EBSIMultipleCerts  || self.mode == .EBSIProcessingVPExchange && self.viewModel?.EBSI_credentials?.first?.count ?? 0 > 1 || self.mode == .other && self.viewModel?.allItemsIncludedGroups.count ?? 0 > 1 {
                self.multipleCardAvailabelText.isHidden = false
                let purpose = getPurposeFromPresentationDefinition()
                                if !purpose.isEmpty {
                    infoText.text = presentationDefinitionModel?.purpose ?? presentationDefinitionModel?.inputDescriptors?.first?.purpose
                } else {
                    self.infoText.attributedText = NSMutableAttributedString().normal("ebsi_multiple_cards_sharing".localizedForSDK() + " " + "connect_by_choosing_confirm_you_agree_to_the_requested_data_to_org_name".localizedForSDK()).bold(" " + (self.viewModel?.orgName ?? "" ))
                }
            }
            self.setInfoText()
            self.refresh()
            self.view.subviews.forEach { view in
                view.isHidden = false
            }
            UIApplicationUtils.hideLoader()
        })
    }
    
    @objc func tappedOnDataAgreement() {
        let vm = DataAgreementViewModel(dataAgreement: viewModel?.dataAgreement,
                                        connectionRecordId: viewModel?.connectionModel?.id ?? "",
                                        mode: .dataExchange)
        let vc = DataAgreementBottomSheetVC()
        vc.viewModel = vm
        self.present(vc: vc, presentationStyle: .overCurrentContext)
    }
    
    private func addRightBarButton() {
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
    
    @objc
    private func tappedOnEyeButton() {
        showValues = !showValues
        addRightBarButton()
        self.collectionView.reloadInMain()
    }
    
    func updateCompanyDetails(){
        if let logo = logo ?? self.viewModel?.connectionModel?.value?.orgDetails?.logoImageURL {
            ImageUtils.shared.setRemoteImage(for: self.companyLogo, imageUrl: logo, orgName:  self.viewModel?.connectionModel?.value?.orgDetails?.name)
        } else {
            // If no image available
            if let letter = name?.first ?? self.viewModel?.connectionModel?.value?.orgDetails?.name?.first {
                let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: letter, size: CGSize(width: 100, height: 100))
                self.companyLogo.image = profileImage
            } else {
                self.companyLogo.image  =  UIImage(named: "iGrant.io_DW_Logo")
            }
        }
        self.companyName.text = name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.connectionModel?.value?.theirLabel ?? self.viewModel?.orgName ?? ""
        self.companyLocation.text = location ?? self.viewModel?.connectionModel?.value?.orgDetails?.location ?? self.viewModel?.orgLocation ?? ""
        
        if  mode == .EBSIProcessingVPExchange {
            if self.viewModel?.EBSI_credentials?.first?.count ?? 0 > 0 {
                var cerNameText: String = ""
                if let text = presentationDefinitionModel?.name, !text.isEmpty {
                    cerNameText = text.uppercased()
                } else if let text = presentationDefinitionModel?.inputDescriptors?.first?.name, !text.isEmpty {
                    cerNameText = text.uppercased()
                } else if let text = viewModel?.EBSI_credentials?.first?[pageControl.currentPage].value?.searchableText,!text.isEmpty {
                    cerNameText = text
                }
                self.certName.text = cerNameText.camelCaseToWords().uppercased()
            }
        } else if mode == .EBSIMultipleCerts {
            self.certName.text = (self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.orgName ?? self.viewModel?.connectionModel?.value?.theirLabel ?? "" )
        }
        updateDataAgreementButton()
    }
    
//    override func localizableValues() {
//        super.localizableValues()
//        self.title = "general_data_agreement".localized()
//        self.acceptButton.setTitle("general_confirm".localized(), for: .normal)
//        self.collectionView.reloadData()
//
//         if mode == .EBSIMultipleCerts || mode == .EBSIProcessingVPExchange && viewModel?.EBSI_credentials?.records?.count ?? 0 > 1  || mode == .other && viewModel?.allItemsIncludedGroups.count ?? 0 > 1 {
//            multipleCardAvailabelText.isHidden = false
//             let purpose = getPurposeFromPresentationDefinition()
//             if !purpose.isEmpty {
//                 infoText.text = presentationDefinitionModel?.purpose ?? presentationDefinitionModel?.inputDescriptors?.first?.purpose
//             } else {
//                 infoText.attributedText = NSMutableAttributedString().normal("ebsi_multiple_cards_sharing".localized() + " " + "connect_by_choosing_confirm_you_agree_to_the_requested_data_to_org_name".localized()).bold(" " + (name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.orgName ?? self.viewModel?.connectionModel?.value?.theirLabel ?? "" ))
//             }
//            self.updateCompanyDetails()
//         } else {
//             let purpose = getPurposeFromPresentationDefinition()
//             if !purpose.isEmpty {
//                 infoText.text = presentationDefinitionModel?.purpose ?? presentationDefinitionModel?.inputDescriptors?.first?.purpose
//             } else {
//                 infoText.attributedText = NSMutableAttributedString().normal("connect_by_choosing_confirm_you_agree_to_the_requested_data_to_org_name".localized()).bold(" " + ((name ?? self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.connectionModel?.value?.theirLabel ?? viewModel?.orgName) ?? ""))
//             }
//             self.updateCompanyDetails()
//         }
//    }
    
    func dataAgreementPolicyButton(disabledMode: Bool = false) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        dataAgreementView.translatesAutoresizingMaskIntoConstraints = false
        dataAgreementView.backgroundColor = .clear
        dataAgreementView.subviews.forEach { $0.removeFromSuperview() }

        dataAgreementButton.translatesAutoresizingMaskIntoConstraints = false
        dataAgreementButton.backgroundColor = .white
        dataAgreementButton.layer.cornerRadius = 10
        dataAgreementButton.setTitle("certificate_data_agreement_policy".localizedForSDK(), for: .normal)
        dataAgreementButton.setTitleColor(.darkGray, for: .normal)
        dataAgreementButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        dataAgreementButton.contentHorizontalAlignment = .left
        dataAgreementButton.titleEdgeInsets.left = 20
        dataAgreementButton.removeTarget(nil, action: nil, for: .allEvents)
        dataAgreementButton.addTarget(self, action: #selector(self.tappedOnDataAgreement), for: .touchUpInside)

        let rightArrow = UIImageView()
        rightArrow.translatesAutoresizingMaskIntoConstraints = false
        rightArrow.image = disabledMode ? UIImage(named: "ic_disabled_arrow") : UIImage(systemName: "chevron.right")
        rightArrow.tintColor = .darkGray
        rightArrow.contentMode = .center

        dataAgreementView.addSubview(dataAgreementButton)
        dataAgreementView.addSubview(rightArrow)
        containerView.addSubview(dataAgreementView)

        NSLayoutConstraint.activate([
            dataAgreementView.topAnchor.constraint(equalTo: containerView.topAnchor),
            dataAgreementView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            dataAgreementView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            dataAgreementView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            dataAgreementView.heightAnchor.constraint(equalToConstant: 60),

            dataAgreementButton.leadingAnchor.constraint(equalTo: dataAgreementView.leadingAnchor),
            dataAgreementButton.trailingAnchor.constraint(equalTo: dataAgreementView.trailingAnchor),
            dataAgreementButton.topAnchor.constraint(equalTo: dataAgreementView.topAnchor, constant: -10),
            dataAgreementButton.heightAnchor.constraint(equalToConstant: 45),
            

            rightArrow.centerYAnchor.constraint(equalTo: dataAgreementButton.centerYAnchor),
            rightArrow.trailingAnchor.constraint(equalTo: dataAgreementButton.trailingAnchor, constant: -10),
            rightArrow.widthAnchor.constraint(equalToConstant: 20),
            rightArrow.heightAnchor.constraint(equalToConstant: 20),
        ])

        return containerView
    }
    
    func updateDataAgreementButton(){
        if !dynamicDataStack.subviews.contains(dataAgreementView) {
            if viewModel?.dataAgreement == nil {
                dataAgreementButton.isUserInteractionEnabled = false
                dataAgreementButton.alpha = 0.5
                dynamicDataStack.addArrangedSubview(dataAgreementPolicyButton(disabledMode: true))
                super.viewDidLoad()
            } else {
                dataAgreementButton.isUserInteractionEnabled = true
                dataAgreementButton.alpha = 1
                dynamicDataStack.addArrangedSubview(dataAgreementPolicyButton())
                super.viewDidLoad()
            }
        }
    }
    
    func showCardDetails(id: String?) {
        var recordId = id ?? ""
        self.viewModel?.getCertDetail(recordId: recordId, completion: { cert in
            if let cert = cert{
                if cert.value?.type == CertType.isSelfAttested(type: cert.value?.type) || cert.value?.type == CertType.idCards.rawValue{
                    switch cert.value?.subType {
                    case SelfAttestedCertTypes.covidCert_EU.rawValue:
                        let vc = CertificateViewController(pageType: .covid(isScan: false))
                        if let model = cert.value?.covidCert_EU {
                            vc.viewModel.covid = CovidCertificateStateViewModel(model: model)
                        }
                        vc.viewModel.covid?.recordId = cert.id ?? ""
                        //self.push(vc: vc)
                        self.present(vc: vc)
                    case SelfAttestedCertTypes.covidCert_IN.rawValue:
                        let vc = CertificateViewController(pageType: .covid(isScan: false))
                        if let model = cert.value?.covidCert_IND {
                            vc.viewModel.covid = CovidCertificateStateViewModel(model: model)
                        }
                        vc.viewModel.covid?.recordId = cert.id ?? ""
                        //self.push(vc: vc)
                        self.present(vc: vc)
                    case SelfAttestedCertTypes.aadhar.rawValue:
                        let vc = CertificateViewController(pageType: .aadhar(isScan: false))
                        if let model = cert.value?.aadhar {
                            vc.viewModel.aadhar = AadharStateViewModel(model: model)
                        }
                        vc.viewModel.aadhar?.recordId = cert.id ?? ""
                        //self.push(vc: vc)
                        self.present(vc: vc)
                    case SelfAttestedCertTypes.passport.rawValue:
                        let vc = CertificateViewController(pageType: .passport(isScan: false))
                        vc.viewModel.passport.passportModel = cert.value?.passport
                        vc.viewModel.passport.recordId = cert.id ?? ""
                        vc.viewModel.addedDate = cert.value?.addedDate ?? ""
                        //self.push(vc: vc)
                        self.present(vc: vc)
                    case SelfAttestedCertTypes.PhotoIDWithAge.rawValue:
                        let vc = CertificateViewController(pageType: .photoId(isScan: false))
                        vc.viewModel.photoID = SelfAttestedPhotoIDViewModel()
                        vc.viewModel.photoID?.photoIDCredential = cert.value?.photoIDCredential
                        vc.viewModel.addedDate = cert.value?.addedDate ?? ""
                        vc.viewModel.photoID?.recordId = cert.id ?? ""
                        //self.push(vc: vc)
                        self.present(vc: vc)
                        
                    default:
                        break
                    }
                } else {
                    
                    //TODO: USE CERT SUB TYPE IN FUTURE
                    //Receipt
                    if let receiptModel = ReceiptCredentialModel.isReceiptCredentialModel(certModel: cert){
                        //Show Receipt UI
                        let vc = CertificateViewController(pageType: .issueReceipt(mode: .view))
                        vc.viewModel.receipt = ReceiptStateViewModel(walletHandle: self.viewModel?.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert, receiptModel: receiptModel)
                        self.present(vc: vc)
                        //self.navigationController?.pushViewController(vc, animated: true)
                        return
                    }
                    
                    if cert.value?.photoIDCredential != nil || cert.value?.vct == "eu.europa.ec.eudi.photoid.1" {
                       
                       let tempCredential = SDJWTUtils.shared.updateIssuerJwtWithDisclosures(credential: cert.value?.EBSI_v2?.credentialJWT)
                           let dict = UIApplicationUtils.shared.convertToDictionary(text: tempCredential ?? "{}") ?? [:]
                           if let photoIDCredential = cert.value?.photoIDCredential ?? PhotoIDCredential.decode(withpDictionary: dict as [String : Any]) {
                               let vc = CertificateViewController(pageType: .photoId(isScan: false))
                               vc.viewModel.photoID = SelfAttestedPhotoIDViewModel()
                               vc.viewModel.photoID?.photoIDCredential = photoIDCredential
                               vc.viewModel.addedDate = cert.value?.addedDate ?? ""
                               vc.viewModel.photoID?.display = Display(mName: "", mLocation: "", mLocale: "", mDescription: "", mCover: DisplayCover(mUrl: "", mAltText: ""), mLogo:  DisplayCover(mUrl: "", mAltText: ""), mBackgroundColor: cert.value?.backgroundColor, mTextColor: cert.value?.textColor)
                               vc.viewModel.photoID?.orgInfo = cert.value?.connectionInfo?.value?.orgDetails
                               vc.viewModel.photoID?.recordId = cert.id ?? ""
                               self.present(vc: vc)
                           }
                       
                    } else {
                        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
                            let vc = CertificateViewController(pageType: .general(isScan: false))
                            vc.viewModel.general = GeneralStateViewModel.init(walletHandle: self.viewModel?.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert)
                            vc.viewModel.covid?.recordId = cert.id ?? ""
                            let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                            if let topVC = UIApplicationUtils.shared.getTopVC() {
                                topVC.present(sheetVC, animated: false, completion: nil)
                            }
                        } else {
                            let vc = CertificateViewController(pageType: .general(isScan: false))
                            vc.viewModel.general = GeneralStateViewModel.init(walletHandle: self.viewModel?.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert)
                            vc.viewModel.covid?.recordId = cert.id ?? ""
                            self.present(vc: vc)
                        }
                    }
                }
            }
        })
    }
    
    @IBAction func showSelectedCardDetail(_ sender: Any) {
        var recordId = ""
        if mode == .EBSI || mode == .EBSIMultipleCerts || mode == .EBSIProcessingVPExchange {
            recordId = viewModel?.EBSI_credentials?.first?[pageControl.currentPage].id ?? ""
        } else {
            recordId = viewModel?.allItemsIncludedGroups[pageControl.currentPage].id ?? ""
        }
        self.viewModel?.getCertDetail(recordId: recordId, completion: { cert in
            if let cert = cert{
                if cert.value?.type == CertType.isSelfAttested(type: cert.value?.type) || cert.value?.type == CertType.idCards.rawValue{
                    switch cert.value?.subType {
                    case SelfAttestedCertTypes.covidCert_EU.rawValue:
                        let vc = CertificateViewController(pageType: .covid(isScan: false))
                        if let model = cert.value?.covidCert_EU {
                            vc.viewModel.covid = CovidCertificateStateViewModel(model: model)
                        }
                        vc.viewModel.covid?.recordId = cert.id ?? ""
                        //self.push(vc: vc)
                        self.present(vc: vc)
                    case SelfAttestedCertTypes.covidCert_IN.rawValue:
                        let vc = CertificateViewController(pageType: .covid(isScan: false))
                        if let model = cert.value?.covidCert_IND {
                            vc.viewModel.covid = CovidCertificateStateViewModel(model: model)
                        }
                        vc.viewModel.covid?.recordId = cert.id ?? ""
                        //self.push(vc: vc)
                        self.present(vc: vc)
                    case SelfAttestedCertTypes.aadhar.rawValue:
                        let vc = CertificateViewController(pageType: .aadhar(isScan: false))
                        if let model = cert.value?.aadhar {
                            vc.viewModel.aadhar = AadharStateViewModel(model: model)
                        }
                        vc.viewModel.aadhar?.recordId = cert.id ?? ""
                        //self.push(vc: vc)
                        self.present(vc: vc)
                    case SelfAttestedCertTypes.passport.rawValue:
                        let vc = CertificateViewController(pageType: .passport(isScan: false))
                        vc.viewModel.passport.passportModel = cert.value?.passport
                        vc.viewModel.passport.recordId = cert.id ?? ""
                        vc.viewModel.addedDate = cert.value?.addedDate ?? ""
                        //self.push(vc: vc)
                        self.present(vc: vc)
                    case SelfAttestedCertTypes.PhotoIDWithAge.rawValue:
                        let vc = CertificateViewController(pageType: .photoId(isScan: false))
                        vc.viewModel.photoID = SelfAttestedPhotoIDViewModel()
                        vc.viewModel.photoID?.photoIDCredential = cert.value?.photoIDCredential
                        vc.viewModel.addedDate = cert.value?.addedDate ?? ""
                        vc.viewModel.photoID?.recordId = cert.id ?? ""
                        //self.push(vc: vc)
                        self.present(vc: vc)
                        
                    default:
                        break
                    }
                } else {
                    
                    //TODO: USE CERT SUB TYPE IN FUTURE
                    //Receipt
                    if let receiptModel = ReceiptCredentialModel.isReceiptCredentialModel(certModel: cert){
                        //Show Receipt UI
                        let vc = CertificateViewController(pageType: .issueReceipt(mode: .view))
                        vc.viewModel.receipt = ReceiptStateViewModel(walletHandle: self.viewModel?.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert, receiptModel: receiptModel)
                        self.present(vc: vc)
                        //self.navigationController?.pushViewController(vc, animated: true)
                        return
                    }
                    let vc = CertificateViewController(pageType: .general(isScan: false))
                    vc.viewModel.general = GeneralStateViewModel.init(walletHandle: self.viewModel?.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert)
                                vc.viewModel.covid?.recordId = cert.id ?? ""
                    //vc.modalPresentationStyle = .overCurrentContext
                    self.present(vc: vc)
                }
            }
        })
    }
    
    func performVPExchange(){
        var state = String()
        var nonce = String()
        var redirectURI = String()
        var credentialsListArray: [String] = []
        
        guard let dcqlQueryData = EBSIWallet.shared.dcqlQuery else { return }
        if let url = URL.init(string: redirectUri),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let uri = components.queryItems?.first(where: { $0.name == "redirect_uri" })?.value {
            redirectURI = uri
            
            let pfComponents = self.presentationDefinition.components(separatedBy: "nonce=")
            var nonceFromPresentationDef = ""
            if pfComponents.count > 1 {
                nonceFromPresentationDef = pfComponents[1]
            }
            
            state = components.queryItems?.first(where: { $0.name == "state" })?.value ?? ""
            nonce = components.queryItems?.first(where: { $0.name == "nonce" })?.value ?? nonceFromPresentationDef
        } else {
            // Convert JSON string to data
            guard let jsonData = redirectUri.data(using: .utf8) else {
                return
            }
            
            guard let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                return
            }
            
            redirectURI = jsonDict["response_uri"] as? String ?? ""
            nonce = jsonDict["nonce"] as? String ?? ""
            state = jsonDict["state"] as? String ?? ""
        }
        
        for session in viewModel?.sessionList ?? [] {
            // Only process MandatoryWithSingleOption
            if session.type == "MandatoryWithSingleOption" {
                
                for (idIndex, credId) in session.credentialIdList.enumerated() {
                    // Find the credential in dcqlQuery.credentials
                    if let dcqlIndex = dcqlQuery?.credentials.firstIndex(where: { $0.id == credId }) {
                        // Get the EBSI list for that credential
                        let ebsiList = viewModel?.EBSI_credentials?[dcqlIndex]
                        // Get the selected index for this credential id
                        let selectedIndex = session.selectedCredentialIndex[idIndex]
                        // Safety check
                        if selectedIndex < ebsiList?.count ?? 0{
                            let jwt = ebsiList?[selectedIndex].value?.EBSI_v2?.credentialJWT ?? ""
                            credentialsListArray.append(jwt)
                        }
                    }
                }
            } else {
                
                // 🔹 Flow 2: Other types (use checkedItem)
                for checkedIndex in session.checkedItem {
                    // checkedIndex is already the index in credentialIdList
                    if checkedIndex < session.credentialIdList.count {
                        let credentialId = session.credentialIdList[checkedIndex]
                        
                        // Find where this credentialId appears in dcqlQuery credentials
                        if let dcqlIndex = dcqlQuery?.credentials.firstIndex(where: { $0.id == credentialId }) {
                            
                            let ebsiList = viewModel?.EBSI_credentials?[dcqlIndex]
                            let selectedIndex = session.selectedCredentialIndex[checkedIndex] // Use checkedIndex here
                            
                            if selectedIndex < ebsiList?.count ?? 0 {
                                let jwt = ebsiList?[selectedIndex].value?.EBSI_v2?.credentialJWT ?? ""
                                credentialsListArray.append(jwt)
                            }
                        }
                    }
                }
                
            }
        }
        var updatedCredentialListArray : [String] = []
        let ss = filterSelectedCredentialsForCredentialSet(value: viewModel?.EBSI_credentials, sessionList: viewModel?.sessionList ?? [], dcql: dcqlQueryData)
        let filteredCred = ss
        sharedCredentials = filteredCred
        for (index,item) in sharedCredentials.enumerated() {
            let credentialItemDcql =  dcqlQueryData.credentials[index]
            var credentialFormat: String = ""
            if credentialItemDcql.format.isNotEmpty {
                credentialFormat = credentialItemDcql.format
            }
            if item.contains("~") {
                let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                let sdjwtR = eudiWalletOidcIos.SDJWTService.shared.createSDJWTR(credential: item, query: credentialItemDcql, format: credentialFormat, keyHandler: keyHandler)
                updatedCredentialListArray.append(sdjwtR ?? "")
            } else {
                updatedCredentialListArray.append(item)
            }
        }
        
        var result : WrappedVerificationResponse? = nil
        let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
        let verificationHandler = eudiWalletOidcIos.VerificationService(keyhandler: keyHandler)
        
        if let url = URL.init(string: self.redirectUri),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let redirect_uri = components.queryItems?.first(where: { $0.name == "redirect_uri" })?.value {
            UIApplicationUtils.showLoader()
            let walletHandler = WalletViewModel.openedWalletHandler ?? 0
            AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletUnitAttestation,searchType: .withoutQuery) { (success, searchHandler, error) in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [self] (fetched, response, error) in
                    let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                    let searchResponse = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                    Task {
                        
                        let pfComponents = self.presentationDefinition.components(separatedBy: "nonce=")
                        var nonceFromPresentationDef = ""
                        if pfComponents.count > 1 {
                            nonceFromPresentationDef = pfComponents[1]
                        }
                        
                        state = components.queryItems?.first(where: { $0.name == "state" })?.value ?? ""
                        nonce = components.queryItems?.first(where: { $0.name == "nonce" })?.value ?? nonceFromPresentationDef
                        let clientID = components.queryItems?.first(where: { $0.name == "client_id" })?.value ?? ""
                        let clientMetaData = components.queryItems?.first(where: { $0.name == "client_metadata" })?.value ?? ""
                        let clientIDScheme = components.queryItems?.first(where: { $0.name == "client_id_scheme"})?.value
                        let responseType = components.queryItems?.first(where: { $0.name == "response_type"})?.value
                        let responseMode = components.queryItems?.first(where: { $0.name == "response_mode"})?.value
                        let authSession = components.queryItems?.first(where: { $0.name == "auth_session"})?.value
                        let privateKey = EBSIWallet.shared.handlePrivateKey()
                        let presentationRequest = eudiWalletOidcIos.PresentationRequest(state: state, clientId: clientID, redirectUri: redirect_uri, responseUri: redirectURI, responseType: responseType, responseMode: responseMode, scope: "", nonce: nonce, requestUri: "", presentationDefinition: self.presentationDefinition, clientMetaData: clientMetaData, presentationDefinitionUri: "", clientMetaDataUri: "", clientIDScheme: clientIDScheme, transactionData: [], dcqlQuery: dcqlQueryData, request: "", authSession: authSession)
                        let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                        let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
                        let pop = await WalletUnitAttestationService().generateWUAProofOfPossession( keyHandler: keyHandler, aud: presentationRequest.clientId)
                        let DID = await EBSIWallet.shared.createDIDKeyIdentifierForV3(privateKey: privateKey) ?? ""
                        EBSIWallet.shared.vpTokenRedirectUri = redirect_uri
                        
                        UIApplicationUtils.showLoader()
                        result = await verificationHandler.processOrSendAuthorizationResponse(did: did, presentationRequest: presentationRequest, credentialsList: updatedCredentialListArray, wua: searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT ?? "", pop: pop)
                        self.processResult(result: result, mState: state, mNonce: nonce, mRedirectUri: redirectURI, credentialList: updatedCredentialListArray, clientID: presentationRequest.clientId)
                    }
                }
            }
        }
        //Fixme: linking with credentials we have selected when sending vp token is pending
        print(credentialsListArray)
    }
    
    @IBAction func acceptButtonTapped(sender: Any) {
        if mode == .EBSI {
            viewModel?.verifyEBSI_cred()
        } else if mode == .EBSIMultipleCerts {
            Task {
                if !EBSIWallet.shared.enoughCredentials {
                    DispatchQueue.main.async {
                        UIApplicationUtils.hideLoader ()
                        UIApplicationUtils.showErrorSnackbar(message: "connection_no_data_available".localized ())
                    }
                } else {
                    self.navigationController?.popViewController(animated:true)
                    await EBSIWallet.shared.credentialRequestAfterCertificateExchange()
                }
            }
        } else if mode == .EBSIProcessingVPExchange {
            if let dcqlQuery = dcqlQuery, (dcqlQuery.credentialSets?.isNotEmpty ?? false) {
                if (viewModel?.sessionIndex ?? 0) < (viewModel?.sessionList.count ?? 0) - 1 {
                    viewModel?.sessionIndex = (viewModel?.sessionIndex ?? 0) + 1
                    viewModel?.EBSI_credentialsForSession = viewModel?.buildEbsiCredentialForSession(sessionItems: viewModel?.sessionList ?? [], targetIndex: viewModel?.sessionIndex ?? 0, dcqlQuery: dcqlQuery, inputMatrix: viewModel?.EBSI_credentials)
                    credentialSetBackButton.isHidden = false
                    additionalDataText.isHidden = false
                    additionalDataText.text = "verification_additional_data_requested_confirm_to_proceed".localizedForSDK()
                    expandedSections = viewModel?.EBSI_credentialsForSession?.count == 1 ? [0] : []
                    updateAcceptButtonState()
                    if viewModel?.sessionIndex == (viewModel?.sessionList.count ?? 0) - 1  {
                        additionalDataText.isHidden = true
                    }
                    tableView?.reloadData()
                } else {
                    performVPExchange()
                }
            } else {
                var state = String()
                var nonce = String()
                var redirectURI = String()
                var credentialsListArray: [String] = []
                sharedCredentials = selectedCredentialIndexes.sorted { $0.key < $1.key }.map { $0.value }
                //let dummy = getSelectedCredentials()
                let dcqlQueryData = EBSIWallet.shared.dcqlQuery
                if let url = URL.init(string: redirectUri),
                   let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let uri = components.queryItems?.first(where: { $0.name == "redirect_uri" })?.value {
                    redirectURI = uri
                    
                    let pfComponents = self.presentationDefinition.components(separatedBy: "nonce=")
                    var nonceFromPresentationDef = ""
                    if pfComponents.count > 1 {
                        nonceFromPresentationDef = pfComponents[1]
                    }
                    
                    state = components.queryItems?.first(where: { $0.name == "state" })?.value ?? ""
                    nonce = components.queryItems?.first(where: { $0.name == "nonce" })?.value ?? nonceFromPresentationDef
                } else {
                    // Convert JSON string to data
                    guard let jsonData = redirectUri.data(using: .utf8) else {
                        return
                    }
                    
                    guard let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                        return
                    }
                    
                    redirectURI = jsonDict["response_uri"] as? String ?? ""
                    nonce = jsonDict["nonce"] as? String ?? ""
                    state = jsonDict["state"] as? String ?? ""
                }
                Task { [self] in
                    debugPrint("### CredentialsJWT dict count:\(credentialsDict.count)")
                    // Step: 8.3: Send VP token
                    //                    let dict = self.credentialsDict[viewModel?.selectedCardIndex ?? 0]
                    
                    
                    if let dcqlData = dcqlQueryData {
                        if dcqlData.credentials.count > 1 {
                            
                            for (index,item) in sharedCredentials.enumerated() {
                                let credentialItemDcql =  dcqlData.credentials[index]
                                var credentialFormat: String = ""
                                if let format = presentationDefinitionModel?.format {
                                    for (key, _) in format {
                                        credentialFormat = key
                                    }
                                } else if credentialItemDcql.format.isNotEmpty {
                                    credentialFormat = credentialItemDcql.format
                                }
                                if item.contains("~") {
                                    let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                                    let sdjwtR = eudiWalletOidcIos.SDJWTService.shared.createSDJWTR(credential: item, query: credentialItemDcql, format: credentialFormat, keyHandler: keyHandler)
                                    credentialsListArray.append(sdjwtR ?? "")
                                } else {
                                    credentialsListArray.append(item)
                                }
                            }
                            
                        } else {
                            
                            let credentialItemDcql =  dcqlData.credentials.first
                            var credentialFormat: String = ""
                            if let format = presentationDefinitionModel?.format {
                                for (key, _) in format {
                                    credentialFormat = key
                                }
                            } else {
                                credentialFormat = credentialItemDcql?.format ?? ""
                            }
                            let dict = self.credentialsDict[viewModel?.selectedCardIndex ?? 0]
                            if let credential = dict["noKey"] as? String, credential.contains("~") {
                                let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                                let sdjwtR = eudiWalletOidcIos.SDJWTService.shared.createSDJWTR(credential: credential, query: credentialItemDcql, format: credentialFormat, keyHandler: keyHandler)
                                credentialsListArray.append(sdjwtR ?? "")
                            } else {
                                credentialsListArray.append(dict["noKey"] as? String ?? "")
                            }
                        }
                    } else {
                        let jsonData = presentationDefinition.replacingOccurrences(of: "+", with: " ").data(using: .utf8)!
                        let presentationDefinitionModel = try? JSONDecoder().decode(eudiWalletOidcIos.PresentationDefinitionModel.self, from: jsonData)
                        var inputDescriptor: InputDescriptor? = nil
                        if presentationDefinitionModel?.inputDescriptors?.count ?? 0 > 1 {
                            
                            for (index,item) in sharedCredentials.enumerated() {
                                inputDescriptor = presentationDefinitionModel?.inputDescriptors?[index]
                                var credentialFormat: String = ""
                                if let format = presentationDefinitionModel?.format ?? inputDescriptor?.format {
                                    for (key, _) in format {
                                        credentialFormat = key
                                    }
                                }
                                if item.contains("~") {
                                    let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                                    let sdjwtR = eudiWalletOidcIos.SDJWTService.shared.createSDJWTR(credential: item, query: inputDescriptor, format: credentialFormat, keyHandler: keyHandler)
                                    credentialsListArray.append(sdjwtR ?? "")
                                } else {
                                    credentialsListArray.append(item)
                                }
                            }
                        } else {
                            inputDescriptor = presentationDefinitionModel?.inputDescriptors?.first
                            var credentialFormat: String = ""
                            if let format = presentationDefinitionModel?.format ?? inputDescriptor?.format {
                                for (key, _) in format {
                                    credentialFormat = key
                                }
                            }
                            let dict = self.credentialsDict[viewModel?.selectedCardIndex ?? 0]
                            if let credential = dict["noKey"] as? String, credential.contains("~") {
                                let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                                let sdjwtR = eudiWalletOidcIos.SDJWTService.shared.createSDJWTR(credential: credential, query: inputDescriptor, format: credentialFormat, keyHandler: keyHandler)
                                credentialsListArray.append(sdjwtR ?? "")
                            } else {
                                credentialsListArray.append(dict["noKey"] as? String ?? "")
                            }
                        }
                    }
                    
                    var result : WrappedVerificationResponse? = nil
                    let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                    let verificationHandler = eudiWalletOidcIos.VerificationService(keyhandler: keyHandler)
                    
                    if let url = URL.init(string: self.redirectUri),
                       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let redirect_uri = components.queryItems?.first(where: { $0.name == "redirect_uri" })?.value {
                        UIApplicationUtils.showLoader()
                        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
                        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletUnitAttestation,searchType: .withoutQuery) { (success, searchHandler, error) in
                            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [self] (fetched, response, error) in
                                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                                let searchResponse = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                                Task {
                                    
                                    let pfComponents = self.presentationDefinition.components(separatedBy: "nonce=")
                                    var nonceFromPresentationDef = ""
                                    if pfComponents.count > 1 {
                                        nonceFromPresentationDef = pfComponents[1]
                                    }
                                    
                                    state = components.queryItems?.first(where: { $0.name == "state" })?.value ?? ""
                                    nonce = components.queryItems?.first(where: { $0.name == "nonce" })?.value ?? nonceFromPresentationDef
                                    let clientID = components.queryItems?.first(where: { $0.name == "client_id" })?.value ?? ""
                                    let clientMetaData = components.queryItems?.first(where: { $0.name == "client_metadata" })?.value ?? ""
                                    let clientIDScheme = components.queryItems?.first(where: { $0.name == "client_id_scheme"})?.value
                                    let responseType = components.queryItems?.first(where: { $0.name == "response_type"})?.value
                                    let responseMode = components.queryItems?.first(where: { $0.name == "response_mode"})?.value
                                    let authSession = components.queryItems?.first(where: { $0.name == "auth_session"})?.value
                                    let privateKey = EBSIWallet.shared.handlePrivateKey()
                                    let presentationRequest = eudiWalletOidcIos.PresentationRequest(state: state, clientId: clientID, redirectUri: redirect_uri, responseUri: redirectURI, responseType: responseType, responseMode: responseMode, scope: "", nonce: nonce, requestUri: "", presentationDefinition: self.presentationDefinition, clientMetaData: clientMetaData, presentationDefinitionUri: "", clientMetaDataUri: "", clientIDScheme: clientIDScheme, transactionData: [], dcqlQuery: dcqlQueryData, request: "", authSession: authSession)
                                    let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                                    let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
                                    let pop = await WalletUnitAttestationService().generateWUAProofOfPossession( keyHandler: keyHandler, aud: presentationRequest.clientId)
                                    let DID = await EBSIWallet.shared.createDIDKeyIdentifierForV3(privateKey: privateKey) ?? ""
                                    EBSIWallet.shared.vpTokenRedirectUri = redirect_uri
                                    
                                    UIApplicationUtils.showLoader()
                                    result = await verificationHandler.processOrSendAuthorizationResponse(did: did, presentationRequest: presentationRequest, credentialsList: credentialsListArray, wua: searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT ?? "", pop: pop)
                                    self.processResult(result: result, mState: state, mNonce: nonce, mRedirectUri: redirectURI, credentialList: credentialsListArray, clientID: presentationRequest.clientId)
                                }
                            }
                        }
                        //////
                        
                        /////
                    }
                    
                }
            }
        } else {
            viewModel?.checkConnection()
        }
    }
    
    func filterSelectedCredentialsForCredentialSet(
        value: [[SearchItems_CustomWalletRecordCertModel]]?,
        sessionList: [SessionItem],
        dcql: DCQLQuery?
    ) -> [String] {
        
        var selectedCredentials: [String] = []
        
        guard let credentials = dcql?.credentials else {
            print(" No credentials found in dcqlQuery")
            return selectedCredentials
        }
        
        for (index, credentialDescriptor) in credentials.enumerated() {
            let credentialId = credentialDescriptor.id
            var selectedCredential: String? = nil
            
            // Find all sessions that contain this credentialId
            let matchingSessions = sessionList.filter { $0.credentialIdList.contains(credentialId) }
            
            for session in matchingSessions {
                print(" [\(index)] Found session: \(session)")
                
                let credentialsForDescriptor = value?.at(index)
                
                // Find ALL positions where this credentialId appears in the session
                let allSessionIndices = session.credentialIdList.enumerated()
                    .filter { $0.element == credentialId }
                    .map { $0.offset }
                
                // Check if any of these specific positions are checked
                for sessionIndex in allSessionIndices {
                    if session.checkedItem.contains(sessionIndex) {
                        print(" [\(index)] Session index \(sessionIndex) is in checkedItem")
                        
                        // Get the selected index for this specific position in the session
                        let selectedIndex = session.selectedCredentialIndex.at(sessionIndex)
                        
                        if let selectedIndex = selectedIndex {
                            selectedCredential = credentialsForDescriptor?.at(selectedIndex)?.value?.EBSI_v2?.credentialJWT
                            print(" [\(index)] Found selected credential for session index \(sessionIndex)")
                            break // Found a checked occurrence, no need to check other indices
                        } else {
                            print(" [\(index)] No matching selectedIndex for session index \(sessionIndex)")
                        }
                    }
                }
                
                if selectedCredential != nil {
                    break // Found in this session, no need to check other sessions
                }
            }
            
            if selectedCredential == nil {
                print(" [\(index)] Adding NULL to result - credentialId \(credentialId) not found in any checked session")
            }
            selectedCredentials.append(selectedCredential ?? "")
        }
        return selectedCredentials
    }

    
    func processResult(result: WrappedVerificationResponse?,
                       mState:String,
                       mNonce:String,
                       mRedirectUri:String, credentialList: [String], clientID: String?) {
        UIApplicationUtils.hideLoader()
        var state = mState
        var nonce = mNonce
        var redirectURI = mRedirectUri
        var redirectUriValue: String? = nil
        var clientIDScheme: String? = nil
        if result?.error == nil {
            UIApplicationUtils.hideLoader()
                if EBSIWallet.shared.isDynamicCredentialRequest == true {
                    Task{
                        if let data = result?.data, let toURL = data.toUrl as? URL, let code = toURL.queryParameters?["code"] {
                            let walletHandler = WalletViewModel.openedWalletHandler ?? 0
                            AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletUnitAttestation,searchType: .withoutQuery) { (success, searchHandler, error) in
                                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [self] (fetched, response, error) in
                                    let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                                    let searchResponse = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                                    Task {
                                        let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                                        let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
                                        let pop = await WalletUnitAttestationService().generateWUAProofOfPossession(keyHandler: keyHandler, aud: clientID)
                                        let clientIDAssertion = await WalletUnitAttestationService().createClientAssertion(aud: clientID ?? "", keyHandler: keyHandler)
                                        let privateKey = EBSIWallet.shared.handlePrivateKey()
                                        let accessTokenResponse = await EBSIWallet.shared.issueHandler?.processTokenRequest(did: did, tokenEndPoint: EBSIWallet.shared.tokenEndpointForConformanceFlow ?? "", code: code, codeVerifier: EBSIWallet.shared.codeVerifierCreated, isPreAuthorisedCodeFlow: false, userPin: "", version: "",clientIdAssertion: clientIDAssertion, wua: searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT ?? "", pop: pop, redirectURI: EBSIWallet.shared.webRedirectURI)
                                        print("tttttfcdgfacdfaecdfe: \(accessTokenResponse)")
                                        if accessTokenResponse?.error != nil{
                                            DispatchQueue.main.async {
                                                UIApplicationUtils.hideLoader()
                                                UIApplicationUtils.showErrorSnackbar(message: accessTokenResponse?.error?.message ?? "connection_unexpected_error_please_try_again".localizedForSDK())
                                            }
                                        } else {
                                            let authServerUrl = AuthorizationServerUrlUtil().getAuthorizationServerUrl(issuerConfig: EBSIWallet.shared.openIdIssuerResponseData, credentialOffer: EBSIWallet.shared.credentialOffer)
                                            let authServer = EBSIWallet.shared.getAuthorizationServerFromCredentialOffer(credential: EBSIWallet.shared.credentialOffer) ?? authServerUrl
                                            let authConfig = try await DiscoveryService.shared.getAuthConfig(authorisationServerWellKnownURI: (authServer?.isEmpty == true ? EBSIWallet.shared.credentialOffer?.credentialIssuer : authServer) ?? "")
                                            let nonce = await NonceServiceUtil().fetchNonce(accessTokenResponse: accessTokenResponse, nonceEndPoint: EBSIWallet.shared.openIdIssuerResponseData?.nonceEndPoint)
                                            await EBSIWallet.shared.requestCredentialUsingEbsiV3(didKeyIdentifier: EBSIWallet.shared.globalDID, c_nonce: nonce ?? "", accessToken: accessTokenResponse?.accessToken ?? "", privateKey: privateKey, jwkUri: authConfig?.jwksURI, refreshToken: accessTokenResponse?.refreshToken ?? "", authDetails: accessTokenResponse?.authorizationDetails, tokenResponse: accessTokenResponse)
                                            self.goBack()
                                            EBSIWallet.shared.isDynamicCredentialRequest = false
                                            UIApplicationUtils.hideLoader()
                                        }
                                    }
                                }
                            }
                        } else {
                            print("Unable to retrieve code from url")
                        }
                        
                    }
                }else{
                    if let url = URL.init(string: self.redirectUri),
                       let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                       let redirect_uri = components.queryItems?.first(where: { $0.name == "redirect_uri" })?.value {
                        redirectUriValue = redirect_uri
                        let pfComponents = self.presentationDefinition.components(separatedBy: "nonce=")
                        var nonceFromPresentationDef = ""
                        if pfComponents.count > 1 {
                            nonceFromPresentationDef = pfComponents[1]
                        }
                        state = components.queryItems?.first(where: { $0.name == "state" })?.value ?? ""
                        nonce = components.queryItems?.first(where: { $0.name == "nonce" })?.value ?? nonceFromPresentationDef
                        let clientMetaData = components.queryItems?.first(where: { $0.name == "client_metadata" })?.value ?? ""
                        clientIDScheme = components.queryItems?.first(where: { $0.name == "client_id_scheme"})?.value
                        let privateKey = EBSIWallet.shared.handlePrivateKey()
                        EBSIWallet.shared.clearCacheAfterIssuanceAndExchange()
                    }
                }
            var presentationDefinition :PresentationDefinitionModel? = nil
            do {
                presentationDefinition = try VerificationService.processPresentationDefinition(self.presentationDefinition)
            } catch {
                presentationDefinition = nil
            }
            //viewModel?.connectionModel?.value?.orgDetails?.isValidOrganization = isValidOrg
            Task {
                //Fixme: i removed added date form below func but its there in DW
                let (_, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),recipientKey: "",label: viewModel?.connectionModel?.value?.orgDetails?.name ?? "", type: UpdateWalletType.trusted, id: viewModel?.connectionModel?.value?.requestID ?? "", theirDid: "", myDid: viewModel?.connectionModel?.value?.myDid ?? "",imageURL: viewModel?.connectionModel?.value?.orgDetails?.coverImageURL ?? "" ,invitiationKey: "", isIgrantAgent: false, routingKey: nil, orgDetails: viewModel?.connectionModel?.value?.orgDetails, orgID: viewModel?.connectionModel?.value?.orgDetails?.orgId)
            }
            guard let dummy = viewModel?.EBSI_credentials else {return}
            let matchingSharedCredentials: [SearchItems_CustomWalletRecordCertModel] = dummy
                .flatMap { $0 }
                .filter { item in
                    if let jwt = item.value?.EBSI_v2?.credentialJWT {
                        return sharedCredentials.contains(jwt)
                    }
                    return false
                }
            var sharedData = Search_CustomWalletRecordCertModel()
            if matchingSharedCredentials.count == 0 {
                sharedData.records = viewModel?.EBSI_credentials?.first
                sharedData.totalCount = viewModel?.EBSI_credentials?.first?.count
            } else {
                sharedData.records = matchingSharedCredentials
                sharedData.totalCount = matchingSharedCredentials.count
            }
            var queryItem: Any?
            if let dcqlQueryData = dcqlQuery {
                queryItem = dcqlQueryData
            } else if let presentationDefinitionData = presentationDefinition {
                queryItem = presentationDefinitionData
            }
            let updatedCredentialList: [String] = credentialList.filter { !$0.isEmpty }
            self.viewModel?.addHistoryToEBSI(jwtList: credentialList, presentationDefinition: presentationDefinition, clientMetaData: self.clientMetaData, isValidOrganization: isValidOrg, credentials: sharedData, queryItem: queryItem)
            NotificationCenter.default.post(name: Constants.reloadOrgList, object: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if let redirectURIValue = result?.data?.split(separator: "#").first.map { String($0) }, !redirectURIValue.contains("https://www.example.com") {
                        self.handleRedirectUri(redirectURIValue)
                    }
                }
            } else {
                let errorMsg = result?.error?.message?.count ?? 0 > 200 ? "Unexpected error. Please try again.".localizedForSDK() : result?.error?.message
                UIApplicationUtils.showErrorSnackbar(message: errorMsg ?? "Unexpected error. Please try again.".localizedForSDK())
                UIApplicationUtils.hideLoader()
            }

    }
    
    private func handleRedirectUri(_ redirectUri: String) {
        guard let url = URL(string: redirectUri) else {
            return
        }
        UIApplication.shared.open(url, options: [:])
    }
    
    @IBAction func rejectButtonTapped(sender: Any) {
        
        let alert = UIAlertController(title: "Data Wallet", message: "data_do_you_want_to_cancel_the_exchange_request".localizedForSDK(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "general_yes".localizedForSDK(), style: .default, handler: { [self] action in
            viewModel?.rejectCertificate()
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "general_no".localizedForSDK(), style: .default, handler: { action in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func getPurposeFromPresentationDefinition() -> String {
        var purpose: String = ""
        if let text = presentationDefinitionModel?.purpose, !text.isEmpty {
            purpose = text
        } else if let text = presentationDefinitionModel?.inputDescriptors?.first?.purpose,  !text.isEmpty {
            purpose = text
        }
        return purpose
    }

}

extension ExchangeDataPreviewBottomSheetVC: ExchangeDataPreviewViewModelDelegate {
    
    func goBack() {
        if let callback = completion {
            callback(true)
            return
        }
        DispatchQueue.main.async {
            UIApplicationUtils.hideLoader()
            NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
            if (self.viewModel?.isFromQR ?? false) {
                self.dismiss(animated: true)
                //self.navigationController?.popToRootViewController(animated: true)
            } else {
                //self.navigationController?.popViewController(animated: true)
                self.dismiss(animated: true)
                NotificationCenter.default.post(name: Constants.didReceiveDataExchangeRequest, object: nil)
            }
        }
    }
    
    func showError(message: String) {
        
    }
    
    func refresh() {
        DispatchQueue.main.async {
            self.pageControl.numberOfPages = self.mode == .other ? self.viewModel?.allItemsIncludedGroups.count ?? 0 : self.viewModel?.EBSI_credentials?.first?.count ?? 0
            self.collectionView.reloadData()
            self.tableView.reloadData()
            self.updateDataAgreementButton()
            if (self.pageControl.numberOfPages < 2) || self.dcqlQuery?.credentialSets != nil{
                self.multipleCardInfoView.isHidden = true
                self.pageControlView.isHidden = true
                self.multipleCardButton.isHidden = true
            } else {
                self.multipleCardInfoView.isHidden = false
                self.pageControlView.isHidden = false
                self.multipleCardButton.isHidden = true
            }
        }
    }
    
    func showAllViews() {
        DispatchQueue.main.async {
            self.view.subviews.forEach { view in
                view.isHidden = false
            }
        }
    }
    
    func calcualteTheMaxHeightOfColectionView(){
//        for rows in (0..<collectionView.numberOfItems(inSection: 0)){
//            if let cell =
//                collectionView.cellForItem(at: IndexPath.init(row: rows, section: 0)) as? CertificateCardCollectionViewCell{
//                var totalCollectionHeightConstraint: CGFloat = 0
//                for section in (0..<cell.tableView.numberOfSections) {
////                    totalCollectionHeightConstraint += 40
//                    for row in (0..<cell.tableView.numberOfRows(inSection: section)) {
//                        if let sub_cell = cell.tableView.cellForRow(at: IndexPath.init(row: row, section: section)) as? CovidValuesRowTableViewCell{
//                            sub_cell.arrangeStackForDataAgreement()
//                            sub_cell.layoutIfNeeded()
//                            totalCollectionHeightConstraint +=  sub_cell.frame.height + 20
//                    }
//                    }
//                }
//                if maxHeight < totalCollectionHeightConstraint {
//                    maxHeight = totalCollectionHeightConstraint
//                }
//            } else {
//                self.collectionHeightConstraint.constant =  self.collectionView.contentSize.height + 15
//            }
//        }
//        maxHeight = self.collectionView.contentSize.height
        
        if maxHeight > self.collectionHeightConstraint.constant {
            self.collectionHeightConstraint.constant = maxHeight
            self.collectionView.frame = CGRect.init(x: 0, y: 5, width: self.collectionView.frame.width, height: maxHeight)
            self.dynamicDataStack.frame = CGRect.init(x: 0, y: 0, width: baseTableView.frame.width, height: (self.collectionHeightConstraint.constant) + 60)
            self.baseView.frame = self.dynamicDataStack.frame
            self.baseTableView.frame = self.baseView.frame
            self.collectionView.reloadInMain()
            debugPrint("baseView -- \(self.baseView.frame.height)  dynamicDataStack -- \(self.dynamicDataStack.frame.height) collection -- \(collectionHeightConstraint.constant) pageControl -- \(pageControl.frame.height)")
        }
    }
    
    func updateCollectionViewHeight(cell: ExchangeBottomSheetCollectionViewCell){
        let cellHeight = cell.tableView.contentSize.height - 18
        if maxHeight < cellHeight {
            maxHeight = cellHeight
            DispatchQueue.main.async {
                self.calcualteTheMaxHeightOfColectionView()
            }
        }
    }
}

extension ExchangeDataPreviewBottomSheetVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if mode == .EBSI || mode == .EBSIMultipleCerts || mode == .EBSIProcessingVPExchange {
            let jsonData = presentationDefinition.replacingOccurrences(of: "+", with: " ").data(using: .utf8)!
            let presentationDefinitionModel = try? JSONDecoder().decode(eudiWalletOidcIos.PresentationDefinitionModel.self, from: jsonData)
            
            if isMultipleInputDescriptors() ?? false {
                return 1
            }
            return viewModel?.EBSI_credentials?.first?.count ?? 0
        } else {
            return viewModel?.allItemsIncludedGroups.count ?? 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =
        collectionView.dequeueReusableCell(withReuseIdentifier:
                                            "ExchangeBottomSheetCollectionViewCell", for: indexPath) as! ExchangeBottomSheetCollectionViewCell
        if let model = viewModel {
            cell.delegate = self
            
            cell.updateCellWith(viewModel: model, index: indexPath.row, showValues: showValues, presentationDefinition: presentationDefinition)
        }
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        viewModel?.selectedCardIndex = pageControl.currentPage
        if !(isMultipleInputDescriptors() ?? false) {
            certName.text = viewModel?.EBSI_credentials?.first?[pageControl.currentPage].value?.searchableText
        }
    }

}

extension ExchangeDataPreviewBottomSheetVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if let data = viewModel?.EBSI_credentialsForSession {
            let count = data.count ?? 0
            return count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return expandedSections.contains(section) ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: ExchangeDataPreviewMultipleInputDescriptorTVC.self, for: indexPath)
        guard let credentials = viewModel?.EBSI_credentialsForSession else { return UITableViewCell()}
        
        cell.updateBlurState(showValues: showValues)
        let sessionItem: SessionItem? = {
            if let sessionList = viewModel?.sessionList,
               let sessionIndex = viewModel?.sessionIndex,
               !sessionList.isEmpty,
               sessionIndex < sessionList.count {
                return sessionList[sessionIndex]
            }
            return nil
        }()
        //cell.setCheckboxSelected(isCheckBoxSelected)
        var isMultipleOptions: Bool = false
        if let session = viewModel?.sessionList, !session.isEmpty {
            if (viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].type == "MandatoryWithOROption" || viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].type == "OptionalWithOrOption") &&
                (viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].options.count ?? 0 > 1)  {
                isMultipleOptions = true
            }
        }
        cell.configure(with: credentials[indexPath.section], index: indexPath.section, showValues: showValues, sessionItem: sessionItem, isMultipleOptions: isMultipleOptions)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let items = viewModel?.EBSI_credentialsForSession?[section] else { return nil}
        
        if selectedCredentialIndexes[section] == nil,
           let firstCredential = items.first?.value?.EBSI_v2?.credentialJWT {
            selectedCredentialIndexes[section] = firstCredential
        }
            var  title = ""
        var selectedIndex: Int = 0
        if let session = viewModel?.sessionList, !session.isEmpty {
            selectedIndex = session[viewModel?.sessionIndex ?? 0].selectedCredentialIndex[section] ?? 0
        } else {
            selectedIndex = 0
        }
        if let name = presentationDefinitionModel?.inputDescriptors?[section].name, !name.isEmpty {
            title = name
        } else if
            let name = items[safe: selectedIndex]?.value?.searchableText, !name.isEmpty {
            title = name
        } else  if let name = presentationDefinitionModel?.inputDescriptors?[section].id, !name.isEmpty {
            title = name
        }
            let isExpanded = expandedSections.contains(section)
        
        var initialCheckboxState = false
        if let sessionIndex = self.viewModel?.sessionIndex,
           sessionIndex < self.viewModel?.sessionList.count ?? 0,
           section < self.viewModel?.sessionList[sessionIndex].credentialIdList.count ?? 0 {
            
            let session = self.viewModel!.sessionList[sessionIndex]
            initialCheckboxState = session.checkedItem.contains(section)
        }
        var indexOfCheckedItem: Int?
        let leadingConstant = isExpanded ? 0 : 10
        var isMandatorySingle: Bool = false
        if let session = viewModel?.sessionList, !session.isEmpty {
            isMandatorySingle =  self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].type == "MandatoryWithSingleOption"
//            let optionData = dcqlQuery?.credentialSets?[self.viewModel?.sessionIndex ?? 0].options
//            print("")
//            if isMandatorySingle {
//                for id in optionData?.first ?? [] {
//                    if !(self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.contains(id) ?? false) {
//                        self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.append(id)
//                    }
//                }
//            }
        }
        var optionTitle = ""
        var isOptionsTitleVisible: Bool = false
        var isMultipleOptions: Bool = false
        if let session = viewModel?.sessionList, !session.isEmpty {
            if let options = viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].options {
                var currentIndex = 0
                //var showOptionLabel = false
                
                for (groupIndex,group) in options.enumerated() {
                    // If sectionIndex belongs to this group
                    if section >= currentIndex && section < currentIndex + group.count {
                        // Only show label for the first item in the group
                        isOptionsTitleVisible = (section == currentIndex && (session[viewModel?.sessionIndex ?? 0].options.count) > 1)
                        if isOptionsTitleVisible {
                            optionTitle = "OPTION \(groupIndex + 1)"
                        }
                        break
                    }
                    currentIndex += group.count
                }
            }
            
            if (viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].type == "MandatoryWithOROption" || viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].type == "OptionalWithOrOption") &&
                (viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].options.count ?? 0 > 1) {
                isMultipleOptions = true
            }
        }
        //let isMultipleOptions = dcqlQuery?.credentialSets?[self.viewModel?.sessionIndex ?? 0].options.count ?? 0 > 1
        let showOptionLabel = isMultipleOptions && isOptionsTitleVisible
        let header = ExpandableHeaderView(title: title, section: section, isExpanded: isExpanded, leadingConstant: CGFloat(leadingConstant), isChecked: initialCheckboxState, isOptionSelected: initialCheckboxState, showCheckbox: dcqlQuery?.credentialSets != nil, isMandatory: isMandatorySingle, showOptionLabel: showOptionLabel, isMultipleOptions: isMultipleOptions) { [weak self] sectionIndex in
                guard let self = self else { return }
                if self.expandedSections.contains(sectionIndex) {
                    self.expandedSections.remove(sectionIndex)
                } else {
                    self.expandedSections.insert(sectionIndex)
                    
                }
            tableView.beginUpdates()
            tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
            tableView.endUpdates()

        } checkboxAction: { [weak self] sectionIndex, isChecked in
            guard let self = self else { return }
            if isChecked {
                
                self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.removeAll()
                
                let options = viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].options
                let credentialIDList =  self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].credentialIdList
                
                if let selectedCredentialID = self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].credentialIdList[section]{
                    
                    if let optionGroups = options {
                        var foundGroup: [String]?
                        var currentIndex = 0
                        
                        for group in optionGroups {
                            if currentIndex <= sectionIndex && sectionIndex < currentIndex + group.count {
                                foundGroup = group
                                break
                            }
                            currentIndex += group.count
                        }
                        
                        if let group = foundGroup {
                            for i in 0..<group.count {
                                let indexToAdd = currentIndex + i
                                self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.append(indexToAdd)
                            }
                        } else {
                            self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.append(sectionIndex)
                        }
                    }
                }
                self.updateAcceptButtonState()
                var checkSelected: Bool?
                if let credChecked = self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.first {
                    indexOfCheckedItem = credChecked
                }
                if let indexOfCheckedItem = indexOfCheckedItem {
                     checkSelected = sectionIndex == indexOfCheckedItem
                }
                
                if let previousHeader = self.headerViews[indexOfCheckedItem ?? 0] {
                    let isMandatorySingle =  self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].type == "MandatoryWithSingleOption"
                    previousHeader.setCheckboxState(checkSelected ?? false, isMandatorySingle: isMandatorySingle)
                  
                }
                
            } else {
                self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.removeAll()
                if let previousHeader = self.headerViews[sectionIndex] {
                    let isMandatorySingle =  self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].type == "MandatoryWithSingleOption"
                    previousHeader.setCheckboxState(false, isMandatorySingle: isMandatorySingle)
                }
                self.updateAcceptButtonState()
               
            }
            
            let session = self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0]
            let isMandatorySingle = session?.type == "MandatoryWithSingleOption"

            if let session = session {
                let checkedIndices = session.checkedItem // already indices

                for (idx, header) in self.headerViews {
                    let sectionChecked = checkedIndices.contains(idx)
                    header.setCheckboxState(sectionChecked, isMandatorySingle: isMandatorySingle)
                }
            }
            for section in 0..<tableView.numberOfSections {
                for row in 0..<tableView.numberOfRows(inSection: section) {
                    let indexPath = IndexPath(row: row, section: section)
                    if let cell = tableView.cellForRow(at: indexPath) as? ExchangeDataPreviewMultipleInputDescriptorTVC {
                        let credentials = self.viewModel?.EBSI_credentialsForSession?[indexPath.section] ?? []
                        let sessionItem = self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0]

                        cell.configure(with: credentials,
                                       index: indexPath.section,
                                       showValues: self.showValues,
                                       sessionItem: sessionItem, isMultipleOptions: isMultipleOptions)
                    }
                }
            }
        } optionCheckboxAction: { [weak self] sectionIndex, isChecked in
            guard let self = self else { return }
            if isChecked {
                
                self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.removeAll()
                
                let options = viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].options
                
                    if let optionGroups = options {
                        var foundGroup: [String]?
                        var currentIndex = 0
                        
                        for group in optionGroups {
                            if currentIndex <= sectionIndex && sectionIndex < currentIndex + group.count {
                                foundGroup = group
                                break
                            }
                            currentIndex += group.count
                        }
                        
                        if let group = foundGroup {
                            for i in 0..<group.count {
                                let indexToAdd = currentIndex + i
                                self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.append(indexToAdd)
                            }
                        } else {
                            self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.append(sectionIndex)
                        }
                    }
                self.updateAcceptButtonState()
                var checkSelected: Bool?
                if let credChecked = self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.first {
                    indexOfCheckedItem = credChecked
                }
                if let indexOfCheckedItem = indexOfCheckedItem {
                     checkSelected = sectionIndex == indexOfCheckedItem
                }
                
                if let previousHeader = self.headerViews[indexOfCheckedItem ?? 0] {
                    let isMandatorySingle =  self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].type == "MandatoryWithSingleOption"
                    previousHeader.setCheckboxState(checkSelected ?? false, isMandatorySingle: isMandatorySingle)
                    previousHeader.setOptionCheckboxState(checkSelected ?? false)
                  
                }
                
            } else {
//                self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].checkedItem.removeAll()
//                if let previousHeader = self.headerViews[sectionIndex] {
//                    let isMandatorySingle =  self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].type == "MandatoryWithSingleOption"
//                   previousHeader.setCheckboxState(false, isMandatorySingle: isMandatorySingle)
//                   previousHeader.setOptionCheckboxState(false)
//                }
//                self.updateAcceptButtonState()
            }
            
            let session = self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0]
            let isMandatorySingle = session?.type == "MandatoryWithSingleOption"

            if let session = session {
                let checkedIndices = session.checkedItem // already indices

                for (idx, header) in self.headerViews {
                    let sectionChecked = checkedIndices.contains(idx)
                    header.setCheckboxState(sectionChecked, isMandatorySingle: isMandatorySingle)
                    header.setOptionCheckboxState(sectionChecked)
                }
            }
            for section in 0..<tableView.numberOfSections {
                for row in 0..<tableView.numberOfRows(inSection: section) {
                    let indexPath = IndexPath(row: row, section: section)
                    if let cell = tableView.cellForRow(at: indexPath) as? ExchangeDataPreviewMultipleInputDescriptorTVC {
                        let credentials = self.viewModel?.EBSI_credentialsForSession?[indexPath.section] ?? []
                        let sessionItem = self.viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0]

                        cell.configure(with: credentials,
                                       index: indexPath.section,
                                       showValues: self.showValues,
                                       sessionItem: sessionItem, isMultipleOptions: isMultipleOptions)
                    }
                }
            }
        }
        if showOptionLabel {
            header.setOptionText(optionTitle)
        }
        headerViews[section] = header

        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        var isOptionsTitleVisible: Bool = false
        var isMultipleOptions: Bool = false
        if let session = viewModel?.sessionList, !session.isEmpty {
            if let options = viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].options {
                var currentIndex = 0
                
                for group in options {
                    if section >= currentIndex && section < currentIndex + group.count {
                        // Only show label for the first item in the group
                        isOptionsTitleVisible = section == currentIndex
                        break
                    }
                    currentIndex += group.count
                }
            }
            if (viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].type == "MandatoryWithOROption" || viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].type == "OptionalWithOrOption") &&
                (viewModel?.sessionList[self.viewModel?.sessionIndex ?? 0].options.count ?? 0 > 1) {
                isMultipleOptions = true
            }
        }
        let showOptionLabel = isMultipleOptions && isOptionsTitleVisible
        return showOptionLabel ? 70 : 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == tableView.numberOfSections - 1 {
            return 60
        } else {
            return 12
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == tableView.numberOfSections - 1 {
            return createDataAgreementButtonView()
        } else {
            let spacerView = UIView()
            spacerView.backgroundColor = .clear
            return spacerView
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let customCell = cell as? ExchangeDataPreviewMultipleInputDescriptorTVC {
            customCell.updateBlurState(showValues: showValues)
        }
    }
    
}

extension ExchangeDataPreviewBottomSheetVC: ExchangeDataPreviewMultipleInputDescriptorTVCDelegate, ExchangeBottomSheetCollectionViewCellProtocol {
    
    
    func didSelectItem(id: String?) {
        showCardDetails(id: id)
    }
    
    
    func presentVC(vc: UIViewController) {
        present(vc: vc)
    }
    
    
    func updateHeaderTitle(_ title: String, forSection section: Int) {
        headerTitles[section] = title
        if let name = presentationDefinitionModel?.inputDescriptors?[section].name, name.isEmpty {
            if let header = headerViews[section] {
                header.setupTitle(title: title)
            }
        }
        else {
            if let header = headerViews[section] {
                header.setupTitle(title: title)
            }
        }
    }
    
    
    func didSelectCredential(for credential: String, forSection section: Int) {
        selectedCredentialIndexes[section] = credential
        
        //tableView.reloadSections(IndexSet(integer: section), with: .none)
    }
    
    func didScrolledSection(credentialIndex: Int, pagerIndex: Int) {
        guard (viewModel?.sessionIndex ?? 0) < (viewModel?.sessionList.count ?? 0) else { return }
        
        // get the sessionItem
        var item = viewModel?.sessionList[viewModel?.sessionIndex ?? 0]
        
        // ensure index is valid
        guard credentialIndex < item?.selectedCredentialIndex.count ?? 0 else { return }
        
        // update the selectedCredentialIndex
        item?.selectedCredentialIndex[credentialIndex] = pagerIndex
        
        // put back updated item into the array
        if let item = item {
            viewModel?.sessionList[viewModel?.sessionIndex ?? 0] = item
        }
    }
    
    func refreshHeight() {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func showImageDetails(image: UIImage?) {
        if let vc = ShowQRCodeViewController().initialize() as? ShowQRCodeViewController {
            vc.QRCodeImage = image
            self.present(vc: vc, transStyle: .crossDissolve, presentationStyle: .overCurrentContext)
        }
    }
    
}
