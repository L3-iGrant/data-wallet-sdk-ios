//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 16/09/25.
//

import Foundation
import eudiWalletOidcIos
import UIKit

final class BoardingPassViewController: UIViewController, CustomNavigationBarIconViewDelegate, ValuesRowImageTableViewCellDelegate {
    
    func showImageDetail(image: UIImage?) {
        if let vc = ShowQRCodeViewController().initialize() as? ShowQRCodeViewController {
            vc.QRCodeImage = image
            self.present(vc: vc, transStyle: .crossDissolve, presentationStyle: .overCurrentContext)
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var buttonView: UIView!
    @IBOutlet weak var buttonViewHeight: NSLayoutConstraint!
        
    func cusNavtappedAction(tag: Int) {
        switch tag {
        case 1:
            self.blurStatus.toggle()
            self.updateNavigationContent()
        default:
            self.returnBack()
        }
    }
    
    var blurStatus: Bool = false
    let backNavIcon = CustomNavigationBarIconView()
    let eyeNavIcon = CustomNavigationBarIconView()
    var viewModel = BoardingPassViewModel()
    var onAccept: ((Bool) -> Void)?
    private var didAccept = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        viewModel.delegate = self
        updateCustomNavigationBar()
        setUpColor()
        if viewModel.originatingFrom == .detail || viewModel.originatingFrom == .history {
            addRightBarButtonForOther()
            updateNavigationContent()
        } else {
            addRightBarButton()
        }
        setText()
        if viewModel.originatingFrom == .detail || viewModel.originatingFrom == .history {
            buttonView.isHidden = true
            buttonViewHeight.constant = 0
        }
        self.title = "Boarding Pass".localized()
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
    
    func setUpColor() {
        if viewModel.originatingFrom == .history {
            if let bgColor = viewModel.histories?.value?.history?.display?.backgroundColor {
                view.backgroundColor = UIColor(hex: bgColor)
            }
            if let textColor = viewModel.histories?.value?.history?.display?.textColor {
                acceptButton.layer.borderWidth = 1
                acceptButton.layer.borderColor = UIColor(hex: textColor).cgColor
            }

        } else {
            if let bgColor = viewModel.certModel?.value?.backgroundColor {
                view.backgroundColor = UIColor(hex: bgColor)
            }
            if let textColor = viewModel.certModel?.value?.textColor {
                acceptButton.layer.borderWidth = 1
                acceptButton.layer.borderColor = UIColor(hex: textColor).cgColor
            }
        }
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: ValuesRowImageTableViewCell.self)
        tableView.register(cellType: BoardingPassDetailsTableViewCell.self)
        tableView.register(cellType: IssuanceTimeTableViewCell.self)
        tableView.register(cellType: BoardingPassArrivalandDepartureCell.self)
        tableView.register(cellType: PKPassQRTableViewCell.self)
        tableView.register(cellType: PhotoIDIssuerDetailsCell.self)
    }
    
    func setText() {
        acceptButton.layer.cornerRadius = 25
        acceptButton.setTitle("general_accept".localizedForSDK(), for: .normal)
        acceptButton.backgroundColor = AriesMobileAgent.themeColor
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
    
    @objc func tappedOnEyeButton(){
        blurStatus = !blurStatus
        if viewModel.originatingFrom == .detail || viewModel.originatingFrom == .history {
            addRightBarButtonForOther()
        } else {
            addRightBarButton()
        }
        self.tableView.reloadData()
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
    
    func addRightBarButtonForOther() {
        eyeNavIcon.tag = 1
        eyeNavIcon.frame = CGRect(x: 0, y: 0, width: self.topAreaHeight, height: self.topAreaHeight)
        let barbtnItem = UIBarButtonItem(customView: eyeNavIcon)
        eyeNavIcon.delegate = self
        eyeNavIcon.updateImageHeight(update: 5)
        //eyeNavIcon.setRight(constant: 5)
        self.navigationItem.rightBarButtonItem = barbtnItem
    }
    
    func deleteAction() {
        AlertHelper.shared.askConfirmationRandomButtons(message: "connect_are_you_sure_you_want_to_delete_this_item".localizedForSDK(), btn_title: ["general_yes".localizedForSDK(), "general_no".localizedForSDK()], completion: { [weak self] row in
            switch row {
            case 0:
                self?.viewModel.deleteCredentialWith(id: self?.viewModel.certModel?.value?.referent?.referent ?? "", walletRecordId: self?.viewModel.certModel?.id ?? "")
            default:
                break
            }
        })
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
    
    @IBAction func acceptButtonTapped(_ sender: Any) {
        Task {
            guard !didAccept else { return }
            didAccept = true
            await viewModel.acceptEBSI_V2_Certificate()
            if let accept = onAccept {
                accept(true)
            }
        }
    }
    
    func updateCustomNavigationBar(tint: UIColor = .black) {
        backNavIcon.containerView.isHidden = true
        eyeNavIcon.containerView.isHidden = true
        backNavIcon.iconImg.tintColor = .black
        eyeNavIcon.iconImg.tintColor = .black
    }
    
}

extension BoardingPassViewController : UITableViewDelegate, UITableViewDataSource {
    
    private var hasQRCode: Bool {
        let attributesArray = viewModel.originatingFrom == .history ?
            viewModel.histories?.value?.history?.attributes :
            viewModel.certModel?.value?.EBSI_v2?.attributes
        
        if let image = attributesArray?.first(where: { $0.name == "ticket QR" }),
           EBSIWallet.shared.isBase64(string: image.value ?? "") {
            return true
        }
        return false
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        if viewModel.originatingFrom == .other && !hasQRCode {
            return 5
        }
        return 6
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return 3
        } else if section == 3 {
            return 2
        } else if section == 4 {
            if viewModel.originatingFrom == .detail || viewModel.originatingFrom == .history {
                return hasQRCode ? 2 : 1
            } else if viewModel.originatingFrom == .other {
                return  1
            }
        } else {
          return 1
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(with: BoardingPassDetailsTableViewCell.self, for: indexPath)
            let attributesArray = viewModel.originatingFrom == .history ? self.viewModel.histories?.value?.history?.attributes : viewModel.certModel?.value?.EBSI_v2?.attributes
            let seat = attributesArray?.first(where: { $0.name == "seat Number"})
            let type = attributesArray?.first(where: { $0.name == "seat Type"})
            if let textColor = viewModel.certModel?.value?.textColor  {
                cell.renderForCredebtialBranding(clr: UIColor(hex: textColor))
            } else if let textColor = viewModel.histories?.value?.history?.display?.textColor {
                cell.renderForCredebtialBranding(clr: UIColor(hex: textColor))
            }
            cell.selectionStyle = .none
            cell.updateCellData(imageData: viewModel.certModel?.value?.connectionInfo?.value?.orgDetails?.logoImageURL ?? viewModel.histories?.value?.history?.connectionModel?.value?.orgDetails?.logoImageURL, seat: seat?.value, type: type?.value)
            cell.layoutIfNeeded()
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(with: BoardingPassArrivalandDepartureCell.self, for: indexPath)
            let attributesArray = viewModel.originatingFrom == .history ? self.viewModel.histories?.value?.history?.attributes : viewModel.certModel?.value?.EBSI_v2?.attributes
            let arrivalDate = attributesArray?.first(where: { $0.name == "arrival Date"})
            let arrivalTime = attributesArray?.first(where: { $0.name == "arrival Time"})
            let arrivalDestination = attributesArray?.first(where: { $0.name == "arrival Port"})
            let departureTime = attributesArray?.first(where: { $0.name == "departure Time"})
            let departureDate = attributesArray?.first(where: { $0.name == "departure Date"})
            cell.updateCell(arrivalDate: arrivalDate?.value, arrivalTime: arrivalTime?.value, imageData: "", departureDate: departureDate?.value, departureTime: departureTime?.value, destination: arrivalDestination?.value)
            if let textColor = viewModel.certModel?.value?.textColor  {
                cell.renderForCredebtialBranding(clr: UIColor(hex: textColor))
            } else if let textColor = viewModel.histories?.value?.history?.display?.textColor {
                cell.renderForCredebtialBranding(clr: UIColor(hex: textColor))
            }
            cell.selectionStyle = .none
            cell.layoutIfNeeded()
            return cell
        } else if indexPath.section == 2 || indexPath.section == 3 {
            var attrArray: [IDCardAttributes] = []
            let attributesArray = viewModel.originatingFrom == .history ? self.viewModel.histories?.value?.history?.attributes : viewModel.certModel?.value?.EBSI_v2?.attributes
            if indexPath.section == 2 {
                if let ticketNumber = attributesArray?.first(where: { $0.name == "ticket Number"}) {
                    attrArray.append(ticketNumber)
                }
                if let ticketLet = attributesArray?.first(where: { $0.name == "ticket Let"}) {
                    attrArray.append(ticketLet)
                }
                if let vesselDescription = attributesArray?.first(where: { $0.name == "vessel Description"}) {
                    attrArray.append(vesselDescription)
                }
            } else if indexPath.section == 3 {
                if let firstName = attributesArray?.first(where: { $0.name == "first Name"}) {
                    attrArray.append(firstName)
                }
                if let lastName = attributesArray?.first(where: { $0.name == "last Name"}) {
                    attrArray.append(lastName)
                }
            }
            let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
            if let data = attrArray[safe: indexPath.row] {
                cell.setData(model: data, blurStatus: blurStatus)
                cell.renderUI(index: indexPath.row, tot: attrArray.count)
            }
            cell.arrangeStackForDataAgreement()
            if let textColor = viewModel.certModel?.value?.textColor {
                cell.renderForCredentialBranding(clr: UIColor(hex: textColor))
            } else if let textColor = viewModel.histories?.value?.history?.display?.textColor {
                cell.renderForCredentialBranding(clr: UIColor(hex: textColor))
            }
            cell.layoutIfNeeded()
            return cell
        } else if indexPath.section == 4 {
            
            if hasQRCode {
                if indexPath.row == 0 {
                    let attributesArray = viewModel.originatingFrom == .history ? self.viewModel.histories?.value?.history?.attributes : viewModel.certModel?.value?.EBSI_v2?.attributes
                    if let  image = attributesArray?.first(where: { $0.name == "ticket QR"}), EBSIWallet.shared.isBase64(string: image.value ?? "") {
                        let cell = tableView.dequeueReusableCell(with: PKPassQRTableViewCell.self, for: indexPath)
                        ImageUtils.shared.setRemoteImage(for: cell.QRCode, imageUrl: image.value, orgName: nil)
                        cell.delegate = self
                        cell.removeAdditionalData()
                        return cell
                    } else {
                        return UITableViewCell()
                    }
                } else {
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
                }
            } else {
                if viewModel.originatingFrom != .other {
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
                    let cell = tableView.dequeueReusableCell(with: PhotoIDIssuerDetailsCell.self, for: indexPath)
                    if viewModel.originatingFrom == .history {
                        cell.configureCell(value: viewModel.histories?.value?.history?.connectionModel?.value?.orgDetails)
                    } else {
                        cell.configureCell(value: viewModel.certModel?.value?.connectionInfo?.value?.orgDetails)
                    }
                    if let color = viewModel.certModel?.value?.textColor {
                        cell.renderForCredebtialBranding(clr: UIColor(hex: color))
                    } else if let textColor = viewModel.histories?.value?.history?.display?.textColor {
                        cell.renderForCredebtialBranding(clr: UIColor(hex: textColor))
                    }
                    return cell
                }
                    
            }
        } else {
                let cell = tableView.dequeueReusableCell(with: PhotoIDIssuerDetailsCell.self, for: indexPath)
                if viewModel.originatingFrom == .history {
                    cell.configureCell(value: viewModel.histories?.value?.history?.connectionModel?.value?.orgDetails)
                } else {
                    cell.configureCell(value: viewModel.certModel?.value?.connectionInfo?.value?.orgDetails)
                }
                if let color = viewModel.certModel?.value?.textColor {
                    cell.renderForCredebtialBranding(clr: UIColor(hex: color))
                } else if let textColor = viewModel.histories?.value?.history?.display?.textColor {
                    cell.renderForCredebtialBranding(clr: UIColor(hex: textColor))
                }
                return cell
        }
            
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == tableView.numberOfSections - 1 {
            let view = GeneralTitleView.init()
            view.value = "issued_by".localizedForSDK().uppercased()
            if let color = viewModel.certModel?.value?.textColor {
                view.lbl.textColor = UIColor(hex: color)
            } else if let textColor = viewModel.histories?.value?.history?.display?.textColor {
                view.lbl.textColor = UIColor(hex: textColor)
            }
            view.btnNeed = false
            return view
        } else {
            return nil
        }
        
    }
    
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    
    func calculateHeightForText(text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == tableView.numberOfSections - 1 && viewModel.originatingFrom == .detail {
            let view = RemoveBtnVew()
            view.tapAction = { [weak self] in
                self?.deleteAction()
            }
            if let color = viewModel.certModel?.value?.textColor {
                view.layerColor = UIColor(hex: color)
            }
            view.value = "data_remove_data_card".localized()
            return view
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if viewModel.originatingFrom == .detail && section == tableView.numberOfSections - 1  {
            return 65
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
}

extension BoardingPassViewController: ReceiptItemViewModelDelegate {
    
    func dismiss() {
        DispatchQueue.main.async {
            self.pop()
        }
    }
    
}
