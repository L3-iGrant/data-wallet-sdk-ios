//
//  PaymentDataConfirmationHeaderView.swift
//  dataWallet
//
//  Created by iGrant on 11/12/24.
//

import Foundation
import UIKit
import eudiWalletOidcIos

protocol PaymentDataConfirmationHeaderViewDelegate: AnyObject {
    func present(vc: UIViewController)
}

class PaymentDataConfirmationHeaderView: UIView {
    
    
    @IBOutlet var view: UIView!
    
    @IBOutlet weak var rupeesLabel: UILabel!
    
    @IBOutlet weak var bankAccountView: UIView!
    
    @IBOutlet weak var issuanceTimeLabel: UILabel!
    
    @IBOutlet weak var verifierImageView: UIImageView!
    
    @IBOutlet weak var accountNumberLabel: UILabel!
    
    @IBOutlet weak var rupeesBlurredView: BlurredTextView!
    
    @IBOutlet weak var accountNumberBlurredView: BlurredTextView!
    
    
    @IBOutlet weak var blurredTextView: BlurredTextView!
    
    
    @IBOutlet weak var cardParentView: UIView!
    
    @IBOutlet weak var cardBGLogo: UIImageView!
    
    @IBOutlet weak var cardSchemeLogo: UIImageView!
    
    @IBOutlet weak var cardNumber: UILabel!
    
    @IBOutlet weak var cardVerifierLogo: UIImageView!
    
    @IBOutlet weak var verifierLogoWidth: NSLayoutConstraint!
    
    @IBOutlet weak var verifierLogoHeight: NSLayoutConstraint!
    
    @IBOutlet weak var cardView: UIView!
    
   
    @IBOutlet weak var paidToLabel: UILabel!
    
    @IBOutlet weak var paymentView: UIView!
    
    @IBOutlet weak var paidToLogo: UIImageView!
    @IBOutlet weak var payeeName: UILabel!
    @IBOutlet weak var payeeLocation: UILabel!
    
    @IBOutlet weak var paymentViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    weak var delegate: PaymentDataConfirmationHeaderViewDelegate?
   // var presentationDefinitionModel: PresentationDefinitionModel? = nil
    var queryItem: Any?
    
    var viewModel: PaymentDataConfirmationMySharedDataViewModel?
    
    var homeDataList: Search_CustomWalletRecordCertModel?
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerView()
        addView(subview: view)
    }
    
    required init(title: String) {
        super.init(frame: .zero)
        registerView()
        addView(subview: view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: CovidValuesRowTableViewCell.self)
        tableView.register(cellType: PaymentVerificationTableViewCell.self)
    }
    
    func setData(model: PaymentDataConfirmationMySharedDataViewModel?, blurStatus: Bool) {
        viewModel = model
       
        if viewModel?.isMultipleInputDescriptors() ?? false {
            setupData(model: model)
        }
        setupTableView()
        rupeesBlurredView.blurLbl.font = UIFont.systemFont(ofSize: 55)
        if let model = model {
            let currencyCode = getCurrencySymbol(from: model.history?.value?.history?.transactionData?.paymentData?.currencyAmount?.currency ?? "EUR")
            rupeesBlurredView.text = "\(currencyCode ?? "")\(model.history?.value?.history?.transactionData?.paymentData?.currencyAmount?.value ?? 0.0)"
            rupeesBlurredView.blurStatus = blurStatus
            rupeesBlurredView.blurLbl.textAlignment = .center
            rupeesBlurredView.blurLbl.textColor = .black
            cardView.layer.shadowColor = UIColor.gray.cgColor
            cardView.layer.shadowOpacity = 0.5
            cardView.layer.shadowRadius = 8
            cardView.layer.masksToBounds = false
            cardView.layer.shadowOffset = CGSize(width: 0, height: 0)
            guard let fundingSource = model.history?.value?.history?.fundingSource else { return }
            ImageUtils.shared.loadImage(from: fundingSource.icon ?? "", imageIcon: cardVerifierLogo, logoWidth: verifierLogoWidth, logoHeight: verifierLogoHeight)
            blurredTextView.blurStatus = blurStatus
            blurredTextView.blurLbl.textAlignment = .left
            blurredTextView.blurLbl.font = UIFont.systemFont(ofSize: 17, weight: .bold)
            blurredTextView.text = "****" + " " + (fundingSource.panLastFour ?? "")
            if let cover = model.history?.value?.history?.display?.cover {
                UIApplicationUtils.shared.setRemoteImageOn(cardBGLogo, url: cover)
            } else {
                cardBGLogo.backgroundColor = UIColor(hex: model.history?.value?.history?.display?.backgroundColor ?? "")
            }
            cardSchemeLogo.image = getLogoDetails(cardScheme: fundingSource.scheme)
            if let textColor = model.history?.value?.history?.display?.textColor {
                blurredTextView.blurLbl.textColor = UIColor(hex: textColor)
                cardSchemeLogo.tintColor = UIColor(hex: textColor)
            }
        }

            
    }
    
    func setupData(model: PaymentDataConfirmationMySharedDataViewModel?) {
        DispatchQueue.main.async {
            self.homeDataList = self.updateJwtWithPresentationDefinition(jwtList: model?.history?.value?.history?.JWTList, queryItem: model?.history?.value?.history?.presentationDefinition, credentialType: model?.history?.value?.history?.certSubType ?? "", searchableText: model?.history?.value?.history?.certSubType ?? "")
            if let index = self.homeDataList?.records?.firstIndex(where: { $0.value?.vct == "PaymentWalletAttestation" }) {
                self.queryItem = model?.history?.value?.history?.presentationDefinition
                if let wrapper = self.queryItem as? PresentationDefinitionWrapper {
                    switch wrapper {
                    case .dcqlQuery(var dcql):
                        dcql.credentials.remove(at: index)
                        self.queryItem = dcql
                    case .presentationDefinition(var pd):
                        pd.inputDescriptors?.remove(at: index)
                        self.queryItem = pd
                    }
                }
            }
            self.tableView.reloadData()
        }
    }
    
    func updateJwtWithPresentationDefinition(jwtList: [String]?, queryItem: Any?, credentialType: String, searchableText: String?) -> Search_CustomWalletRecordCertModel? {
        let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
        let verificationHandler = eudiWalletOidcIos.VerificationService(keyhandler: keyHandler)
        var newModel = Search_CustomWalletRecordCertModel()
        var records = [SearchItems_CustomWalletRecordCertModel]()
        var newItem = SearchItems_CustomWalletRecordCertModel()
        let historyRecords = viewModel?.history?.value?.history?.credentials?.records
        guard let jwtList = jwtList else { return nil}
        
        for (index, item) in jwtList.enumerated() {
            var queryData: Any?
            var credentialFormat: String = ""
            var displayText: String? = ""
            if let wrapper = queryItem as? PresentationDefinitionWrapper {
                switch wrapper {
                case .dcqlQuery(let dcql):
                    queryData = dcql.credentials[index]
                    if let credentialData = queryData as? CredentialItems {
                        credentialFormat = credentialData.format
                        if let text = historyRecords?[index].value?.searchableText, !text.isEmpty {
                            displayText = text
                        }
                    }

                case .presentationDefinition(let pd):
                    if pd.inputDescriptors?.count ?? 0 > 1 {
                        queryData = pd.inputDescriptors?[index]
                    } else {
                        queryData = pd.inputDescriptors?.first
                    }
                    var queryFormat: [String: Any]? = [:]
                    let data = queryData as? InputDescriptor
                    queryFormat = (data?.format ?? [:]) as [String : Any]
                    if let format = pd.format ?? queryFormat {
                        for (key, _) in format {
                            credentialFormat = key
                        }
                    }
                    if let text = data?.name, !text.isEmpty {
                        displayText = text
                    } else if let text = historyRecords?[index].value?.searchableText, !text.isEmpty {
                        displayText = text
                    }
                }
            }
           
            if credentialFormat == "mso_mdoc" {
                let updatedCbor = verificationHandler.getFilteredCbor(credential: item, query: queryData)
                let cborString = Data(updatedCbor.encode()).base64EncodedString()

                var base64StringWithoutPadding = cborString.replacingOccurrences(of: "=", with: "")
                base64StringWithoutPadding = base64StringWithoutPadding.replacingOccurrences(of: "+", with: "-")
                base64StringWithoutPadding = base64StringWithoutPadding.replacingOccurrences(of: "/", with: "_")
                //newItem = SearchItems_CustomWalletRecordCertModel(type: "",id: "",value: MDOCParser.shared.getMDOCCredentialWalletRecord(connectionModel: EBSIWallet.shared.connectionModel, credential_cbor: base64StringWithoutPadding, format: credentialFormat, credentialType: displayText))
            } else {
                let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                let updatedJwt = eudiWalletOidcIos.SDJWTService.shared.processDisclosures(credential: item, query: queryData, format: credentialFormat, keyHandler: keyHandler)
                newItem = SearchItems_CustomWalletRecordCertModel(type: "", id: "", value:EBSIWallet.shared.updateCredentialWithJWT(jwt:updatedJwt ?? "", searchableText: displayText ?? ""))
            }
            
            records.append(newItem)
        }
        newModel.records = records
        newModel.totalCount = records.count
        return newModel
    }
    
    func getLogoDetails(cardScheme: String?) -> UIImage {
            guard let cardScheme = cardScheme, !cardScheme.isEmpty else {
                return "visa".getImage()
            }
        if cardScheme.contains("visa") {
            return "visa".getImage()
            } else if  cardScheme.contains("Mastercard"){
                return "mastercard".getImage()
            } else if  cardScheme.contains("American Express"){
                return "american_express".getImage()
            } else if cardScheme.contains("JCB") {
                return "jcb".getImage()
            } else if cardScheme.contains("Discover") {
                return "discover".getImage()
            } else if cardScheme.contains("RuPay") {
                return "RuPay".getImage()
            } else if cardScheme.contains("maestro") {
                return "maestro".getImage()
            } else {
                return "visa".getImage()
            }
    }
    
    func getLogoDetails(cardNumber: String?) -> UIImage {
            guard let cardNumber = cardNumber, !cardNumber.isEmpty else {
                return UIImage(named: "visa")!
            }
            let sanitizedCardNumber = cardNumber.replacingOccurrences(of: "[-\\s]", with: "", options: .regularExpression)
            guard sanitizedCardNumber.count >= 6 else {
                return UIImage(named: "visa")!
            }
            let prefix = String(sanitizedCardNumber.prefix(6))
            if sanitizedCardNumber.hasPrefix("4") {
                return UIImage(named: "visa")!
            } else if let firstTwoDigits = Int(sanitizedCardNumber.prefix(2)),
                      (51...55).contains(firstTwoDigits) || (2221...2720).contains(Int(prefix) ?? 0) {
                return UIImage(named: "mastercard")!
            } else if sanitizedCardNumber.hasPrefix("34") || sanitizedCardNumber.hasPrefix("37") {
                return UIImage(named: "american_express")!
            } else if let firstFourDigits = Int(sanitizedCardNumber.prefix(4)),
                      (3528...3589).contains(firstFourDigits) {
                return UIImage(named: "jcb")!
            } else if let firstFourDigits = Int(sanitizedCardNumber.prefix(4)),
                      firstFourDigits == 6011 || (622126...622925).contains(firstFourDigits) ||
                        (644...649).contains(firstFourDigits) || sanitizedCardNumber.hasPrefix("65") {
                return UIImage(named: "discover")!
            } else if sanitizedCardNumber.hasPrefix("60") ||
                        (6521...6522).contains(Int(prefix) ?? 0) {
                return UIImage(named: "RuPay")!
            } else if let firstTwoDigits = Int(sanitizedCardNumber.prefix(2)),
                      (56...69).contains(firstTwoDigits) {
                return UIImage(named: "maestro")!
            } else {
                return UIImage(named: "visa")!
            }
    }
    
    func getCurrencySymbol(from currencyCode: String) -> String? {
        let localeIdentifiers = Locale.availableIdentifiers
        for identifier in localeIdentifiers {
            let locale = Locale(identifier: identifier)
            if locale.currencyCode == currencyCode {
                return locale.currencySymbol
            }
        }
        return nil
    }
}

extension PaymentDataConfirmationHeaderView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel?.isMultipleInputDescriptors() ?? false {
            let records = homeDataList?.records?.filter( {$0.value?.vct != "PaymentWalletAttestation"})
            return (records?.count ?? 0) + 1
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let records = homeDataList?.records?.filter( {$0.value?.vct != "PaymentWalletAttestation"})
        let isLastRow = indexPath.row == (records?.count ?? 0)
        if isLastRow {
            let cell = tableView.dequeueReusableCell(with: PaymentVerificationTableViewCell.self, for: indexPath)
            cell.configureCell(model: viewModel)
            cell.selectionStyle = .none
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
            cell.renderUI(index: indexPath.row, tot: records?.count ?? 0)
            var title: String = ""
            if let name = viewModel?.getNameAndIdFromInputDescriptor(index: indexPath.row).0, !name.isEmpty {
                title = name
            } else if let name = records?[indexPath.row].value?.searchableText, !name.isEmpty {
                title = name.capitalized
            }
            cell.leftPadding.constant = 0
            cell.rightPadding.constant = 0
            cell.mainLbl.text = title
            cell.blurView.isHidden = true
            cell.rightImage = UIImage(systemName: "chevron.right")
            cell.rightImageView.tintColor = .darkGray
           // cell.disableCheckBox()
            cell.layoutIfNeeded()
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel?.isMultipleInputDescriptors() ?? false {
            let headerView = UIView()
            headerView.backgroundColor = .appColor(.walletBg)
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = UIFont.systemFont(ofSize: 16)
            label.textColor = .darkGray
            headerView.addSubview(label)
            label.text = "payment_additional_data_requests".localizedForSDK()
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 0),
                label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
                label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
            ])
            return headerView
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel?.isMultipleInputDescriptors() ?? false {
            return 30
        } else {
            return CGFloat.leastNormalMagnitude
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let records = homeDataList?.records?.filter( {$0.value?.vct != "PaymentWalletAttestation"})
        let isLastRow = indexPath.row == (records?.count ?? 0)
        if !isLastRow {
            let vc = PaymentAdditionalDataRequestBottomSheetVC(nibName: "PaymentAdditionalDataRequestBottomSheetVC", bundle: nil)
            if let selectedData = records?[indexPath.row] {
                vc.record = selectedData
                vc.isFromHistory = true
                vc.credentailModel = [selectedData]
                var title: String?
                if let name = viewModel?.getNameAndIdFromInputDescriptor(index: indexPath.row).0, !name.isEmpty {
                    title = name
                } else if let name = selectedData.value?.searchableText, !name.isEmpty {
                    title = name
                } else {
                    title = viewModel?.getNameAndIdFromInputDescriptor(index: indexPath.row).1
                }
                vc.sectionHeaderName = title ?? ""
                vc.queryItem = queryItem
                vc.cellIndex = indexPath.row
                vc.modalPresentationStyle = .overCurrentContext
                self.delegate?.present(vc: vc)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}
