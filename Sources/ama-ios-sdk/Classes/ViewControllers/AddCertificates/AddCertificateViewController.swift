//
//  AddCertificateViewController.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 17/07/21.
//

import UIKit
import qr_code_scanner_ios
//import mrz_nfc_reader_ios
import Localize_Swift
import Gzip
import AVFoundation

final class AddCertificateViewController: AriesBaseViewController, NavigationHandlerProtocol {

    func rightTapped(tag: Int) {
        if let vc = CountriesViewController().initialize() as? CountriesViewController {
            vc.delegate = self
            vc.allowMultipleSelection = true
            vc.selectedCountries = viewModel.selectedCountriesArray
            self.push(vc: vc)
        }
    }

    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBarBgView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!

    var navHandler: NavigationHandler!
    var viewModel = AddCertificateViewModel()
    var isSelfCredentials = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(right: [.connectionSettings])
        tableView.delegate = self
        tableView.dataSource = self
        viewModel.delegate = self
        searchBar.delegate = self
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = UIColor.white.cgColor
        searchBarBgView.layer.cornerRadius = 8
        scanButton.layer.cornerRadius = 23
        if !isSelfCredentials {
            viewModel.configForAllCards()
            fetchAllnotifications()
        } else {
            viewModel.configForSelfAttestedCert()
        }
        searchBar.removeBg()
        viewModel.getSelectedCountries()
        NotificationCenter.default.addObserver(self, selector: #selector(fetchAllnotifications), name: Constants.didRecieveCertOffer, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchAllnotifications), name: Constants.didReceiveDataExchangeRequest, object: nil)
    }

    @objc
    func fetchAllnotifications(){
        viewModel.fetchNotifications(completion: {[weak self] (success) in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchBar.placeholder = "Search".localizedForSDK()
//         IDCardListViewController.addDummyData(navVC: self.navigationController!)
    }

    override func localizableValues() {
        super.localizableValues()
        self.title = "Add Card".localizedForSDK()
        self.searchBar.placeholder = "Search".localizedForSDK()
    }

    @IBAction func scanButtonTapped(_ sender: Any) {

    }

    @IBAction func searchBarCancelButtonAction(_ sender: Any) {
        self.view.endEditing(true)
        self.cancelButton.isEnabled = false
    }
}

extension AddCertificateViewController : UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let item = viewModel.searchedCardTypes?[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier:"AddCovidCertificateTableViewCell",for: indexPath) as! AddCovidCertificateTableViewCell
            cell.title.text = item?.title?.localizedForSDK().uppercased()
            cell.subTitle.text = item?.subTitle ?? ""
            cell.mainImage.image = item?.mainImage
            cell.subImage.image = item?.subImage
            return cell

        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier:"NotificationTableViewCell",for: indexPath) as! NotificationTableViewCell

            let inboxData = viewModel.searchedNotifications?[indexPath.row]
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
                if(inboxData?.tags?.state != "offer_received") {
                    cell.notificationStatus.isHidden = false
                    //                cell.notificationStatus.text = "Processing"
                }
            } else {
                let req = inboxData?.value?.presentationRequest
                cell.certName?.text = req?.value?.presentationRequest?.name ?? ""
                cell.notificationType.text = "Data exchange".localizedForSDK()
                let dateFormat = DateFormatter.init()
                dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
                if let notifDate = dateFormat.date(from: req?.value?.updatedAt ?? "") {
                    cell.time.text = notifDate.timeAgoDisplay()
                }
            }

            UIApplicationUtils.shared.setRemoteImageOn(cell.orgImage, url: inboxData?.value?.connectionModel?.value?.imageURL ?? "")
            cell.shadowView.layer.cornerRadius = 20
            cell.selectionStyle = .none
            if indexPath.row == (tableView.numberOfRows(inSection: indexPath.section) - 1) {
                cell.separatorInset = UIEdgeInsets(top: 0, left: cell.bounds.size.width , bottom: 0, right: 0)
            }else{
                cell.separatorInset = UIEdgeInsets.zero
            }
            return cell
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return viewModel.searchedCardTypes?.count ?? 0
        } else {
            return viewModel.searchedNotifications?.count ?? 0
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        if (indexPath.section == 0) {
            switch viewModel.searchedCardTypes?[indexPath.row].type {
            case .Aadhar:
                if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
                    DispatchQueue.main.async {
                        self.showQRCode()
                    }
                } else {
                    AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                        if granted {
                            DispatchQueue.main.async {
                                self.showQRCode()
                            }
                        } else {
                            return
                        }
                    })
                }
            case .EU_Passport:
                if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
                    DispatchQueue.main.async {
//                        self.addEUPassport()
                    }
                } else {
                    AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                        if granted {
                            DispatchQueue.main.async {
//                                self.addEUPassport()
                            }
                        } else {
                            return
                        }
                    })
                }
            case .other,.EBSI_verifiableID,.EBSI_studentID,.EBSI_diploma:
                self.showQRCode()
            case .My_data_profile:
                let vc = MyDataProfileViewController(nibName: "MyDataProfileViewController", bundle: Constants.bundle)
                push(vc: vc)
                break
            default:
                return
            }
        } else {
            let inboxData = viewModel.notifications?[indexPath.row]
            let type = inboxData?.value?.type
            if type == InboxType.certOffer.rawValue {
                let offer = inboxData?.value?.offerCredential
                if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "CertificatePreviewViewController") as? CertificatePreviewViewController {
                    controller.viewModel = CertificatePreviewViewModel.init(walletHandle: viewModel.walletHandler, reqId: inboxData?.value?.connectionModel?.id ?? "", certDetail: offer, inboxId: inboxData?.id,connectionModel: inboxData?.value?.connectionModel,dataAgreement: inboxData?.value?.dataAgreement)
                    controller.inboxCertState = inboxData?.tags?.state
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            } else {
                let req = inboxData?.value?.presentationRequest
                if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:Bundle.module).instantiateViewController( withIdentifier: "ExchangeDataPreviewViewController") as? ExchangeDataPreviewViewController {
                    controller.viewModel = ExchangeDataPreviewViewModel.init(walletHandle: viewModel.walletHandler, reqDetail: req, inboxId: inboxData?.id,connectionModel:inboxData?.value?.connectionModel)
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            }
        }
    }
}

extension AddCertificateViewController: QRScannerViewDelegate {

    func showQRCode() {
        let newVC = AriesBaseViewController()
        let qrScannerView = QRScannerView(frame: newVC.view.bounds)
        newVC.view.addSubview(qrScannerView)
        qrScannerView.configure(delegate: self)
        qrScannerView.startRunning()
        newVC.title = "Scan".localizedForSDK()
        let topVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController
        topVC?.pushViewController(newVC, animated: true)
    }

    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        self.navigationController?.popViewController(animated: true)
        
        //Check EBSI
        Task {
            if await EBSIWallet.shared.checkEBSI_QR(code: code) { return}
            var isAriesRequired = UserDefaults.standard.bool(forKey: "isAriesRequired")
            if  UserDefaults.standard.object(forKey: "isAriesRequired") == nil {
                isAriesRequired = true
            }
            if isAriesRequired {
            let value = "\(code.split(separator: "=").last ?? "")".decodeBase64() ?? ""
            let data = UIApplicationUtils.shared.convertToDictionary(text: value)
            
            if let type = data?["type"] as? String,
               type == "self_attested",
               let data = value.data(using: .utf8) {
                let decoder = JSONDecoder()
                do {
                    let result = try decoder.decode(SelfAttestedModel.self, from: data)
                    let vc = OrganizationDetailViewController()
                    vc.viewModel = OrganizationDetailViewModel(walletHandle: self.viewModel.walletHandler, render: .genericCard(model: result))
                    push(vc: vc)
                } catch {
                    print(error)
                }
            } else {
                let qrModel = ExchangeDataQRCodeModel.decode(withDictionary: data as NSDictionary? ?? NSDictionary()) as? ExchangeDataQRCodeModel
                if qrModel?.invitationURL == nil {
                    Task {
                        let (success, qrCodeModel, message, id) = await AriesMobileAgent.shared.saveConnection(withPopup: true, url: code)
                        if success {
                            if let message = message, message.isNotEmpty {
                                UIApplicationUtils.showSuccessSnackbar(message: message)
                            }
                        } else {
                            if let message = message, message.isNotEmpty {
                                UIApplicationUtils.showErrorSnackbar(message: message)
                            }
                        }
                        
                        if success {
                            AadharQRUtils.shared.populateAadharQRDetails(code: code)
                        }
                    }
                } else {
                    AadharQRUtils.shared.populateAadharQRDetails(code: code)
                }
            }
            } else {
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.showErrorSnackbar(message: "Aries disabled".localizedForSDK())
                return
            }
        }
    }

    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        UIApplicationUtils.showErrorSnackbar(message: "Invalid QR code")
        self.navigationController?.popViewController(animated: true)
    }

    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess binary: [UInt8]) {
        UIApplicationUtils.showErrorSnackbar(message: "Invalid QR code")
        self.navigationController?.popViewController(animated: true)
    }
}

extension AddCertificateViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.updateSearchedItems(searchString: searchText)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.cancelButton.isEnabled = true
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.cancelButton.isEnabled = false
    }
}

extension AddCertificateViewController: AddCertificateDelegate {
    func reloadData() {
        self.tableView.reloadData()
    }
}

//Countrycode delegate methods
extension AddCertificateViewController: CountriesViewControllerDelegate {
    func countriesViewController(_ countriesViewController: CountriesViewController, didSelectCountries countries: [Country]) {
        var arrayOfIds: [String] = []
        countries.forEach { co in
            arrayOfIds.append(co.regionID ?? "")
            arrayOfIds.append(contentsOf: co.parent ?? [])
        }
        let idsSet = Set(arrayOfIds)
        UserDefaults.standard.setValue(idsSet.joined(separator: ","), forKey: Constants.add_card_selected_countries)
        viewModel.getSelectedCountries()
    }

    func countriesViewControllerDidCancel(_ countriesViewController: CountriesViewController) {
    }

    func countriesViewController(_ countriesViewController: CountriesViewController, didSelectCountry country: Country) {

    }

    func countriesViewController(_ countriesViewController: CountriesViewController, didUnselectCountry country: Country) {

        //        Logger.println(country.name + " unselected")

    }
}

//EU Passport
extension AddCertificateViewController{
//    func addEUPassport() {
//       // mrzNfcReader.masterListURL = Bundle.main.url(forResource: "masterList", withExtension: ".pem")
//        mrzNfcReader.showPassportScanner(language: Localize.currentLanguage(), completed: { [weak self] (passportModel, error) in
//            if  !(passportModel?.passportDataNotTampered ?? true) || !(passportModel?.PACEStatus == .success) {
//                DispatchQueue.main.async {
//                    let alert = UIAlertController(title: "Error".localizedForSDK(), message: "Passport authentication failed.".localizedForSDK(), preferredStyle: UIAlertController.Style.alert)
//                    alert.addAction(UIAlertAction(title: "OK".localizedForSDK(), style: UIAlertAction.Style.default, handler: nil))
//                    self?.present(alert, animated: true, completion: nil)
//                }
//                return
//            }
//            if let passport = passportModel {
////                DispatchQueue.main.async {
////                    // All good, we got a passport
////                    guard let _ = self else { return }
////                    let vc = CertificateViewController(pageType: .passport(isScan: true))
////                    let model = IDCardModel.initFromPassportModel(model: passport)
////                    vc.viewModel.passport.passportModel = model
////                    self?.pop()
////                    self?.push(vc: vc)
////
////                }
//            } else {
//                DispatchQueue.main.async {
//                    let alert = UIAlertController(title: "Error".localizedForSDK(), message: "Not able to get data from NFC.".localize, preferredStyle: UIAlertController.Style.alert)
//                    alert.addAction(UIAlertAction(title: "OK".localize, style: UIAlertAction.Style.default, handler: nil))
//                    self?.present(alert, animated: true, completion: nil)
//                }
//            }
//        })
//    }
}
