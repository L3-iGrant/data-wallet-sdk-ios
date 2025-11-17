//
//  ExchangeDataListViewController.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 14/12/20.
//

import UIKit

class NotificationListViewController: AriesBaseViewController {
    
    @IBOutlet public weak var tableView: UITableView!
    @IBOutlet weak var bottomSheetHeaderView: UIView!
    
    @IBOutlet weak var bottomSheetHeaderHeight: NSLayoutConstraint!
    
    var viewModel : NotificationsListViewModel?
    var navHandler: NavigationHandler!
    var viewMode: ViewMode = .FullScreen

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        viewModel = NotificationsListViewModel.init(walletHandle: WalletViewModel.openedWalletHandler)
        fetchAllnotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchAllnotifications), name: Constants.didRecieveCertOffer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchAllnotifications), name: Constants.didReceiveDataExchangeRequest, object: nil)
        self.title = "Notification".localizedForSDK()
        if viewMode == .BottomSheet {
            bottomSheetHeaderView.isHidden = false
            bottomSheetHeaderHeight.constant = 50
        } else {
            bottomSheetHeaderView.isHidden = true
            bottomSheetHeaderHeight.constant = 0
        }
        setNav()
    }
    
    @objc func fetchAllnotifications(){
        viewModel?.fetchNotifications(completion: {[weak self] (success) in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        })
    }
    
    private func setNav() {
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(title: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchAllnotifications()
    }
    
    override func localizableValues() {
        super.localizableValues()
        self.title = "Notifications".localizedForSDK()
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
}

extension NotificationListViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier:"NotificationTableViewCell",for: indexPath) as! NotificationTableViewCell
        
        let inboxData = viewModel?.notifications?[indexPath.row]
        let type = inboxData?.value?.type
        cell.notificationStatus.isHidden = true
        if type == InboxType.certOffer.rawValue {
            let offer = inboxData?.value?.offerCredential
            let schemeSeperated = offer?.value?.schemaID?.split(separator: ":")
            cell.certName?.text = "\(schemeSeperated?[2] ?? "")"
            cell.notificationType.text = "Data agreement".localizedForSDK()
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            if let notifDate = dateFormat.date(from: offer?.value?.updatedAt ?? "") {
                cell.time.text = notifDate.timeAgoDisplay()
            }
            if(inboxData?.tags?.state != "offer_received"){
                cell.notificationStatus.isHidden = false
//                cell.notificationStatus.text = "Processing"
            }
        } else if type == InboxType.certRequest.rawValue{
            let req = inboxData?.value?.presentationRequest
            cell.certName?.text = req?.value?.presentationRequest?.name ?? ""
            cell.notificationType.text = "Data exchange".localizedForSDK()
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            if let notifDate = dateFormat.date(from: req?.value?.updatedAt ?? "") {
                cell.time.text = notifDate.timeAgoDisplay()
            }
        } else {
            cell.certName?.text = inboxData?.value?.walletRecordCertModel?.searchableText ?? ""
            cell.notificationType.text = "Data agreement".localizedForSDK()
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            if let epochTime = Int(inboxData?.value?.walletRecordCertModel?.addedDate ?? ""){
             let notifDate = Date.init(timeIntervalSince1970: TimeInterval(epochTime))
                cell.time.text = notifDate.timeAgoDisplay()
            }
            if(inboxData?.tags?.state != "offer_received"){
                cell.notificationStatus.isHidden = false
            }
        }
       
        var imageUrl: String? = nil
       
            imageUrl = inboxData?.value?.walletRecordCertModel?.logo ?? (inboxData?.value?.connectionModel?.value?.orgDetails?.logoImageURL ?? "")
        
        let orgName = inboxData?.value?.connectionModel?.value?.orgDetails?.name ?? ""
        let bgColor = inboxData?.value?.walletRecordCertModel?.backgroundColor
        ImageUtils.shared.setRemoteImage(for: cell.orgImage, imageUrl: imageUrl, orgName: orgName, bgColor: bgColor)
       // UIApplicationUtils.shared.setRemoteImageOn(cell.orgImage, url: inboxData?.value?.connectionModel?.value?.imageURL ?? "")
        cell.shadowView.layer.cornerRadius = 10
//        cell.shadowView.layer.shadowColor = UIColor.lightGray.cgColor
//        cell.shadowView.layer.shadowOpacity = 0.5
//        cell.shadowView.layer.shadowOffset = .zero
//        cell.shadowView.layer.shadowRadius = 5
        cell.selectionStyle = .none
        if indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
            cell.separatorInset = UIEdgeInsets(top: 0, left: cell.bounds.size.width , bottom: 0, right: 0)
        }else{
            cell.separatorInset = UIEdgeInsets.zero
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel?.notifications?.count ?? 0 == 0 {
            self.tableView.setEmptyMessage("No new notification available".localizedForSDK())
        } else {
            self.tableView.restore()
        }
        return viewModel?.notifications?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let inboxData = viewModel?.notifications?[indexPath.row]
        let type = inboxData?.value?.type
        if type == InboxType.certOffer.rawValue {
            let offer = inboxData?.value?.offerCredential
           
            if let controller = UIStoryboard(name:"ama-ios-sdk", bundle: UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "CertificatePreviewViewController") as? CertificatePreviewViewController {
                if let model = offer, let receiptModel = ReceiptCredentialModel.isReceiptCredentialModel(certModel: model){
                    //Show Receipt UI
                    controller.mode = .Receipt(model: receiptModel)
                }
                controller.viewModel = CertificatePreviewViewModel.init(walletHandle: viewModel?.walletHandle, reqId: inboxData?.value?.connectionModel?.id ?? "", certDetail: offer, inboxId: inboxData?.id,connectionModel: inboxData?.value?.connectionModel, dataAgreement: inboxData?.value?.dataAgreement)
                controller.viewModel?.inboxModel = inboxData
                controller.inboxCertState = inboxData?.tags?.state
               
                if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
                    let vc = CertificatePreviewBottomSheet(nibName: "CertificatePreviewBottomSheet", bundle: UIApplicationUtils.shared.getResourcesBundle())
                    if let model = offer, let receiptModel = ReceiptCredentialModel.isReceiptCredentialModel(certModel: model){
                        //Show Receipt UI
                        vc.mode = .Receipt(model: receiptModel)
                    }
                    vc.viewModel = CertificatePreviewViewModel.init(walletHandle: viewModel?.walletHandle, reqId: inboxData?.value?.connectionModel?.id ?? "", certDetail: offer, inboxId: inboxData?.id,connectionModel: inboxData?.value?.connectionModel, dataAgreement: inboxData?.value?.dataAgreement)
                    vc.viewModel?.inboxModel = inboxData
                    vc.inboxCertState = inboxData?.tags?.state
                    let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                    sheetVC.onDismiss = { [weak self] in
                        self?.fetchAllnotifications()
                    }
                    if let topVC = UIApplicationUtils.shared.getTopVC() {
                        topVC.present(sheetVC, animated: true, completion: nil)
                    }
                } else {
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            }
        } else if type == InboxType.certRequest.rawValue{
            let req = inboxData?.value?.presentationRequest
            if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "ExchangeDataPreviewViewController") as? ExchangeDataPreviewViewController {
                controller.viewModel = ExchangeDataPreviewViewModel.init(walletHandle: viewModel?.walletHandle, reqDetail: req, inboxId: inboxData?.id,connectionModel:inboxData?.value?.connectionModel, QR_ID: req?.value?.QR_ID ?? "", dataAgreementContext: inboxData?.value?.dataAgreement)
                self.navigationController?.pushViewController(controller, animated: true)
            }
        } else {
            if let controller = UIStoryboard(name:"ama-ios-sdk", bundle: UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "CertificatePreviewViewController") as? CertificatePreviewViewController {
                var searchModel = SearchItems_CustomWalletRecordCertModel.init()
                searchModel.value = inboxData?.value?.walletRecordCertModel
                if inboxData?.value?.walletRecordCertModel?.fundingSource != nil {
                    if viewMode == .BottomSheet {
                        let vc = PWAPreviewBottomSheet(nibName: "PWAPreviewBottomSheet", bundle: Bundle.module)
                        UIApplicationUtils.hideLoader()
                        vc.viewModel = PWAPreviewViewModel.init(walletHandle: WalletViewModel.openedWalletHandler, reqId: "", certDetail: nil, inboxId: inboxData?.id, certModel: searchModel, connectionModel: inboxData?.value?.connectionModel, dataAgreement: nil, fundingSource: inboxData?.value?.walletRecordCertModel?.fundingSource)
                        vc.viewModel?.inboxModel = inboxData
                        vc.modalPresentationStyle = .overCurrentContext
                        vc.onDismiss = { [weak self] in
                            self?.fetchAllnotifications()
                        }
                        let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                        if let topVC = UIApplicationUtils.shared.getTopVC() {
                            topVC.present(sheetVC, animated: true, completion: nil)
                        }
                    } else {
                        let vc = PWAPreviewViewController(nibName: "PWAPreviewViewController", bundle: UIApplicationUtils.shared.getResourcesBundle())
                        if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                            UIApplicationUtils.hideLoader()
                            vc.viewModel = PWAPreviewViewModel.init(walletHandle: WalletViewModel.openedWalletHandler, reqId: "", certDetail: nil, inboxId: inboxData?.id, certModel: searchModel, connectionModel: inboxData?.value?.connectionModel, dataAgreement: nil, fundingSource: inboxData?.value?.walletRecordCertModel?.fundingSource)
                            vc.viewModel?.inboxModel = inboxData
                            self.navigationItem.backButtonTitle = ""
                            self.navigationController?.navigationBar.tintColor = .black
                            navVC.pushViewController(vc, animated: true)
                        } else {
                            UIApplicationUtils.hideLoader()
                            UIApplicationUtils.shared.getTopVC()?.push(vc: vc)
                        }
                    }
                } else if inboxData?.value?.walletRecordCertModel?.receiptData != nil {
                    if viewMode == .BottomSheet {
                        let vc = ReceiptBottomSheetVC(nibName: "ReceiptBottomSheetVC", bundle: UIApplicationUtils.shared.getResourcesBundle())
                        vc.viewModel.certModel = searchModel
                        vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                        vc.viewModel.connectionModel = inboxData?.value?.connectionModel
                        vc.viewModel.inboxId = inboxData?.id
                        let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                        vc.modalPresentationStyle = .overCurrentContext
                        sheetVC.onDismiss = { [weak self] in
                            self?.fetchAllnotifications()
                        }
                        if let topVC = UIApplicationUtils.shared.getTopVC() {
                            topVC.present(sheetVC, animated: false, completion: nil)
                        }
                    } else {
                        let vc = ReceiptViewController(nibName: "ReceiptViewController", bundle: UIApplicationUtils.shared.getResourcesBundle())
                        vc.viewModel.certModel = searchModel
                        vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                        vc.viewModel.connectionModel = inboxData?.value?.connectionModel
                        vc.viewModel.inboxId = inboxData?.id
                        vc.modalPresentationStyle = .fullScreen
                        
                        if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                            UIApplicationUtils.hideLoader()
                            self.navigationItem.backButtonTitle = ""
                            self.navigationController?.navigationBar.tintColor = .black
                            navVC.pushViewController(vc, animated: true)
                        } else {
                            UIApplicationUtils.hideLoader()
                            UIApplicationUtils.shared.getTopVC()?.push(vc: vc)
                        }
                    }
                } else if inboxData?.value?.walletRecordCertModel?.vct == "VerifiableFerryBoardingPassCredentialSDJWT" {
                    if viewMode == .BottomSheet {
                        let vc = BoardingPassBottomSheetVC(nibName: "BoardingPassBottomSheetVC", bundle: UIApplicationUtils.shared.getResourcesBundle())
                        vc.viewModel.certModel = searchModel
                        vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                        vc.viewModel.connectionModel = inboxData?.value?.connectionModel
                        vc.viewModel.inboxId = inboxData?.id
                        let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                        sheetVC.modalPresentationStyle = .overCurrentContext
                        sheetVC.onDismiss = { [weak self] in
                            self?.fetchAllnotifications()
                        }
                        if let topVC = UIApplicationUtils.shared.getTopVC() {
                            topVC.present(sheetVC, animated: false, completion: nil)
                        }
                    } else {
                        let vc = BoardingPassViewController(nibName: "BoardingPassViewController", bundle: UIApplicationUtils.shared.getResourcesBundle())
                        vc.viewModel.certModel = searchModel
                        vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                        vc.viewModel.connectionModel = inboxData?.value?.connectionModel
                        vc.viewModel.inboxId = inboxData?.id
                        vc.modalPresentationStyle = .fullScreen
                        if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                            UIApplicationUtils.hideLoader()
                            self.navigationItem.backButtonTitle = ""
                            self.navigationController?.navigationBar.tintColor = .black
                            navVC.pushViewController(vc, animated: true)
                        } else {
                            UIApplicationUtils.hideLoader()
                            UIApplicationUtils.shared.getTopVC()?.push(vc: vc)
                        }
                    }
                } else {
                    if viewMode == .BottomSheet {
                        let controller = CertificatePreviewBottomSheet(nibName: "CertificatePreviewBottomSheet", bundle: UIApplicationUtils.shared.getResourcesBundle())
                        controller.viewModel = CertificatePreviewViewModel.init(walletHandle: viewModel?.walletHandle, reqId: inboxData?.value?.connectionModel?.id ?? "", certDetail: nil, inboxId: inboxData?.id, certModel: searchModel, connectionModel: inboxData?.value?.connectionModel, dataAgreement: nil)
                        controller.mode = .EBSI_V2
                        if inboxData?.value?.walletRecordCertModel?.subType == EBSI_CredentialType.PDA1.rawValue || inboxData?.value?.walletRecordCertModel?.subType == EBSI_CredentialType.PWA.rawValue {
                            controller.mode = .EBSI_PDA1
                        } else if inboxData?.value?.walletRecordCertModel?.subType == EBSI_CredentialType.PhotoIDWithAge.rawValue {
                            controller.mode = .PhotoIDWithAgeBadge
                        }
                        controller.viewModel?.inboxModel = inboxData
                        controller.viewMode = .BottomSheet
                        controller.inboxCertState = inboxData?.tags?.state
                        let sheetVC = WalletHomeBottomSheetViewController(contentViewController: controller)
                        sheetVC.onDismiss = { [weak self] in
                            self?.fetchAllnotifications()
                        }
                        if let topVC = UIApplicationUtils.shared.getTopVC() {
                            topVC.present(sheetVC, animated: false, completion: nil)
                        }
                    } else {
                        controller.viewModel = CertificatePreviewViewModel.init(walletHandle: viewModel?.walletHandle, reqId: inboxData?.value?.connectionModel?.id ?? "", certDetail: nil, inboxId: inboxData?.id, certModel: searchModel, connectionModel: inboxData?.value?.connectionModel, dataAgreement: nil)
                        controller.mode = .EBSI_V2
                        if inboxData?.value?.walletRecordCertModel?.subType == EBSI_CredentialType.PDA1.rawValue {
                            controller.mode = .EBSI_PDA1
                        }
                        controller.viewModel?.inboxModel = inboxData
                        controller.inboxCertState = inboxData?.tags?.state
                        self.navigationController?.pushViewController(controller, animated: true)
                    }
                }
            }
        }
    }
}

extension NotificationListViewController: NavigationHandlerProtocol {
    func rightTapped(tag: Int) {}
}
