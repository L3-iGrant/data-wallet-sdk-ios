//
//  PaymentDataConfirmationBottonSheetView.swift
//  dataWallet
//
//  Created by iGrant on 03/02/25.
//

import Foundation
import UIKit
import eudiWalletOidcIos
import LocalAuthentication
import IndyCWrapper


protocol PaymentDataConfirmationBottonSheetViewDelegate: AnyObject {
    func closeTapped()
    func dismissVC()
    func presentVC(vc: UIViewController)
}

class PaymentDataConfirmationBottonSheetView: UIView {
    
    @IBOutlet weak var parentView: UIView!
    @IBOutlet weak var paymentView: UIView!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControll: UIPageControl!
    @IBOutlet weak var verifierName: UILabel!
    @IBOutlet weak var verifierLocation: UILabel!
    @IBOutlet weak var paymentConfirmedImage: UIImageView!
    @IBOutlet weak var patmentConfirmedLabel: UILabel!
    @IBOutlet weak var rupeesLabel: UILabel!
    @IBOutlet weak var verifierNameLabel: UILabel!
    @IBOutlet weak var verifierLocationLabel: UILabel!
    @IBOutlet weak var verifierPayeeLogo: UIImageView!
    @IBOutlet weak var verifiedLogo: UIImageView!
    
    @IBOutlet weak var paymentUsingLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var paymentBeingMadeToLabel: UILabel!
    weak var delegate: PaymentDataConfirmationBottonSheetViewDelegate?
    
    var clientMetaData = EBSIWallet.shared.clientMetaData
       var transactionData: TransactionData? = nil
       let records = EBSIWallet.shared.pwaDataRecords.filter( { $0.value?.fundingSource != nil})
       let pwaRecord = EBSIWallet.shared.pwaExchangeDataRecordsdModel.filter( { $0.value?.fundingSource != nil})
       var transactionDataBse64Data = EBSIWallet.shared.transactionData
       var redirectUri = EBSIWallet.shared.uri
       private var alert: UIAlertController?
       var credentialsDict = [[String: Any]]()
       var pwaCredentialsDict = [[String: Any]]()
       var presentationDefinition = EBSIWallet.shared.presentationDefinition
       var dcqlQuery = EBSIWallet.shared.dcqlQuery
       var selectedIndex: Int = 0
      // var presentationDefinitionModel: PresentationDefinitionModel? = nil
       var updatedPresentationDefinitionModel: PresentationDefinitionModel? = nil
       var tempTransactionBase64 = EBSIWallet.shared.transactionData
       var viewModel =  PaymentAdditionalDataRequestBottomSheetViewModel()
       var isValidOrg: Bool?
       var filterdRecords = [[SearchItems_CustomWalletRecordCertModel]]()
       var selectedCredentialIndexes: [Int: String] = [:]
       var filteredToOriginalSectionMap: [Int] = []
       var filteredToOriginalSectionPWAMap: [Int] = []
       var sharedCredentials: [String] = []
       var filteredPWASections: [[SearchItems_CustomWalletRecordCertModel]] = []
       var filteredNonPWASections: [[SearchItems_CustomWalletRecordCertModel]] = []
       var selectedPWACredential = ""
       var lastSelectedIndexFromAditionalData: Int?
       var lastSelectedIndexesPerRow: [IndexPath: Int] = [:]
       var queryItem: Any?
       var updatedQueryItem: Any?
       var updatedDCQL: DCQLQuery?
       
       func setupCornerRadius() {
           paymentView.layer.cornerRadius = 15
           payButton.layer.cornerRadius = 22.5
           parentView.layer.cornerRadius = 15
       }
       
       let activityIndicator = UIActivityIndicatorView(style: .large)
       
       func setupActivityIndicator() {
           activityIndicator.color = .darkGray
           activityIndicator.translatesAutoresizingMaskIntoConstraints = false
           parentView.addSubview(activityIndicator)
           activityIndicator.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
           NSLayoutConstraint.activate([
               activityIndicator.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
               activityIndicator.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor, constant: -45)
           ])
       }
       
       required init?(coder: NSCoder) {
           super.init(coder: coder)
           loadNib()
       }
       
       override init(frame: CGRect) {
           super.init(frame: frame)
           loadNib()
       }
       
       func setupPager() {
           pageControll.currentPageIndicatorTintColor = .darkGray
           pageControll.pageIndicatorTintColor = UIColor.darkGray.withAlphaComponent(0.3)
           pageControll.hidesForSinglePage = true
       }
       
       
       @IBAction func payButtonAction(_ sender: Any) {
           authenticationWithTouchID()
       }
       
       private func loadNib() {
           let nib = UINib(nibName: "PaymentDataConfirmationBottonSheetView", bundle: Bundle.module)
           if let view = nib.instantiate(withOwner: self, options: nil).first as? UIView {
               view.frame = self.bounds
               view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
               parentView.backgroundColor = .appColor(.walletBg)
               addSubview(view)
               
               setupCornerRadius()
               setupCollectionView()
               setupPager()
               setupActivityIndicator()
               setupTransactionDataValues()
               paymentUsingLabel.text = "Payment using".localizedForSDK().uppercased()
               let count = !pwaRecord.isEmpty ? pwaRecord.count : records.count
               pageControll.numberOfPages = count
               setupData()
               setupTableView()
               paymentConfirmedImage.isHidden = true
               patmentConfirmedLabel.isHidden = true
               TrustMechanismManager().isIssuerOrVerifierTrusted(credential: EBSIWallet.shared.presentationRequestJwt, format: "", jwksURI: "") { isValid in
                   if let isValid = isValid {
                       self.isValidOrg = isValid
                   }
                   
               }
               viewModel.populateModelForEBSI(presentationDefinition: presentationDefinition, dcql: dcqlQuery) { succes in
                   DispatchQueue.main.async {
                       self.tableView.reloadData()
                       
                       if let originalSections = self.viewModel.EBSI_credentials {
                           for (originalIndex, section) in originalSections.enumerated() {
   //                            if section.allSatisfy({ $0.value?.vct != "PaymentWalletAttestation" }) {
                                  // self.filterdRecords.append(section)
                               if section.allSatisfy({ $0.value?.fundingSource == nil }) {
                                   self.filteredNonPWASections.append(section)
                                   self.filteredToOriginalSectionMap.append(originalIndex)
                               } else if section.allSatisfy({ $0.value?.fundingSource != nil}){
                                   self.filteredPWASections.append(section)
                                   self.filteredToOriginalSectionPWAMap.append(originalIndex)
                               }
   //                            }
                           }
                       }
                   
                       
                       for (filteredIndex, sectionItems) in self.filteredNonPWASections.enumerated() {
                           if let jwt = sectionItems.first?.value?.EBSI_v2?.credentialJWT {
                               let originalIndex = self.filteredToOriginalSectionMap[filteredIndex]
                               self.selectedCredentialIndexes[originalIndex] = jwt
                           }
                       }

                       // PWA selections
                       for (filteredIndex, sectionItems) in self.filteredPWASections.enumerated() {
                           if let jwt = sectionItems.first?.value?.EBSI_v2?.credentialJWT {
                               let originalIndex = self.filteredToOriginalSectionPWAMap[filteredIndex]
                               self.selectedCredentialIndexes[originalIndex] = jwt
                           }
                       }
                       
                       self.collectionView.reloadData()
                       
                   }
                   
               }
               
           }
       }
       
       private func setupTableView() {
           tableView.delegate = self
           tableView.dataSource = self
           tableView.register(cellType: CovidValuesRowTableViewCell.self)
           tableView.register(cellType: PaymentDataConfirmationTableViewCell.self)
       }
       
       func setupTransactionDataValues() {
           let transactionDataBase64 = self.tempTransactionBase64.first?.decodeBase64()
           guard let transactionDataJson = transactionDataBase64?.data(using: .utf8) else { return }
           let transactionDataModel = try? JSONDecoder().decode(eudiWalletOidcIos.TransactionData.self, from: transactionDataJson)
           transactionData = transactionDataModel
       }
       
       func setupData() {
           DispatchQueue.main.async {
               var queryItem: Any?
               if let dcql = self.dcqlQuery {
                   queryItem = dcql
               } else if self.presentationDefinition != "" {
                   let jsonData = (self.presentationDefinition ).replacingOccurrences(of: "+", with: " ").data(using: .utf8)
                   let presentationDefinitionModel = try? JSONDecoder().decode(eudiWalletOidcIos.PresentationDefinitionModel.self, from: jsonData ?? Data())
                   queryItem = presentationDefinitionModel
               }
               if let index = EBSIWallet.shared.pwaDataRecords.firstIndex(where: { $0.value?.vct == "PaymentWalletAttestation" }) {
                   if let data = queryItem as? PresentationDefinitionModel {
                       let jsonData = (self.presentationDefinition ).replacingOccurrences(of: "+", with: " ").data(using: .utf8)
                       self.updatedPresentationDefinitionModel = try? JSONDecoder().decode(eudiWalletOidcIos.PresentationDefinitionModel.self, from: jsonData ?? Data())
                       self.updatedPresentationDefinitionModel?.inputDescriptors?.remove(at: index)
                       self.updatedQueryItem = self.updatedPresentationDefinitionModel
                   } else if let data = queryItem as? DCQLQuery {
                       self.updatedDCQL = self.dcqlQuery
                       self.updatedDCQL?.credentials.remove(at: index)
                       self.updatedQueryItem = self.updatedDCQL
                   }
               }
               let clientDataString = self.clientMetaData.replacingOccurrences(of: "+", with: " ")
               let clientMetadataJson = clientDataString.replacingOccurrences(of: "\'", with: "\"").data(using: .utf8)!
               let clientMetaDataModel = try? JSONDecoder().decode(eudiWalletOidcIos.ClientMetaData.self, from: clientMetadataJson)
               let currencyCode = self.getCurrencySymbol(from: self.transactionData?.paymentData?.currencyAmount?.currency ?? "EUR")
               self.rupeesLabel.text = "\(currencyCode ?? "")\(self.transactionData?.paymentData?.currencyAmount?.value ?? 0.0)"
               self.verifierNameLabel.text = self.transactionData?.paymentData?.payee
               let verifierLogoUrl = clientMetaDataModel?.logoUri
               if PaymentUtils.isBankLeadFlow(clientMetaData: clientMetaDataModel, transactionData: self.transactionData) {
                   let profileImage = UIApplicationUtils.shared.profileImageCreatorWithAlphabet(withAlphabet: self.transactionData?.paymentData?.payee?.first ?? "U" , size: CGSize(width: 100, height: 100))
                   self.verifierPayeeLogo.image = profileImage
                   self.verifierLocationLabel.text = "via" + " " + (clientMetaDataModel?.clientName ?? "")
                   self.verifiedLogo.isHidden = true
               } else {
                   self.verifierLocationLabel.text = clientMetaDataModel?.location
                   ImageUtils.shared.setRemoteImage(for: self.verifierPayeeLogo, imageUrl: verifierLogoUrl, orgName: self.transactionData?.paymentData?.payee)
               }
               
               if self.isMultipleInputDescriptors(queryItem: queryItem) ?? false {
                   self.tableView.isHidden = false
                   self.paymentView.isHidden = true
                   self.paymentBeingMadeToLabel.isHidden = true
               } else {
                   self.tableView.isHidden = true
                   self.paymentView.isHidden = false
                   self.paymentBeingMadeToLabel.isHidden = false
               }
               
               if self.isMultipleInputDescriptors(queryItem: queryItem) ?? false {
                   let records = EBSIWallet.shared.pwaDataRecords.filter( {$0.value?.vct != "PaymentWalletAttestation"})
                   let pwaDataRecord = EBSIWallet.shared.pwaExchangeDataRecordsdModel.filter( {$0.value?.vct == "PaymentWalletAttestation"})
                   for item in pwaDataRecord {
                       var dict: [String: Any] = [:]
                       dict["noKey"] = item.value?.EBSI_v2?.credentialJWT
                       self.pwaCredentialsDict.append(dict)
                   }
                   for item in EBSIWallet.shared.pwaDataRecords {
                       var dict: [String: Any] = [:]
                       dict["noKey"] = item.value?.EBSI_v2?.credentialJWT
                       self.credentialsDict.append(dict)
                   }
               } else {
                   for item in self.pwaRecord {
                       var dict: [String: Any] = [:]
                       dict["noKey"] = item.value?.EBSI_v2?.credentialJWT
                       self.credentialsDict.append(dict)
                   }
               }
               let title = self.isMultipleInputDescriptors(queryItem: queryItem) ?? false ? "Confirm and Pay".localizedForSDK() : "Pay".localizedForSDK()
               self.payButton.setTitle(title, for: .normal)
               
               self.collectionView.reloadData()
           }
       }
       
       func showActivityIndicator() {
           activityIndicator.isHidden = false
           activityIndicator.startAnimating()
       }
       
       func hideActivityIndicator() {
           activityIndicator.stopAnimating()
           activityIndicator.isHidden = true
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
       
       func authenticationWithTouchID() {
           let localAuthenticationContext = LAContext()
           
           var authError: NSError?
           let reasonString = "To access the secure data.".localizedForSDK()
           
           if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &authError) {
               
               localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reasonString) { success, evaluateError in
                   
                   if success {
                       DispatchQueue.main.async {
                           //self.removeAuthBlurView()
                           self.alert?.dismiss(animated: false, completion: nil)
                           self.sendAuthorizationResponse()
                       }
                   } else {
                       //TODO: User did not authenticate successfully, look at error and take appropriate action
                       guard let error = evaluateError else {
                           return
                       }
                       
                       debugPrint(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code))
                       
                       //TODO: If you have choosen the 'Fallback authentication mechanism selected' (LAError.userFallback). Handle gracefully
                       
                   }
               }
           } else {
               
               guard let error = authError else {
                   return
               }
               //TODO: Show appropriate alert if biometry/TouchID/FaceID is lockout or not enrolled
               debugPrint(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error.code))
           }
       }
       
       func evaluatePolicyFailErrorMessageForLA(errorCode: Int) -> String {
           var message = ""
           if #available(iOS 11.0, macOS 10.13, *) {
               switch errorCode {
               case LAError.biometryNotAvailable.rawValue:
                   message = "Authentication could not start because the device does not support biometric authentication."
                   
               case LAError.biometryLockout.rawValue:
                   message = "Authentication could not continue because the user has been locked out of biometric authentication, due to failing authentication too many times."
                   
               case LAError.biometryNotEnrolled.rawValue:
                   message = "Authentication could not start because the user has not enrolled in biometric authentication."
               default:
                   message = "Did not find error code on LAError object"
               }
           } else {
               switch errorCode {
               case LAError.touchIDLockout.rawValue:
                   message = "Too many failed attempts."
                   
               case LAError.touchIDNotAvailable.rawValue:
                   message = "TouchID is not available on the device"
                   
               case LAError.touchIDNotEnrolled.rawValue:
                   message = "TouchID is not enrolled on the device"
                   
               default:
                   message = "Did not find error code on LAError object"
               }
           }
           return message;
       }
       
       func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
           var message = ""
           switch errorCode {
           case LAError.authenticationFailed.rawValue:
               message = "The user failed to provide valid credentials"
               
           case LAError.appCancel.rawValue:
               message = "Authentication was cancelled by application"
               
           case LAError.invalidContext.rawValue:
               message = "The context is invalid"
               
           case LAError.notInteractive.rawValue:
               message = "Not interactive"
               
           case LAError.passcodeNotSet.rawValue:
               message = "Passcode is not set on the device"
               
           case LAError.systemCancel.rawValue:
               message = "Authentication was cancelled by the system"
               showAuthenticationError()
               
           case LAError.userCancel.rawValue:
               message = "The user did cancel"
               showAuthenticationError()
               
           case LAError.userFallback.rawValue:
               message = "The user chose to use the fallback"
               
           default:
               message = evaluatePolicyFailErrorMessageForLA(errorCode: errorCode)
           }
           return message
       }
       
       func showAuthenticationError() {
           //addAuthBlurView()
           DispatchQueue.main.async {
               self.alert = UIAlertController(title: "Data Wallet Locked".localizedForSDK(), message: "Please authenticate to continue".localizedForSDK(), preferredStyle: UIAlertController.Style.alert)
               
               self.alert?.addAction(UIAlertAction(title: "OK".localizedForSDK(), style: UIAlertAction.Style.default, handler: { _ in
                   DispatchQueue.main.async {
                       self.authenticationWithTouchID()
                   }
               }))
               self.delegate?.presentVC(vc: self.alert!)
               //self.present(self.alert!, animated: false, completion:nil)
           }
       }
       
       func sendAuthorizationResponse() {
           var state = String()
           var nonce = String()
           var redirectURI = String()
           var credentialsListArray: [String] = []
           
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
                   fatalError("Failed to convert JSON string to data")
               }
               
               guard let jsonDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
                   fatalError("Failed to deserialize JSON data")
               }
               
               redirectURI = jsonDict["response_uri"] as? String ?? ""
               nonce = jsonDict["nonce"] as? String ?? ""
               state = jsonDict["state"] as? String ?? ""
           }
           Task { [self] in
               debugPrint("### CredentialsJWT dict count:\(credentialsDict.count)")
               // Step: 8.3: Send VP token
               
               
               var result : WrappedVerificationResponse? = nil
               sharedCredentials = selectedCredentialIndexes.sorted { $0.key < $1.key }.map { $0.value }
               let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
               let verificationHandler = eudiWalletOidcIos.VerificationService(keyhandler: keyHandler)
               var queryItem: Any?
               if let dcql = dcqlQuery {
                   queryItem = dcql
               } else if presentationDefinition != "" {
                   let jsonData = (self.presentationDefinition ).replacingOccurrences(of: "+", with: " ").data(using: .utf8)
                   let presentationDefinitionModel = try? JSONDecoder().decode(eudiWalletOidcIos.PresentationDefinitionModel.self, from: jsonData ?? Data())
                   queryItem = presentationDefinitionModel
               }
               if isMultipleInputDescriptors(queryItem: queryItem) ?? false {
                   let matchingSectionIndices = self.viewModel.EBSI_credentials?.enumerated().compactMap { index, section in
                       let allArePaymentAttestation = section.allSatisfy { item in
                           item.value?.vct == "PaymentWalletAttestation"
                       }
                       return allArePaymentAttestation ? index : nil
                   } ?? []
                   let pwaCred = selectedPWACredential == "" ? filteredPWASections[0].first?.value?.EBSI_v2?.credentialJWT : selectedPWACredential
                   sharedCredentials.remove(at: matchingSectionIndices.first as? Int ?? 0)
                   sharedCredentials.insert(pwaCred ?? ""
                                            , at: matchingSectionIndices.first as? Int ?? 0)
                   for (index,item) in sharedCredentials.enumerated() {
                       var queryCredentialItem: Any?
                       var credentialFormat: String? = ""
                       if let dcql = queryItem as? DCQLQuery {
                           queryCredentialItem = dcql.credentials[index]
                           credentialFormat = dcql.credentials[index].format
                       } else if let pd = queryItem as? PresentationDefinitionModel {
                           queryCredentialItem = pd.inputDescriptors?[index]
                           if let format = pd.format ?? pd.inputDescriptors?[index].format {
                               for (key, _) in format {
                                   credentialFormat = key
                               }
                           }
                       }
                       
                       if item.contains("~") {
                           let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                           let sdjwtR = eudiWalletOidcIos.SDJWTService.shared.createSDJWTR(credential: item, query: queryCredentialItem, format: credentialFormat, keyHandler: keyHandler)
                           credentialsListArray.append(sdjwtR ?? "")
                       } else {
                           credentialsListArray.append(item)
                       }
                   }
               } else {
                   let dict = self.credentialsDict[selectedIndex]
                   var queryCredentialItem: Any?
                   var credentialFormat: String? = ""
                   if let dcql = queryItem as? DCQLQuery {
                       queryCredentialItem = dcql.credentials.first
                       credentialFormat = dcql.credentials.first?.format
                   } else if let pd = queryItem as? PresentationDefinitionModel {
                       queryCredentialItem = pd.inputDescriptors?.first
                       if let format = pd.format ?? pd.inputDescriptors?.first?.format {
                           for (key, _) in format {
                               credentialFormat = key
                           }
                       }
                   }
                   if let credential = dict["noKey"] as? String, credential.contains("~") {
                       let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                       let sdjwtR = eudiWalletOidcIos.SDJWTService.shared.createSDJWTR(credential: credential, query: queryCredentialItem, format: credentialFormat, keyHandler: keyHandler)
                       credentialsListArray.append(sdjwtR ?? "")
                   } else if let credential = dict["noKey"] as? String {
                       credentialsListArray.append(credential)
                   }
                   
               }
               
               if let url = URL.init(string: self.redirectUri),
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let redirect_uri = components.queryItems?.first(where: { $0.name == "redirect_uri" })?.value {
                   showActivityIndicator()
                   payButton.isHidden = true
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
                               let presentationRequest = eudiWalletOidcIos.PresentationRequest(state: state, clientId: clientID, redirectUri: redirect_uri, responseUri: redirectURI, responseType: responseType, responseMode: responseMode, scope: "", nonce: nonce, requestUri: "", presentationDefinition: self.presentationDefinition, clientMetaData: clientMetaData, presentationDefinitionUri: "", clientMetaDataUri: "", clientIDScheme: clientIDScheme, transactionData: transactionDataBse64Data, dcqlQuery: self.dcqlQuery, request: "", authSession: authSession)
                               _ = await EBSIWallet.shared.createDIDKeyIdentifierForV3(privateKey: privateKey) ?? ""
                               EBSIWallet.shared.vpTokenRedirectUri = redirect_uri
                               let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                               let did = await WalletUnitAttestationService().createDIDforWUA(keyHandler: keyHandler)
                               let pop = await WalletUnitAttestationService().generateWUAProofOfPossession(keyHandler: keyHandler, aud: presentationRequest.clientId)
                               
                               result = await verificationHandler.processOrSendAuthorizationResponse(did: did, presentationRequest: presentationRequest, credentialsList: credentialsListArray, wua: searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT ?? "", pop: pop)
                               UIApplicationUtils.showLoader()
                               if result?.error == nil {
                                   hideActivityIndicator()
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
                                                           let pop = await WalletUnitAttestationService().generateWUAProofOfPossession( keyHandler: keyHandler, aud: presentationRequest.clientId)
                                                           let clientIDAssertion = await WalletUnitAttestationService().createClientAssertion( aud: presentationRequest.clientId ?? "", keyHandler: keyHandler)
                                                           let privateKey = EBSIWallet.shared.handlePrivateKey()
                                                           let accessTokenResponse = await EBSIWallet.shared.issueHandler?.processTokenRequest(did: did, tokenEndPoint: EBSIWallet.shared.tokenEndpointForConformanceFlow ?? "", code: code, codeVerifier: EBSIWallet.shared.codeVerifierCreated, isPreAuthorisedCodeFlow: false, userPin: "", version: "",clientIdAssertion: clientIDAssertion ,wua: searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT ?? "", pop: pop, redirectURI: EBSIWallet.shared.webRedirectURI)
                                                           if accessTokenResponse?.error != nil{
                                                               DispatchQueue.main.async {
                                                                   UIApplicationUtils.showErrorSnackbar(message: accessTokenResponse?.error?.message ?? "Unexpected error. Please try again.".localizedForSDK())
                                                               }
                                                           } else {
                                                               let authServerUrl = AuthorizationServerUrlUtil().getAuthorizationServerUrl(issuerConfig: EBSIWallet.shared.openIdIssuerResponseData, credentialOffer: EBSIWallet.shared.credentialOffer)
                                                               let authServer = EBSIWallet.shared.getAuthorizationServerFromCredentialOffer(credential: EBSIWallet.shared.credentialOffer) ?? authServerUrl
                                                               let authConfig = try await DiscoveryService.shared.getAuthConfig(authorisationServerWellKnownURI: (authServer?.isEmpty == true ? EBSIWallet.shared.credentialOffer?.credentialIssuer : authServer) ?? "")
                                                               let nonce = await NonceServiceUtil().fetchNonce(accessTokenResponse: accessTokenResponse, nonceEndPoint: EBSIWallet.shared.openIdIssuerResponseData?.nonceEndPoint)
                                                               await EBSIWallet.shared.requestCredentialUsingEbsiV3(didKeyIdentifier: EBSIWallet.shared.globalDID, c_nonce: nonce ?? "", accessToken: accessTokenResponse?.accessToken ?? "", privateKey: privateKey, jwkUri: authConfig?.jwksURI, refreshToken: accessTokenResponse?.refreshToken ?? "",authDetails: accessTokenResponse?.authorizationDetails, tokenResponse: accessTokenResponse, isPWA: true)
                                                               self.delegate?.dismissVC()
                                                               EBSIWallet.shared.isDynamicCredentialRequest = false
                                                               UIApplicationUtils.hideLoader()
                                                           }
                                                       }
                                                   }
                                               }
                                               /////
                                               
                                               //////
                                           } else {
                                               print("Unable to retrieve code from url")
                                           }
                                           
                                           UIApplicationUtils.hideLoader()
                                           DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                               self.delegate?.dismissVC()
                                           })
                                           
                                       }
                                   }else{
                                       if let url = URL.init(string: self.redirectUri),
                                          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                                          let redirect_uri = components.queryItems?.first(where: { $0.name == "redirect_uri" })?.value {
                                           
                                           let pfComponents = self.presentationDefinition.components(separatedBy: "nonce=")
                                           var nonceFromPresentationDef = ""
                                           if pfComponents.count > 1 {
                                               nonceFromPresentationDef = pfComponents[1]
                                           }
                                           state = components.queryItems?.first(where: { $0.name == "state" })?.value ?? ""
                                           nonce = components.queryItems?.first(where: { $0.name == "nonce" })?.value ?? nonceFromPresentationDef
                                           let clientMetaData = components.queryItems?.first(where: { $0.name == "client_metadata" })?.value ?? ""
                                           let clientIDScheme = components.queryItems?.first(where: { $0.name == "client_id_scheme"})?.value
                                           
                                           
                                           let privateKey = EBSIWallet.shared.handlePrivateKey()
                                           
                                           UIApplicationUtils.hideLoader()
                                           payButton.isHidden = true
                                           paymentConfirmedImage.isHidden = false
                                           paymentConfirmedImage.image = "connection_success".getImage()
                                           patmentConfirmedLabel.isHidden = false
                                           EBSIWallet.shared.clearCacheAfterIssuanceAndExchange()
                                       }
                                       DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                                           self.delegate?.dismissVC()
                                       })
                                   }
                               } else {
                                   hideActivityIndicator()
                                   UIApplicationUtils.hideLoader()
                                   paymentConfirmedImage.isHidden = false
                                   patmentConfirmedLabel.isHidden = false
                                   paymentConfirmedImage.image = "payment_failed".getImage()
                                   patmentConfirmedLabel.text = "Payment confirmation failed".localizedForSDK()
                                   DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                                       self.delegate?.dismissVC()
                                   })
                               }
                               var list: [String] = []
                               if isMultipleInputDescriptors(queryItem: queryItem) ?? false {
                                   for data in sharedCredentials {
                                       list.append(data )
                                   }
                               } else {
                                   let dict = self.credentialsDict[selectedIndex]
                                   list.append(dict["noKey"] as? String ?? "")
                               }
                               guard let dummy = viewModel.EBSI_credentials else {return}
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
                                   sharedData.records = viewModel.EBSI_credentials?.first
                                   sharedData.totalCount = viewModel.EBSI_credentials?.first?.count
                               } else {
                                   sharedData.records = matchingSharedCredentials
                                   sharedData.totalCount = matchingSharedCredentials.count
                               }
                               self.addHistoryToEBSI(jwtList: list, clientMetaData: self.clientMetaData, credentials: sharedData, queryItem: queryItem)
                               NotificationCenter.default.post(name: Constants.reloadOrgList, object: nil)
                           }
                       }
                   }
               }
               
           }
       }
       
       func setupCollectionView() {
           collectionView.delegate = self
           collectionView.dataSource = self
           let layout = UICollectionViewFlowLayout()
           layout.scrollDirection = .horizontal
           layout.minimumLineSpacing = 0
           layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
           collectionView.collectionViewLayout = layout
           collectionView.isPagingEnabled = true
           collectionView.register(cellType: PaymentCardCollectionViewCell.self)
       }
       
       func clearGlobalVariables() {
           clientMetaData = ""
           tempTransactionBase64 = []
           transactionData = nil
       }
       
       func isMultipleInputDescriptors(queryItem: Any?) -> Bool? {
           guard let data = queryItem else { return false }
           if let pd = queryItem as? PresentationDefinitionModel {
               return pd.inputDescriptors?.count ?? 0 > 1
           } else if let dcql = queryItem as? DCQLQuery {
               return dcql.credentials.count > 1
           } else {
               return false
           }
       }
       
       func getNameFromPresentationDefinition(index: Int) -> String? {
           guard let data = updatedQueryItem else { return nil }
           if let pd = data as? PresentationDefinitionModel {
               return pd.inputDescriptors?[index].name
           } else if let dcql = data as? DCQLQuery {
               return nil
           } else {
               return nil
           }
       }
       
       func addHistoryToEBSI(jwtList: [String] = [], presentationDefinition: PresentationDefinitionModel? = nil, clientMetaData: String = "", credentials: Search_CustomWalletRecordCertModel? = nil, queryItem: Any?) {
           let historyRecord = pwaRecord.isNotEmpty ? pwaRecord : records
           let records = viewModel.EBSI_credentials
           let search_cert_model = historyRecord[selectedIndex].value
           let walletHandle = WalletViewModel.openedWalletHandler ?? 0

           Task {
               let clientMetadataJson = clientMetaData.data(using: .utf8)!
               let clientMetaDataModel = try? JSONDecoder().decode(ClientMetaData.self, from: clientMetadataJson)
               var display = EBSIWallet.shared.convertClientMetaDataToDisplay(clientMetaData: clientMetaDataModel)
               let connection = await EBSIWallet.shared.getEBSI_V3_connection(orgID: EBSIWallet.shared.exchangeClientID) ?? CloudAgentConnectionWalletModel()
               connection.value?.orgDetails?.isValidOrganization = isValidOrg
               connection.value?.orgDetails?.x5c = EBSIWallet.shared.presentationRequestJwt
               let walletHandler = walletHandle
               var history = History()
               history.JWT = ""
               history.attributesValues = search_cert_model?.attributes
               history.dataAgreementModel = nil
               history.dataAgreementModel?.validated = .not_validate
               let dateFormat = DateFormatter.init()
               dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
               dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
               history.date = dateFormat.string(from: Date())
               history.connectionModel = connection
               history.type = HistoryType.exchange.rawValue
               history.name = CertType.EBSI.rawValue
               history.transactionData = transactionData
               history.fundingSource = search_cert_model?.fundingSource
               if presentationDefinition?.inputDescriptors?.count ?? 0 > 1 {
                   if search_cert_model?.subType == EBSI_CredentialType.PDA1.rawValue || search_cert_model?.subType == EBSI_CredentialType.PWA.rawValue{
                       history.certSubType = search_cert_model?.subType
                   } else {
                       history.certSubType = presentationDefinition?.id
                   }
               } else {
                   history.certSubType = search_cert_model?.subType == "" ? search_cert_model?.searchableText : search_cert_model?.subType
               }
               history.credentials = credentials
               history.JWTList = jwtList
               history.threadID = ""
               if let pd = queryItem as? PresentationDefinitionModel {
                   history.presentationDefinition = .presentationDefinition(pd)
               } else if let dcql = queryItem as? DCQLQuery {
                   history.presentationDefinition = .dcqlQuery(dcql)
               }
               
               if history.display == nil {
                   history.display = CredentialDisplay(name: nil, location: nil, locale: nil, description: nil, cover: nil, logo: nil, backgroundColor: nil, textColor: nil)
               }
               history.display?.name = search_cert_model?.searchableText
               history.display?.description = search_cert_model?.description
               history.display?.logo = display.logo?.url ?? display.logo?.uri
               history.display?.cover = search_cert_model?.cover
               history.display?.textColor = search_cert_model?.textColor
               history.display?.backgroundColor = search_cert_model?.backgroundColor
               do {
                   let jsonData = try JSONEncoder().encode(history)
                   let stringData = String(data: jsonData, encoding: .utf8)
                   print("historyJsonData: \(stringData ?? "")")
               } catch {
                   print("error")
               }
               WalletRecord.shared.add(connectionRecordId: "", walletHandler: walletHandler, type: .dataHistory, historyModel: history) { [weak self] success, id, error in
                   debugPrint("historySaved -- \(success)")
                   guard let strongSelf = self else { return}
                   UIApplicationUtils.hideLoader()
               }
               
               let (_, _) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(),recipientKey: "",label: connection.value?.orgDetails?.name ?? "", type: UpdateWalletType.trusted, id: connection.value?.requestID ?? "", theirDid: "", myDid: connection.value?.myDid ?? "",imageURL: connection.value?.orgDetails?.coverImageURL ?? "" ,invitiationKey: "", isIgrantAgent: false, routingKey: nil, orgDetails: connection.value?.orgDetails, orgID: connection.value?.orgDetails?.orgId)
           }
           
       }
       
       @IBAction func closeButtonAction(_ sender: Any) {
           delegate?.closeTapped()
           clearGlobalVariables()
       }
       
   }

   extension PaymentDataConfirmationBottonSheetView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
       
       func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
           return filteredPWASections.first?.count ?? 0
       }
       
       
       func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier:
                                               "PaymentCardCollectionViewCell", for: indexPath) as! PaymentCardCollectionViewCell
           cell.isFromVerification = true
           cell.updateCell(model: filteredPWASections.first?[indexPath.row], showValue: true, hideDelete: true)
           cell.layoutIfNeeded()
           return cell
       }
       
       func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
           return collectionView.frame.size
       }
       
       func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
           let pageWidth = scrollView.frame.width
           pageControll.currentPage = Int((scrollView.contentOffset.x + (0.5 * pageWidth)) / pageWidth)
           selectedIndex = pageControll.currentPage
           selectedPWACredential = filteredPWASections.first?[selectedIndex].value?.EBSI_v2?.credentialJWT ?? ""
       }
       
   }

   extension PaymentDataConfirmationBottonSheetView: UITableViewDataSource, UITableViewDelegate {
       func numberOfSections(in tableView: UITableView) -> Int {
           return 2
       }
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           if section == 0 {
               let filteredSections = viewModel.EBSI_credentials?.filter { section in
                   // Keep section only if ALL items have nil fundingSource
                   section.allSatisfy { item in
                       item.value?.vct != "PaymentWalletAttestation"
                   }
               }
              // let records = filteredSections?.filter( {$0.value?.vct != "PaymentWalletAttestation"})
               return filteredSections?.count ?? 0
           } else {
               return 1
           }
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           switch indexPath.section {
           case 0:
               let records = viewModel.EBSI_credentials?.filter { section in
                   // Keep section only if ALL items have nil fundingSource
                   section.allSatisfy { item in
                       item.value?.vct != "PaymentWalletAttestation"
                   }
               }
               let cell = tableView.dequeueReusableCell(with: CovidValuesRowTableViewCell.self, for: indexPath)
               cell.renderUI(index: indexPath.row, tot: records?.count ?? 0)
               var title: String = ""
               if let name = getNameFromPresentationDefinition(index: indexPath.row), !name.isEmpty {
                   title = name
               } else if let name = records?[indexPath.row].first?.value?.searchableText, !name.isEmpty {
                   title = name.capitalized
               }
               cell.mainLbl.text = title
               cell.blurView.isHidden = true
               cell.rightImage = UIImage(systemName: "chevron.right")
               cell.rightImageView.tintColor = .darkGray
               //cell.disableCheckBox()
               cell.layoutIfNeeded()
               return cell
           case 1:
               let cell = tableView.dequeueReusableCell(with: PaymentDataConfirmationTableViewCell.self, for: indexPath)
               cell.selectionStyle = .none
               let clientDataString = clientMetaData.replacingOccurrences(of: "+", with: " ")
               let clientMetadataJson = clientDataString.replacingOccurrences(of: "\'", with: "\"").data(using: .utf8)!
               let clientMetaDataModel = try? JSONDecoder().decode(eudiWalletOidcIos.ClientMetaData.self, from: clientMetadataJson)
               cell.configureCell(transactionData: self.transactionData, clientMetaDataModel: clientMetaDataModel)
               return cell
           default:
               return UITableViewCell()
           }
       }
       
       func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
           return UITableView.automaticDimension
       }
       
       func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
           let headerView = UIView()
           headerView.backgroundColor = .appColor(.walletBg)

               let label = UILabel()
               label.translatesAutoresizingMaskIntoConstraints = false
           //label.text = "Additional data requests:".uppercased()
           label.font = UIFont.systemFont(ofSize: 14)
           label.textColor = .darkGray

           headerView.addSubview(label)
           
           if section == 0 {
               label.text = "ADDITIONAL DATA REQUESTS:".localizedForSDK()
               NSLayoutConstraint.activate([
                   label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
                   label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                   label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
                   label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
               ])
           } else {
               label.text = "PAYMENT BEING MADE TO"
               NSLayoutConstraint.activate([
                   label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 15),
                   label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
                   label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 0),
                   label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
               ])
           }
           
           return headerView
       }
       
       func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
           return 30
       }
       
       func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           if indexPath.section == 0 {
               let vc = PaymentAdditionalDataRequestBottomSheetVC(nibName: "PaymentAdditionalDataRequestBottomSheetVC", bundle: nil)

               let filteredSections = viewModel.EBSI_credentials?.filter { section in
                   // Keep section only if ALL items have nil fundingSource
                   section.allSatisfy { item in
                       item.value?.vct != "PaymentWalletAttestation"
                   }
               }
               
               vc.credentailModel = filteredSections?[indexPath.row]
               vc.delegate = self
               let key = indexPath
               vc.selectedCredentialIndex = lastSelectedIndexesPerRow[key] ?? 0
               
               vc.onCredentialIndexChange = { [weak self] selectedIndex in
                   self?.lastSelectedIndexesPerRow[key] = selectedIndex
               }
               vc.cellIndex = indexPath.row
               vc.sectionIndex = filteredToOriginalSectionMap[indexPath.row]
               vc.queryItem = queryItem
               self.delegate?.presentVC(vc: vc)
           }
       }
       
   }

   extension PaymentDataConfirmationBottonSheetView: PaymentAdditionalDataRequestBottomSheetVCDelegate {
       
       func didScrollToCredential(at index: Int) {
           lastSelectedIndexFromAditionalData = index
       }
       
       
       func didSelectCredential(for data: String?, section: Int) {
           selectedCredentialIndexes[section] = data
           print("")
       }
       
       
   }
