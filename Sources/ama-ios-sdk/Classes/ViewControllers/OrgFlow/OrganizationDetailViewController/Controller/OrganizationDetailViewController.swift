//
//  OrganizationDetailViewController.swift
//  dataWallet
//
//  Created by sreelekh N on 12/12/21.
//

import UIKit
import IndyCWrapper

protocol OrganizationDelegate: AnyObject {
    func tappedRow(index: IndexPath)
    func goBackAction()
    func reload()
}

final class OrganizationDetailViewController: AriesBaseViewController, CustomNavigationBarIconViewDelegate {
    
    func cusNavtappedAction(tag: Int) {
        switch tag {
        case 1:
            self.viewModel?.showData.toggle()
            self.updateNavigationContent()
            self.tableView.reloadInMain()
        default:
            self.returnBack()
        }
    }
    
    override var wx_navigationBarBackgroundColor: UIColor? {
        return .appColor(.walletBg)
    }
    var viewMode: ViewMode = .FullScreen
    let tableView = UITableView.getTableview()
    var headerView = OrganizationHeaderView()
//    var headerView: UIView {
//        if viewMode == .BottomSheet {
//            return BottomSheetHeaderView()
//        } else {
//            return OrganizationHeaderView()
//        }
//    }
    var bottomSheetHeaderView = BottomSheetHeaderView()
    var navHandler: NavigationHandler!
    
    var viewModel : OrganizationDetailViewModel?
    
    let navBarHeight: CGFloat = 44.0
    var changeNavAlphaHolder = true
    var positionOffset = UIScrollView()
    let headerHeight: CGFloat = 150
    
    let backNavIcon = CustomNavigationBarIconView()
    let eyeNavIcon = CustomNavigationBarIconView()
    let floatingBtn = ShareDataFloting()
    var headerName: String? = ""
    
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
        }
    }
    var initialLoad = true
    var pageTitle: String?
    
    override func loadView() {
        super.loadView()
        view.tupleViews(views: tableView)
        tableView.addAnchorFull(view)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellType: OverViewTableViewCell.self)
        tableView.register(cellType: RemoveBtnTableViewCell.self)
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: ValuesRowImageTableViewCell.self)
        tableView.register(cellType: NotificationTableViewCell.self)
        tableView.register(cellType: BlurredTextTableViewCell.self)
        tableView.register(cellType: IssuanceTimeTableViewCell.self)
        switch viewModel?.loadUIFor {
            case .receiptHistory:
                self.registerCellsForReceipt(tableView: tableView)
                self.tableView.estimatedSectionHeaderHeight = 20
            default: break
                
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        addToHeaderView()
        wx_navigationBar.alpha = 0.0
        viewModel?.pageDelegate = self
        
        addCustomBackTabIcon()
        didLoadRender()
        backNavIcon.updateForAlpha(alpha: 0.0)
        eyeNavIcon.updateForAlpha(alpha: 0.0)
        setCredentialColor()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    // Setting card color based on credential branding
    func setCredentialColor() {
        if let bgColor = viewModel?.history?.value?.history?.display?.backgroundColor {
            view.backgroundColor = UIColor(hex: bgColor)
        }
    }
    
    private func didLoadRender() {
        switch viewModel?.loadUIFor {
        case .history,.receiptHistory:
            self.setHeaderContent()
            self.addCustomEyeTabIcon()
            self.updateNavigationContent()
        case .genericCard:
            self.setHeaderContent()
            self.updateNavigationContent()
            self.addCustomEyeTabIcon()
            if self.viewModel?.homeData == nil {
                self.view.addSubview(floatingBtn)
                floatingBtn.addAnchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, paddingBottom: 25, width: 190, height: 60, centerX: view.centerXAnchor)
                floatingBtn.shareBtn.setTitle("Accept".localize, for: .normal)
                floatingBtn.shareBtn.setImage(nil, for: .normal)
                floatingBtn.delegate = self
            }
        case .EBSI:
            self.setHeaderContent()
            self.tableView.isHidden = false
            self.addCustomEyeTabIcon()
            self.updateNavigationContent()
        default:
            fetchData()
            tableView.isHidden = true
            NotificationCenter.default.addObserver(self, selector: #selector(fetchData), name: Constants.didRecieveCertOffer, object: nil)
        }
    }
    
    @objc func fetchData() {
        self.viewModel?.fetchCertificates(completion: { [weak self] success in
            if self?.viewModel?.initialLoad ?? false {
                self?.setHeaderContent()
                self?.tableView.isHidden = false
                self?.tableView.reloadInMain()
                UIApplicationUtils.hideLoader()
            } else {
                self?.viewModel?.initialLoad = true
            }
        })
    }
    
    override func localizableValues() {
        super.localizableValues()
        self.tableView.reloadInMain()
    }
    
    private func setHeaderContent() {
        if let model = viewModel {
            if viewMode == .FullScreen {
                headerView.delegate = self
                headerView.setData(model: model)
            } else {
                bottomSheetHeaderView.bottomSheetDelegate = self
                bottomSheetHeaderView.setData(model: model)
            }
//            if let header = headerView as? OrganizationHeaderView {
//                header.delegate = self
//                header.setData(model: model)
//            } else if let header = headerView as? BottomSheetHeaderView {
//                header.delegate = self
//                header.setData(model: model)
//            }
        }
    }
    
    private func updateNavigationContent() {
        if !(self.viewModel?.showData ?? false) {
            eyeNavIcon.iconImg.image = "eye".getImage()
        } else {
            eyeNavIcon.iconImg.image = "eye.slash".getImage()
        }
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
}

extension OrganizationDetailViewController: ShareDataFlotingDelegate {
    func shareDataTapped() {
        switch self.viewModel?.loadUIFor {
        case .genericCard(model: let model):
            let customWalletModel = CustomWalletRecordCertModel.init()
            customWalletModel.referent = nil
            customWalletModel.schemaID = nil
            customWalletModel.certInfo = nil
            customWalletModel.connectionInfo = nil
            customWalletModel.type = model.type
            customWalletModel.subType = model.subType
            customWalletModel.searchableText = SelfAttestedCertTypes.generic.rawValue
            customWalletModel.passport = nil
            customWalletModel.generic = model
            
            WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, walletHandler: self.viewModel?.walletHandle ?? IndyHandle(), type: .walletCert ) { [weak self] success, id, error in
                debugPrint("historySaved -- \(success)")
                self?.popToRoot()
            }
        default:
            break
        }
        
    }
    
    func deleteParkingCirtificate() {
        if let indy = self.viewModel?.walletHandle, let id = self.viewModel?.homeData?.id {
            AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: indy, type: AriesAgentFunctions.walletCertificates, id: id) { [weak self] (success, error) in
                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                self?.returnBack()
                NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
            }
        }
    }
}

extension OrganizationDetailViewController: BottomSheetHeaderViewDelegate {
    
    func eyeButtonAction(showValue: Bool) {
        self.viewModel?.showData = showValue
        tableView.reloadInMain()
    }
    
    
    func closeAction() {
        dismiss(animated: true)
    }
    
    
}
