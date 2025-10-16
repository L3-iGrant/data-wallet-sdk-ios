//
//  CirtificateViewController.swift
//  dataWallet
//
//  Created by sreelekh N on 07/01/22.
//

import UIKit
import PassKit

enum CredentialMode {
    case issue
    case view
    case exchange
}
final class CertificateViewController: AriesBaseViewController, CustomNavigationBarIconViewDelegate {
    
    override var wx_barTintColor: UIColor? {
        switch pageType {
        case .pkPass:
            return self.viewModel.pkPass?.labelColor ?? .darkGray
        default:
            return .black
        }
        
    }
    
    override var wx_titleTextAttributes: [NSAttributedString.Key : Any]? {
        switch pageType {
        case .pkPass:
            return [.foregroundColor: self.viewModel.pkPass?.labelColor ?? .darkGray]
        default:
            return [.foregroundColor: UIColor.black]
        }
    }
    
    var viewModel = CirtificateViewModel()
    var showValues = false
    var navHandler: NavigationHandler!
    
    let scanHeader = CirtificateHeaderView()
    let tableView = UITableView.getTableview()
    let collectionView = UICollectionView.getCV()
    let nextButton = ShareDataFloting()
    let pkPassHeaderView = PkPassHeaderView()
    let connectionHeaderView = ConnectionDetailHeaderView()
    let bottomSheetHeaderView = BottomSheetHeaderView()
    let pwaIssuedDateView = PWAIssuedDAteView()
    let pwaPagerView = PagerView()
    let RemoveButtonview = RemoveBtnVew()
    var dataAgreementButton = UIButton.init(type: .custom)
    var certificateName: String? = ""
    let backNavIcon = CustomNavigationBarIconView()
    let eyeNavIcon = CustomNavigationBarIconView()
    let skipIcon = CustomNavigationBarIconView()
    var pwaCertificates: Search_CustomWalletRecordCertModel? = nil
    var selectedPWAIndex: Int = 0
    
    enum PageType {
        case passport(isScan: Bool = false)
        case aadhar(isScan: Bool = false)
        case covid(isScan: Bool = false)
        case pkPass(isScan: Bool = false)
        case general(isScan: Bool = false)
        case issueReceipt(mode: CredentialMode)
        case multipleTypeCards(isScan: Bool = false)
        case pwa(isScan: Bool = false)
        case photoId(isScan: Bool = false)
    }
    
    let pageType: PageType
    
    var viewMode: ViewMode = .FullScreen
    
    init(pageType: PageType) {
        self.pageType = pageType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("error inside cirtificate invoke")
    }
    
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if isDark ?? false {
            return .lightContent
        } else {
            return .darkContent
        }
    }
    
    var isDark: Bool? {
        didSet {
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    var imageLightValue: Bool? {
        didSet {
            isDark = imageLightValue
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func loadView() {
        super.loadView()
        switch pageType {
        case .passport(let isScan):
            renderUIForPassport(isScan: isScan)
        case .aadhar(let isScan), .covid(let isScan):
            renderUIForAadharCovid(isScan: isScan)
        case .pkPass(let isScan):
            renderUIForPKPass(isScan: isScan)
        case .general(let isScan):
            renderUIForGeneralCert(isScan: isScan)
        case .issueReceipt(mode: let mode):
            renderUIForReceiptCert(mode: mode)
        case .multipleTypeCards(isScan: let isScan):
            renderUIForMultipleTypeCard(isScan: isScan)
        case .pwa(isScan: let isScan):
            fetchPWAforSameOrganizationsAndRenderUI(isScan: isScan)
            renderUIForPWA(isScan: isScan)
        case .photoId(isScan: let isScan):
            renderUIForPhotoID(isScan: isScan)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //isDark = false
        didLoad()
        setCredentialColor()
        updateNavigationContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    private func didLoad() {
        navHandler = NavigationHandler(parent: self, delegate: self)
        addNavigationItems()
        switch pageType {
        case .passport(isScan: let isScan):
            let passportModel = self.viewModel.passport.passportModel
            self.title = "cards_passport_detail".localized()
            self.viewModel.passport.pageDelegate = self
            if let passportModel = passportModel {
                self.viewModel.passport.loadData(model: passportModel)
            }
            if isScan {
                addRightBarButtonWithSkip()
            }
        case .aadhar:
            self.viewModel.aadhar?.pageDelegate = self
            self.title = "cards_aadhar_details".localized()
            scanHeader.titleLbl.text = "cards_unique_identification_authority_of_india".localized()
            scanHeader.subLbl.text = "certificate_government_of_india".localized()
            scanHeader.btnImage = self.viewModel.aadhar?.QRCodeImage
        case .covid:
            self.viewModel.covid?.pageDelegate = self
            scanHeader.btnImage = self.viewModel.covid?.QRCodeImage
            switch self.viewModel.covid?.certificateType {
            case .digitalTestCertificate:
                self.title = "certificate_digital_test_certificate".localized().localizedUppercase
                scanHeader.titleLbl.text = "certificate_digital_test_certificate".localized()
                scanHeader.subLbl.text = viewModel.covid?.certificateIssuer ?? ""
            default:
                scanHeader.setTitles(type: self.viewModel.covid?.type, issuer: viewModel.covid?.certificateIssuer ?? "")
                switch self.viewModel.covid?.type {
                case .Europe:
                    self.title = "cards_digital_vaccination_certificate".localized().localizedUppercase
                default:
                    self.title = "certificate_covid_vaccination_certificate".localized()
                }
            }
        case .pkPass:
            self.viewModel.pkPass?.pageDelegate = self
            self.viewModel.pkPass?.getIDCardAttributesArray()
            self.title = self.viewModel.pkPass?.getPKPassType() ?? "PKPASS".localized()
            
            if PKPassLibrary.isPassLibraryAvailable() {
                let wallet = PKPassLibrary()
                let passArray = wallet.passes()
                debugPrint(passArray)
            }
        case .general:
            self.viewModel.general?.pageDelegate = self
            if let generalModel = self.viewModel.general {
               // connectionHeaderView.delegate = self
                self.bottomSheetHeaderView.bottomSheetDelegate = self
                self.bottomSheetHeaderView.setData(model: generalModel)
                //self.connectionHeaderView.setData(model: generalModel)
            }
        case .issueReceipt:
            self.viewModel.receipt?.pageDelegate = self
            if let receiptModel = self.viewModel.receipt {
               // connectionHeaderView.delegate = self
                self.connectionHeaderView.setData(model: receiptModel)
            }
        case .multipleTypeCards:
            self.viewModel.general?.pageDelegate = self
            if let multiTypeModel = self.viewModel.multipleType {
               // connectionHeaderView.delegate = self
                self.connectionHeaderView.setData(model: multiTypeModel)
                addRightBarButton()
            }
        case .pwa(isScan: let isScan):
            self.viewModel.pwaCert?.pageDelegate = self
            if let pwaModel = self.viewModel.pwaCert {
                //connectionHeaderView.delegate = self
                if viewMode == .BottomSheet {
                    self.bottomSheetHeaderView.bottomSheetDelegate = self
                    self.bottomSheetHeaderView.setData(model: pwaModel)
                } else {
                    self.connectionHeaderView.setData(model: pwaModel)
                }
            }
        case .photoId(isScan: let isScan):
            let photoIDModel = self.viewModel.photoID?.photoIDCredential
            self.title = "cards_photo_id_detail".localized()
            self.viewModel.photoID?.pageDelegate = self
            if isScan {
                addRightBarButtonWithSkip()
            }
            if let photoIDModel = photoIDModel {
                self.viewModel.photoID?.loadData(model: photoIDModel)
            }
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }
    
    // Setting card color based on credential branding
    func setCredentialColor() {
        if let color = viewModel.general?.certModel?.value?.backgroundColor {
            view.backgroundColor = UIColor(hex: color)
        }
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
        addRightBarButtonWithSkip()
        self.tableView.reloadInMain()
        self.collectionView.reloadInMain()
    }
    
    @objc func tappedOnSkipButton() {
        
    }
    
    @IBAction func rejectButtonTapped(sender: Any) {
        let alert = UIAlertController(title: "Data Wallet", message: "data_do_you_want_to_cancel_the_exchange_request".localizedForSDK(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "general_yes".localizedForSDK(), style: .default, handler: { [self] action in
            // viewModel?.rejectCertificate()
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "general_no".localizedForSDK(), style: .default, handler: { action in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func renderUIForPassport(isScan: Bool) {
        if isScan {
            view.tupleViews(views: tableView, nextButton)
            nextButton.addAnchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 25, width: 190, height: 60, centerX: view.centerXAnchor)
            nextButton.delegate = self
            nextButton.title(lbl: "read_next".localized())
        } else {
            view.addSubview(tableView)
        }
        updateCustomNavigationBar()
        tableView.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: SignImageTableViewCell.self)
        tableView.register(cellType: IssuanceTimeTableViewCell.self)
    }
    
    private func renderUIForPhotoID(isScan: Bool) {
        if isScan {
            view.tupleViews(views: tableView, nextButton)
            nextButton.addAnchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 25, width: 190, height: 60, centerX: view.centerXAnchor)
            nextButton.delegate = self
            nextButton.title(lbl: "read_next".localized())
        } else {
            view.addSubview(tableView)
        }
        updateCustomNavigationBar()
        tableView.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: SignImageTableViewCell.self)
        tableView.register(cellType: IssuanceTimeTableViewCell.self)
        tableView.register(cellType: PhotoIdWithImageCell.self)
        tableView.register(cellType: PhotoIDIssuerDetailsCell.self)
    }
    
    private func renderUIForAadharCovid(isScan: Bool) {
        if isScan {
            view.tupleViews(views: scanHeader, tableView, nextButton)
            scanHeader.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 70)
            tableView.addAnchor(top: scanHeader.bottomAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
            nextButton.addAnchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 25, width: 190, height: 60, centerX: view.centerXAnchor)
            nextButton.title(lbl: "read_next".localized())
            nextButton.delegate = self
            scanHeader.delegate = self
        } else {
            view.tupleViews(views: scanHeader, tableView)
            scanHeader.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 70)
            tableView.addAnchor(top: scanHeader.bottomAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
            scanHeader.delegate = self
        }
        updateCustomNavigationBar()
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: IssuanceTimeTableViewCell.self)
    }
    
    private func renderUIForPKPass(isScan: Bool) {
        if isScan {
            view.tupleViews(views: pkPassHeaderView, tableView, nextButton)
            pkPassHeaderView.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 150)
            tableView.addAnchor(top: pkPassHeaderView.bottomAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
            nextButton.addAnchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 25, width: 190, height: 60, centerX: view.centerXAnchor)
            nextButton.delegate = self
            nextButton.title(lbl: "read_next".localized())
        } else {
            view.tupleViews(views: pkPassHeaderView, tableView)
            pkPassHeaderView.addAnchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: 150)
            tableView.addAnchor(top: pkPassHeaderView.bottomAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        }
        updateCustomNavigationBar(tint: viewModel.pkPass?.labelColor ?? .black)
        tableView.contentInset.top = 20
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: PKPassQRTableViewCell.self)
        tableView.register(cellType: IssuanceTimeTableViewCell.self)
    }
    
    private func renderUIForGeneralCert(isScan: Bool) {
        if isScan {
            //Fixme
            view.tupleViews(views: bottomSheetHeaderView, tableView, nextButton)
           // connectionHeaderView.setCoverImageHeight()
            //connectionHeaderView.delegate = self
            bottomSheetHeaderView.addAnchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor)
            tableView.addAnchor(top: bottomSheetHeaderView.bottomAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
            nextButton.addAnchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 25, width: 190, height: 60, centerX: view.centerXAnchor)
            nextButton.delegate = self
            nextButton.title(lbl: "read_next".localized())
        } else {
            view.tupleViews(views: bottomSheetHeaderView, tableView)
            //connectionHeaderView.setCoverImageHeight()
            bottomSheetHeaderView.addAnchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor)
            tableView.addAnchor(top: bottomSheetHeaderView.bottomAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        }
        if viewModel.general?.isEBSI() ?? false {
            
        }
        tableView.contentInset.top = 0
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: ValuesRowImageTableViewCell.self)
        tableView.register(cellType: IssuanceTimeTableViewCell.self)
        tableView.register(cellType: PaymentWalletAttestationImageRowCell.self)
        tableView.register(cellType: PhotoIdWithImageCell.self)

    }
    
    private func renderUIForMultipleTypeCard(isScan: Bool) {
        view.tupleViews(views: connectionHeaderView, tableView, nextButton)
       // connectionHeaderView.setCoverImageHeight()
        connectionHeaderView.addAnchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor)
        tableView.addAnchor(top: connectionHeaderView.bottomAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)

        tableView.contentInset.top = 20
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: ValuesRowImageTableViewCell.self)
        tableView.register(cellType: IssuanceTimeTableViewCell.self)
        tableView.tableFooterView = footerView()
        
        // Floating button on bottom
        nextButton.addAnchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 25, width: 190, height: 60, centerX: view.centerXAnchor)
        nextButton.delegate = self
        nextButton.title(lbl: "general_confirm".localized())
    }
    
    func footerView() -> UIView {
        let width = (self.navigationController?.view.frame.width ?? self.tableView.frame.width)
        let view  = UIView.init(frame: CGRect.init(x: 0, y: 0, width: width, height: 60))
        view.backgroundColor = .clear
        dataAgreementButton.frame = CGRect.init(x: 15, y: 20, width: width - 30, height: 45)
        dataAgreementButton.backgroundColor = .white
        dataAgreementButton.layer.cornerRadius = 10
        dataAgreementButton.setTitle("certificate_data_agreement_policy".localized(), for: .normal)
        dataAgreementButton.setTitleColor(.darkGray, for: .normal)
        dataAgreementButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        dataAgreementButton.contentHorizontalAlignment = .left
        dataAgreementButton.titleEdgeInsets.left = 20
        let rightArrow = UIImageView.init(frame: CGRect.init(x: width - 60, y: 12.5, width: 20, height: 20))
        rightArrow.image = UIImage(systemName: "chevron.right")
        rightArrow.tintColor = .darkGray
        rightArrow.contentMode = .center
        // dataAgreementButton.addTarget(self, action:#selector(self.tappedOnDataAgreement), for: .touchUpInside)
        dataAgreementButton.addSubview(rightArrow)
        view.addSubview(dataAgreementButton)
        return view
    }
    
    func updateCustomNavigationBar(tint: UIColor = .black) {
        backNavIcon.containerView.isHidden = true
        eyeNavIcon.containerView.isHidden = true
        backNavIcon.iconImg.tintColor = tint
        eyeNavIcon.iconImg.tintColor = tint
    }
      
    @objc func tappedOnDataAgreement() {
//        if viewModel?.dataAgreement == nil {
//            return
//        }
//        let vm = DataAgreementViewModel(dataAgreement: viewModel?.dataAgreement,
//                                        connectionRecordId: viewModel?.connectionModel?.id ?? "",
//                                        mode: .issueCredential)
//        vm.inboxId = viewModel?.inboxId
//        vm.inboxModel = viewModel?.inboxModel
//
//        let vc = DataAgreementViewController(vm: vm)
//        self.push(vc: vc)
    }
    
    private func renderUIForReceiptCert(mode: CredentialMode) {
        if mode != .view {
            view.tupleViews(views: connectionHeaderView, tableView, nextButton)
           // connectionHeaderView.setCoverImageHeight()
            connectionHeaderView.addAnchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor)
            tableView.addAnchor(top: connectionHeaderView.bottomAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
            nextButton.addAnchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 25, width: 190, height: 60, centerX: view.centerXAnchor)
            nextButton.delegate = self
            nextButton.title(lbl: "general_accept".localized())
        } else {
            view.tupleViews(views: connectionHeaderView, tableView)
           // connectionHeaderView.setCoverImageHeight()
            connectionHeaderView.addAnchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor)
            tableView.addAnchor(top: connectionHeaderView.bottomAnchor, bottom: view.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor)
        }
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: ValuesRowImageTableViewCell.self)
        tableView.register(cellType: ReceiptTableViewCell.self)
        tableView.register(cellType: IssuanceTimeTableViewCell.self)
    }
    
    private func renderUIForPWA(isScan: Bool) {
        if viewMode == .BottomSheet {
            view.tupleViews(views: bottomSheetHeaderView, collectionView, pwaIssuedDateView)
        } else {
            view.tupleViews(views: connectionHeaderView, collectionView, pwaIssuedDateView)
        }
       

        if let data = pwaCertificates {
            if pwaCertificates?.records?.count ?? 0 > 1 {
                view.tupleViews(views: pwaPagerView, RemoveButtonview)
            } else {
                view.tupleViews(views: RemoveButtonview)
            }
        }

       // connectionHeaderView.setCoverImageHeight()
        if viewMode == .BottomSheet {
            bottomSheetHeaderView.addAnchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor)

            collectionView.addAnchor(top: bottomSheetHeaderView.bottomAnchor,
                                     left: view.leftAnchor,
                                     right: view.rightAnchor,
                                     height: 232)
        } else {
            connectionHeaderView.addAnchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor)

            collectionView.addAnchor(top: connectionHeaderView.bottomAnchor,
                                     left: view.leftAnchor,
                                     right: view.rightAnchor,
                                     height: 232)
        }

        pwaIssuedDateView.addAnchor(top: collectionView.bottomAnchor,
                                    left: view.leftAnchor,
                                    right: view.rightAnchor,
                                    height: 30)

        if let data = pwaCertificates {
            if pwaCertificates?.records?.count ?? 0 > 1 {
                pwaPagerView.addAnchor(top: pwaIssuedDateView.bottomAnchor,
                                       left: view.leftAnchor,
                                       right: view.rightAnchor,
                                       height: 30)
                
                RemoveButtonview.addAnchor(top: pwaPagerView.bottomAnchor,
                                           left: view.leftAnchor,
                                           right: view.rightAnchor,
                                           height: 67)
            } else {
                RemoveButtonview.addAnchor(top: pwaIssuedDateView.bottomAnchor,
                                           left: view.leftAnchor,
                                           right: view.rightAnchor,
                                           height: 67)
            }
        }

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            collectionView.isPagingEnabled = true
        }

        RemoveButtonview.tapAction = { [weak self] in
            self?.removePWACer()
        }

        if let data = pwaCertificates {
            if pwaCertificates?.records?.count ?? 0 > 1 {
                pwaPagerView.pageControll.currentPageIndicatorTintColor = .darkGray
                pwaPagerView.pageControll.pageIndicatorTintColor = UIColor.darkGray.withAlphaComponent(0.3)
                pwaPagerView.pageControll.hidesForSinglePage = true
            }
        }

        collectionView.register(cellType: PaymentCardCollectionViewCell.self)
    }
    
    
    func addNavigationItems() {
        switch pageType {
        case .pkPass:
            addCustomBackTabIcon()
            addCustomEyeTabIcon()
        case .multipleTypeCards:
            self.navHandler.vc.title = "Data Agreemennt".localized()
        case .passport(isScan: true), .photoId(isScan: true):
            addCustomBackTabIcon()
            addRightBarButtonWithSkip()
        default:
            addCustomBackTabIcon()
            addCustomEyeTabIcon()
            //navHandler.setNavigationComponents(right: [!showValues ? .eye : .eyeFill])
        }
    }
    
    func addRightBarButtonWithSkip() {
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
        
        let skipButton = UIButton(type: .custom)
        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(.black, for: .normal)
        skipButton.contentHorizontalAlignment = .right
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        skipButton.frame = CGRect(x: 15, y: 0, width: 40, height: 25)
        skipButton.addTarget(self, action: #selector(tappedOnSkipButton), for: .touchUpInside)
        let barButton2 = UIBarButtonItem(customView: skipButton)
        let currWidth2 = barButton2.customView?.widthAnchor.constraint(equalToConstant: 30)
        currWidth2?.isActive = true
        let currHeight2 = barButton2.customView?.heightAnchor.constraint(equalToConstant: 25)
        currHeight2?.isActive = true
        
        self.navigationItem.rightBarButtonItems = [barButton,barButton2]
    }
    
    private func addCustomBackTabIcon() {
        backNavIcon.tag = 0
        backNavIcon.frame = CGRect(x: 0, y: 0, width: self.topAreaHeight, height: self.topAreaHeight)
        let barbtnItem = UIBarButtonItem(customView: backNavIcon)
        backNavIcon.delegate = self
        self.navigationItem.leftBarButtonItem = barbtnItem
    }
    
    private func addCustomEyeTabIcon() {
        eyeNavIcon.tag = 1
        eyeNavIcon.frame = CGRect(x: 0, y: 0, width: self.topAreaHeight, height: self.topAreaHeight)
        let barbtnItem = UIBarButtonItem(customView: eyeNavIcon)
        eyeNavIcon.delegate = self
        eyeNavIcon.updateImageHeight(update: 5)
        eyeNavIcon.setRight()
        self.navigationItem.rightBarButtonItem = barbtnItem
    }
    
    private func updateNavigationContent() {
        if !self.showValues {
            eyeNavIcon.iconImg.image = "eye".getImage()
        } else {
            eyeNavIcon.iconImg.image = "eye.slash".getImage()
        }
        //addRightBarButton()
        self.tableView.reloadInMain()
        self.collectionView.reloadInMain()
    }
    
    func cusNavtappedAction(tag: Int) {
        switch tag {
        case 1:
            self.showValues.toggle()
            self.updateNavigationContent()
        default:
            self.returnBack()
        }
    }
    
    func deleteAction() {
        if viewMode == .BottomSheet {
            AlertHelper.shared.askConfirmationFromBottomSheet(on: self, message: "connect_are_you_sure_you_want_to_delete_this_item".localizedForSDK(), btn_title: ["general_yes".localizedForSDK(), "general_no".localizedForSDK()], completion: { [weak self] row in
                switch row {
                case 0:
                    self?.deleteCard()
                default:
                    break
                }
            })
        } else {
            AlertHelper.shared.askConfirmationRandomButtons(message: "connect_are_you_sure_you_want_to_delete_this_item".localizedForSDK(), btn_title: ["general_yes".localizedForSDK(), "general_no".localizedForSDK()], completion: { [weak self] row in
                switch row {
                case 0:
                    self?.deleteCard()
                default:
                    break
                }
            })
        }
    }
    
    private func deleteCard() {
        switch pageType {
        case .passport:
            self.viewModel.passport.deleteIDCardFromWallet(walletRecordId: self.viewModel.passport.recordId ?? "")
        case .aadhar:
            self.viewModel.aadhar?.deleteIDCardFromWallet(walletRecordId: self.viewModel.aadhar?.recordId ?? "")
        case .covid:
            self.viewModel.covid?.deleteIDCardFromWallet(walletRecordId: self.viewModel.covid?.recordId ?? "")
        case .pkPass:
            self.viewModel.pkPass?.deleteIDCardFromWallet(walletRecordId: self.viewModel.pkPass?.recordId ?? "")
        case .general:
            self.viewModel.general?.deleteCredentialWith(id: self.viewModel.general?.certModel?.value?.referent?.referent ?? "", walletRecordId: self.viewModel.general?.certModel?.id ?? "")
        case .issueReceipt:
            self.viewModel.receipt?.deleteCredentialWith(id: self.viewModel.receipt?.certModel?.value?.referent?.referent ?? "", walletRecordId: self.viewModel.receipt?.certModel?.id ?? "")
        case .multipleTypeCards:
            self.viewModel.general?.deleteCredentialWith(id: self.viewModel.general?.certModel?.value?.referent?.referent ?? "", walletRecordId: self.viewModel.general?.certModel?.id ?? "")
        case .pwa(isScan: let isScan):
            break
        case .photoId(isScan: let isScan):
            self.viewModel.photoID?.deleteIDCardFromWallet(walletRecordId: self.viewModel.photoID?.recordId ?? "")
        }
    }
    
    func updatePKPassHeader() {
        if let bgColor = self.viewModel.pkPass?.bgColor {
            self.view.backgroundColor = bgColor
        }
        self.title = self.viewModel.pkPass?.getPKPassType() ?? "PKPASS".localized()
        if let model = self.viewModel.pkPass {
            pkPassHeaderView.setData(model: model)
        }
    }
}

extension CertificateViewController: PaymentCardCollectionViewCellDelegate {
    
    func deletePWACard() {
        if viewMode == .BottomSheet {
            AlertHelper.shared.askConfirmationFromBottomSheet(on: self, message: "connect_are_you_sure_you_want_to_delete_this_item".localizedForSDK(), btn_title: ["general_yes".localizedForSDK(), "general_no".localizedForSDK()], completion: { [weak self] row in
                switch row {
                case 0:
                    self?.viewModel.pwaCert?.deleteCredentialWith(id: self?.pwaCertificates?.records?[self?.selectedPWAIndex ?? 0].value?.referent?.referent ?? "", walletRecordId: self?.pwaCertificates?.records?[self?.selectedPWAIndex ?? 0].id ?? "", data: self?.pwaCertificates?.records?[self?.selectedPWAIndex ?? 0])
                    DispatchQueue.main.async {
                        self?.fetchPWAforSameOrganizationsAndRenderUI()
                    }                default:
                    break
                }
            })
        } else {
            AlertHelper.shared.askConfirmationRandomButtons(message: "connect_are_you_sure_you_want_to_delete_this_item".localizedForSDK(), btn_title: ["general_yes".localizedForSDK(), "general_no".localizedForSDK()], completion: { [weak self] row in
                switch row {
                case 0:
                    self?.viewModel.pwaCert?.deleteCredentialWith(id: self?.pwaCertificates?.records?[self?.selectedPWAIndex ?? 0].value?.referent?.referent ?? "", walletRecordId: self?.pwaCertificates?.records?[self?.selectedPWAIndex ?? 0].id ?? "", data: self?.pwaCertificates?.records?[self?.selectedPWAIndex ?? 0])
                    DispatchQueue.main.async {
                        self?.fetchPWAforSameOrganizationsAndRenderUI()
                    }
                default:
                    break
                }
            })
        }
        
    }
    
    func removePWACer() {
        if viewMode == .BottomSheet {
            AlertHelper.shared.askConfirmationFromBottomSheet(on: self, message: "connect_are_you_sure_you_want_to_delete_this_item".localizedForSDK(), btn_title: ["general_yes".localizedForSDK(), "general_no".localizedForSDK()], completion: { [weak self] row in
                switch row {
                case 0:
                    self?.viewModel.pwaCert?.deleteAllCredentialInPWAWith(record: self?.pwaCertificates?.records)
                default:
                    break
                }
            })
        } else {
            AlertHelper.shared.askConfirmationRandomButtons(message: "connect_are_you_sure_you_want_to_delete_this_item".localizedForSDK(), btn_title: ["general_yes".localizedForSDK(), "general_no".localizedForSDK()], completion: { [weak self] row in
                switch row {
                case 0:
                    self?.viewModel.pwaCert?.deleteAllCredentialInPWAWith(record: self?.pwaCertificates?.records)
                default:
                    break
                }
            })
        }
    }
    
    func setIssuedDate() {
        guard let records = pwaCertificates?.records, records.count > selectedPWAIndex else {
               return
           }
        let dateFormat = DateFormatter.init()
        pwaIssuedDateView.expiredOrRevokedLabel.isHidden = true
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
        dateFormat.locale = Locale(identifier: "en_US_POSIX")
        let dateFormat2 = DateFormatter.init()
        dateFormat2.dateFormat = "yyyy-MM-dd hh:mm:ss.SSSSSS a'Z'"
        dateFormat2.locale = Locale(identifier: "en_US_POSIX")
        if let expiredDate = pwaCertificates?.records?[selectedPWAIndex].value?.expiredTime, viewModel.pwaCert?.isFromExpired == true {
            pwaIssuedDateView.expiredOrRevokedLabel.isHidden = false
            let formattedDate = dateFormat.date(from:  expiredDate) ?? dateFormat2.date(from:  expiredDate)
            pwaIssuedDateView.expiredOrRevokedLabel.text = "expired_at".localized() + "\(formattedDate?.timeAgoDisplay() ?? "")"
        } else if let revokedDate = pwaCertificates?.records?[selectedPWAIndex].value?.revokedTime, viewModel.pwaCert?.isFromExpired == true{
            pwaIssuedDateView.expiredOrRevokedLabel.isHidden = false
            let formattedDate = dateFormat.date(from:  revokedDate) ?? dateFormat.date(from:  revokedDate)
            pwaIssuedDateView.expiredOrRevokedLabel.text = "revoked_at".localized() +  "\(formattedDate?.timeAgoDisplay() ?? "")"
        }
        if let unixTimestamp = TimeInterval(pwaCertificates?.records?[selectedPWAIndex].value?.addedDate ?? "" ) {
            let date = Date(timeIntervalSince1970: unixTimestamp)
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateString = dateFormat.string(from: date)
            let formattedDate = dateFormat.date(from: dateString)
            pwaIssuedDateView.issuedDate.text = "welcome_issued_at".localizedForSDK() + (formattedDate?.timeAgoDisplay() ?? "")
        }
    }
    
    func fetchPWAforSameOrganizationsAndRenderUI(isScan: Bool = false) {
        if viewModel.pwaCert?.isFromExpired ?? false {
            var records: [SearchItems_CustomWalletRecordCertModel] = []
            if let data = viewModel.pwaCert?.certModel {
                records.append(data)
                var certSearchModel = Search_CustomWalletRecordCertModel(totalCount: records.count, records: records)
                self.pwaCertificates = certSearchModel
                DispatchQueue.main.async {
                    self.pwaPagerView.pageControll.numberOfPages = self.pwaCertificates?.records?.count ?? 0
                    self.selectedPWAIndex = self.pwaPagerView.pageControll.currentPage
                    self.renderUIForPWA(isScan: isScan)
                    self.collectionView.reloadData()
                    self.setIssuedDate()
                }
            }
        } else {
            let walletHandler = WalletViewModel.openedWalletHandler ?? 0
            AriesAgentFunctions.shared.openWalletSearch(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates,query: ["sub_type": viewModel.pwaCert?.certModel?.value?.subType ?? ""]) {(success, searchHandler, error) in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (fetched, response, error) in
                    let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                    var certSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                    let filteredRecords = certSearchModel?.records?.filter( { $0.value?.fundingSource != nil })
                    let paymentCards = filteredRecords?.filter( { $0.value?.connectionInfo?.value?.orgDetails?.name == self.viewModel.pwaCert?.certModel?.value?.connectionInfo?.value?.orgDetails?.name })
                    let sortedPaymentCards = paymentCards?.sorted {
                        guard let timestamp1 = $0.value?.addedDate, let timestamp2 = $1.value?.addedDate,
                              let addedTime1 = TimeInterval(timestamp1),
                              let addedTime2 = TimeInterval(timestamp2) else { return false }
                        let date1 = Date(timeIntervalSince1970: addedTime1)
                        let date2 = Date(timeIntervalSince1970: addedTime2)
                        return date1 > date2
                    }
                    certSearchModel?.records = sortedPaymentCards
                    certSearchModel?.totalCount = sortedPaymentCards?.count
                    self.pwaCertificates = certSearchModel
                    DispatchQueue.main.async {
                        self.pwaPagerView.pageControll.numberOfPages = self.pwaCertificates?.records?.count ?? 0
                        self.renderUIForPWA(isScan: isScan)
                        self.selectedPWAIndex = self.pwaPagerView.pageControll.currentPage
                        self.collectionView.reloadData()
                        self.setIssuedDate()
                    }
                }
            }
        }
    }
    
}

extension CertificateViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pwaCertificates?.records?.count ?? 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier:
                                            "PaymentCardCollectionViewCell", for: indexPath) as! PaymentCardCollectionViewCell
        cell.delegate = self
        let shouldHideDelete = (pwaCertificates?.records?.count ?? 0) == 1
        cell.updateCell(model: pwaCertificates?.records?[indexPath.row], showValue: showValues, hideDelete: shouldHideDelete)
        cell.layoutIfNeeded()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.width
        pwaPagerView.pageControll.currentPage = Int((scrollView.contentOffset.x + (0.5 * pageWidth)) / pageWidth)
        selectedPWAIndex = pwaPagerView.pageControll.currentPage
        setIssuedDate()
    }
}

//extension CertificateViewController: ConnectionDetailHeaderViewDelegate {
//    
//    
//    func getHeaderFetchedImage(image: UIImage) {
//        let dominantClr = image.getDominantColor()
//        let isLight = dominantClr.isLight()
//        let color = isLight ?? false ? UIColor.black : UIColor.white
//        connectionHeaderView.addGradient(color: color)
//        imageLightValue = isLight
//    }
//      
//}

extension CertificateViewController: BottomSheetHeaderViewDelegate {
    
    func eyeButtonAction(showValue: Bool) {
        self.showValues = showValue
        self.tableView.reloadInMain()
        self.collectionView.reloadInMain()
    }
    
    
    func closeAction() {
        self.dismiss(animated: true)
        //self.navigationController?.popViewController(animated: true)
    }
    
    
}
