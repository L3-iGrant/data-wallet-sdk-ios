//
//  ExchangeDataPreviewViewController.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 14/12/20.
//

import UIKit

enum ExchangeDataPreviewMode {
    case EBSI
    case other
    case EBSIMultipleCerts
    case EBSIProcessingVPExchange
}

final class ExchangeDataPreviewViewController: AriesBaseViewController, NavigationHandlerProtocol {
    func leftTapped(tag: Int) {
        debugPrint("Tag:\(tag)")
    }
    
    func rightTapped(tag: Int) {
        debugPrint("Tag:\(tag)")
    }
   
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
    
    var completion: ((Bool) -> Void)?
    var showValues = false
    var viewModel: ExchangeDataPreviewViewModel?
    let dataAgreementHeaderHeight: CGFloat = 50
    var mode = ExchangeDataPreviewMode.other
    var maxHeight: CGFloat = 0
    var dataAgreementButton = UIButton.init(type: .custom)
    var isFromSDK = false
    var navHandler: NavigationHandler!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isFromSDK {
            updateLeftbatBtn(status: isFromSDK)
        }
        
        viewModel?.delegate = self
        self.pageControl.hidesForSinglePage = true
        addRightBarButton()
        withContentOnDidLoad()
        
        if mode == .EBSI {
            viewModel?.populateModelForEBSI()
        } else {
            viewModel?.fetchDataAgreement()
            fetchAllData()
        }
        self.view.subviews.forEach { view in
            view.isHidden = true
        }
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
    
    private func withContentOnDidLoad() {
        certName.text = viewModel?.isFromQR ?? false ? "\(viewModel?.QRData?.proofRequest?.name ?? "")" : "\(viewModel?.reqDetail?.value?.presentationRequest?.name ?? "")"
        infoText.attributedText = NSMutableAttributedString().normal("By choosing confirm you agree to share the requested data to".localizedForSDK()).bold(" " + (viewModel?.orgName ?? "" ))
        collectionView.register(UINib(nibName: "ExchangeDataAgreementCollectionViewCell", bundle: Constants.bundle), forCellWithReuseIdentifier: "ExchangeDataAgreementCollectionViewCell")
        acceptButton.layer.cornerRadius = 25
        rejectButton.layer.cornerRadius = 25
        companyLogo.layer.cornerRadius = 35
        self.acceptButton.setTitle("Confirm".localizedForSDK(), for: .normal)
        acceptButton.backgroundColor = AriesMobileAgent.themeColor
        rejectButton.backgroundColor = AriesMobileAgent.themeColor.withAlphaComponent(0.7)
        dynamicDataStack.addArrangedSubview(dataAgreementPolicyButton())
        
        if mode == .EBSI {
            certName.text = "EBSI"
            infoText.attributedText = NSMutableAttributedString().normal("By choosing confirm you agree to share the requested data to".localizedForSDK()).bold(" " + "EBSI")
            self.updateCompanyDetails()
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
            self.infoText.attributedText = NSMutableAttributedString().normal("By choosing confirm you agree to share the requested data to".localizedForSDK()).bold(" " + (self.viewModel?.orgName ?? "" ))
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
        let vc = DataAgreementViewController(vm: vm)
        self.push(vc: vc)
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
    
    //To fix autolayout issues -- Setting the frame manually
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        debugPrint("Exchange VC ----- viewDidLayoutSubviews")
////        if let cell = collectionView.cellForItem(at: IndexPath.init(row: 0, section: 0)) as? CertificateCardCollectionViewCell{
////                self.collectionHeightConstraint.constant = cell.tableView.contentSize.height + 20
////                self.collectionView.frame = CGRect.init(x: 0, y: 5, width: self.collectionView.frame.width, height: cell.tableView.contentSize.height + 20)
////        } else {
////            self.collectionHeightConstraint.constant =  self.collectionView.contentSize.height + 15
////        }
////        self.dynamicDataStack.frame = CGRect.init(x: 0, y: 0, width: baseTableView.frame.width, height: self.collectionHeightConstraint.constant + self.pageControlView.frame.height + 70)
////
////        self.baseView.frame = self.dynamicDataStack.frame
////        self.baseTableView.frame = self.baseView.frame
////        self.collectionView.reloadData()
////        debugPrint("baseView -- \(self.baseView.frame.height)  dynamicDataStack -- \(self.dynamicDataStack.frame.height) collection -- \(collectionHeightConstraint.constant) pageControl -- \(pageControl.frame.height)")
//
//        calcualteTheMaxHeightOfColectionView()
//    }
    
    func updateCompanyDetails(){
        if let logo = self.viewModel?.connectionModel?.value?.imageURL ?? self.viewModel?.orgImage {
            UIApplicationUtils.shared.setRemoteImageOn(self.companyLogo, url: logo)
        }
        self.companyName.text = self.viewModel?.connectionModel?.value?.orgDetails?.name ?? self.viewModel?.connectionModel?.value?.theirLabel ?? self.viewModel?.orgName ?? ""
        self.companyLocation.text = self.viewModel?.connectionModel?.value?.orgDetails?.location ?? self.viewModel?.orgLocation ?? ""
        updateDataAgreementButton()
    }
    
    func dataAgreementPolicyButton() -> UIView {
        let viewWidth =  self.view.frame.width - 30
        let view  = UIView.init(frame: CGRect.init(x: 0, y: 0, width: dynamicDataStack.frame.width, height: 60))
        view.backgroundColor = .clear
        dataAgreementButton.frame = CGRect.init(x: 15, y: 0, width: viewWidth - 15, height: 50)
        dataAgreementButton.backgroundColor = .white
        dataAgreementButton.layer.cornerRadius = 10
        dataAgreementButton.setTitle("Data Agreement Policy".localizedForSDK(), for: .normal)
        dataAgreementButton.setTitleColor(.darkGray, for: .normal)
        dataAgreementButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        dataAgreementButton.contentHorizontalAlignment = .left
        dataAgreementButton.titleEdgeInsets.left = 20
        let rightArrow = UIImageView.init(frame: CGRect.init(x: viewWidth - 30, y: 15, width: 20, height: 20))
        rightArrow.image = UIImage(systemName: "chevron.right")
        rightArrow.tintColor = .darkGray
        rightArrow.contentMode = .center
        dataAgreementButton.addTarget(self, action:#selector(self.tappedOnDataAgreement), for: .touchUpInside)
        view.addSubview(dataAgreementButton)
        view.addSubview(rightArrow)
        
        return view
    }
    
    override func localizableValues() {
        super.localizableValues()
        self.title = "Data agreement".localizedForSDK()
        infoText.attributedText = NSMutableAttributedString().normal("By choosing confirm you agree to share the requested data to".localizedForSDK()).bold(" " + (viewModel?.orgName ?? "" ))
        self.acceptButton.setTitle("Confirm".localizedForSDK(), for: .normal)
        self.collectionView.reloadData()
        
        if mode == .EBSI {
            certName.text = "EBSI"
            infoText.attributedText = NSMutableAttributedString().normal("By choosing confirm you agree to share the requested data to".localizedForSDK()).bold(" " + "EBSI")
            self.updateCompanyDetails()
        }
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
    
    @IBAction func showSelectedCardDetail(_ sender: Any) {
        var recordId = ""
        if mode == .EBSI {
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
                        self.push(vc: vc)
                    case SelfAttestedCertTypes.covidCert_IN.rawValue:
                        let vc = CertificateViewController(pageType: .covid(isScan: false))
                        if let model = cert.value?.covidCert_IND {
                            vc.viewModel.covid = CovidCertificateStateViewModel(model: model)
                        }
                        vc.viewModel.covid?.recordId = cert.id ?? ""
                        self.push(vc: vc)
                    case SelfAttestedCertTypes.aadhar.rawValue:
                        let vc = CertificateViewController(pageType: .aadhar(isScan: false))
                        if let model = cert.value?.aadhar {
                            vc.viewModel.aadhar = AadharStateViewModel(model: model)
                        }
                        vc.viewModel.aadhar?.recordId = cert.id ?? ""
                        self.push(vc: vc)
                    case SelfAttestedCertTypes.passport.rawValue:
                        let vc = CertificateViewController(pageType: .passport(isScan: false))
                        vc.viewModel.passport.passportModel = cert.value?.passport
                        vc.viewModel.passport.recordId = cert.id ?? ""
                        self.push(vc: vc)
                        
                    default:
                        let vc = CertificateViewController(pageType: .general(isScan: false))
                        vc.viewModel.general = GeneralStateViewModel.init(walletHandle: self.viewModel?.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert)
                        self.push(vc: vc)
                    }
                } else {
                    
                    //TODO: USE CERT SUB TYPE IN FUTURE
                    //Receipt
                    if let receiptModel = ReceiptCredentialModel.isReceiptCredentialModel(certModel: cert){
                        //Show Receipt UI
                        let vc = CertificateViewController(pageType: .issueReceipt(mode: .view))
                        vc.viewModel.receipt = ReceiptStateViewModel(walletHandle: self.viewModel?.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert, receiptModel: receiptModel)
                        self.navigationController?.pushViewController(vc, animated: true)
                        return
                    }
                    let vc = CertificateViewController(pageType: .general(isScan: false))
                    vc.viewModel.general = GeneralStateViewModel.init(walletHandle: self.viewModel?.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert)
                                vc.viewModel.covid?.recordId = cert.id ?? ""
                                self.push(vc: vc)
                }
            }
        })
    }
    
    @IBAction func acceptButtonTapped(sender: Any) {
        if mode == .EBSI {
            viewModel?.verifyEBSI_cred()
        } else {
            viewModel?.checkConnection()
        }
    }
    
    @IBAction func rejectButtonTapped(sender: Any) {
        
        let alert = UIAlertController(title: "Data Wallet", message: "Do you want to cancel the exchange request?".localizedForSDK(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes".localizedForSDK(), style: .default, handler: { [self] action in
            viewModel?.rejectCertificate()
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "No".localizedForSDK(), style: .default, handler: { action in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
}
