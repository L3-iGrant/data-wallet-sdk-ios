//
//  BoardingPassViewModel.swift
//  dataWallet
//
//  Created by iGrant on 06/08/25.
//

import Foundation
import eudiWalletOidcIos
import IndyCWrapper

final class BoardingPassViewModel {
    
    var originatingFrom: CredentialViewType = .other
    var certModel:SearchItems_CustomWalletRecordCertModel?
    var walletHandle: IndyHandle?
    weak var delegate: ReceiptItemViewModelDelegate?
    var reqId : String?
    var inboxId: String?
    var connectionModel: CloudAgentConnectionWalletModel?
    var histories: HistoryRecordValue?
    var isFromExpired: Bool = false
    var isRejectOrAcceptTapped: Bool = false

    
    func deleteCredentialWith(id:String,walletRecordId: String?) {
        let walletHandler = self.walletHandle ?? 0
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, id: walletRecordId ?? "") { [weak self](success, error) in
            AriesPoolHelper.shared.deleteCredentialFromWallet(withId: id, walletHandle: walletHandler) {[weak self] (success, error) in
                    NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                Task { [weak self] in
                    if let notificationEndPont = self?.certModel?.value?.notificationEndPont, let notificationID = self?.certModel?.value?.notificationID {
                        let accessTokenParts = self?.certModel?.value?.accessToken?.split(separator: ".")
                        var accessTokenData: String? =  nil
                        var refreshTokenData: String? =  nil
                        if accessTokenParts?.count ?? 0 > 1 {
                            let accessTokenBody = "\(accessTokenParts?[1] ?? "")".decodeBase64()
                            let dict = UIApplicationUtils.shared.convertToDictionary(text: String(accessTokenBody ?? "{}")) ?? [:]
                            let exp = dict["exp"] as? Int ?? 0
                            let expiryDate = TimeInterval(exp)
                            let currentTimestamp = Date().timeIntervalSince1970
                            if expiryDate < currentTimestamp {
                                accessTokenData = await NotificationService().refreshAccessToken(refreshToken: self?.certModel?.value?.refreshToken ?? "", endPoint: self?.certModel?.value?.tokenEndPoint ?? "").0
                                refreshTokenData = await NotificationService().refreshAccessToken(refreshToken: self?.certModel?.value?.refreshToken ?? "", endPoint: self?.certModel?.value?.tokenEndPoint ?? "").1
                            } else {
                                accessTokenData = self?.certModel?.value?.accessToken
                                refreshTokenData = self?.certModel?.value?.refreshToken
                            }
                        }
                        self?.certModel?.value?.refreshToken = refreshTokenData
                        self?.certModel?.value?.accessToken = accessTokenData
                        await NotificationService().sendNoticationStatus(endPoint: self?.certModel?.value?.notificationEndPont, event: NotificationStatus.credentialDeleted.rawValue, notificationID: self?.certModel?.value?.notificationID, accessToken: self?.certModel?.value?.accessToken ?? "", refreshToken: self?.certModel?.value?.refreshToken ?? "", tokenEndPoint: self?.certModel?.value?.tokenEndPoint ?? "")
                    }
                }
                self?.delegate?.dismiss()
            }
        }
    }
    
    func rejectCertificate() {
        let walletHandler = walletHandle ?? IndyHandle()
        UIApplicationUtils.showLoader()
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.certType, id: self.reqId ?? "") {[weak self]
            (deletedSuccessfully, error) in
            AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: self?.inboxId ?? "") { [weak self](deletedSuccessfully, error) in
                print("Cert deleted \(deletedSuccessfully)")
                UIApplicationUtils.hideLoader()
                self?.isRejectOrAcceptTapped = true
                self?.delegate?.dismiss()
                NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
            }
        }
    }
    
    
    func acceptEBSI_V2_Certificate() async {
        let walletHandler = self.walletHandle ?? 0
        do {
            let (success, certRecordId) = try await WalletRecord.shared.add(connectionRecordId: "", walletCert: certModel?.value, walletHandler: walletHandler, type: .walletCert)
            await self.addHistory()
            isRejectOrAcceptTapped = true
            if success {
                UIApplicationUtils.showSuccessSnackbar(message: "connect_new_certificate_is_added_to_your_data_wallet".localizedForSDK())
                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                NotificationCenter.default.post(name: Constants.reloadOrgList, object: nil)
                if let notificationEndPont = certModel?.value?.notificationEndPont, let notificationID = certModel?.value?.notificationID {
                    let accessTokenParts = certModel?.value?.accessToken?.split(separator: ".")
                    var accessTokenData: String? =  nil
                    var refreshTokenData: String? =  nil
                    if accessTokenParts?.count ?? 0 > 1 {
                        let accessTokenBody = "\(accessTokenParts?[1] ?? "")".decodeBase64()
                        let dict = UIApplicationUtils.shared.convertToDictionary(text: String(accessTokenBody ?? "{}")) ?? [:]
                        let exp = dict["exp"] as? Int ?? 0
                        let expiryDate = TimeInterval(exp)
                        let currentTimestamp = Date().timeIntervalSince1970
                        if expiryDate < currentTimestamp {
                            accessTokenData = await NotificationService().refreshAccessToken(refreshToken: certModel?.value?.refreshToken ?? "", endPoint: certModel?.value?.tokenEndPoint ?? "").0
                            refreshTokenData = await NotificationService().refreshAccessToken(refreshToken: certModel?.value?.refreshToken ?? "", endPoint: certModel?.value?.tokenEndPoint ?? "").1
                        } else {
                            accessTokenData = certModel?.value?.accessToken
                            refreshTokenData = certModel?.value?.refreshToken
                        }
                    }
                    certModel?.value?.refreshToken = refreshTokenData
                    certModel?.value?.accessToken = accessTokenData
                    await NotificationService().sendNoticationStatus(endPoint: certModel?.value?.notificationEndPont, event: NotificationStatus.credentialAccepted.rawValue, notificationID: certModel?.value?.notificationID, accessToken: certModel?.value?.accessToken ?? "", refreshToken: certModel?.value?.refreshToken ?? "", tokenEndPoint: certModel?.value?.tokenEndPoint ?? "")
                }
            } else {
                UIApplicationUtils.showErrorSnackbar(message: "Error saving certificate to wallet")
            }
            if inboxId != nil { //ie from notification list. For EBSI, we need to delete the list item after adding cert.
                AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: self.inboxId ?? "") { [weak self](deletedSuccessfully, error) in
                    print("Cert deleted \(deletedSuccessfully)")
                    UIApplicationUtils.hideLoader()
                    self?.delegate?.dismiss()
                }
            } else {
                UIApplicationUtils.hideLoader()
            self.delegate?.dismiss()
            }
            
        } catch {
            UIApplicationUtils.hideLoader()
            UIApplicationUtils.showErrorSnackbar(message: "Error saving certificate to wallet")
            debugPrint(error.localizedDescription)
        }
    }
    
    func addHistory(mode: CertificatePreviewVC_Mode = .other) async{
        do {
            let walletHandler = walletHandle ?? IndyHandle()
            var history = History()
            let attrArray = certModel?.value?.EBSI_v2?.attributes ?? []
            history.attributes = attrArray
            history.attributesValues = certModel?.value?.attributes
            history.sectionStruct = certModel?.value?.sectionStruct
            history.dataAgreementModel?.validated = .not_validate
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
            history.date = dateFormat.string(from: Date())
            history.type = HistoryType.issuedCertificate.rawValue
            
            switch mode {
            case .EBSI_V2,.EBSI_PDA1:
                    history.certSubType = certModel?.value?.subType
                case .other:
                    history.certSubType = certModel?.value?.subType
                case .Receipt:
                history.certSubType = CertSubType.Reciept.rawValue
            default:
                history.certSubType = certModel?.value?.subType
            }
            var historyName = ""
            if let name = certModel?.value?.type {
                historyName = name
            }
            // Setting credential branding data
            if history.display == nil {
                history.display = CredentialDisplay(name: nil, location: nil, locale: nil, description: nil, cover: nil, logo: nil, backgroundColor: nil, textColor: nil)
            }
            history.receiptData = certModel?.value?.receiptData
            history.connectionModel = connectionModel
            history.name = certModel?.value?.searchableText ?? historyName
            history.display?.name = certModel?.value?.searchableText
            history.display?.description = certModel?.value?.description
            history.display?.logo = certModel?.value?.logo
            history.display?.cover = certModel?.value?.cover
            history.display?.backgroundColor = certModel?.value?.backgroundColor
            history.display?.textColor = certModel?.value?.textColor
            let (success, id) = try await WalletRecord.shared.add(connectionRecordId: "", walletHandler: walletHandler, type: .dataHistory, historyModel: history)
            debugPrint("historySaved -- \(success)")
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
}
