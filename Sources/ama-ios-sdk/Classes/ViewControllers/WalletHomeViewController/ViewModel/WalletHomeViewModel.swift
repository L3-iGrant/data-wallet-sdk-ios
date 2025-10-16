//
//  WalletHomeViewModel.swift
//  dataWallet
//
//  Created by sreelekh N on 31/10/21.
//

import Foundation
import SVProgressHUD
import IndyCWrapper
import eudiWalletOidcIos
import DeviceCheck

protocol WalletDelegate: AnyObject {
    func walletDataUpdated(itemCount: Int)
}

final class WalletViewModel: NSObject {
    
    let lruCache = LRUCache(capacity: 1000)
    weak var pageDelegate: WalletHomeViewControllerDelegate?
    var shouldFetch: Int?
    var isFirst = true
    static let shared = WalletViewModel()
    private override init(){}
    static var mediatorVerKey: String?
    var walletHandle: IndyHandle? {
        didSet {
            WalletViewModel.openedWalletHandler = walletHandle
        }
    }
    static var openedWalletHandler: IndyHandle?
    static var isWUAEnabled: Bool = false
    static var showShareButton = false
    var invitation: AgentConfigurationResponse?
    var myDid: String?
    var myVerKey: String?
    var mediatorDid: String?
    var connectionHelper = AriesAgentFunctions.shared
    var pollingTimer: Timer?
    weak var delegate: WalletDelegate?
    var certificates: [SearchItems_CustomWalletRecordCertModel] = []
    var wuaCert: [SearchItems_CustomWalletRecordCertModel] = []
    var searchCert: [SearchItems_CustomWalletRecordCertModel] = []
    var pollingInterval = 5
    static var poolingEnabled = true
    var filterBy: HomeFilterContents = .all {
        didSet {
            updateSearchedItems()
        }
    }
    var searchBy: String = "" {
        didSet {
            updateSearchedItems()
        }
    }
    var new_dataAgreement: DataAgreementContext?
    
    func checkForDBUpdate(){
        Task{
            await DataWalletBackwardSupportUtils().checkAndUpdateDataWallet()
            getSavedCertificates()
        }
    }
    
    func checkForAutoBackup(){
        if Constants.autoBackupEnabled && Constants.needBackup{
            if Constants.selectedBackupType == 0 {
                ExportImportWallet.shared.exportWallet(type: .iCloud) { success in
                    if success {
                        Constants.autoBackupDate = Date()
                    }
                }
            } else {
                ExportImportWallet.shared.exportWallet(type: .dataPods) { success in
                    if success {
                        Constants.autoBackupDate = Date()
                    }
                }
            }
        }
    }
    
    func getSavedCertificates() {
        DispatchQueue.main.async {
            
            CredentialManager.shared.checkCredentialExpiry { success in
                if success {
                    WalletRecord.shared.fetchAllCert { certSearchModel in
                        var selfAttestedCertificates: [SearchItems_CustomWalletRecordCertModel] = []
                        var otherCredentials: [SearchItems_CustomWalletRecordCertModel] = []
                        var pwaOrganisationMap: [String: SearchItems_CustomWalletRecordCertModel] = [:]
                        for cert in certSearchModel?.records ?? [] {
                            if cert.value?.type == CertType.idCards.rawValue {
                                selfAttestedCertificates.append(cert)
                            } else {
                                if cert.value?.vct == "PaymentWalletAttestation" && cert.value?.fundingSource != nil {
                                    if let orgName = cert.value?.connectionInfo?.value?.orgDetails?.name {
                                        
                                        if let existingCert = pwaOrganisationMap[orgName] {
                                            if let newDateStr = cert.value?.addedDate,
                                               let existingDateStr = existingCert.value?.addedDate,
                                               let newDate = TimeInterval(newDateStr),
                                               let existingDate = TimeInterval(existingDateStr),
                                               newDate > existingDate {
                                                pwaOrganisationMap[orgName] = cert
                                            }
                                        } else {
                                            pwaOrganisationMap[orgName] = cert
                                        }
                                    }
                                } else {
                                    otherCredentials.append(cert)
                                }
                            }
                        }
                        let pwaCredentials = Array(pwaOrganisationMap.values)
                        let sortedSelfAttestedCert = selfAttestedCertificates.sorted(by: { ($0.value?.searchableText ?? "", $0.value?.passport?.firstName?.value ?? "") > ($1.value?.searchableText ?? "",$1.value?.passport?.firstName?.value ?? "") })
                        let sortedOtherCredentials = otherCredentials.sorted(by: { ($0.value?.searchableText ?? "") > ($1.value?.searchableText ?? "") })
                        self.certificates = sortedSelfAttestedCert + sortedOtherCredentials + self.wuaCert + pwaCredentials
                        
                        if self.certificates.isNotEmpty {
                            WalletViewModel.showShareButton = true
                        } else {
                            WalletViewModel.showShareButton = false
                        }
                        DispatchQueue.main.async {
                            self.updateSearchedItems()
                            self.delegate?.walletDataUpdated(itemCount: self.certificates.count )
                        }
                    }
                } else {
                    WalletRecord.shared.fetchAllCert { certSearchModel in
                        if certSearchModel?.totalCount == 0 {
                            if self.wuaCert.count == 0 {
                                self.certificates = []
                            } else {
                                self.certificates = self.wuaCert
                            }
                            
                            DispatchQueue.main.async {
                                self.updateSearchedItems()
                                self.delegate?.walletDataUpdated(itemCount: self.certificates.count )
                            }
                        }
                    }
                }
            }
        }
    }
    
//    func getSavedCertificates() {
//        WalletRecord.shared.fetchAllCert { certSearchModel in
//            var selfAttestedCertificates: [SearchItems_CustomWalletRecordCertModel] = []
//            var otherCredentials: [SearchItems_CustomWalletRecordCertModel] = []
//            for cert in certSearchModel?.records ?? [] {
//                if cert.value?.type == CertType.idCards.rawValue {
//                    selfAttestedCertificates.append(cert)
//                } else {
//                    otherCredentials.append(cert)
//                }
//            }
//            let sortedSelfAttestedCert = selfAttestedCertificates.sorted(by: { ($0.value?.searchableText ?? "", $0.value?.passport?.firstName?.value ?? "") > ($1.value?.searchableText ?? "",$1.value?.passport?.firstName?.value ?? "") })
//            let sortedOtherCredentials = otherCredentials.sorted(by: { ($0.value?.searchableText ?? "") > ($1.value?.searchableText ?? "") })
//            self.certificates = sortedSelfAttestedCert + sortedOtherCredentials + self.wuaCert
//            self.updateSearchedItems()
//            if self.certificates.isNotEmpty {
//                WalletViewModel.showShareButton = true
//            } else {
//                WalletViewModel.showShareButton = false
//            }
//            self.delegate?.walletDataUpdated(itemCount: self.certificates.count )
//            debugPrint("wallet credentials fetched")
//        }
//    }
    
    func updateSearchedItems() {
        
        let wuaItems = self.wuaCert
        let otherItems = filterByType().filter { item in
            !wuaItems.contains(where: { $0.value?.EBSI_v2?.credentialJWT == item.value?.EBSI_v2?.credentialJWT })
        }
        let othersSortedContent = otherItems.sorted { (item1, item2) -> Bool in
                if let addedTime1String = item1.value?.addedDate,
                   let addedTime2String = item2.value?.addedDate,
                   let addedTime1 = TimeInterval(addedTime1String),
                   let addedTime2 = TimeInterval(addedTime2String) {
                    
                    let date1 = Date(timeIntervalSince1970: addedTime1)
                    let date2 = Date(timeIntervalSince1970: addedTime2)
                    
                    return date1 > date2
                }
                return false
            }
        var sortedContent: [SearchItems_CustomWalletRecordCertModel] = []
        sortedContent = othersSortedContent + wuaItems
//        if filterBy == .all || filterBy == .system {
//            sortedContent = othersSortedContent + wuaItems
//        } else {
//            sortedContent = othersSortedContent
//        }
        if searchBy == "" {
            self.searchCert = sortedContent
            print("sortedContent count 2: \(self.searchCert.count)")
            print("certificates count 2: \(self.certificates.count)")
            delegate?.walletDataUpdated(itemCount: self.certificates.count)
            return
        }
        let filteredArray = sortedContent.filter({ (item) -> Bool in
            return (item.value?.searchableText?.lowercased() ?? "").contains(searchBy.lowercased()) || (item.value?.connectionInfo?.value?.orgDetails?.name?.lowercased() ?? "").contains(searchBy.lowercased())
        })
        self.searchCert = filteredArray
        print("certificates count 3: \(self.certificates.count)")
        delegate?.walletDataUpdated(itemCount: self.certificates.count)
        return
    }
    
//    func updateSearchedItems() {
//        if searchBy == "" {
//            self.searchCert = filterByType()
//            delegate?.walletDataUpdated(itemCount: self.certificates.count)
//            return
//        }
//        let filteredArray = filterByType().filter({ (item) -> Bool in
//            return ((item.value?.searchableText?.lowercased() ?? "").contains(searchBy.lowercased()))
//        })
//        self.searchCert = filteredArray
//        delegate?.walletDataUpdated(itemCount: self.certificates.count)
//        return
//    }
    
    func filterByType() -> [SearchItems_CustomWalletRecordCertModel] {
        switch filterBy {
        case .all:
            return certificates
        case .health:
            return certificates.filter { cert in
                if cert.value?.type == CertType.isSelfAttested(type: cert.value?.type) || cert.value?.type == CertType.idCards.rawValue {
                    return cert.value?.subType == SelfAttestedCertTypes.covidCert_EU.rawValue || cert.value?.subType == SelfAttestedCertTypes.covidCert_IN.rawValue || cert.value?.subType == SelfAttestedCertTypes.covidCert_PHL.rawValue || cert.value?.subType == SelfAttestedCertTypes.digitalTestCertificateEU.rawValue
                } else {
                    return false
                }
            }
        case .profile:
            return certificates.filter { cert in
                return cert.value?.subType == SelfAttestedCertTypes.profile.rawValue
            }
        case .idCards:
            return certificates.filter { cert in
                if cert.value?.type == CertType.isSelfAttested(type: cert.value?.type) || cert.value?.type == CertType.idCards.rawValue {
                    return cert.value?.subType == SelfAttestedCertTypes.aadhar.rawValue || cert.value?.subType == SelfAttestedCertTypes.passport.rawValue
                } else {
                    return false
                }
            }
        case .travel:
            let cert = certificates.filter { cert in
                return cert.value?.subType == SelfAttestedCertTypes.pkPass.rawValue
            }
            return cert
        case .receipts:
            let cert = certificates.filter { cert in
                return cert.value?.subType == CertSubType.Reciept.rawValue || ReceiptCredentialModel.isReceiptCredentialModel(certModel: cert) != nil
            }
            return cert
        }
    }
    
    func setupNewConnectionToMediator() {
        NetworkManager.shared.getAgentConfig { [weak self] (response) in
            self?.invitation = response
            self?.newConnectionConfigMediator(label: response?.invitation?.label ?? "", theirVerKey: response?.invitation?.recipientKeys?.first ?? "", serviceEndPoint: response?.serviceEndpoint ?? "", routingKey: response?.routingKey ?? "")
        }
    }
    
    func checkForWUA(baseUrl: String) {
        Task {
            let baseURL = baseUrl
            let walletHandler = WalletViewModel.openedWalletHandler ?? 0
            
            AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletUnitAttestation,searchType: .withoutQuery) { (success, searchHandler, error) in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (fetched, response, error) in
                    let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                    let searchResponse = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                    Task {
                        do {
                            
                            if searchResponse?.records?.count == 1, let jwt = searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT, !jwt.isEmpty {
                                let keyId = WalletUnitAttestationService().retrieveKeyIdFromKeychain()
                                EBSIWallet.shared.keyIDforWUA = keyId ?? ""
                                EBSIWallet.shared.keyHandlerKeyID = keyId ?? ""
                                let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                                let validKeyID = self.isKeyIDValid(keyHandler: keyHandler, wua: searchResponse?.records?.first?.value?.EBSI_v2?.credentialJWT)
                                EBSIWallet.shared.issueHandler = eudiWalletOidcIos.IssueService(keyHandler: keyHandler)
                                EBSIWallet.shared.verificationHandler = eudiWalletOidcIos.VerificationService(keyhandler: keyHandler)
                                let did = await EBSIWallet.shared.getDIDFromWalletUnitAttestation()
                                EBSIWallet.shared.DIDforWUA = did
                                let revokedCred = await CredentialRevocationService().getRevokedCredentials(credentialList: [jwt], keyHandler: keyHandler)
                                print("wua keyID for testing: \(EBSIWallet.shared.keyIDforWUA )")
                                print("wua credential created for testing: \(jwt)")
                                if ExpiryValidator().validateExpiryDate(jwt: jwt, format: "") ?? false || revokedCred.first == jwt || !validKeyID {
                                    self.connectionHelper.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletUnitAttestation, id: searchResponse?.records?.first?.id ?? "") {[weak self] (deletedSuccessfully, error) in
                                        if deletedSuccessfully {
                                            Task {
                                                let result = try await WalletUnitAttestationService().initiateWalletUnitAttestation(walletProviderUrl: baseURL ?? "")
                                                let keyId = WalletUnitAttestationService().retrieveKeyIdFromKeychain()
                                                EBSIWallet.shared.keyIDforWUA = keyId ?? ""
                                                EBSIWallet.shared.keyHandlerKeyID = keyId ?? ""
                                                let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                                                EBSIWallet.shared.issueHandler = eudiWalletOidcIos.IssueService(keyHandler: keyHandler)
                                                EBSIWallet.shared.verificationHandler = eudiWalletOidcIos.VerificationService(keyhandler: keyHandler)
                                                let did = await EBSIWallet.shared.getDIDFromWalletUnitAttestation()
                                              EBSIWallet.shared.DIDforWUA = did
                                              EBSIWallet.shared.processCredentialOffer(uri: result.1)
                                            }
                                        }
                                    }
                                            
                                }
                            } else {
                                let result = try await WalletUnitAttestationService().initiateWalletUnitAttestation(walletProviderUrl: baseURL ?? "")
                                let keyId = WalletUnitAttestationService().retrieveKeyIdFromKeychain()
                                EBSIWallet.shared.keyIDforWUA = keyId ?? ""
                                EBSIWallet.shared.keyHandlerKeyID = keyId ?? ""
                                let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
                                EBSIWallet.shared.issueHandler = eudiWalletOidcIos.IssueService(keyHandler: keyHandler)
                                EBSIWallet.shared.verificationHandler = eudiWalletOidcIos.VerificationService(keyhandler: keyHandler)
                                let did = await EBSIWallet.shared.getDIDFromWalletUnitAttestation()
                                EBSIWallet.shared.DIDforWUA = did
                                EBSIWallet.shared.processCredentialOffer(uri: result.1)
                                
                            }
                            print("")
                        } catch {
                            print("")
                        }
                    }
                }
            }
        }
    }
    
    func isKeyIDValid(keyHandler: SecureKeyProtocol, wua: String?) -> Bool {
        var isKeyidValid: Bool = false
        if let pubKey = keyHandler.generateSecureKey()?.publicKey {
            let jwk = keyHandler.getJWK(publicKey: pubKey)
            let split = wua?.split(separator: ".")
            if split?.count ?? 0 > 1 {
                let decoded = "\(split?[1] ?? "")".decodeBase64() ?? ""
                let decodedDict = UIApplicationUtils.shared.convertToDictionary(text: decoded)
                if let cnf = decodedDict?["cnf"] as? [String: Any], let jwkData = cnf["jwk"] as? [String: Any] {
                    if areDictionariesEqual(jwk, jwkData) {
                        isKeyidValid = true
                    } else {
                        isKeyidValid = false
                    }
                }
            }
        }
        return isKeyidValid
    }
    
    func areDictionariesEqual(_ lhs: [String: Any]?, _ rhs: [String: Any]?) -> Bool {
        guard let lhsData = try? JSONSerialization.data(withJSONObject: lhs ?? [:], options: [.sortedKeys]),
              let rhsData = try? JSONSerialization.data(withJSONObject: rhs ?? [:], options: [.sortedKeys]) else {
            return false
        }
        return lhsData == rhsData
    }
    
    func fetchWUACredentials() {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
            AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletUnitAttestation,searchType: .withoutQuery) { (success, searchHandler, error) in
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (fetched, response, error) in
                    let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                    let searchResponse = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                    self.wuaCert = searchResponse?.records ?? []
                    self.certificates = searchResponse?.records ?? []
                }
            }
    }

    
    func fetchNotifications(completion: @escaping (Bool) -> Void) {
        WalletRecord.shared.fetchNotifications { notificationModel in
            completion((notificationModel?.records?.count ?? 0) > 0)
        }
    }
    
    func newConnectionConfigMediator(label: String, theirVerKey: String,serviceEndPoint: String, routingKey: String){
        let walletHandler = self.walletHandle ?? 0
        
        WalletRecord.shared.add(invitationKey: theirVerKey, label: label, serviceEndPoint: serviceEndPoint, connectionRecordId: "", walletHandler: walletHandler,type: .mediatorConnection , completion: { [weak self](addRecord_Connection_Completed, connectionRecordId, error) in
            if addRecord_Connection_Completed{
                WalletRecord.shared.add(invitationKey: theirVerKey, label: label, serviceEndPoint: serviceEndPoint,connectionRecordId: connectionRecordId, walletHandler: walletHandler,type: ( .mediatorInvitation)) { [weak self](addWalletRecord_ConnectionInvitation_Completed, connectionInvitationRecordId, error) in
                    if (addWalletRecord_ConnectionInvitation_Completed){
                        WalletRecord.shared.get(walletHandler: walletHandler,connectionRecordId: connectionRecordId, type: AriesAgentFunctions.mediatorConnection, completion: {[weak self] (getWalletRecordSuccessfully,_, error) in
                            if getWalletRecordSuccessfully {
                                self?.connectionHelper.createAndStoreId(walletHandler: walletHandler) {[weak self] (createDidSuccess, myDid, verKey,error) in
                                    self?.mediatorDid = myDid
                                    WalletViewModel.mediatorVerKey = verKey
                                    self?.connectionHelper.setMetadata(walletHandler: walletHandler, myDid: myDid ?? "",verKey:verKey ?? "", completion: {[weak self] (metaAdded) in
                                        if(metaAdded){
                                            self?.connectionHelper.updateWalletRecord(walletHandler: walletHandler,recipientKey: theirVerKey,label: label, type: UpdateWalletType.initial, id: connectionRecordId, theirDid: "", myDid: myDid ?? "",
                                                                                      invitiationKey: theirVerKey,completion: {[weak self] (updateWalletRecordSuccess,updateWalletRecordId ,error) in
                                                if(updateWalletRecordSuccess){
                                                    self?.connectionHelper.updateWalletTags(walletHandler: walletHandler, id: connectionRecordId, myDid: myDid ?? "", theirDid: "",recipientKey: "", serviceEndPoint: "",type: .initial, completion: {[weak self] (updateWalletTagSuccess, error) in
                                                        if(updateWalletTagSuccess){
                                                            self?.getRecordAndConnectForMediator(connectionRecordId: connectionRecordId, verKey: verKey ?? "", myDid: myDid ?? "", recipientKey: theirVerKey, label: label,packageMsgType: .initialMediator,routingKey: "",serviceEndPoint: serviceEndPoint, isRoutingKeyEnabled: false)
                                                        }
                                                    })
                                                }
                                            })
                                        }
                                    })
                                }
                            }
                        })
                    }
                }
            }
        })
    }
    
    func checkMediatorConnectionAvailable() {
        let walletHandler = self.walletHandle ?? 0
        connectionHelper.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.mediatorConnection,searchType: .withoutQuery, completion: {[weak self] (success, searchWalletHandler, error) in
            if (success){
                self?.connectionHelper.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler, completion: {[weak self] (fetchedSuccessfully,results,error) in
                    if (fetchedSuccessfully){
                        let resultDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                        let firstResult = (resultDict?["records"] as? [[String: Any]])?.first
                        if let connectionRecordId = (resultDict?["records"] as? [[String:Any]])?.first?["id"] as? String {
                            if let myDid = (firstResult?["value"] as? [String: Any])?["my_did"] as? String, let recipientKey = (firstResult?["value"] as? [String: Any])?["reciepientKey"] as? String {
                                self?.mediatorDid = myDid
                                self?.connectionHelper.getMyDidWithMeta(walletHandler: walletHandler, myDid: myDid, completion: {[weak self] (metadataReceived,metadata, error) in
                                    let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata ?? "")
                                    if let verKey = metadataDict?["verkey"] as? String{
                                        WalletViewModel.mediatorVerKey = verKey
                                        self?.connectionHelper.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.mediatorConnectionInvitation, searchType: .withoutQuery, completion: {[weak self] (invitationRecordFetchSuccess, invitationRecordSearchWalletHandler, error) in
                                            if (invitationRecordFetchSuccess){
                                                self?.connectionHelper.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: invitationRecordSearchWalletHandler, completion: {[weak self] (fetchedInvitationRecordSuccessfully,results,error) in
                                                    let recordData =  UIApplicationUtils.shared.convertToDictionary(text: results)
                                                    let records = recordData?["records"] as? [[String:Any?]]
                                                    let values = records?.first?["value"] as? [String:Any?]
                                                    let label = values?["label"] as? String ?? ""
                                                    
                                                    if let state = (firstResult?["value"] as? [String: Any])?["state"] as? String, let theirDid =  (firstResult?["value"] as? [String: Any])?["their_did"] as? String {
                                                        if state == "response"{
                                                            self?.createInbox(connectionRecordId: connectionRecordId, verKey: verKey, myDid: myDid , recipientKey: recipientKey,theirDid: theirDid, label: label,invitationKey: recipientKey)
                                                            return
                                                        } else if state == "active"{
                                                            debugPrint("active mediator connection found")
                                                            Task{
                                                                await RegistryHelper.shared.checkForExistingRegistryConnection()
                                                            }
                                                            self?.pollingMediator(connectionRecordId: connectionRecordId, verKey: verKey, myDid: myDid , recipientKey: recipientKey, label: label,packageMsgType: .initialMediator, routingKey: "",serviceEndPoint: "")
                                                            return
                                                        }
                                                    }
                                                    
                                                    self?.getRecordAndConnectForMediator(connectionRecordId: connectionRecordId, verKey: verKey, myDid: myDid , recipientKey: recipientKey, label: label,packageMsgType: .initialMediator, routingKey: "",serviceEndPoint: "", isRoutingKeyEnabled: false)
                                                })
                                            }
                                        })
                                    }
                                })
                            }
                        } else {
                            self?.setupNewConnectionToMediator()
                        }
                    }
                })
            } else {
                self?.setupNewConnectionToMediator()
            }
        })
    }
    
    func getRecordAndConnectForMediator(connectionRecordId: String,verKey: String, myDid: String, recipientKey: String, label: String, packageMsgType: PackMessageType, routingKey: String, serviceEndPoint: String,isRoutingKeyEnabled: Bool){
        let walletHandler = self.walletHandle ?? 0
        
        WalletRecord.shared.get(walletHandler: walletHandler,connectionRecordId: connectionRecordId, type: AriesAgentFunctions.mediatorConnection, completion: {[weak self] (getWallerRecord2Success,_, error) in
            if (getWallerRecord2Success){
                self?.connectionHelper.packMessage(walletHandler: walletHandler,label: label, recipientKey: recipientKey,  id: connectionRecordId, didCom: "", myDid: myDid , myVerKey: verKey ,serviceEndPoint: serviceEndPoint, routingKey: routingKey, deleteItemId: "", type: packageMsgType, isRoutingKeyEnabled: false, completion:{[weak self] (packMsgSuccess, messageData, error) in
                    if (packMsgSuccess){
                        NetworkManager.shared.sendMsg(isMediator:true ,msgData: messageData ?? Data()) {[weak self] (statuscode,receivedData) in
                            
                            self?.connectionHelper.unpackMessage(walletHandler: walletHandler, messageData: receivedData ?? Data() , completion: { [weak self](unpackMsgSuccess, unpackedMsgData, error) in
                                if let messageModel = try? JSONSerialization.jsonObject(with: unpackedMsgData ?? Data(), options: []) as? [String : Any] {
                                    
                                    debugPrint("unpackmsg -- \(messageModel)")
                                    let msgString = (messageModel)["message"] as? String
                                    let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                    //connection~sig
                                    let connSigDict = (msgDict)?["connection~sig"] as? [String:Any]
                                    
                                    let sigDataBase64String = (connSigDict)?["sig_data"] as? String
                                    let sigDataString = sigDataBase64String?.decodeBase64_first8bitRemoved()
                                    let sigDataDict = UIApplicationUtils.shared.convertToDictionary(text: sigDataString ?? "")
                                    let theirDid = sigDataDict?["DID"] as? String ?? ""
                                    let dataDic = ((sigDataDict?["DIDDoc"] as? [String:Any])?["service"] as? [[String:Any]])?.first
                                    let senderVerKey = (dataDic?["recipientKeys"] as? [String])?.first ?? ""
                                    let serviceEndPoint = (dataDic?["serviceEndpoint"] as? String) ?? ""
                                    let routingKey = (dataDic?["routingKeys"] as? [String])?.first ?? ""
                                    self?.connectionHelper.addWalletRecord_DidDoc(walletHandler: walletHandler, invitationKey: recipientKey, theirDid: theirDid , recipientKey: senderVerKey , serviceEndPoint: serviceEndPoint,routingKey: routingKey, type: DidDocTypes.mediatorDidDoc, completion: { [weak self](didDocRecordAdded, didDocRecordId, error) in
                                        if (didDocRecordAdded){
                                            self?.connectionHelper.addWalletRecord_DidKey(walletHandler: walletHandler, theirDid: theirDid, recipientKey: senderVerKey, type: DidKeyTypes.mediatorDidKey, completion: { [weak self](didKeyRecordAdded, didKeyRecordId, error) in
                                                self?.connectionHelper.updateWalletRecord(walletHandler: walletHandler,recipientKey: senderVerKey,label: label, type: .updateTheirDid, id: connectionRecordId, theirDid: theirDid, myDid: myDid ,invitiationKey: recipientKey, completion: {[weak self] (updatedSuccessfully, updatedRecordId, error) in
                                                    if(updatedSuccessfully){
                                                        self?.connectionHelper.updateWalletTags(walletHandler: walletHandler, id: connectionRecordId, myDid: myDid , theirDid: theirDid, recipientKey: senderVerKey, serviceEndPoint: "", invitiationKey: recipientKey, type: .updateTheirDid, completion: { [weak self](updatedSuccessfully, error) in
                                                            if (updatedSuccessfully){
                                                                if packageMsgType == .initialMediator {
                                                                    self?.createInbox(connectionRecordId: connectionRecordId, verKey: verKey, myDid: myDid , recipientKey: senderVerKey,theirDid: theirDid, label: label,invitationKey: recipientKey)
                                                                }
                                                            }
                                                        })
                                                    }
                                                })
                                            })
                                        }
                                    })
                                }
                            })
                        }
                    }
                })
            }
        })
    }
    
    
    
    
    func createInbox(connectionRecordId: String,verKey: String, myDid: String, recipientKey: String, theirDid: String, label: String, invitationKey: String) {
        let walletHandler = self.walletHandle ?? 0
        self.connectionHelper.packMessage(walletHandler: walletHandler, label: label, recipientKey: recipientKey, id: connectionRecordId, didCom: "", myDid: myDid, myVerKey: verKey, serviceEndPoint: "", routingKey: "", deleteItemId: "", type: .createInbox,isRoutingKeyEnabled: false) { [weak self](packedSuccessfully, packedData, error) in
            if (packedSuccessfully){
                NetworkManager.shared.sendMsg(isMediator: true, msgData: packedData ?? Data()) {[weak self] (statuscode,receivedData) in
                    
                    self?.connectionHelper.updateWalletRecord(walletHandler: walletHandler,recipientKey: recipientKey,label: label, type: .inboxCreated, id: connectionRecordId, theirDid: theirDid, myDid: myDid ,invitiationKey: invitationKey, completion: {[weak self] (updatedSuccessfully, updatedRecordId, error) in
                        if(updatedSuccessfully){
                            self?.connectionHelper.updateWalletTags(walletHandler: walletHandler, id: connectionRecordId, myDid: myDid, theirDid: theirDid, recipientKey: recipientKey, serviceEndPoint: "", invitiationKey: invitationKey, type: .mediatorActive) {[weak self] (tagUpdated, error) in
                                if (tagUpdated){
                                    Task{
                                        await RegistryHelper.shared.checkForExistingRegistryConnection()
                                    }
                                    self?.pollingMediator(connectionRecordId: connectionRecordId, verKey: verKey, myDid: myDid, recipientKey: recipientKey, label: label, packageMsgType: .pollingMediator, routingKey: "", serviceEndPoint: "")
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    func pollingMediator(connectionRecordId: String,verKey: String, myDid: String, recipientKey: String, label: String, packageMsgType: PackMessageType, routingKey: String, serviceEndPoint: String) {
        let walletHandler = self.walletHandle ?? 0
        self.connectionHelper.packMessage(walletHandler: walletHandler, label: label, recipientKey: recipientKey, id:connectionRecordId, didCom: "" , myDid: myDid, myVerKey: verKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey, deleteItemId: "", type: .pollingMediator, isRoutingKeyEnabled: false, completion: { [weak self] (packedSuccessfully, packedData, error) in
            if (packedSuccessfully){
                guard let weakSelf = self else {return}
                guard let data = packedData else {
                    UIApplicationUtils.showErrorSnackbar(message: "Polling failed")
                    return
                }
                PollingFunction.call(weakSelf.pollingLogic(packedData: data, connectionRecordId: connectionRecordId,verKey: verKey, myDid: myDid, recipientKey: recipientKey, label: label, packageMsgType: packageMsgType, routingKey: routingKey, serviceEndPoint: serviceEndPoint))
            }
        })
    }
    
    func pollingLogic(packedData: Data,connectionRecordId: String,verKey: String, myDid: String, recipientKey: String, label: String, packageMsgType: PackMessageType, routingKey: String, serviceEndPoint: String){
        
        let walletHandler = self.walletHandle ?? 0
        NetworkManager.shared.polling(msgData: packedData) {[weak self] (statuscode,receivedData) in
            debugPrint("polling......")
            
            if receivedData != nil {
                self?.connectionHelper.unpackMessage(walletHandler: walletHandler, messageData: receivedData ?? Data(), completion: { [weak self] (unpackedSuccessfully, unpackedData, error) in
                    if let messageModel = try? JSONSerialization.jsonObject(with: unpackedData ?? Data(), options: []) as? [String : Any] {
                        let messageString = messageModel["message"] as? String
                        let msgDict = UIApplicationUtils.shared.convertToDictionary(text: messageString ?? "")
                        let items = msgDict?["Items"] as? [[String: Any]] ?? []
                        if items.count > 0 {
                            debugPrint("items -- \(items.count)")
                           
                            for itemDict in items {
                                let dataDict = itemDict["Data"] as? [String : Any] ?? [:]
                                if let data = try? JSONSerialization.data(withJSONObject: dataDict, options: .prettyPrinted) {
                                    self?.connectionHelper.unpackMessage(walletHandler: walletHandler, messageData: data, completion: { [weak self](unpackMsgSuccess, unpackedMsgData, error) in
                                        if let messageModel = try? JSONSerialization.jsonObject(with: unpackedMsgData ?? Data(), options: []) as? [String : Any] {
                                            debugPrint("unpackmsg -- \(messageModel)")
                                            
                                            print(data.prettyPrintedJSONString())
                                            
                                            let msgString = (messageModel)["message"] as? String
                                            let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                            //connection~sig
                                            let itemType = (msgDict?["@type"] as? String)?.split(separator: "/").last ?? ""
                                            let connSigDict = (msgDict)?["connection~sig"] as? [String:Any]
                                            let sigDataBase64String = (connSigDict)?["sig_data"] as? String
                                            let sigDataString = sigDataBase64String?.decodeBase64_first8bitRemoved()
                                            let sigDataDict = UIApplicationUtils.shared.convertToDictionary(text: sigDataString ?? "") ?? [String: Any]()
                                            let itemId = itemDict["@id"] as? String ?? ""
                                            let recipient_verkey = (messageModel)["recipient_verkey"] as? String ?? ""
                                            let sender_verkey = (messageModel)["sender_verkey"] as? String ?? ""
                                            debugPrint("itemType -- \((itemType,itemId))")
                                            
                                            //                                                                                            delete Item
                                            self?.connectionHelper.packMessage(walletHandler: walletHandler, label: label, recipientKey: recipientKey, id: connectionRecordId, didCom: "", myDid: myDid, myVerKey: verKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey, deleteItemId: itemId, type: .deleteInboxItem, isRoutingKeyEnabled: false) {[weak self] (packedSuccessfully, data, error) in
                                                
                                               //debugPrint(data?.prettyPrintedJSONString())
                                                
                                                if (packedSuccessfully) {
                                                    NetworkManager.shared.sendMsg(isMediator: true, msgData: data ?? Data()) { [weak self] (statuscode,deleteResponse) in
                                                        debugPrint("Item deleted \(itemId)")
                                                        let id = msgDict?["@id"] as? String
                                                    if !(self?.lruCache.contains(id ?? "") ?? true) {
                                                        self?.lruCache.add(id ?? "")
                                                        switch itemType {
                                                        case "response":
                                                            AriesCloudAgentHelper.shared.addWalletRecord_CloudAgent(walletHandle: self?.walletHandle, connectionRecordId: connectionRecordId,verKey: recipient_verkey, recipientKey: sender_verkey,  packageMsgType: .initialCloudAgent, sigDataDict:sigDataDict as [String : Any],type:(msgDict?["@type"] as? String))
                                                        case "ping_response":
                                                            AriesCloudAgentHelper.shared.pingResponseHandler(walletHandle: self?.walletHandle, verKey: recipient_verkey, recipientKey: sender_verkey,type:(msgDict?["@type"] as? String ?? ""))
                                                            
                                                        case "offer-credential":
                                                            debugPrint("Offer-Cert Received")
                                                            print(msgString)
                                                            
                                                            if let docModel = CertificateIssueModel.decode(withDictionary: msgDict ?? [:]) as? CertificateIssueModel {
                                                                self?.saveCertificate(withoutDataAgreement: AriesMobileAgent.isAutoAcceptIssuanceEnabled ?? false, certIssueModel: docModel, verKey: recipient_verkey, recipientKey: sender_verkey, type: (msgDict?["@type"] as? String ?? ""))
                                                            }
                                                        case "issue-credential":
                                                            debugPrint("Issue Credential")
                                                            let issueCredentialModel = IssueCredentialMesage.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? IssueCredentialMesage
                                                            let threadID = (msgDict?["~thread"] as? [String:Any])?["thid"] as? String ?? ""
                                                            self?.issueCredential(model: issueCredentialModel,myVerKey: recipient_verkey,recipientKey: sender_verkey,threadId: threadID,type:(msgDict?["@type"] as? String ?? ""))
                                                        case "request-presentation":
                                                            debugPrint("Presentation request received")
                                                            let requestPresentationMessageModel = RequestPresentationMessageModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? RequestPresentationMessageModel
                                                            self?.requestPresentationReceived(requestPresentationMessageModel:requestPresentationMessageModel,myVerKey: recipient_verkey,recipientKey: sender_verkey,type:(msgDict?["@type"] as? String ?? ""))
                                                        case "notification":
                                                            debugPrint("Notification received")
                                                            if let pullDataNotificationModel = PullDataNotificationModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? PullDataNotificationModel {
                                                                self?.handlePullDataNotification(model: pullDataNotificationModel,receiptId: recipient_verkey)
                                                            }
                                                        case "receipt":
                                                            debugPrint("receipt")
                                                            if let receiptModel = ReceiptNotificationModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? ReceiptNotificationModel {
                                                                self?.handleReceipt(model: receiptModel)
                                                            }
                                                        default:
                                                            break
                                                        }
                                                    }
                                                    }
                                                }
                                            }
                                            
                                        }
                                    })
                                    
                                }
                            }
                        }
                    }
                })
            }
            guard let weakSelf = self else {return}
            DispatchQueue.main.asyncAfter(deadline: (DispatchTime.now() + DispatchTimeInterval.seconds(weakSelf.pollingInterval))) {
                if WalletViewModel.poolingEnabled{
                    PollingFunction.reCall()
                }
            }
        }
    }
}

extension WalletViewModel {
    
    func saveCertificate(withoutDataAgreement: Bool, certIssueModel: CertificateIssueModel, verKey: String, recipientKey: String, type: String) {
        if withoutDataAgreement {
                let walletHandler = self.walletHandle ?? 0
                self.connectionHelper.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithMyVerKey, searchValue: verKey) { [weak self](Success, searchHandler, error) in
                    self?.connectionHelper.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (success, result, error) in
                        let resultDict = UIApplicationUtils.shared.convertToDictionary(text: result)
                        let requestArray = resultDict?["records"] as? [[String:Any]] ?? []
                        let requestDict = requestArray.first?["value"] as? [String:Any]
                        let request_id = requestDict?["request_id"] as? String ?? ""
                        let firstRecord = requestArray.first
                        let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord as NSDictionary? ?? NSDictionary()) as? CloudAgentConnectionWalletModel
                        WalletRecord.shared.add(threadID: certIssueModel.id ?? "", connectionRecordId: request_id, certIssueModel: certIssueModel, walletHandler: walletHandler, type: .offerCredential) {_,_,_ in 
                            Task {
                                [weak self] in
                                guard let self = self else { return }
                                await self.acceptCertificateWithoutDataAgreement(certIssueModel: certIssueModel, connectionModel: connectionModel)
                            }
                        }
                    }
                }
        } else {
            certificateOfferReceived(verKey: verKey, recipientKey: recipientKey, certIssueModel: certIssueModel, type: type)
        }
    }
    
    func certificateOfferReceived(verKey: String, recipientKey: String, certIssueModel: CertificateIssueModel, type:String){
      
        let walletHandler = self.walletHandle ?? 0
        self.connectionHelper.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.certType, searchType: .searchWithThreadId, searchValue: certIssueModel.id ?? "") {[weak self] (Success, searchHandler, error) in
            self?.connectionHelper.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) {[weak self] (success, result, error) in
                let resultDict = UIApplicationUtils.shared.convertToDictionary(text: result)
                let count = resultDict?["totalCount"] as? Int ?? 0
                if (count > 0) {
                    debugPrint("Cert Already added to wallet")
                    return
                }
                self?.connectionHelper.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithMyVerKey, searchValue: verKey) { [weak self](Success, searchHandler, error) in
                    self?.connectionHelper.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (success, result, error) in
                        let resultDict = UIApplicationUtils.shared.convertToDictionary(text: result)
                        let requestArray = resultDict?["records"] as? [[String:Any]] ?? []
                        let requestDict = requestArray.first?["value"] as? [String:Any]
                        let request_id = requestDict?["request_id"] as? String ?? ""
                        let firstRecord = requestArray.first
                        let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord as NSDictionary? ?? NSDictionary()) as? CloudAgentConnectionWalletModel
                        WalletRecord.shared.add(threadID: certIssueModel.id ?? "", connectionRecordId: request_id, certIssueModel: certIssueModel, walletHandler: walletHandler, type: .offerCredential) { (Added, recordId, error) in
                            debugPrint("cert offer record saved")
                          
                            WalletRecord.shared.add(threadID: certIssueModel.id ?? "",connectionRecordId: request_id,certIssueModel: certIssueModel, connectionModel: connectionModel,orgRecordId:recordId, walletHandler: walletHandler, type: .inbox) { (success, id, error) in
                                NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
                                //SDK
//                                UIApplicationUtils.showSuccessSnackbar(message: "Received offer credential".localizedForSDK(),navToNotifScreen:true)
                                AriesMobileAgent.shared.delegate?.notificationReceived(message: "Received offer credential".localizedForSDK())
                            }
                        }
                    }
                }
            }
        }
    }
    
    func acceptCertificateWithoutDataAgreement(certIssueModel: CertificateIssueModel, connectionModel: CloudAgentConnectionWalletModel?) async {
        var credReqPackTemplate: [String: Any]?
        let base64Content = certIssueModel.offersAttach?.first?.data?.base64?.decodeBase64() ?? ""
        let base64ContentDict = UIApplicationUtils.shared.convertToDictionary(text: base64Content) ?? [String: Any]()
        var attributes: [SearchCertificateAttribute] = []
        for attr in certIssueModel.credentialPreview?.attributes ?? [] {
            attributes.append(
                SearchCertificateAttribute.init(name:  attr.name, value: attr.value)
            )
        }
        let cred_def_id = base64ContentDict["cred_def_id"] as? String ?? ""
        let schema_id =  base64ContentDict["schema_id"] as? String ?? ""
        let searchCertificateCredentialProposalDict =  SearchCertificateCredentialProposalDict.init(
            type: "did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/propose-credential",
            id: AgentWrapper.shared.generateRandomId_BaseUID4(),
            comment: "string",
            credDefID: cred_def_id,
            schemaID: schema_id,
            credentialProposal:SearchCertificateCredentialProposal.init(type:"did:sov:BzCbsNYhMrjHiqZDTUASHg;spec/issue-credential/1.0/credential-preview", attributes: attributes))
        let searchCertificateRecord = SearchCertificateRecord.init()
        searchCertificateRecord.value = SearchCertificateValue.init(
            threadID: certIssueModel.id,
            createdAt: AgentWrapper.shared.getCurrentDateTime(),
            updatedAt: AgentWrapper.shared.getCurrentDateTime(),
            connectionID: AgentWrapper.shared.generateRandomId_BaseUID4(),
            credentialProposalDict: searchCertificateCredentialProposalDict,
            credentialOfferDict: nil,
            credentialOffer: SearchCertificateCredentialOffer.decode(withDictionary: base64ContentDict as NSDictionary? ?? NSDictionary()) as? SearchCertificateCredentialOffer,
            credentialRequest: nil,
            credentialRequestMetadata: nil,
            errorMsg: nil,
            credDefJson: nil,
            rawCredential: nil,
            credential: nil,
            parentThreadID: nil,
            credentialDefinitionID: cred_def_id,
            schemaID: schema_id,
            credentialID: nil,
            revocRegID: nil,
            revocationID: nil,
            role: nil,
            state: nil)
        if let dataAgreementContext = certIssueModel.dataAgreement, dataAgreementContext.message?.body?.proof != nil {
            (credReqPackTemplate,new_dataAgreement) = await SignCredential.shared.signCredential(dataAgreement: dataAgreementContext, recordId: connectionModel?.id ?? "")
        }
        let walletHandler = walletHandle ?? IndyHandle()
        

        do{
            let success = try await AriesPoolHelper.shared.pool_setProtocol(version: 2)
            let _ = try? await AriesPoolHelper.shared.pool_openLedger(name: "default", config: [String:Any]())
            let (success2, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithId, searchValue: connectionModel?.id ?? "")
            if (success2){
                let (fetchedSuccessfully, results) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler)
                if (fetchedSuccessfully){
                    let resultDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                    let firstResult = (resultDict?["records"] as? [[String: Any]])?.first
                    if let connectionRecordId = (resultDict?["records"] as? [[String:Any]])?.first?["id"] as? String {
                        if let myDid = (firstResult?["value"] as? [String: Any])?["my_did"] as? String, let recipientKey = (firstResult?["value"] as? [String: Any])?["reciepientKey"] as? String {
                            let (metadataReceived, metadata) = try await AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid: myDid)
                            let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata)
                            if let verKey = metadataDict?["verkey"] as? String{
                                let (success2, credDefId, credDefJson,error) = await AriesPoolHelper.shared.parseGetCredDefResponseWithLedgerSwitching(credentialDefinitionID: searchCertificateRecord.value?.credentialDefinitionID ?? "")
                                if error?.localizedDescription.contains("309") ?? false {
                                    UIApplicationUtils.hideLoader()
                                    UIApplicationUtils.showErrorSnackbar(message: "Invalid Ledger. You can choose proper ledger from settings".localizedForSDK())
                                    return
                                }
                                if success2{
                                    let credentialOfferData = try! JSONEncoder().encode(searchCertificateRecord.value?.credentialOffer)
                                    let credentialOfferJsonString = String(data: credentialOfferData, encoding: .utf8)!
                                    let (success, credReqJSON, credReqMetadataJSON) = try await AriesPoolHelper.shared.pool_prover_create_credential_request(walletHandle: walletHandler, forCredentialOffer: credentialOfferJsonString, credentialDefJSON: credDefJson, proverDID: myDid)
                                    if success {
                                        let label = (firstResult?["value"] as? [String: Any])?["their_label"] as? String
                                        let their_did = (firstResult?["value"] as? [String: Any])?["their_did"] as? String
                                        
                                        // No need
                                        let (success, searchHandle) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: self.walletHandle ?? IndyHandle(), type:AriesAgentFunctions.certType, searchType: .searchWithId, searchValue: connectionModel?.id ?? "")
                                        let (success1, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: self.walletHandle ?? IndyHandle(), searchWalletHandler: searchHandle)
                                        let resultDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                                        let certRecord = (resultDict?["records"] as? [[String: Any]])?.first
                                        let certRecordId = certRecord?["id"] as? String ?? ""
                                        var tempCertModel = searchCertificateRecord
                                        tempCertModel.value?.credentialOffer = SearchCertificateCredentialOffer.decode(withDictionary: (UIApplicationUtils.shared.convertToDictionary(text: credentialOfferJsonString) ?? [String:Any]()) as NSDictionary? ?? NSDictionary()) as? SearchCertificateCredentialOffer
                                        tempCertModel.value?.credentialRequestMetadata = SearchCertificateCredentialRequestMetadata.decode(withDictionary: (UIApplicationUtils.shared.convertToDictionary(text:credReqMetadataJSON) ?? [String:Any]()) as NSDictionary? ?? NSDictionary()) as? SearchCertificateCredentialRequestMetadata
                                        tempCertModel.value?.credentialRequest = SearchCertificateCredentialRequest.decode(withDictionary: (UIApplicationUtils.shared.convertToDictionary(text: credReqJSON) ?? [String:Any]()) as NSDictionary? ?? NSDictionary()) as? SearchCertificateCredentialRequest
                                        tempCertModel.value?.credDefJson = CredentialDefModel.decode(withDictionary: (UIApplicationUtils.shared.convertToDictionary(text:credDefJson) ?? [String:Any]()) as NSDictionary? ?? NSDictionary()) as? CredentialDefModel
                                        tempCertModel.value?.state = "request_sent"
                                        let (success2, newId) = try await AriesAgentFunctions.shared.updateWalletRecord(walletHandler: walletHandler, type: .issueCredential, id: certRecordId, certModel: tempCertModel ?? SearchCertificateRecord.init())
                                        let success3 = try await AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler, id: certRecordId, type: .issueCredential, threadId: searchCertificateRecord.value?.threadID ?? "", state: "request_sent")
                                        
                                        let (success5, searchWalletHandler) = try await AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type:AriesAgentFunctions.cloudAgentConnectionInvitation, searchType: .searchWithId, searchValue: connectionModel?.id ?? "")
                                        if (success5){
                                            let (fetchedSuccessfully, results) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler)
                                            if (fetchedSuccessfully){
                                                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                                                let invitationRecord = (resultsDict?["records"] as? [[String: Any]])?.first
                                                let serviceEndPoint = (invitationRecord?["value"] as? [String: Any])?["serviceEndpoint"] as? String ?? ""
                                                let externalRoutingKey = (invitationRecord?["value"] as? [String: Any])?["routing_key"] as? [String] ?? []
                                                let didcom = searchCertificateRecord.value?.credentialProposalDict?.type?.split(separator: ";").first ?? ""
                                                
                                                let packTemplate = credReqPackTemplate != nil ?
                                                AriesPackMessageTemplates.requestCredentialWithDataAgreement(didCom: String(didcom), credReq: credReqJSON, threadId: searchCertificateRecord.value?.threadID ?? "", dataAgreementContext: credReqPackTemplate ?? [:]) : AriesPackMessageTemplates.requestCredential(didCom: String(didcom), credReq: credReqJSON, threadId: searchCertificateRecord.value?.threadID ?? "")
                                                let (_, packedData) = try await AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, label: label ?? "", recipientKey: recipientKey, id: connectionRecordId, didCom: String(didcom), myDid: myDid, myVerKey: verKey, serviceEndPoint: "", routingKey: "", deleteItemId: "", threadId:searchCertificateRecord.value?.threadID ?? "", credReq: credReqJSON, type: .rawDataBody, isRoutingKeyEnabled: externalRoutingKey.count > 0, externalRoutingKey: externalRoutingKey, rawDict: packTemplate)
                                                let (statuscode, _) = await NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData , url: serviceEndPoint)
                                                if statuscode != 200 {
                                                    UIApplicationUtils.hideLoader()
                                                    return
                                                }
                                                    Task {
                                                        await self.addAriesCredentialToHistory(certData: searchCertificateRecord, connectionModels: connectionModel, newDataAgreement: new_dataAgreement, dataAgreement: certIssueModel.dataAgreement)
                                                    }
                                                UIApplicationUtils.hideLoader()
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                    } else {
                        UIApplicationUtils.hideLoader()
                        UIApplicationUtils.showErrorSnackbar(message: "No related organisation found. You may have removed the organisation".localizedForSDK())
                    }
                }
            }
        } catch(let error){
            if error.localizedDescription.contains("309") {
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.showErrorSnackbar(message: "Invalid Ledger. You can choose proper ledger from settings".localizedForSDK())
                return
            }
            UIApplicationUtils.hideLoader()
//            UIApplicationUtils.showErrorSnackbar(message: "Invalid Ledger. You can choose proper ledger from settings".localizedForSDK())
            debugPrint(error.localizedDescription)
        }
    }
    
    func addAriesCredentialToHistory(mode: CertificatePreviewVC_Mode = .other, certData: SearchCertificateRecord, connectionModels: CloudAgentConnectionWalletModel?, newDataAgreement: DataAgreementContext?, dataAgreement: DataAgreementContext?) async{
        do {
            let walletHandler = walletHandle ?? IndyHandle()
            var history = History()
            let attrArray = certData.value?.credentialProposalDict?.credentialProposal?.attributes?.map({ (item) -> IDCardAttributes in
                return IDCardAttributes.init(type: CertAttributesTypes.string, name: item.name ?? "", value: item.value)
            })
            history.attributes = attrArray
            history.dataAgreementModel = newDataAgreement ?? dataAgreement
            history.dataAgreementModel?.validated = .not_validate
            history.threadID = certData.value?.threadID
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            history.date = dateFormat.string(from: Date())
            history.type = HistoryType.issuedCertificate.rawValue
            
            if let schemeSeperated = certData.value?.schemaID?.split(separator: ":"){
                history.name = "\(schemeSeperated[2])".uppercased()
            }
            history.connectionModel = connectionModels
            let (success, id) = try await WalletRecord.shared.add(connectionRecordId: "", walletHandler: walletHandler, type: .dataHistory, historyModel: history)
            debugPrint("historySaved -- \(success)")
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
}

// MARK: ISSUE CREDENTIAL

extension WalletViewModel {
    func issueCredential(model:IssueCredentialMesage?,myVerKey: String,recipientKey: String,threadId: String, type:String) {
        debugPrint("issue-credential item -- \(model?.id ?? "")")
        let walletHandler = self.walletHandle ?? 0
        let base64Data = model?.credentialsAttach?.first?.data?.base64?.decodeBase64() ?? ""
        let credentialAttachDict = UIApplicationUtils.shared.convertToDictionary(text: base64Data)
        let credentialAttachModel = SearchCertificateRawCredential.decode(withDictionary: credentialAttachDict as NSDictionary? ?? NSDictionary()) as? SearchCertificateRawCredential
        self.connectionHelper.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithMyVerKey,searchValue: myVerKey) {[weak self] (success, searchHandler, error) in
            self?.connectionHelper.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler,count: 100) {[weak self] (success, record, error) in
                let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: record)
                let records = recordResponse?["records"] as? [[String:Any]]
                let firstRecord = records?.first
                let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord as NSDictionary? ?? NSDictionary()) as? CloudAgentConnectionWalletModel
                self?.connectionHelper.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.certType, searchType: .searchWithThreadId, searchValue: threadId) {[weak self] (success, searchHandler, error) in
                    self?.connectionHelper.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler,count: 10) {[weak self] (success, certRecords, error) in
                        let certCecordResponse = UIApplicationUtils.shared.convertToDictionary(text: certRecords)
                        let certificatedModel = SearchCertificateResponse.decode(withDictionary: certCecordResponse as NSDictionary? ?? NSDictionary()) as? SearchCertificateResponse
                        let tempCert = certificatedModel?.records?.first
                        tempCert?.value?.rawCredential = credentialAttachModel
                        tempCert?.type = type
                        tempCert?.value?.state = "credential_received"
                        tempCert?.tags?.state = "credential_received"
                        self?.connectionHelper.updateWalletRecord(walletHandler: walletHandler, type: .issueCredential, id: tempCert?.id ?? "", certModel: tempCert ?? SearchCertificateRecord.init()) { [weak self](success, updatedID, error) in
                            AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler,id:connectionModel?.value?.requestID ?? "", type: .issueCredential, threadId: tempCert?.value?.threadID ?? "",state: tempCert?.tags?.state) { [weak self] (success, error) in
                                debugPrint("Credential Received Successfully")
                                self?.credentialAckToIssuer(connectionDetailModel: connectionModel, threadId: tempCert?.value?.threadID ?? "", recipientKey: recipientKey, myKey: myVerKey, certModel: tempCert ?? SearchCertificateRecord.init(),type: type)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func credentialAckToIssuer(connectionDetailModel:CloudAgentConnectionWalletModel?, threadId:String,recipientKey: String,myKey:String,certModel:SearchCertificateRecord,type:String) {
        let walletHandler = self.walletHandle ?? 0
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type:
                                                            DidDocTypes.cloudAgentDidDoc.rawValue,searchType: .searchWithTheirDid, searchValue: connectionDetailModel?.value?.theirDid ?? "", completion: {[weak self] (success, searchWalletHandler, error) in
            if (success){
                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler, completion: {
                    [weak self](fetchedSuccessfully,results,error) in
                    if (fetchedSuccessfully) {
                        let resultDict = UIApplicationUtils.shared.convertToDictionary(text: results)
                        let didcom = type.split(separator: ";").first ?? ""
                        let didDocModel = SearchDidDocModel.decode(withDictionary: resultDict as NSDictionary? ?? NSDictionary()) as? SearchDidDocModel
                        AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler,recipientKey: recipientKey,didCom: String(didcom), myVerKey: myKey, threadId: threadId, type: .credentialAck, isRoutingKeyEnabled: connectionDetailModel?.value?.routingKey?.count ?? 0 > 0,externalRoutingKey: connectionDetailModel?.value?.routingKey ?? []) {[weak self] (success, data, error) in
                            
                            let serviceEndPoint = didDocModel?.records?.first?.value?.service?.first?.serviceEndpoint ?? ""
                            NetworkManager.shared.sendMsg(isMediator: false, msgData: data ?? Data(), url: serviceEndPoint) { [weak self] (statuscode,responseData) in
                                self?.checkSharingToThirdParty(certModel: certModel, connectionDetailModel: connectionDetailModel)
                            }
                        }
                    }
                })
            }
        })
    }
    
    func checkSharingToThirdParty(certModel: SearchCertificateRecord,connectionDetailModel:CloudAgentConnectionWalletModel?){
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.history, searchType:.searchWithThreadId, searchValue: certModel.value?.threadID ?? "") { [weak self](success, prsntnExchngSearchWallet, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: prsntnExchngSearchWallet, count: 1000) { [weak self] (success, response, error) in
                let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: response)
                let searchModel = SearchHistoryModel.decode(withDictionary: recordResponse ?? [:]) as? SearchHistoryModel
                guard let strongSelf = self else {return}
                Task{
                    if let model = searchModel?.records?.first, (model.value?.history?.dataAgreementModel?.message?.body?.dataPolicy?.thirdPartyDataSharing ?? false) {
                        await strongSelf.saveCredentialToWallet(certModel: certModel,connectionDetailModel:connectionDetailModel,addToWallet: false)
                    } else {
                        await strongSelf.saveCredentialToWallet(certModel: certModel,connectionDetailModel:connectionDetailModel)
                    }
                }
            }
        }
    }
    
    func saveCredentialToWallet(certModel: SearchCertificateRecord,connectionDetailModel:CloudAgentConnectionWalletModel?, addToWallet: Bool? = true) async {
        let (success3, credID, error) = await AriesPoolHelper.shared.saveCredentialToWalletWithAutoLedgerSwitch(certModel: certModel)
        if error?.localizedDescription.contains("309") ?? false {
            UIApplicationUtils.hideLoader()
            UIApplicationUtils.showErrorSnackbar(message: "Invalid Ledger. You can choose proper ledger from settings".localizedForSDK())
            return
        }
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()

            if success3 {
                self.connectionHelper.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.certType, id: certModel.id ?? "") {[weak self] (deletedSuccessfully, error) in
                    debugPrint("Cert record deleted \(deletedSuccessfully)")
                    self?.deleteFromInbox(threadId: certModel.value?.threadID ?? "")
                    if !(addToWallet ?? true) {
                        return
                    }
                    let credentialDict = UIApplicationUtils.shared.convertToDictionary(text: credID)
                    let walletCredentialModel = SearchProofReqCredInfo.decode(withDictionary: credentialDict as NSDictionary? ?? NSDictionary()) as? SearchProofReqCredInfo
                    
                    let customWalletModel = CustomWalletRecordCertModel.init()
                    customWalletModel.referent = walletCredentialModel
                    customWalletModel.schemaID = certModel.value?.schemaID
                    customWalletModel.certInfo = certModel
                    customWalletModel.connectionInfo = connectionDetailModel
                    customWalletModel.type = CertType.credentials.rawValue
                    customWalletModel.subType = ""
                    if let _ = ReceiptCredentialModel.isReceiptCredentialModel(certModel: SearchItems_CustomWalletRecordCertModel.init(type: "", id: "", value: customWalletModel)){
                        customWalletModel.subType = CertSubType.Reciept.rawValue
                    }
                    
                    let schemeSeperated = certModel.value?.schemaID?.split(separator: ":")
                    let name = "\(schemeSeperated?[2] ?? "")"
                    customWalletModel.searchableText = name
                    WalletRecord.shared.add(connectionRecordId: "",walletCert:customWalletModel, walletHandler: walletHandler, type: .walletCert) { [weak self](success, response, error) in
                        if success {
                            //SDK
//                            UIApplicationUtils.showSuccessSnackbar(message: "New certificate is added to wallet".localizedForSDK())
                            AriesMobileAgent.shared.delegate?.notificationReceived(message: "New certificate is added to wallet".localizedForSDK())
                            self?.getSavedCertificates()
                        } else {
                            UIApplicationUtils.showErrorSnackbar(message: "Error saving certificate to wallet")
                        }
                        
                    }
                    
                }
            }
    }


func deleteFromInbox(threadId:String) {
    let walletHandler = self.walletHandle ?? 0
    AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, searchType: .searchWithThreadId,searchValue: threadId) { (success, searchHanlder, error) in
        AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHanlder) { (sucess, response, error) in
            let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: response)
            let resultModel = SearchInboxModel.decode(withDictionary: resultsDict as NSDictionary? ?? NSDictionary()) as? SearchInboxModel
            let recordId = resultModel?.records?.first?.id ?? ""
            AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: recordId) { (success, error) in
                if success{
                    NotificationCenter.default.post(Notification.init(name: Constants.didRecieveCertOffer))
                    debugPrint("Cert deleted from inbox records")
                }
            }
        }
    }
}

func deleteCredentialWith(id:String,walletRecordId: String?){
    let walletHandler = self.walletHandle ?? 0
    AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, id: walletRecordId ?? "") { [weak self](success, error) in
        AriesPoolHelper.shared.deleteCredentialFromWallet(withId: id, walletHandle: walletHandler) { [weak self](success, error) in
            self?.getSavedCertificates()
        }
    }
}
}

//MARK: request-presentation
extension WalletViewModel {
    
    func requestPresentationReceived(requestPresentationMessageModel: RequestPresentationMessageModel?,myVerKey: String,recipientKey: String,type: String) {
        let walletHandler = self.walletHandle ?? 0
        let base64String = requestPresentationMessageModel?.requestPresentationsAttach?.first?.data?.base64?.decodeBase64() ?? ""
        let base64DataDict = UIApplicationUtils.shared.convertToDictionary(text: base64String)
        let presentationRequestModel = PresentationRequestModel.decode(withDictionary: base64DataDict as NSDictionary? ?? NSDictionary()) as? PresentationRequestModel
        self.connectionHelper.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithMyVerKey,searchValue: myVerKey) { [weak self](success, searchHandler, error) in
            self?.connectionHelper.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) {[weak self] (success, record, error) in
                let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: record)
                let cloudAgentSearchConnectionModel = CloudAgentSearchConnectionModel.decode(withDictionary: recordResponse as NSDictionary? ?? NSDictionary()) as? CloudAgentSearchConnectionModel
                if cloudAgentSearchConnectionModel?.totalCount ?? 0 > 0 {
                    self?.connectionHelper.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.presentationExchange,searchType:.searchWithThreadId, searchValue: requestPresentationMessageModel?.id ?? "") {[weak self] (success, prsntnExchngSearchWallet, error) in
                        self?.connectionHelper.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: prsntnExchngSearchWallet) { (success, response, error) in
                            let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: response)
                            if (recordResponse?["totalCount"] as? Int ?? 0) > 0 {
                                return
                            }
                            //                            let searchPresentationExchangeModel = SearchPresentationExchangeModel.decode(withDictionary: recordResponse as NSDictionary? ?? NSDictionary()) as? SearchPresentationExchangeModel
                            let connectionModel = cloudAgentSearchConnectionModel?.records?.first
                            var  presentationExchangeWalletModel = PresentationRequestWalletRecordModel.init()
                            presentationExchangeWalletModel.threadID = requestPresentationMessageModel?.id
                            presentationExchangeWalletModel.QR_ID = requestPresentationMessageModel?.QR_ID
                            presentationExchangeWalletModel.connectionID = connectionModel?.value?.requestID
                            presentationExchangeWalletModel.createdAt = AgentWrapper.shared.getCurrentDateTime()
                            presentationExchangeWalletModel.updatedAt = AgentWrapper.shared.getCurrentDateTime()
                            presentationExchangeWalletModel.initiator = "external"
                            presentationExchangeWalletModel.presentationRequest = presentationRequestModel
                            presentationExchangeWalletModel.role = "prover"
                            presentationExchangeWalletModel.state = "request_received"
                            presentationExchangeWalletModel.autoPresent = true
                            presentationExchangeWalletModel.trace = false
                            presentationExchangeWalletModel.dataAgreement = requestPresentationMessageModel?.dataAgreementContext
                            
                            WalletRecord.shared.add(connectionRecordId: connectionModel?.value?.requestID, presentationExchangeModel:presentationExchangeWalletModel, walletHandler: walletHandler,  type: .presentationRequest,didComType: type) { (success, recordId, error) in
                                WalletRecord.shared.add(connectionRecordId: connectionModel?.value?.requestID, presentationExchangeModel:presentationExchangeWalletModel, connectionModel: connectionModel,orgRecordId:recordId, walletHandler: walletHandler, type: .inbox, didComType: type) { (success, id, error) in
                                    debugPrint("Add wallet record - Presentation Request")
                                    NotificationCenter.default.post(name: Constants.didReceiveDataExchangeRequest, object: nil)
                                    //SDK
//                                    UIApplicationUtils.showSuccessSnackbar(message: "New exchange data request received".localizedForSDK(),navToNotifScreen:true)
                                    AriesMobileAgent.shared.delegate?.notificationReceived(message: "New exchange data request received".localizedForSDK())
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

class PollingFunction {
    static var calledFunc: (() -> Void)?
    
    static func call(_ function: @escaping @autoclosure () -> Void) {
        // Store the function
        calledFunc = function
        
        // Call it
        function()
    }
    
    static func reCall() {
        // Called the stored function
        calledFunc?()
    }
    
    // Call this when you no longer want SFC to hold onto your function.
    // Your class will not deallocate if you passed in `self` to `call()`
    // as long as `calledFunc` retains your function.  Setting it to `nil`
    // frees it.
    static func forget() {
        calledFunc = nil
    }
}
