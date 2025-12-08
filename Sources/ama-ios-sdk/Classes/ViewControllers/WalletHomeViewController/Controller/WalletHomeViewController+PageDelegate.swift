//
//  WalletHomeViewController+PageDelegate.swift
//  dataWallet
//
//  Created by sreelekh N on 01/11/21.
//

import Foundation
import UIKit
import eudiWalletOidcIos
extension WalletHomeViewController: WalletHomeViewControllerDelegate, WalletHomeTitleDelegate, ShareDataFlotingDelegate {
    
    func closeButtonAction() {
        dismiss(animated: true)
    }
    
    
    func searchStarted(value: String) {
        self.viewModel.searchBy = value
    }
    
    func filterAction(filterOn: Int) {
        self.viewModel.filterBy = HomeFilterContents(rawValue: filterOn) ?? .all
    }
    
    func notificationTapped() {
        self.viewModel.shouldFetch = viewModel.searchCert.count
        if let vc = NotificationListViewController().initialize() as? NotificationListViewController {
            vc.viewModel = NotificationsListViewModel.init(walletHandle: viewModel.walletHandle)
            self.push(vc: vc)
        }
    }
    
    func connectTapped() {
        self.viewModel.shouldFetch = viewModel.searchCert.count
        let vc = ConnectionsViewController()
        vc.viewModel = OrganisationListViewModel.init(walletHandle: viewModel.walletHandle, mediatorVerKey: WalletViewModel.mediatorVerKey)
        push(vc: vc)
    }
    
    func settingsTapped() {
        self.viewModel.shouldFetch = viewModel.searchCert.count
        let vc = SettingsPageViewController()
        self.push(vc: vc)
    }
    
    func shareDataTapped() {
        //initaiateNewExchangeData()
        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
            initaiateNewExchangeDataForBottomSheet()
        } else {
            initaiateNewExchangeData()
        }
    }
    
    func addCardTapped() {
//        self.viewModel.shouldFetch = viewModel.searchCert.count
//        let vc = AddCertificateViewController().initialize()
//        push(vc: vc)
        
        //SDK
        shareDataTapped()
    }
    
    func orgTapped() {
        self.viewModel.shouldFetch = viewModel.searchCert.count
        let vc = IDCardListViewController().initialize()
        self.push(vc: vc)
    }
    
    func cardTapped(card: Int) {
        self.viewModel.shouldFetch = viewModel.searchCert.count
        let cert = viewModel.searchCert[card]
        if cert.value?.type == CertType.isSelfAttested(type: cert.value?.type) || cert.value?.type == CertType.idCards.rawValue {
            switch cert.value?.subType {
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
                if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
                    let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                    if let topVC = UIApplicationUtils.shared.getTopVC() {
                        present(sheetVC, animated: true, completion: nil)
                    }
                } else {
                    self.push(vc: vc)
                }
                
            case SelfAttestedCertTypes.pkPass.rawValue:
                if let pkPassData = cert.value?.pkPass?.pkPass {
                    PKPassUtils.shared.getDictionaryFromPKPassData(data: pkPassData , completion: { (dict,imageData) in
                        
                        let vc = CertificateViewController(pageType: .pkPass(isScan: false))
                        
                        if let meta = self.coreDataManager.getPKPassMetaData() {
                            vc.viewModel.pkPass = PKPassStateViewModel(pkPassDict: dict, pkPassData: pkPassData, recordId: cert.id ?? "", imageData: imageData, orgName: cert.value?.pkPass?.orgName ?? "")
                            vc.viewModel.pkPass?.PKPassMeta = meta
                            vc.viewModel.pkPass?.subTitleKeys = (meta["PKPASS BoardingPass Flight Number"] ?? []).map({ e in
                                e.lowercased()
                            })
                            self.push(vc: vc)
                            
                        } else {
                            MetaDataUtils.shared.updatePKPassMetaData {
                                if let meta = self.coreDataManager.getPKPassMetaData() {
                                    vc.viewModel.pkPass = PKPassStateViewModel(pkPassDict: dict, pkPassData: pkPassData, recordId: cert.id ?? "", imageData: imageData, orgName: cert.value?.pkPass?.orgName ?? "")
                                    vc.viewModel.pkPass?.PKPassMeta = meta
                                    vc.viewModel.pkPass?.subTitleKeys = (meta["PKPASS BoardingPass Flight Number"] ?? []).map({ e in
                                        e.lowercased()
                                    })
                                    self.push(vc: vc)
                                }
                            }
                        }
                    })
                }
            case SelfAttestedCertTypes.generic.rawValue:
                if let generic = cert.value?.generic {
                    let vc = OrganizationDetailViewController()
                    vc.viewModel = OrganizationDetailViewModel(walletHandle: self.viewModel.walletHandle, render: .genericCard(model: generic), homeData: cert)
                    push(vc: vc)
                }
            case SelfAttestedCertTypes.profile.rawValue:
                if let generic = cert.value?.attributes {
                    let vc = MyDataProfileViewController(nibName: "MyDataProfileViewController", bundle: Constants.bundle)
                    vc.viewModel.walletModel = cert
                    push(vc: vc)
                }
            default:
                if let selfAttestedCert = cert.value?.attributes {
                    let vc = CertificateViewController(pageType: .general(isScan: false))
                    vc.viewModel.general = GeneralStateViewModel.init(walletHandle: viewModel.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert)
                    if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
                        let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                        if let topVC = UIApplicationUtils.shared.getTopVC() {
                            present(sheetVC, animated: true, completion: nil)
                        }
                    } else {
                        self.push(vc: vc)
                    }
                }
            }
        } else {
            
            //TODO: USE CERT SUB TYPE IN FUTURE
            //Receipt
            if let receiptModel = ReceiptCredentialModel.isReceiptCredentialModel(certModel: cert){
                //Show Receipt UI
                let vc = CertificateViewController(pageType: .issueReceipt(mode: .view))
                vc.viewModel.receipt = ReceiptStateViewModel(walletHandle: viewModel.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert, receiptModel: receiptModel)
                self.navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            if cert.value?.subType == "PAYMENT WALLET ATTESTATION" && cert.value?.fundingSource != nil {
                let vc = CertificateViewController(pageType: .pwa(isScan: false))
                vc.viewModel.pwaCert = PWACertViewModel.init(walletHandle: viewModel.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert)
                vc.viewMode = viewMode
                if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
                    let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                    sheetVC.modalPresentationStyle = .overCurrentContext
                    if let topVC = UIApplicationUtils.shared.getTopVC() {
                        present(sheetVC, animated: true, completion: nil)
                    }
                } else {
                    self.push(vc: vc)
                }
            } else if cert.value?.vct == "Receipt" || cert.value?.vct == "VerifiablevReceiptSDJWT"{
                if viewMode == .BottomSheet {
                    let vc = ReceiptBottomSheetVC(nibName: "ReceiptBottomSheetVC", bundle: UIApplicationUtils.shared.getResourcesBundle())
                    vc.viewModel.certModel = cert
                    vc.viewModel.originatingFrom = .detail
                    vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                    let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                    vc.modalPresentationStyle = .overCurrentContext
                    
                    if let topVC = UIApplicationUtils.shared.getTopVC() {
                        topVC.present(sheetVC, animated: false, completion: nil)
                    }
                } else {
                    let vc = ReceiptViewController(nibName: "ReceiptViewController", bundle: Bundle.module)
                    vc.viewModel.certModel = cert
                    vc.viewModel.originatingFrom = .detail
                    vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                    vc.modalPresentationStyle = .fullScreen
                    if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                        UIApplicationUtils.hideLoader()
                        navVC.pushViewController(vc, animated: true)
                    } else {
                        //Fixme - it was push
                        UIApplicationUtils.hideLoader()
                        self.push(vc: vc)
                        //UIApplicationUtils.shared.getTopVC()?.present(vc: vc)
                    }
                }
            } else if  cert.value?.vct == "VerifiableFerryBoardingPassCredentialSDJWT" {
                if viewMode == .BottomSheet {
                    let vc = BoardingPassBottomSheetVC(nibName: "BoardingPassBottomSheetVC", bundle: UIApplicationUtils.shared.getResourcesBundle())
                    vc.viewModel.certModel = cert
                    vc.viewModel.originatingFrom = .detail
                    vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                    let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                    sheetVC.modalPresentationStyle = .overCurrentContext
                    
                    if let topVC = UIApplicationUtils.shared.getTopVC() {
                        topVC.present(sheetVC, animated: false, completion: nil)
                    }
                } else {
                    let vc = BoardingPassViewController(nibName: "BoardingPassViewController", bundle: Bundle.module)
                    vc.viewModel.certModel = cert
                    vc.viewModel.originatingFrom = .detail
                    vc.viewModel.walletHandle = WalletViewModel.openedWalletHandler
                    vc.modalPresentationStyle = .fullScreen
                    if let navVC = UIApplicationUtils.shared.getTopVC() as? UINavigationController {
                        UIApplicationUtils.hideLoader()
                        navVC.pushViewController(vc, animated: true)
                    } else {
                        UIApplicationUtils.hideLoader()
                        UIApplicationUtils.shared.getTopVC()?.push(vc: vc)
                    }
                }
                
            } else if cert.value?.photoIDCredential != nil || cert.value?.vct == "eu.europa.ec.eudi.photoid.1" {
                
                let tempCredential = SDJWTUtils.shared.updateIssuerJwtWithDisclosures(credential: cert.value?.EBSI_v2?.credentialJWT)
                    let dict = UIApplicationUtils.shared.convertToDictionary(text: tempCredential ?? "{}") ?? [:]
                    if let photoIDCredential = cert.value?.photoIDCredential ?? PhotoIDCredential.decode(withpDictionary: dict as [String : Any]) {
                        let vc = CertificateViewController(pageType: .photoId(isScan: false))
                        vc.viewModel.photoID = SelfAttestedPhotoIDViewModel()
                        vc.viewModel.photoID?.photoIDCredential = photoIDCredential
                        vc.viewModel.addedDate = cert.value?.addedDate ?? ""
                        vc.viewModel.photoID?.display = Display(mName: "", mLocation: "", mLocale: "", mDescription: "", mCover: DisplayCover(mUrl: "", mAltText: ""), mLogo:  DisplayCover(mUrl: "", mAltText: ""), mBackgroundColor: cert.value?.backgroundColor, mTextColor: cert.value?.textColor)
                        vc.viewModel.photoID?.orgInfo = cert.value?.connectionInfo?.value?.orgDetails
                        vc.viewModel.photoID?.recordId = cert.id ?? ""
                        if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
                            let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                            if let topVC = UIApplicationUtils.shared.getTopVC() {
                                present(sheetVC, animated: true, completion: nil)
                            }
                        } else {
                            self.push(vc: vc)
                        }
                    }
                
            } else {
                let vc = CertificateViewController(pageType: .general(isScan: false))
                vc.viewMode = viewMode
                vc.viewModel.general = GeneralStateViewModel.init(walletHandle: viewModel.walletHandle, reqId: cert.value?.certInfo?.id, certDetail: cert.value?.certInfo, inboxId: nil, certModel: cert)
                if AriesMobileAgent.shared.getViewMode() == .BottomSheet {
                    let sheetVC = WalletHomeBottomSheetViewController(contentViewController: vc)
                    //sheetVC.modalPresentationStyle = .overCurrentContext
                    if let topVC = UIApplicationUtils.shared.getTopVC() {
                        present(sheetVC, animated: true, completion: nil)
                    }
                } else {
                    self.push(vc: vc)
                }
            }
        }
    }
}
