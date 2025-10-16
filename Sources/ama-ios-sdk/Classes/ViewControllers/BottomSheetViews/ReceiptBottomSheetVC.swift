//
//  ReceiptViewController.swift
//  dataWallet
//
//  Created by iGrant on 13/05/25.
//

import Foundation
import eudiWalletOidcIos
import UIKit


final class ReceiptBottomSheetVC: UIViewController, CustomNavigationBarIconViewDelegate, NavigationHandlerProtocol {
    
    func rightTapped(tag: Int) {
        blurStatus = !blurStatus
        addCustomBackTabIcon()
        if viewModel.originatingFrom == .detail || viewModel.originatingFrom == .history {
            addRightBarButtonForOther()
        } else {
            addRightBarButton()
        }
        self.tableView.reloadInMain()
    }
    
    
    func cusNavtappedAction(tag: Int) {
        switch tag {
        case 1:
            self.blurStatus.toggle()
            self.updateNavigationContent()
        default:
            self.returnBack()
        }
    }
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var orgImageView: UIImageView!
    @IBOutlet weak var orgNameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var eyeButton: UIButton!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var purchaseRecieptIdLabel: UILabel!
    @IBOutlet weak var purchaseIssuedDateLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var trustOrganizationStackView: UIStackView!
    @IBOutlet weak var verifiedImageView: UIImageView!
    @IBOutlet weak var trustedOrgLabel: UILabel!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    
    var blurStatus: Bool = false
    var viewModel = ReceiptItemViewModel()
    var onAccept: ((Bool) -> Void)?
    let backNavIcon = CustomNavigationBarIconView()
    let eyeNavIcon = CustomNavigationBarIconView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setOrgDetails()
        setText()
        addCustomBackTabIcon()
        updateEyeButtonImage()
        viewModel.delegate = self
        if viewModel.originatingFrom == .detail || viewModel.originatingFrom == .history {
            buttonView.isHidden = true
        }
        if viewModel.originatingFrom == .other {
            self.title = "general_data_agreement".localizedForSDK()
        }
        if viewModel.originatingFrom == .detail || viewModel.originatingFrom == .history {
            addRightBarButtonForOther()
            updateNavigationContent()
            trashButton.isHidden = true
        } else {
            trashButton.isHidden = false
            addRightBarButton()
        }
        setupTitleTexts()
        setUpColor()
        setTrustOrganization()
        updateCustomNavigationBar()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(trustServicetapped))
        self.trustOrganizationStackView.addGestureRecognizer(tapGesture)
    }
    
    func updateCustomNavigationBar(tint: UIColor = .black) {
        backNavIcon.containerView.isHidden = true
        eyeNavIcon.containerView.isHidden = true
        backNavIcon.iconImg.tintColor = tint
        eyeNavIcon.iconImg.tintColor = tint
    }
    
    func setTrustOrganization() {
        var isValidOrganization: Bool? = false
        if viewModel.originatingFrom == .detail {
            isValidOrganization = viewModel.certModel?.value?.connectionInfo?.value?.orgDetails?.isValidOrganization
        } else if viewModel.originatingFrom == .history {
            isValidOrganization = viewModel.histories?.value?.history?.connectionModel?.value?.orgDetails?.isValidOrganization
        } else {
            isValidOrganization = viewModel.connectionModel?.value?.orgDetails?.isValidOrganization
        }
        if let isValidOrganization = isValidOrganization {
            if isValidOrganization {
                trustOrganizationStackView.isHidden = false
                locationLabel.isHidden = true
                verifiedImageView.image = "gpp_good".getImage()
                verifiedImageView.tintColor = UIColor(hex: "1EAA61")
                trustedOrgLabel.textColor = UIColor(hex: "1EAA61")
                trustedOrgLabel.text = "general_trusted_service_provider".localizedForSDK()
            } else {
                trustOrganizationStackView.isHidden = false
                locationLabel.isHidden = true
                verifiedImageView.image = "gpp_bad".getImage()
                verifiedImageView.tintColor = .systemRed
                trustedOrgLabel.textColor = .systemRed
                trustedOrgLabel.text = "general_untrusted_service_provider".localizedForSDK()
            }
        } else {
            trustOrganizationStackView.isHidden = true
            locationLabel.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if viewModel.originatingFrom == .history {
            navigationController?.navigationBar.tintColor = viewModel.histories?.value?.history?.display?.textColor != nil ? UIColor(hex: (viewModel.histories?.value?.history?.display?.textColor)!) : UIColor.darkGray
            navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: viewModel.histories?.value?.history?.display?.textColor != nil ? UIColor(hex: (viewModel.histories?.value?.history?.display?.textColor)!) : UIColor.darkGray
            ]
        } else {
            navigationController?.navigationBar.tintColor = viewModel.certModel?.value?.textColor != nil ? UIColor(hex: viewModel.certModel!.value!.textColor!) : UIColor.darkGray
            navigationController?.navigationBar.titleTextAttributes = [
                .foregroundColor: viewModel.certModel?.value?.textColor != nil ? UIColor(hex: viewModel.certModel!.value!.textColor!) : UIColor.darkGray
            ]
        }
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func showButtonAction(_ sender: Any) {
        blurStatus.toggle()
        updateEyeButtonImage()
        self.tableView.reloadData()
    }
    
    private func updateEyeButtonImage() {
        let config = UIImage.SymbolConfiguration(scale: .small)
        let imageName = blurStatus ? "eye.slash" : "eye"
        let image = UIImage(systemName: imageName, withConfiguration: config)
        showButton.setImage(image, for: .normal)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.tintColor =  UIColor.darkGray
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor:  UIColor.darkGray
        ]
        if !(viewModel.isRejectOrAcceptTapped) && viewModel.inboxId == nil {
            if let accept = onAccept {
                accept(true)
            }
        }
    }
    
    @objc func tappedOnEyeButton(){
        blurStatus = !blurStatus
        if viewModel.originatingFrom == .detail || viewModel.originatingFrom == .history {
            addRightBarButtonForOther()
        } else {
            addRightBarButton()
        }
        self.tableView.reloadData()
    }
    
    private func updateNavigationContent() {
        if !self.blurStatus {
            eyeNavIcon.iconImg.image = "eye".getImage()
        } else {
            eyeNavIcon.iconImg.image = "eye.slash".getImage()
        }
        //addRightBarButton()
        self.tableView.reloadInMain()
    }
    
    @IBAction func trashButtonAction(_ sender: Any) {
        rejectButtonTapped()
    }
    
    
    func setupTitleTexts() {
        var receiptAddress: ReceiptAddress?
        if viewModel.originatingFrom == .history {
            receiptAddress = viewModel.histories?.value?.history?.receiptData?.address
            if let textColor = viewModel.histories?.value?.history?.display?.textColor {
                purchaseRecieptIdLabel.textColor = UIColor(hex: textColor)
                purchaseIssuedDateLabel.textColor = UIColor(hex: textColor)
            } else {
                purchaseRecieptIdLabel.textColor = .systemGray
                purchaseIssuedDateLabel.textColor = .systemGray
            }
            purchaseIssuedDateLabel.text = "receipt_receipt_issued_on".localizedForSDK() + " " + (viewModel.histories?.value?.history?.receiptData?.purchaseReceipt.issueDate ?? "")
            purchaseRecieptIdLabel.text = "receipt_purchase_receipt_id".localizedForSDK() + " " + (viewModel.histories?.value?.history?.receiptData?.purchaseReceipt.id ?? "")
        } else {
            receiptAddress = viewModel.certModel?.value?.receiptData?.address
            if let textColor = viewModel.certModel?.value?.textColor {
                purchaseIssuedDateLabel.textColor = UIColor(hex: textColor)
                purchaseRecieptIdLabel.textColor = UIColor(hex: textColor)
            } else {
                purchaseIssuedDateLabel.textColor = .systemGray
                purchaseRecieptIdLabel.textColor = .systemGray
            }
            purchaseIssuedDateLabel.text = "receipt_receipt_issued_on".localizedForSDK() + " " + (viewModel.certModel?.value?.receiptData?.purchaseReceipt.issueDate ?? "")
            purchaseRecieptIdLabel.text = "receipt_purchase_receipt_id".localizedForSDK() + " " + (viewModel.certModel?.value?.receiptData?.purchaseReceipt.id ?? "")
        }
        if let receiptAddress = receiptAddress {
            var parts: [String] = []

            if let name = receiptAddress.streetName, !name.isEmpty {
                parts.append(name)
            }
            if let name = receiptAddress.cityName, !name.isEmpty {
                parts.append(name)
            }

            var lastLineParts: [String] = []

            if let name = receiptAddress.postcode, !name.isEmpty {
                lastLineParts.append(name)
            }
            if let name = receiptAddress.countryIdentifier, !name.isEmpty {
                lastLineParts.append(name)
            }

            if !lastLineParts.isEmpty {
                parts.append(lastLineParts.joined(separator: " "))
            }

            let address = parts.joined(separator: ", ").trimmingCharacters(in: CharacterSet(charactersIn: ", "))
            addressLabel.text = address
        }
    }
    
    @objc func trustServicetapped() {
        var credential: String?
        var jwks: String?
        if viewModel.originatingFrom == .detail {
            credential = viewModel.certModel?.value?.EBSI_v2?.credentialJWT
            jwks = viewModel.certModel?.value?.connectionInfo?.value?.orgDetails?.jwksURL
        } else if viewModel.originatingFrom == .history {
            credential = viewModel.histories?.value?.history?.connectionModel?.value?.orgDetails?.x5c
            jwks = viewModel.histories?.value?.history?.connectionModel?.value?.orgDetails?.jwksURL
        } else {
            credential = viewModel.connectionModel?.value?.orgDetails?.x5c
            jwks = viewModel.connectionModel?.value?.orgDetails?.jwksURL
        }
        
        TrustMechanismManager().trustProviderInfo(credential: credential, format: "", jwksURI: jwks) { data in
            if let data = data {
                DispatchQueue.main.async {
                    let vc = TrustServiceProviersBottomSheetVC(nibName: "TrustServiceProviersBottomSheetVC", bundle: nil)
                    vc.modalPresentationStyle = .overFullScreen
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
        if viewModel.originatingFrom == .history {
            if let bgColor = viewModel.histories?.value?.history?.display?.backgroundColor {
                view.backgroundColor = UIColor(hex: bgColor)
            }
            if let textColor = viewModel.histories?.value?.history?.display?.textColor {
                orgNameLabel.textColor = UIColor(hex: textColor)
                locationLabel.textColor = UIColor(hex: textColor)
                acceptButton.layer.borderWidth = 1
                acceptButton.layer.borderColor = UIColor(hex: textColor).cgColor
            }

        } else {
            if let bgColor = viewModel.certModel?.value?.backgroundColor {
                view.backgroundColor = UIColor(hex: bgColor)
            }
            if let textColor = viewModel.certModel?.value?.textColor {
                orgNameLabel.textColor = UIColor(hex: textColor)
                locationLabel.textColor = UIColor(hex: textColor)
                acceptButton.layer.borderWidth = 1
                acceptButton.layer.borderColor = UIColor(hex: textColor).cgColor
            }
        }
    }
    
    @objc func rejectButtonTapped() {
        let alert = UIAlertController(title: "Data Wallet", message: "connect_are_you_sure_you_want_to_delete_this_item".localizedForSDK(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "general_yes".localizedForSDK(), style: .default, handler: { [self] action in
            self.viewModel.rejectCertificate()
            if let accept = onAccept {
                accept(true)
            }
            
            Task {
                if let notificationEndPont = viewModel.certModel?.value?.notificationEndPont, let notificationID = viewModel.certModel?.value?.notificationID {
                    let accessTokenParts = viewModel.certModel?.value?.accessToken?.split(separator: ".")
                    var accessTokenData: String? =  nil
                    var refreshTokenData: String? =  nil
                    if accessTokenParts?.count ?? 0 > 1 {
                        let accessTokenBody = "\(accessTokenParts?[1] ?? "")".decodeBase64()
                        let dict = UIApplicationUtils.shared.convertToDictionary(text: String(accessTokenBody ?? "{}")) ?? [:]
                        let exp = dict["exp"] as? Int ?? 0
                        let expiryDate = TimeInterval(exp)
                        let currentTimestamp = Date().timeIntervalSince1970
                        if expiryDate < currentTimestamp {
                            accessTokenData = await NotificationService().refreshAccessToken(refreshToken: viewModel.certModel?.value?.refreshToken ?? "", endPoint: viewModel.certModel?.value?.tokenEndPoint ?? "").0
                            refreshTokenData = await NotificationService().refreshAccessToken(refreshToken: viewModel.certModel?.value?.refreshToken ?? "", endPoint: viewModel.certModel?.value?.tokenEndPoint ?? "").1
                        } else {
                            accessTokenData = viewModel.certModel?.value?.accessToken
                            refreshTokenData = viewModel.certModel?.value?.refreshToken
                        }
                    }
                    viewModel.certModel?.value?.refreshToken = refreshTokenData
                    viewModel.certModel?.value?.accessToken = accessTokenData
                    await NotificationService().sendNoticationStatus(endPoint: viewModel.certModel?.value?.notificationEndPont, event: NotificationStatus.credentialDeleted.rawValue, notificationID: viewModel.certModel?.value?.notificationID, accessToken: viewModel.certModel?.value?.accessToken ?? "", refreshToken: viewModel.certModel?.value?.refreshToken ?? "", tokenEndPoint: viewModel.certModel?.value?.tokenEndPoint ?? "")
                }
            }
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "general_no".localizedForSDK(), style: .default, handler: { action in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func addRightBarButton() {
        let eyeButton = UIButton(type: .custom)
        eyeButton.setImage(!blurStatus ? "eye".getImage() : "eye.slash".getImage(), for: .normal)
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
        deleteButton.addTarget(self, action: #selector(rejectButtonTapped), for: .touchUpInside)
        let barButton2 = UIBarButtonItem(customView: deleteButton)
        let currWidth2 = barButton2.customView?.widthAnchor.constraint(equalToConstant: 30)
        currWidth2?.isActive = true
        let currHeight2 = barButton2.customView?.heightAnchor.constraint(equalToConstant: 25)
        currHeight2?.isActive = true
        
        self.navigationItem.rightBarButtonItems = [barButton2,barButton]
    }
    
    private func addCustomBackTabIcon() {
        backNavIcon.tag = 0
        backNavIcon.frame = CGRect(x: 0, y: 0, width: self.topAreaHeight, height: self.topAreaHeight)
        let barbtnItem = UIBarButtonItem(customView: backNavIcon)
        backNavIcon.delegate = self
        self.navigationItem.leftBarButtonItem = barbtnItem
    }
    
    func addRightBarButtonForOther() {
        eyeNavIcon.tag = 1
        eyeNavIcon.frame = CGRect(x: 0, y: 0, width: self.topAreaHeight, height: self.topAreaHeight)
        let barbtnItem = UIBarButtonItem(customView: eyeNavIcon)
        eyeNavIcon.delegate = self
        eyeNavIcon.updateImageHeight(update: 5)
        //eyeNavIcon.setRight(constant: 5)
        self.navigationItem.rightBarButtonItem = barbtnItem
    }

    
    func setText() {
        acceptButton.layer.cornerRadius = 25
        acceptButton.setTitle("general_accept".localizedForSDK(), for: .normal)
        acceptButton.backgroundColor = AriesMobileAgent.themeColor
    }
    
    func setOrgDetails() {
        orgImageView.layer.cornerRadius = 35
        if viewModel.originatingFrom == .detail || viewModel.originatingFrom == .other {
            let imageUrl = viewModel.certModel?.value?.logo ?? viewModel.certModel?.value?.connectionInfo?.value?.orgDetails?.logoImageURL
            let orgName = viewModel.certModel?.value?.connectionInfo?.value?.orgDetails?.name
            let bgColor = viewModel.certModel?.value?.backgroundColor
            ImageUtils.shared.setRemoteImage(for: orgImageView, imageUrl: imageUrl, orgName: orgName, bgColor: bgColor)
            self.orgNameLabel.text = viewModel.certModel?.value?.connectionInfo?.value?.orgDetails?.name ??
            (viewModel.connectionModel?.value?.theirLabel ?? "")
            self.locationLabel.text = viewModel.connectionModel?.value?.orgDetails?.location ??  viewModel.certModel?.value?.connectionInfo?.value?.orgDetails?.location ?? ""
        } else {
            if let value = viewModel.histories?.value?.history?.connectionModel?.value?.orgDetails {
                let imageURL = viewModel.histories?.value?.history?.display?.logo ?? value.logoImageURL
                let orgName = value.name
                var bgColour = viewModel.histories?.value?.history?.display?.backgroundColor
                ImageUtils.shared.setRemoteImage(for: orgImageView, imageUrl: imageURL, orgName: orgName, bgColor: bgColour)
                let title = value.name ?? viewModel.histories?.value?.history?.connectionModel?.value?.theirLabel ?? ""
                orgNameLabel.text = title
                locationLabel.text = value.location ?? ""
            }
        }
    }
    
    func deleteAction() {
        AlertHelper.shared.askConfirmationFromBottomSheet(on: self, message: "connect_are_you_sure_you_want_to_delete_this_item".localizedForSDK(), btn_title: ["general_yes".localizedForSDK(), "general_no".localizedForSDK()], completion: { [weak self] row in
            switch row {
            case 0:
                self?.viewModel.deleteCredentialWith(id: self?.viewModel.certModel?.value?.referent?.referent ?? "", walletRecordId: self?.viewModel.certModel?.id ?? "")
            default:
                break
            }
        })
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
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
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
            button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 15),
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -15),
            button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            
            rightArrow.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            rightArrow.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -25),
            rightArrow.widthAnchor.constraint(equalToConstant: 20),
            rightArrow.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        if let textColor = viewModel.certModel?.value?.textColor {
            rightArrow.tintColor = UIColor(hex: textColor).withAlphaComponent(0.5)
            button.backgroundColor = UIColor(hex: textColor).withAlphaComponent(0.1)
            button.setTitleColor(UIColor(hex:textColor).withAlphaComponent(0.5), for: .normal)
        } else if let textColor = viewModel.histories?.value?.history?.display?.textColor {
            rightArrow.tintColor = UIColor(hex: textColor).withAlphaComponent(0.5)
            button.backgroundColor = UIColor(hex: textColor).withAlphaComponent(0.1)
            button.setTitleColor(UIColor(hex:textColor).withAlphaComponent(0.5), for: .normal)
        } else {
            rightArrow.tintColor = .darkGray
            button.alpha = 0.5
        }
        return containerView
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func acceptButtonTapped(_ sender: Any) {
        Task {
            await viewModel.acceptEBSI_V2_Certificate()
            if let accept = onAccept {
                accept(true)
            }
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: ValuesRowImageTableViewCell.self)
        tableView.register(cellType: ReceiptTableViewCell.self)
        tableView.register(cellType: IssuanceTimeTableViewCell.self)
        tableView.register(cellType: ReceiptTotalTableViewCell.self)

    }
}

extension ReceiptBottomSheetVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else {
            if viewModel.originatingFrom == .history || viewModel.originatingFrom == .detail {
                return 2
            } else {
                return 1
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(with: ReceiptTableViewCell.self, for: indexPath)
            if let textColor = viewModel.certModel?.value?.textColor {
                //cell.renderForCredentialBranding(clr: UIColor(hex: textColor))
            } else if let textColor = viewModel.histories?.value?.history?.display?.textColor {
               // cell.renderForCredentialBranding(clr: UIColor(hex: textColor))
            }
            if indexPath.row == 0 {
                cell.setHeader(blurStatus: true, isFromNewReceipt: true)
            } else if indexPath.row == 2 {
                let cell = tableView.dequeueReusableCell(with: ReceiptTotalTableViewCell.self, for: indexPath)
                cell.selectionStyle = .none
                if let textColor = viewModel.certModel?.value?.textColor {
                    cell.renderForCredentialBranding(clr: UIColor(hex: textColor))
                } else if let textColor = viewModel.histories?.value?.history?.display?.textColor {
                    cell.renderForCredentialBranding(clr: UIColor(hex: textColor))
                }
                if viewModel.originatingFrom == .history {
                    let currencyCode = viewModel.histories?.value?.history?.receiptData?.purchaseReceipt.documentCurrencyCode ?? "EUR"
                    let amount = viewModel.histories?.value?.history?.receiptData?.purchaseReceipt.purchaseReceiptLine.taxInclusiveLineExtensionAmount ?? ""
                    cell.setTotalInfo(amount: amount, percentage: viewModel.histories?.value?.history?.receiptData?.taxTotal.taxSubtotal.percent ?? "", taxAmount: viewModel.histories?.value?.history?.receiptData?.taxTotal.taxSubtotal.taxAmount ?? "", currency: currencyCode, blurStatus: blurStatus)
                } else {
                    let currencyCode = viewModel.certModel?.value?.receiptData?.purchaseReceipt.documentCurrencyCode ?? "EUR"
                    let amount = viewModel.certModel?.value?.receiptData?.purchaseReceipt.purchaseReceiptLine.taxInclusiveLineExtensionAmount ?? ""
                    cell.setTotalInfo(amount: amount, percentage: viewModel.certModel?.value?.receiptData?.taxTotal.taxSubtotal.percent ?? "", taxAmount: viewModel.certModel?.value?.receiptData?.taxTotal.taxSubtotal.taxAmount ?? "", currency: currencyCode, blurStatus: blurStatus)
                }
                return cell
            } else {
                if viewModel.originatingFrom == .history {
                    let currencyCode = viewModel.histories?.value?.history?.receiptData?.purchaseReceipt.documentCurrencyCode ?? "EUR"
                    cell.setDataForReciept(itemName: viewModel.histories?.value?.history?.receiptData?.purchaseReceipt.purchaseReceiptLine.item.commodityClassification.itemClassificationCode, blurStatus: blurStatus, totalAmount: viewModel.histories?.value?.history?.receiptData?.purchaseReceipt.purchaseReceiptLine.taxInclusiveLineExtensionAmount ?? "", qty: viewModel.histories?.value?.history?.receiptData?.purchaseReceipt.purchaseReceiptLine.quantity, currency: currencyCode)
                } else {
                    let currencyCode = viewModel.certModel?.value?.receiptData?.purchaseReceipt.documentCurrencyCode ?? "EUR"
                    cell.setDataForReciept(itemName: viewModel.certModel?.value?.receiptData?.purchaseReceipt.purchaseReceiptLine.item.commodityClassification.itemClassificationCode, blurStatus: blurStatus, totalAmount: viewModel.certModel?.value?.receiptData?.purchaseReceipt.purchaseReceiptLine.taxInclusiveLineExtensionAmount ?? "", qty: viewModel.certModel?.value?.receiptData?.purchaseReceipt.purchaseReceiptLine.quantity, currency: currencyCode)
                }
            }
           
            cell.renderUI(index: indexPath.row, tot: 3)
            cell.layoutIfNeeded()
            return cell
        } else {
            if indexPath.row == 1 {
                let cell = tableView.dequeueReusableCell(with: IssuanceTimeTableViewCell.self, for: indexPath)
                cell.selectionStyle = .none
                let dateFormat = DateFormatter.init()
                if viewModel.originatingFrom == .detail {
                    if let unixTimestamp = TimeInterval(viewModel.certModel?.value?.addedDate ?? "") {
                        let date = Date(timeIntervalSince1970: unixTimestamp)
                        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        let dateString = dateFormat.string(from: date)
                        let formattedDate = dateFormat.date(from: dateString)
                        if let bgColor = viewModel.certModel?.value?.textColor  {
                            cell.setTextColor(colour: UIColor(hex: bgColor) )
                        }
                        cell.setData(text: formattedDate?.timeAgoDisplay() ?? "", data: viewModel.certModel?.value, isFromExpired: viewModel.isFromExpired)
                    }
                } else if viewModel.originatingFrom == .history {
                    let dateFormats = ["yyyy-MM-dd hh:mm:ss.SSSSSS a'Z'", "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"]
                    let historyDate = DateUtils.shared.parseDate(from: viewModel.histories?.value?.history?.date ?? "", formats: dateFormats)
                    if let notifDate = historyDate {
                        // Setting text color based on credential branding
                        if self.viewModel.histories?.value?.history?.display?.textColor != nil {
                            cell.setTextColor(colour: UIColor(hex: self.viewModel.histories?.value?.history?.display?.textColor ?? ""))
                        }
                        cell.setData(text: notifDate.timeAgoDisplay(), isFromExchange: viewModel.histories?.value?.history?.type == HistoryType.exchange.rawValue)
                    }
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
                cell.renderUI(index: indexPath.row, tot: 1)
                cell.mainLbl.text = "receipt_additional_details".localizedForSDK()
                cell.blurView.isHidden = true
                if let textColor = viewModel.certModel?.value?.textColor {
                    cell.renderForCredentialBranding(clr: UIColor(hex: textColor))
                } else if let textColor = viewModel.histories?.value?.history?.display?.textColor {
                    cell.renderForCredentialBranding(clr: UIColor(hex: textColor))
                }
                cell.disableCheckBox()
                cell.rightImage = UIImage(systemName: "chevron.right")
                cell.rightImageView.tintColor = .darkGray
                cell.layoutIfNeeded()
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            viewModel.isRejectOrAcceptTapped = true
            let vc = PKPassAdditionalDetailViewController()
            var bgColor: UIColor?
            var textColor: UIColor?
            if let color = viewModel.certModel?.value?.backgroundColor {
                bgColor = UIColor(hex: color)
            } else if let color = viewModel.histories?.value?.history?.display?.backgroundColor {
                bgColor = UIColor(hex: color)
            }
            if let color = viewModel.certModel?.value?.textColor {
                textColor = UIColor(hex: color)
            } else if let color = viewModel.histories?.value?.history?.display?.textColor {
                textColor = UIColor(hex: color)
            }
            vc.bgColor = bgColor ?? UIColor.appColor(.walletBg)
            vc.labelColor = textColor
            //vc.delegate = self
            if viewModel.originatingFrom == .history {
                vc.backFieldArray = self.viewModel.histories?.value?.history?.attributes ?? []
            } else {
                vc.backFieldArray = self.viewModel.certModel?.value?.EBSI_v2?.attributes ?? []
            }
            self.present(vc: vc)
        }
    }
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        if section == 0 {
//            let headerView = UIView()
//            let label = UILabel()
//            let label2 = UILabel()
//            label2.font = UIFont.systemFont(ofSize: 14)
//            if viewModel.originatingFrom == .history {
//                if let textColor = viewModel.histories?.value?.history?.display?.textColor {
//                    label2.textColor = UIColor(hex: textColor)
//                    label.textColor = UIColor(hex: textColor)
//                } else {
//                    label2.textColor = .systemGray
//                    label.textColor = .systemGray
//                }
//                label2.text = "Receipt Issued on: \(viewModel.histories?.value?.history?.receiptData?.purchaseReceipt.issueDate ?? "")"
//                label.text = "PURCHASE RECEIPT ID: \(viewModel.histories?.value?.history?.receiptData?.purchaseReceipt.id ?? "")"
//            } else {
//                if let textColor = viewModel.certModel?.value?.textColor {
//                    label2.textColor = UIColor(hex: textColor)
//                    label.textColor = UIColor(hex: textColor)
//                } else {
//                    label2.textColor = .systemGray
//                    label.textColor = .systemGray
//                }
//                label2.text = "Receipt Issued on: \(viewModel.certModel?.value?.receiptData?.purchaseReceipt.issueDate ?? "")"
//                label.text = "PURCHASE RECEIPT ID: \(viewModel.certModel?.value?.receiptData?.purchaseReceipt.id ?? "")"
//            }
//            label.font = UIFont.systemFont(ofSize: 16)
//            headerView.addSubview(label)
//
//            let stackView = UIStackView(arrangedSubviews: [label, label2])
//                    stackView.axis = .vertical
//                    stackView.spacing = 4
//                    stackView.translatesAutoresizingMaskIntoConstraints = false
//            headerView.addSubview(stackView)
//            NSLayoutConstraint.activate([
//                stackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
//                stackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -15),
//                stackView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
//                stackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
//            ])
//            return headerView
//        } else {
//            return nil
//        }
//    }
    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return CGFloat.leastNormalMagnitude
//
//    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if viewModel.originatingFrom == .detail && section == 1 {
            let view = RemoveBtnVew()
            view.tapAction = { [weak self] in
                self?.deleteAction()
            }
            if let color = viewModel.certModel?.value?.textColor {
                view.layerColor = UIColor(hex: color)
            }
            view.value = "data_remove_data_card".localizedForSDK()
            return view
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if viewModel.originatingFrom == .detail && section == 1 {
            return 65
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }

    
    
}

extension ReceiptBottomSheetVC: ReceiptItemViewModelDelegate {
    
    func dismiss() {
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }
    
    
}

//extension ReceiptBottomSheetVC: PKPassAdditionalDetailViewControllerDelegate {
//
//    func clearCache() {
//        viewModel.isRejectOrAcceptTapped = false
//    }
//
//
//}
