//
//  OrganizationDetailViewModel.swift
//  dataWallet
//
//  Created by sreelekh N on 22/01/22.
//

import Foundation
import IndyCWrapper
import eudiWalletOidcIos

final class OrganizationDetailViewModel: NSObject {
    
    weak var pageDelegate: OrganizationDelegate?
    enum PageFor {
        case orgDetail
        case history
        case genericCard(model: SelfAttestedModel)
        case EBSI
        case receiptHistory(model: ReceiptCredentialModel)
    }
    
    var loadUIFor: PageFor = .orgDetail
    var history: HistoryRecordValue?
    var showData = false
    
    var walletHandle: IndyHandle?
    var reqId : String?
    var certificates: [InboxModelRecord]?
    var orgInfo: OrganisationInfoModel?
    var orgCertListModel: OrganisationListDataCERTModel?
    var isiGrantOrg: Bool = false
    var connectionModel: CloudAgentConnectionWalletModel?
//    {
//        didSet{
//            self.checkForThirdPartyDataSharing()
//        }
//    }
//    var isThirdPartyDataSharing = false
    private var connectionInvitationRecordId: String?
    var initialLoad = false
    var homeData: SearchItems_CustomWalletRecordCertModel?
    var homeDataList: Search_CustomWalletRecordCertModel?
    
    init(walletHandle: IndyHandle? = nil,
         reqId: String? = nil,
         isiGrantOrg: Bool? = nil,
         render: PageFor = .orgDetail,
         history: HistoryRecordValue? = nil,
         homeData: SearchItems_CustomWalletRecordCertModel? = nil
    ) {
        super.init()
        loadUIFor = render
        switch render {
        case .history:
            self.history = history
            let attributes = self.history?.value?.history?.attributes
            let createLines = attributes?.createAndFindNumberOfLines()
            self.history?.value?.history?.attributes = createLines
            if let attr = attributes, let receiptModel = ReceiptCredentialModel.isReceiptCredentialModel(attributes: attr){
                self.loadUIFor = .receiptHistory(model: receiptModel)
            }
            if let jwList = history?.value?.history?.JWTList, !jwList.isEmpty {
                homeDataList = updateJwtWithPresentationDefinition(jwtList: jwList, queryItem: self.history?.value?.history?.presentationDefinition, credentialType: history?.value?.history?.certSubType ?? "", searchableText: history?.value?.history?.certSubType ?? "")
            } else if self.history?.value?.history?.certSubType == EBSI_CredentialType.PDA1.rawValue {
                let sectionStruct = [
                    DWSection(title: "Personal Details", key: "section1"),
                    DWSection(title: "Member State Legislation", key: "section2"),
                    DWSection(title: "Status Confirmation", key: "section3"),
                    DWSection(title: "Employment Details", key: "section4"),
                    DWSection(title: "Activity Employment Details", key: "section5"),
                    DWSection(title: "Completing Institution", key: "section6")
                ]
                
                var attributeStructure: OrderedDictionary<String, DWAttributesModel> = [:]
                for (index,attr) in (createLines ?? []).enumerated()  {
                    switch index {
                    case 0...7:
                        let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[0].key ?? "")
                        attributeStructure[key] = value
                    case 8...13:
                        let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[1].key ?? "")
                        attributeStructure[key] = value
                    case 14...26: let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[2].key ?? "")
                        attributeStructure[key] = value
                    case 27...30: let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[3].key ?? "")
                        attributeStructure[key] = value
                    case 31: let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[4].key ?? "")
                        attributeStructure[key] = value
                    case 32...:
                        let (key,value) = DWAttributesModel.generateAttributeMap(fromAttributes: attr, parent: sectionStruct[5].key ?? "")
                        attributeStructure[key] = value
                    default:break
                    }
                }
                self.homeData = SearchItems_CustomWalletRecordCertModel()
                self.homeData?.value = CustomWalletRecordCertModel()
                self.homeData?.value?.attributes = attributeStructure
                self.homeData?.value?.sectionStruct = sectionStruct
            }
        case .genericCard:
            self.walletHandle = walletHandle
            self.homeData = homeData
        case .EBSI:
            self.walletHandle = walletHandle
            self.homeData = homeData
        default:
            self.walletHandle = walletHandle
            self.reqId = reqId
            self.isiGrantOrg = isiGrantOrg ?? false
        }
    }
    
    func updateJwtWithPresentationDefinition(jwtList: [String]?, queryItem: Any?, credentialType: String, searchableText: String?) -> Search_CustomWalletRecordCertModel? {
        let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyHandlerKeyID)
        let verificationHandler = eudiWalletOidcIos.VerificationService(keyhandler: keyHandler)
        var newModel = Search_CustomWalletRecordCertModel()
        var records = [SearchItems_CustomWalletRecordCertModel]()
        var newItem = SearchItems_CustomWalletRecordCertModel()
        
        guard let jwtList = jwtList else { return nil}
        
        for (index, item) in jwtList.enumerated() {
            var queryData: Any?
            var credentialFormat: String = ""
            var displayText: String? = ""
            guard !item.isEmpty else { continue }
            if let wrapper = queryItem as? PresentationDefinitionWrapper {
                switch wrapper {
                case .dcqlQuery(let dcql):
                    queryData = dcql.credentials[index]
                    if let credentialData = queryData as? CredentialItems {
                        credentialFormat = credentialData.format
                        if let text = searchableText, !text.isEmpty {
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
                    }
                }
            }
            if credentialFormat == "mso_mdoc" {
                let updatedCbor = verificationHandler.getFilteredCbor(credential: item, query: queryData)
                let cborString = Data(updatedCbor.encode()).base64EncodedString()

                var base64StringWithoutPadding = cborString.replacingOccurrences(of: "=", with: "")
                base64StringWithoutPadding = base64StringWithoutPadding.replacingOccurrences(of: "+", with: "-")
                base64StringWithoutPadding = base64StringWithoutPadding.replacingOccurrences(of: "/", with: "_")
                newItem = SearchItems_CustomWalletRecordCertModel(type: "",id: "",value: MDOCParser.shared.getMDOCCredentialWalletRecord(connectionModel: EBSIWallet.shared.connectionModel, credential_cbor: base64StringWithoutPadding, format: credentialFormat, credentialType: credentialType))
            } else {
                
                let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyHandlerKeyID)
                let updatedJwt = eudiWalletOidcIos.SDJWTService.shared.processDisclosures(credential: item, query: queryData, format: credentialFormat, keyHandler: keyHandler)
                newItem = SearchItems_CustomWalletRecordCertModel(type: "", id: "", value:EBSIWallet.shared.updateCredentialWithJWT(jwt:updatedJwt ?? "", searchableText: displayText ?? ""))
            }
            records.append(newItem)
        }
        newModel.records = records
        newModel.totalCount = records.count
        return newModel
    }
    
    func isMultipleInputDescriptors() -> Bool? {
        guard let data = history?.value?.history else { return false }
        switch data.presentationDefinition {
        case .presentationDefinition(let pd):
            return pd.inputDescriptors?.count ?? 0 > 1
        case .dcqlQuery(let dcql):
            return dcql.credentials.count > 1
        case .none:
            return false
        }
    }
    
    func getNameAndIdFromInputDescriptor(index: Int) -> (String?, String?) {
        var title: String?
        var id: String?
        guard let data = history?.value?.history?.presentationDefinition else { return (nil, nil) }
        switch data {
        case .presentationDefinition(let model):
            title = model.inputDescriptors?[index].name
            id = model.inputDescriptors?[index].id
        case .dcqlQuery(let dcqlModel):
            title = nil
            id = dcqlModel.credentials[index].id
        }
        return (title, id)
    }
    
    func getHeaderForMultipleInputDescriptor(position: Int)-> String{
        if let dataList = homeDataList {
            return  dataList.records?[position].value?.searchableText ?? "OpenID Credential"
        } else {
            return "OpenID Credential"
        }
    }
    
    func getNameFromPresentationDefinition() -> String? {
        var title: String?
        guard let data = history?.value?.history?.presentationDefinition else { return nil }
        switch data {
        case .presentationDefinition(let model):
            title = model.name
        case .dcqlQuery(let dcqlModel):
            title = nil
        }
        return title
    }

    
    func getCertFromThreadID(){
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        let threadId = self.history?.value?.history?.threadID ?? ""
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.certType, searchType: .searchWithThreadId, searchValue: threadId) {[weak self] (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler,count: 10) {[weak self] (success, certRecords, error) in
                let certCecordResponse = UIApplicationUtils.shared.convertToDictionary(text: certRecords)
                let certSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: certCecordResponse as? NSDictionary ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                let tempCert = certSearchModel?.records?.first
                self?.homeData = tempCert
            }
        }
    }
    
    func fetchCertificates(completion: @escaping (Bool) -> Void) {
        let walletHandler = self.walletHandle ?? IndyHandle()
        UIApplicationUtils.showLoader()
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithId, searchValue: self.reqId ?? "") {[weak self] (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) {[weak self] (success, invResult, error) in
                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: invResult)
                let searchConnModel = CloudAgentSearchConnectionModel.decode(withDictionary: resultsDict as NSDictionary? ?? NSDictionary()) as? CloudAgentSearchConnectionModel
                let connModel = searchConnModel?.records?.first
                self?.connectionModel = connModel
                completion(true)  // reaload view with connection data
                AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid: connModel?.value?.myDid ?? "", completion: { [weak self](metadataReceived,metadata, error) in
                    let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata ?? "")
                    if let verKey = metadataDict?["verkey"] as? String{
                        
                        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnectionInvitation, searchType: .searchWithId,searchValue: connModel?.value?.requestID ?? "") { [weak self](success, searchHandler, error) in
                            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [weak self](searchSuccess, records, error) in
                                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: records)
                                let invitationRecord = (resultsDict?["records"] as? [[String: Any]])?.first
                                let serviceEndPoint = (invitationRecord?["value"] as? [String: Any])?["serviceEndpoint"] as? String ?? ""
                                _ = (invitationRecord?["value"] as? [String: Any])?["routing_key"] as? [String] ?? []
                                self?.connectionInvitationRecordId = (invitationRecord?["value"] as? [String: Any])?["@id"] as? String ?? ""
                                AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connModel?.value?.reciepientKey ?? "", didCom: "", myVerKey: verKey, type: .getIgrantOrgDetail,isRoutingKeyEnabled: false) {[weak self] (success, orgPackedData, error) in
                                    NetworkManager.shared.sendMsg(isMediator: false, msgData: orgPackedData ?? Data(),url: serviceEndPoint) { [weak self](statuscode,orgServerResponseData) in
                                        if statuscode != 200 {
                                            completion(true)
                                            return
                                        }
                                        AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: orgServerResponseData ?? Data()) {[weak self] (unpackedSuccessfully, orgDetailsData, error) in
                                            if let messageModel = try? JSONSerialization.jsonObject(with: orgDetailsData ?? Data(), options: []) as? [String : Any] {
                                                print("unpackmsg -- \(messageModel)")
                                                let msgString = (messageModel)["message"] as? String
                                                let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                                _ = (messageModel)["recipient_verkey"] as? String ?? ""
                                                _ = (messageModel)["sender_verkey"] as? String ?? ""
                                                print("Org details received")
                                                let orgInfoModel = OrganisationInfoModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? OrganisationInfoModel
                                                self?.orgInfo = orgInfoModel
                                                
                                                if orgInfoModel?.orgId == nil {
                                                    self?.getOrgDetailFromDataControllerProtocol(walletHandler: walletHandler, verKey: verKey, connModel: connModel, serviceEndPoint: serviceEndPoint, completion: completion)
                                                    return
                                                }
                                                //Get cert list
                                                AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connModel?.value?.reciepientKey ?? "", didCom: "", myVerKey: verKey, type: .getIgrantCertTypeResponse,isRoutingKeyEnabled: false) {[weak self] (certListSuccess, certListData, error) in
                                                    NetworkManager.shared.sendMsg(isMediator: false, msgData: certListData ?? Data(),url: serviceEndPoint) {[weak self] (statuscode,certListServerResponse) in
                                                        
                                                        AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: certListServerResponse ?? Data()) { [weak self](certListUnpackedSuccess, certListUnpackedData, error) in
                                                            
                                                            if let certListUnpackedResponseModel = try? JSONSerialization.jsonObject(with: certListUnpackedData ?? Data(), options: []) as? [String : Any] {
                                                                let certListString = (certListUnpackedResponseModel)["message"] as? String
                                                                let certListDict = UIApplicationUtils.shared.convertToDictionary(text: certListString ?? "")
                                                                let certListModel = OrganisationListDataCERTModel.decode(withDictionary: certListDict as NSDictionary? ?? NSDictionary()) as? OrganisationListDataCERTModel
                                                                self?.orgCertListModel = certListModel
                                                                print("Org List Data cert")
                                                                AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, searchType: .inbox_offerReceived, searchValue: self?.reqId ?? "") {[weak self] (success, searchHandle, error) in
                                                                    AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandle,count: 100) {[weak self] (success, response, error) in
                                                                        let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                                                                        let resultModel = SearchInboxModel.decode(withDictionary: resultsDict as NSDictionary? ?? NSDictionary()) as? SearchInboxModel
                                                                        let records = resultModel?.records
                                                                        self?.certificates = records
                                                                        for cert in self?.orgCertListModel?.dataCertificateTypes ?? []{
                                                                            let tempArray =   self?.certificates?.filter({ (element) -> Bool in
                                                                                return element.value?.offerCredential?.value?.schemaID == cert.schemaID
                                                                            })
                                                                            if tempArray?.count ?? 0 > 0 {
                                                                                cert.offerAvailable = true
                                                                                cert.certificates = tempArray?.first
                                                                                cert.attrArray = tempArray?.first?.value?.offerCredential?.value?.credentialProposalDict?.credentialProposal?.attributes ?? []
                                                                            } else {
                                                                                cert.offerAvailable = false
                                                                                var attr: [SearchCertificateAttribute] = []
                                                                                for item in cert.schemaAttributes ?? []{
                                                                                    attr.append(SearchCertificateAttribute.init(name: item, value: ""))
                                                                                }
                                                                                cert.attrArray = attr
                                                                            }
                                                                        }
                                                                        completion(true)
                                                                        UIApplicationUtils.hideLoader()
                                                                    }
                                                                }
                                                                
                                                            }
                                                        }
                                                    }
                                                }
                                            } else {
                                                completion(true)
                                                UIApplicationUtils.hideLoader()
                                                debugPrint("error")
                                                return
                                            }
                                            
                                            
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
    
    func getOrgDetailFromDataControllerProtocol(walletHandler: IndyHandle,verKey: String,connModel: CloudAgentConnectionWalletModel?,serviceEndPoint: String, completion: @escaping (Bool) -> Void){
        
        let getOrgTemplate = AriesPackMessageTemplates.getDataControllerOrgDetail(from_myDataDid: RegistryHelper.shared.convertDidSovToDidMyData(didSov: connModel?.value?.myDid ?? ""), to_myDataDid: RegistryHelper.shared.convertDidSovToDidMyData(didSov: connModel?.value?.theirDid ?? ""),isThirdPartyShareSupported: (connModel?.value?.isThirdPartyShareSupported == "true"))
        AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connModel?.value?.reciepientKey ?? "", didCom: "", myVerKey: verKey, type: .rawDataBody,isRoutingKeyEnabled: false,rawDict: getOrgTemplate) {[weak self] (success, orgPackedData, error) in
            NetworkManager.shared.sendMsg(isMediator: false, msgData: orgPackedData ?? Data(),url: serviceEndPoint) { [weak self](statuscode,orgServerResponseData) in
                if statuscode != 200 {
                    completion(true)
                    return
                }
                AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: orgServerResponseData ?? Data()) {[weak self] (unpackedSuccessfully, orgDetailsData, error) in
                    if let messageModel = try? JSONSerialization.jsonObject(with: orgDetailsData ?? Data(), options: []) as? [String : Any] {
                        print("unpackmsg -- \(messageModel)")
                        let msgString = (messageModel)["message"] as? String
                        let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                        _ = (messageModel)["recipient_verkey"] as? String ?? ""
                        _ = (messageModel)["sender_verkey"] as? String ?? ""
                        print("Org details received")
                        if let DCModel = DataControllerConnectionDetail.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? DataControllerConnectionDetail {
                            let orgInfoModel = OrganisationInfoModel.init(dataControllerModel: DCModel)
                            self?.orgInfo = orgInfoModel
                        }
                        
                        let readAllTemplate = AriesPackMessageTemplates.readAllTemplate(myDid: connModel?.value?.myDid ?? "", theirDid: connModel?.value?.theirDid ?? "", isThirdPartyShareSupported: (connModel?.value?.isThirdPartyShareSupported == "true"))
        AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: connModel?.value?.reciepientKey ?? "", didCom: "", myVerKey: verKey, type: .rawDataBody,isRoutingKeyEnabled: false, rawDict: readAllTemplate) {[weak self] (certListSuccess, certListData, error) in
            NetworkManager.shared.sendMsg(isMediator: false, msgData: certListData ?? Data(),url: serviceEndPoint) {[weak self] (statuscode,certListServerResponse) in
                
                AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: certListServerResponse ?? Data()) { [weak self](certListUnpackedSuccess, certListUnpackedData, error) in
                    
                    if let certListUnpackedResponseModel = try? JSONSerialization.jsonObject(with: certListUnpackedData ?? Data(), options: []) as? [String : Any] {
                        let certListString = (certListUnpackedResponseModel)["message"] as? String
                        let certListDict = UIApplicationUtils.shared.convertToDictionary(text: certListString ?? "")
                        let certListModel = OrganisationListDataCERTModel.decode(withDictionary: certListDict as NSDictionary? ?? NSDictionary()) as? OrganisationListDataCERTModel
                        self?.orgCertListModel = certListModel
                        print("Org List Data cert")
                        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, searchType: .inbox_offerReceived, searchValue: self?.reqId ?? "") {[weak self] (success, searchHandle, error) in
                            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandle,count: 100) {[weak self] (success, response, error) in
                                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                                let resultModel = SearchInboxModel.decode(withDictionary: resultsDict as NSDictionary? ?? NSDictionary()) as? SearchInboxModel
                                let records = resultModel?.records
                                self?.certificates = records
                                for cert in self?.orgCertListModel?.dataCertificateTypes ?? []{
                                    let tempArray =   self?.certificates?.filter({ (element) -> Bool in
                                        return element.value?.offerCredential?.value?.schemaID == cert.schemaID
                                    })
                                    if tempArray?.count ?? 0 > 0 {
                                        cert.offerAvailable = true
                                        cert.certificates = tempArray?.first
                                        cert.attrArray = tempArray?.first?.value?.offerCredential?.value?.credentialProposalDict?.credentialProposal?.attributes ?? []
                                    } else {
                                        cert.offerAvailable = false
                                        var attr: [SearchCertificateAttribute] = []
                                        for item in cert.schemaAttributes ?? []{
                                            attr.append(SearchCertificateAttribute.init(name: item, value: ""))
                                        }
                                        cert.attrArray = attr
                                    }
                                }
                                completion(true)
                                UIApplicationUtils.hideLoader()
                            }
                        }
                        
                    }
                }
            }
        }
                    }
                }
            }
        }
    }
    
    func deleteOrg() {
        let walletHandler = self.walletHandle ?? IndyHandle()
        UIApplicationUtils.showLoader()
        var numberOfBlockCompleted = 0
        
        //Use dispatch Queue - future improvements
        
        //delete didDoc
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: DidDocTypes.cloudAgentDidDoc.rawValue, searchType: .searchWithTheirDid,searchValue: self.connectionModel?.value?.theirDid ?? "") {[weak self] (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler, count: 1) {[weak self] (success, response, error) in
                let resultDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let didDocModel = SearchDidDocModel.decode(withDictionary: resultDict as NSDictionary? ?? NSDictionary()) as? SearchDidDocModel
                AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type:DidDocTypes.cloudAgentDidDoc.rawValue , id: didDocModel?.records?.first?.value?.id ?? "") { [weak self](success, error) in
                    print("delete didDoc")
                    numberOfBlockCompleted += 1
                    self?.deletedSuccessfully(count: numberOfBlockCompleted)
                }
            }
        }
        
        //delete didKey
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: DidKeyTypes.cloudAgentDidKey.rawValue, searchType: .searchWithTheirDid,searchValue: self.connectionModel?.value?.theirDid ?? "") { [weak self](success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler, count: 1) {[weak self] (success, response, error) in
                let resultDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let record = (resultDict?["records"] as? [[String: Any]])?.first
                let id = (record?["value"] as? [String: Any])?["@id"] as? String ?? ""
                AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type:DidKeyTypes.cloudAgentDidKey.rawValue , id: id ) { [weak self](success, error) in
                    print("delete didkey")
                    numberOfBlockCompleted += 1
                    self?.deletedSuccessfully(count: numberOfBlockCompleted)
                }
            }
        }
        
        //delete certType
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.certType, searchType: .searchWithId, searchValue: self.reqId ?? "") { [weak self](success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler, count: 1000) { [weak self](success, result, error) in
                let resultDict = UIApplicationUtils.shared.convertToDictionary(text: result)
                let certificatedModel = SearchCertificateResponse.decode(withDictionary: resultDict as NSDictionary? ?? NSDictionary()) as? SearchCertificateResponse
                if certificatedModel?.totalCount == 0 {
                    print("delete notifications")
                    numberOfBlockCompleted += 1
                    self?.deletedSuccessfully(count: numberOfBlockCompleted)
                    return
                }
                var count = 1
                for item in certificatedModel?.records ?? [] {
                    AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: item.id ?? "") { [weak self](deletedSuccessfully, error) in
                        if count == certificatedModel?.records?.count ?? 2 - 1 {
                            print("delete certType")
                            numberOfBlockCompleted += 1
                            self?.deletedSuccessfully(count: numberOfBlockCompleted)
                        }
                        count += 1
                    }
                }
            }
        }
        
        //delete presentationExchange
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.presentationExchange, searchType: .searchWithId, searchValue: self.reqId ?? "") {[weak self] (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler, count: 1000) { [weak self](success, result, error) in
                let resultDict = UIApplicationUtils.shared.convertToDictionary(text: result)
                let presentationExchangeModel = SearchPresentationExchangeModel.decode(withDictionary: resultDict as NSDictionary? ?? NSDictionary()) as? SearchPresentationExchangeModel
                if presentationExchangeModel?.totalCount == 0 {
                    print("delete notifications")
                    numberOfBlockCompleted += 1
                    self?.deletedSuccessfully(count: numberOfBlockCompleted)
                    return
                }
                var count = 1
                for item in presentationExchangeModel?.records ?? [] {
                    AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: item.id ?? "") {[weak self] (deletedSuccessfully, error) in
                        if count == presentationExchangeModel?.records?.count ?? 2 - 1 {
                            print("delete presentationExchange")
                            numberOfBlockCompleted += 1
                            self?.deletedSuccessfully(count: numberOfBlockCompleted)
                        }
                        count += 1
                    }
                }
            }
        }
        
        //delete notifications
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, searchType: .searchWithId, searchValue: self.reqId ?? "") { [weak self](success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler, count: 1000) {[weak self] (success, result, error) in
                let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: result)
                let searchInboxModel = SearchInboxModel.decode(withDictionary: recordResponse as NSDictionary? ?? NSDictionary()) as? SearchInboxModel
                if searchInboxModel?.totalCount == 0 {
                    print("delete notifications")
                    numberOfBlockCompleted += 1
                    self?.deletedSuccessfully(count: numberOfBlockCompleted)
                    return
                }
                var count = 1
                for item in searchInboxModel?.records ?? [] {
                    AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: item.id ?? "") { [weak self](deletedSuccessfully, error) in
                        if count == searchInboxModel?.records?.count ?? 2 - 1 {
                            print("delete notifications")
                            numberOfBlockCompleted += 1
                            self?.deletedSuccessfully(count: numberOfBlockCompleted)
                        }
                        count += 1
                    }
                }
            }
        }
    }
    
    func deletedSuccessfully(count: Int){
        if count != 5 {
            return
        }
        let walletHandler = self.walletHandle ?? IndyHandle()
        //delete Connection
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, id: self.reqId ?? "") { [weak self] (deletedSuccessfully, error) in
            //delete connection Invitation
            AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnectionInvitation, id: self?.connectionInvitationRecordId ?? "") { [weak self](success, error) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    UIApplicationUtils.hideLoader()
                    UIApplicationUtils.showSuccessSnackbar(message: "Organisation removed successfully".localizedForSDK())
                    self?.pageDelegate?.goBackAction()
                })
            }
        }
    }
}


//MARK: EBSI SUPPORT

extension OrganizationDetailViewModel {
    
    func isEBSI() -> Bool{
        if history?.value?.history?.name == CertType.EBSI.rawValue {
            return true
        } else {
            return false
        }
    }
    
    func isEBSI_Diploma() -> Bool{
        if history?.value?.history?.certSubType == EBSI_CredentialType.Diploma.rawValue {
            return true
        } else {
            return false
        }
    }
}

//MARK: Check for thirdPartyDataSharing
extension OrganizationDetailViewModel {
//    func checkForThirdPartyDataSharing() {
//        Task{
//            defer {
//                DispatchQueue.main.async {
//                    self.pageDelegate?.reload()
//                }
//            }
//        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
//                do{
//                let (_, searchHandler) = try await  AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.history, searchType: .history_thirdPartyShare, searchValue: "True")
//                    let (_, response) = try await AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler)
//                    let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: response,boolKeys: ["delete", "lawful_usage", "shared_3pp", "enabled", "attributeSensitive", "thirdPartyDataSharing", "removed"])
//                    let searchModel = SearchHistoryModel.decode(withDictionary: recordResponse ?? [:]) as? SearchHistoryModel
//                    if searchModel?.records?.count ?? 0 > 0 {
//                        isThirdPartyDataSharing = true
//                    } else {
//                        isThirdPartyDataSharing =  false
//                    }
//                }catch{
//                    debugPrint(error.localizedDescription)
//                    isThirdPartyDataSharing = false
//                }
//        }
//    }
}
