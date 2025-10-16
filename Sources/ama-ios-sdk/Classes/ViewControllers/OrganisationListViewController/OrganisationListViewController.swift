//
//  OrganisationListViewController.swift
//  Alamofire
//
//  Created by Mohamed Rebin on 06/12/20.
//

import Foundation
import Kingfisher
import SVProgressHUD
import qr_code_scanner_ios

class OrganisationListViewController: AriesBaseViewController {
    
    var viewModel : OrganisationListViewModel?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionViewBaseView: UIView!
    @IBOutlet weak var orgHeaderLabel: UILabel!
    @IBOutlet weak var orgDescriptionLabel: UILabel!
    @IBOutlet weak var searchBarBgView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    var navHandler: NavigationHandler!

    override func viewDidLoad() {
        super.viewDidLoad()
        didLoadFunc()
        setNav()
    }
    
    @objc func reloadList() {
        viewModel?.fetchOrgList(completion: { [weak self] (success) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self?.collectionView.reloadData()
            })
        })
    }
    
    override func localizableValues() {
        super.localizableValues()
        self.orgHeaderLabel.text = "Organisations".localizedForSDK()
        self.orgDescriptionLabel.text = "Choose the organisation to add data to the data wallet. For adding new organisations, click + above".localizedForSDK()
        self.searchBar.placeholder = "Search".localizedForSDK()
        self.cancelButton.setTitle("Cancel".localizedForSDK(), for: .normal)
        self.collectionView.reloadData()
    }
    
    private func setNav() {
        navHandler = NavigationHandler(parent: self, delegate: self)
        navHandler.setNavigationComponents(title: "")
    }
    
    func setupUI() {
        collectionViewBaseView.layer.cornerRadius = 10
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.searchBar.placeholder = "Search".localizedForSDK()
        if viewModel == nil {
            let quick = QuickActionNavigation.shared
            let orgInit = OrganisationListViewModel.init(walletHandle: quick.walletHandle,mediatorVerKey: quick.mediatorVerKey)
            self.viewModel = orgInit
            self.didLoadFunc()
            UIApplicationUtils.hideLoader()
            
        }
    }
    
    @IBAction func addNewOrgButtonAction(_ sender: Any) {
        self.initaiateNewConnectionToCloudAgent()
    }
    
    @IBAction func searchBarCancelButtonAction(_ sender: Any) {
        self.view.endEditing(true)
        self.cancelButton.isEnabled = false
    }
    
    func didLoadFunc() {
        setupUI()
        collectionView.delegate = self
        collectionView.dataSource = self
        viewModel?.pageDelegate = self
        self.title = ""
        let layout = UICollectionViewFlowLayout()
        self.collectionView.collectionViewLayout = layout
        searchBar.delegate = self
        searchBar.layer.borderWidth = 1
        searchBar.layer.borderColor = UIColor.white.cgColor
        searchBarBgView.layer.cornerRadius = 8
        searchBar.removeBg()
        NotificationCenter.default.addObserver(self, selector: #selector(reloadList), name: Constants.reloadOrgList, object: nil)
        viewModel?.fetchOrgList(completion: { [weak self] (success) in
            self?.collectionView.reloadData()
        })
    }
}

extension OrganisationListViewController: UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModel?.searchedConnections?.count == 0 || viewModel?.searchedConnections == nil {
            self.collectionView.setEmptyMessage(self.searchBar.text == "" ? "Click '+' next to Organisations to connect to an organisation to add data.".localizedForSDK() : "No result found".localizedForSDK())
            self.collectionViewBaseView.backgroundColor = self.view.backgroundColor
        } else {
            self.collectionView.restore()
            self.collectionViewBaseView.backgroundColor = .white
            
        }
        return viewModel?.searchedConnections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OrganisationListCollectionViewCell", for: indexPath as IndexPath) as! OrganisationListCollectionViewCell
        let connection = viewModel?.searchedConnections?[indexPath.row]
        cell.orgName.text = connection?.value?.theirLabel != "" ? connection?.value?.theirLabel : "No Name".localizedForSDK()
        cell.orgImage.layer.cornerRadius = 30
        UIApplicationUtils.shared.setRemoteImageOn(cell.orgImage, url: connection?.value?.imageURL ?? "")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (collectionView.frame.size.width - (5 * 3))/3, height: 120.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row >= viewModel?.searchedConnections?.count ?? 0 {
            return
        }
        let item = viewModel?.searchedConnections?[indexPath.row]
        UIPasteboard.general.string = item?.value?.myDid ?? ""
        if item?.value?.isIgrantAgent == "1" {
            if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "IgrantAgentOrgDetailViewController") as? IgrantAgentOrgDetailViewController {
                controller.viewModel = IgrantAgentOrgDetailViewModel.init(walletHandle: viewModel?.walletHandle,reqId: item?.value?.requestID, isiGrantOrg: item?.value?.isIgrantAgent == "1")
                self.navigationController?.pushViewController(controller, animated: true)
            }
        } else {
            if let controller = UIStoryboard(name:"ama-ios-sdk", bundle:UIApplicationUtils.shared.getResourcesBundle()).instantiateViewController( withIdentifier: "CertificateListViewController") as? CertificateListViewController {
                controller.viewModel = CertificateListViewModel.init(walletHandle: viewModel?.walletHandle, reqId: item?.value?.requestID,connectionModel:item?.value)
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
}

//Cloud connection
extension OrganisationListViewController: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess binary: [UInt8]) {
        UIApplicationUtils.showErrorSnackbar(message: "Invalid QR code")
        self.navigationController?.popViewController(animated: true)
    }
    
    func initaiateNewConnectionToCloudAgent() {
        let newVC = AriesBaseViewController()
        let qrScannerView = QRScannerView(frame: newVC.view.bounds)
        newVC.view.addSubview(qrScannerView)
        qrScannerView.configure(delegate: self)
        qrScannerView.startRunning()
        newVC.title = "Scan".localizedForSDK()
        self.navigationController?.pushViewController(newVC, animated: true)
    }
    
    func getCloudAgent() -> UIViewController {
        let newVC = AriesBaseViewController()
        let qrScannerView = QRScannerView(frame: newVC.view.bounds)
        newVC.view.addSubview(qrScannerView)
        qrScannerView.configure(delegate: self)
        qrScannerView.startRunning()
        newVC.title = "Scan".localizedForSDK()
        return newVC
    }
    
    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        self.navigationController?.popViewController(animated: true)
        Task {
            if await EBSIWallet.shared.checkEBSI_QR(code: code) { return}
            var isAriesRequired = UserDefaults.standard.bool(forKey: "isAriesRequired")
            if  UserDefaults.standard.object(forKey: "isAriesRequired") == nil {
                isAriesRequired = true
            }
            if isAriesRequired {
                
                let value = "\(code.split(separator: "=").last ?? "")".decodeBase64() ?? ""
                let dataDID = UIApplicationUtils.shared.convertToDictionary(text: value)
                let recipientKey = (dataDID?["recipientKeys"] as? [String])?.first ?? ""
                let label = dataDID?["label"] as? String ?? ""
                let serviceEndPoint = dataDID?["serviceEndpoint"] as? String ?? ""
                let routingKey = (dataDID?["routingKeys"] as? [String]) ?? []
                let imageURL = dataDID?["imageUrl"] as? String ?? (dataDID?["image_url"] as? String ?? "")
                let type = dataDID?["@type"] as? String ?? ""
                let didcom = type.split(separator: ";").first ?? ""
                
                
                if serviceEndPoint == "" {
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
                        DispatchQueue.main.async {
                            self.viewModel?.fetchOrgList(completion: { [weak self] (success) in
                                self?.collectionView.reloadData()
                            })
                        }
                    }
                    
                    //            if code.contains("igrantio-operator/connection/qr-link") {
                    //                NetworkManager.shared.baseURL = code
                    //                NetworkManager.shared.getQRCodeDetails { (newInvitationData) in
                    //                    let newInv = String(decoding: newInvitationData ?? Data(), as: UTF8.self)
                    //                    print("QRData ... \(newInv)")
                    //                    let newDict = UIApplicationUtils.shared.convertToDictionary(text: newInv)
                    //                    let invitationURL = newDict?["invitation_url"] as? String ?? ""
                    //                    let newValue = "\(invitationURL.split(separator: "=").last ?? "")".decodeBase64() ?? ""
                    //                    let newInvDict = UIApplicationUtils.shared.convertToDictionary(text: newValue)
                    //                    let newRecipientKey = (newInvDict?["recipientKeys"] as? [String])?.first ?? ""
                    //                    let newLabel = newInvDict?["label"] as? String ?? ""
                    //                    let newServiceEndPoint = newInvDict?["serviceEndpoint"] as? String ?? ""
                    //                    let newRoutingKey = (newInvDict?["routingKeys"] as? [String]) ?? []
                    //                    let newImageURL = newInvDict?["imageUrl"] as? String ?? (newInvDict?["image_url"] as? String ?? "")
                    //                    let newType = newInvDict?["@type"] as? String ?? ""
                    //                    let newDidcom = newType.split(separator: ";").first ?? ""
                    //                   UIApplicationUtils.hideLoader()
                    //                    NetworkManager.shared.baseURL = newServiceEndPoint
                    //                    if newServiceEndPoint == "" {
                    //                        UIApplicationUtils.showErrorSnackbar(message: "Sorry, could not open scan content".localizedForSDK())
                    //                        return
                    //                    }
                    //                    self.viewModel?.newConnectionConfigCloudAgent(label: newLabel, theirVerKey: newRecipientKey, serviceEndPoint: newServiceEndPoint,routingKey: newRoutingKey,imageURL: newImageURL, didCom: String(newDidcom),completion: {[weak self] (success) in
                    //                        self.viewModel?.fetchOrgList(completion: { [weak self] (success) in
                    //                            self.collectionView.reloadData()
                    //                        })
                    //                    })
                    //                    return
                    //                }
                    //            } else {
                    //               UIApplicationUtils.hideLoader()
                    //                UIApplicationUtils.showErrorSnackbar(message: "Sorry, could not open scan content".localizedForSDK())
                    //                return
                    //            }
                } else {
                    self.viewModel?.newConnectionConfigCloudAgent(label: label, theirVerKey: recipientKey, serviceEndPoint: serviceEndPoint,routingKey: routingKey,imageURL: imageURL, didCom: String(didcom),completion: {[weak self] (success) in
                        self?.viewModel?.fetchOrgList(completion: { [weak self] (success) in
                            self?.collectionView.reloadData()
                        })
                    })
                }
            } else {
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.showErrorSnackbar(message: "Aries disabled".localizedForSDK())
                return
            }
        }
    }
    
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
        self.navigationController?.popViewController(animated: true)
        
    }
    
}

extension OrganisationListViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel?.searchKey = searchText
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.cancelButton.isEnabled = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.cancelButton.isEnabled = false
    }
}

extension OrganisationListViewController: OrganisationListDelegate {
    func tableAction(_ index: Int) {
        
    }
    
    func reloadData() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
}

extension OrganisationListViewController: NavigationHandlerProtocol {
    func rightTapped(tag: Int) {}
}
