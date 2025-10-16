//
//  DataAgreementViewController.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 30/09/21.
//

import UIKit

enum DataAgreementItems: String,CaseIterable {
    case lawfulBasis = "Lawful basis of processing"
    case policyURL = "Policy URL"
    case jurisdiction = "Jurisdiction"
    case thirdPartyDisclosure = "Third party disclosure"
    case industryScope = "Industry scope"
    case geographicRestriction = "Geographic restriction"
    case shared3Pp = "Is shared to 3pps?"
    case dataRetentionPeriod = "Retention period"
    case purpose = "Purpose"
    case purposeDescription = "Purpose Description"
    case storageLocation = "Storage Location"
    case DPIADate = "DPIA Date"
    case DPIASummary = "DPIA Summary"
    case thirdParty = "Third party data sharing"
}

final class DataAgreementViewController: AriesBaseViewController {
    
    var pageIndex: Int!
    weak var delegate: PageControllerNavHelp?
    var navHandler: NavigationHandler!

    let tableView: UITableView
    let viewModel: DataAgreementViewModel
    init(vm: DataAgreementViewModel) {
        tableView = UITableView.getTableview()
        viewModel = vm
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        view.addSubview(tableView)
        tableView.addAnchor(top: self.view.safeAreaLayoutGuide.topAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: VerifiedDataAgreementTableViewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    let longPressGesture = UILongPressGestureRecognizer.init()
    
    let dataAgreementItems_V1: [DataAgreementItems] = [.policyURL, .jurisdiction, .industryScope, .geographicRestriction]
    let dataAgreementItems_V2: [DataAgreementItems] = [ .policyURL, .jurisdiction, .thirdParty, .industryScope, .geographicRestriction, .dataRetentionPeriod]
    
    var generalSectionData: [DataAgreementItems] = []
    var purposeSectionData: [DataAgreementItems] = []
    var DpiaSectionData: [DataAgreementItems] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.delegate = self
        if viewModel.dataAgreement?.message != nil {
            generalSectionData = dataAgreementItems_V2
        } else {
            generalSectionData = dataAgreementItems_V2
        }
        Task {
            await viewModel.verifyCredential()
        }
        self.title = "Data Agreement Policy".localizedForSDK()
        configureUI()
        setNav()
    }
    
    private func setNav() {
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(title: "")
    }
    
    private func configureUI() {
        if (viewModel.dataAgreement?.message?.body?.dataPolicy?.storageLocation != nil) {
            generalSectionData.append(.storageLocation)
        }
        
        //purpose section
        if (viewModel.dataAgreement?.message?.body?.purpose != nil){
            purposeSectionData.append(.purpose)
        }
        if (viewModel.dataAgreement?.message?.body?.purposeDescription != nil){
            purposeSectionData.append(.purposeDescription)
        }
        if (viewModel.dataAgreement?.message?.body?.lawfulBasis != nil){
            purposeSectionData.append(.lawfulBasis)
        }
        
        //DPIA section
        if (viewModel.dataAgreement?.message?.body?.dpia?.dpiaDate != nil){
            DpiaSectionData.append(.DPIADate)
        }
        if (viewModel.dataAgreement?.message?.body?.dpia?.dpiaSummaryURL != nil){
            DpiaSectionData.append(.DPIASummary)
        }
        tableView.reloadData()
    }
    
    @objc func openPrivacyURL() {
        if let webviewVC = UIStoryboard(name:"ama-ios-sdk", bundle: UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "WebViewVC") as? WebViewViewController {
            webviewVC.urlString = viewModel.dataAgreement?.message?.body?.dataPolicy?.policyURL ?? ""
            webviewVC.title = "Policy URL".localizedForSDK()
            if self.delegate != nil {
                self.delegate?.pushWith(vc: webviewVC)
            } else {
                self.navigationController?.pushViewController(webviewVC, animated: true)
            }
            
        }
    }
    
    @objc func openRinkeryURL(_ sender: BlurredLabel) {
        if let webviewVC = UIStoryboard(name:"ama-ios-sdk", bundle: UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "WebViewVC") as? WebViewViewController {
            let address = (viewModel.dataAgreement?.receipt?.blink ?? "").split(separator: ":").last ?? ""
            let prefix = (viewModel.dataAgreement?.receipt?.blink ?? "").replacingOccurrences(of: address, with: "")
            let blinkModel = MetaDataUtils.shared.getBlinkFromPrefix(prefix: prefix)
            let urlString = (blinkModel?.url ?? "") + "\(address)"
            webviewVC.urlString = urlString
            webviewVC.title = "Blink".localizedForSDK()
            if self.delegate != nil {
                self.delegate?.pushWith(vc: webviewVC)
            } else {
                self.navigationController?.pushViewController(webviewVC, animated: true)
            }
        }
    }
    
}

extension DataAgreementViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 8 : CGFloat.leastNonzeroMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3 + viewModel.getProofCount() + viewModel.getReceiptCount()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0, 1, 2:
            let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
            var sectionData: [DataAgreementItems] = []
            cell.blurView.gestureRecognizers?.removeAll()
            switch indexPath.section {
            case 0: sectionData = purposeSectionData
            case 1: sectionData = generalSectionData
            case 2: sectionData = DpiaSectionData
            default:
                sectionData = generalSectionData
            }
            
            cell.renderUI(index: indexPath.row, tot: sectionData.count)
            cell.blurView.blurStatus = true
            switch sectionData[indexPath.row] {
            case .policyURL:
                cell.mainLbl.text = DataAgreementItems.policyURL.rawValue.localizedForSDK()
                cell.tapGesture = UITapGestureRecognizer()
                cell.tapGesture.addTarget(self, action: #selector(openPrivacyURL))
                cell.blurView.addGestureRecognizer(cell.tapGesture)
                let attributedString = NSMutableAttributedString(string: viewModel.dataAgreement?.message?.body?.dataPolicy?.policyURL ?? "")
                attributedString.addAttribute(.link, value: attributedString, range: NSRange(location: 0, length: attributedString.length))
                cell.blurView.blurLbl.attributedText = attributedString
                cell.blurView.blurLbl.isUserInteractionEnabled = true
            case .jurisdiction:
                cell.mainLbl.text = DataAgreementItems.jurisdiction.rawValue.localizedForSDK()
                cell.blurView.text = self.viewModel.dataAgreement?.message?.body?.dataPolicy?.jurisdiction ?? ""
            case .thirdPartyDisclosure:
                cell.mainLbl.text = DataAgreementItems.thirdPartyDisclosure.rawValue.localizedForSDK()
                cell.blurView.text = ""
            case .industryScope:
                cell.mainLbl.text = DataAgreementItems.industryScope.rawValue.localizedForSDK()
                cell.blurView.text = self.viewModel.dataAgreement?.message?.body?.dataPolicy?.industrySector ?? ""
            case .geographicRestriction:
                cell.mainLbl.text = DataAgreementItems.geographicRestriction.rawValue.localizedForSDK()
                cell.blurView.text = self.viewModel.dataAgreement?.message?.body?.dataPolicy?.geographicRestriction ?? ""
            case .shared3Pp:
                cell.mainLbl.text = DataAgreementItems.geographicRestriction.rawValue.localizedForSDK()
                cell.blurView.text = self.viewModel.dataAgreement?.message?.body?.dataPolicy?.geographicRestriction ?? ""
            case .dataRetentionPeriod:
                cell.mainLbl.text = DataAgreementItems.dataRetentionPeriod.rawValue.localizedForSDK()
                cell.blurView.text = "\(viewModel.dataAgreement?.message?.body?.dataPolicy?.dataRetentionPeriod ?? 0)"
            case .storageLocation:
                cell.mainLbl.text = DataAgreementItems.storageLocation.rawValue.localizedForSDK()
                cell.blurView.text = self.viewModel.dataAgreement?.message?.body?.dataPolicy?.storageLocation ?? ""
                
                //DPIA Section
            case .DPIADate:
                cell.mainLbl.text = DataAgreementItems.DPIADate.rawValue.localizedForSDK()
                cell.blurView.text = self.viewModel.dataAgreement?.message?.body?.dpia?.dpiaDate ?? ""
            case .DPIASummary:
                cell.mainLbl.text = DataAgreementItems.DPIASummary.rawValue.localizedForSDK()
                cell.blurView.text = self.viewModel.dataAgreement?.message?.body?.dpia?.dpiaSummaryURL ?? ""
                
                //Purpose section
            case .purpose:
                cell.mainLbl.text = DataAgreementItems.purpose.rawValue.localizedForSDK()
                cell.blurView.text = self.viewModel.dataAgreement?.message?.body?.purpose ?? ""
            case .purposeDescription:
                cell.mainLbl.text = DataAgreementItems.purposeDescription.rawValue.localizedForSDK()
                cell.blurView.text = self.viewModel.dataAgreement?.message?.body?.purposeDescription ?? ""
            case .lawfulBasis:
                cell.mainLbl.text = DataAgreementItems.lawfulBasis.rawValue.localizedForSDK()
                cell.blurView.text = self.viewModel.dataAgreement?.message?.body?.lawfulBasis ?? ""
            case .thirdParty:
                cell.mainLbl.text = DataAgreementItems.thirdParty.rawValue.localizedForSDK()
                cell.blurView.text = (self.viewModel.dataAgreement?.message?.body?.dataPolicy?.thirdPartyDataSharing ?? false) ? "True" : "False"
            }
            cell.arrangeStackForDataAgreement()
            cell.layoutIfNeeded()
            return cell
        default:
            if isReceiptSection(section: indexPath.section) {
                let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
                switch indexPath.row {
                case 0:
                    cell.mainLbl.text = "Blink"
                    let address = (viewModel.dataAgreement?.receipt?.blink ?? "").split(separator: ":").last ?? ""
                    cell.tapGesture = UITapGestureRecognizer()
                    cell.tapGesture.addTarget(self, action: #selector(openRinkeryURL))
                    cell.blurView.addGestureRecognizer(cell.tapGesture)
                    let attributedString = NSMutableAttributedString(string: "https://rinkeby.etherscan.io/tx/" + "\(address)")
                    attributedString.addAttribute(.link, value: attributedString, range: NSRange(location: 0, length: attributedString.length))
                    cell.blurView.blurLbl.attributedText = attributedString
                    cell.blurView.blurLbl.isUserInteractionEnabled = true
                case 1:
                    cell.mainLbl.text = "My Data DID"
                    cell.blurView.text = viewModel.dataAgreement?.receipt?.mydataDid ?? ""
                default: break
                }
                cell.renderUI(index: indexPath.row, tot: tableView.numberOfRows(inSection: indexPath.section))
                cell.blurView.blurStatus = true
                cell.arrangeStackForDataAgreement()
                return cell
            }
            return getVerificationCell(indexPath: indexPath)
        }
    }
    
    private func isReceiptSection(section: Int) -> Bool {
        return (section == 3 && (viewModel.getReceiptCount() != 0))
    }
    
    private func getVerificationCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: VerifiedDataAgreementTableViewCell.self, for: indexPath)
        let index = indexPath.section - 3 - viewModel.getReceiptCount()
        cell.verifiedHeaderStackView.isHidden = false
        var signatureCellStartSection = 3
        if index == 0 {
            signatureCellStartSection = indexPath.section
        }
        switch indexPath.section {
        case signatureCellStartSection:
            switch viewModel.verification {
            case .loading:
                cell.verifiedLockImageView.isHidden = true
                cell.verifyLoader.isHidden = false
            case .failed:
                cell.verifiedLockImageView.isHidden = false
                cell.verifyLoader.isHidden = true
                cell.verifiedLockImageView.image = UIImage(systemName: "lock.open.fill")
                cell.verifiedLockImageView.tintColor = .red
            case .success:
                cell.verifiedLockImageView.isHidden = false
                cell.verifyLoader.isHidden = true
                cell.verifiedLockImageView.image = UIImage(systemName: "lock.fill")
                cell.verifiedLockImageView.tintColor = #colorLiteral(red: 0.05764851719, green: 0.485810101, blue: 0.06302744895, alpha: 1)
            }
            cell.didLabel.text = viewModel.dataAgreement?.message?.body?.proof?.verificationMethod ?? viewModel.dataAgreement?.message?.body?.proofChain?[index].verificationMethod ?? ""
            
            let signature = viewModel.dataAgreement?.message?.body?.proof?.proofValue ?? viewModel.dataAgreement?.message?.body?.proofChain?[index].proofValue ?? ""
            let attributedStringColor = [NSAttributedString.Key.foregroundColor : UIColor.lightGray];
            let attributedString = NSMutableAttributedString.init(attributedString: NSAttributedString.init(string: "Signature".localizedForSDK() + ": "))
            attributedString.append(NSAttributedString(string: signature, attributes: attributedStringColor))
            cell.signatureLabel.attributedText = attributedString
            cell.didLabelTitle.text = "Controller Decentralised Identifier".localizedForSDK()
        default:
            cell.didLabelTitle.text = "Individual Decentralised Identifier".localizedForSDK()
            cell.verifiedHeaderStackView.isHidden = true
            cell.didLabel.text = viewModel.dataAgreement?.message?.body?.proofChain?[index].verificationMethod ?? ""
            let signature = viewModel.dataAgreement?.message?.body?.proofChain?[index].proofValue ?? ""
            let attributedStringColor = [NSAttributedString.Key.foregroundColor : UIColor.lightGray];
            let attributedString = NSMutableAttributedString.init(attributedString: NSAttributedString.init(string: "Signature".localizedForSDK() + ": "))
            attributedString.append(NSAttributedString(string: signature, attributes: attributedStringColor))
            cell.signatureLabel.attributedText = attributedString
        }
        cell.selectionStyle = .none
        cell.layoutIfNeeded()
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return purposeSectionData.count
        case 1: return generalSectionData.count
        case 2: return DpiaSectionData.count
        default:
            if viewModel.mode == .queryDataAgrement {
                return 0
            }
            return isReceiptSection(section: section) ? 2 : 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension DataAgreementViewController: DataAgreementViewModelDelegate {
    func reloadData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

extension DataAgreementViewController: NavigationHandlerProtocol {
    func rightTapped(tag: Int) {}
}
