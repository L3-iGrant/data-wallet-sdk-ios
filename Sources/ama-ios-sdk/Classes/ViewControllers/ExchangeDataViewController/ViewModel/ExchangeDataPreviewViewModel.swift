//
//  ExchangeDataPreviewViewModel.swift
//  AriesMobileAgent-iOS
//
//  Created by Mohamed Rebin on 15/12/20.
//

import Foundation
import SVProgressHUD
import UIKit
import IndyCWrapper
import eudiWalletOidcIos

protocol ExchangeDataPreviewViewModelDelegate: AnyObject {
    func goBack()
    func showError(message:String)
    func refresh()
    func showAllViews()
}

final class ExchangeDataPreviewViewModel {

    var walletHandle: IndyHandle?
    var reqDetail: SearchPresentationExchangeValueModel?
    var requestedAttributes: [String: ProofCredentialValue] = [String: ProofCredentialValue]()
    var selfAttestedAttributes = [String:Any]()
    var attributelist: [ProofExchangeAttributes] = []
    var certAttributes: [SearchedAttribute] = []
    var groupedAttributes: [String:[IDCardAttributes]]?
    var isInsufficientData: Bool = false
    weak var delegate:ExchangeDataPreviewViewModelDelegate?
    var QRData: ExchangeDataQRCodeModel?
    var orgName: String?
    var orgImage: String?
    var orgLocation: String?
    var isFromQR: Bool = false
    var inboxId: String?
    var connectionModel: CloudAgentConnectionWalletModel?
    var QR_ID:String?
    var allItemsIncludedGroups: [GroupedAttributes] = []
    var sharedAttributes: GroupedAttributes?
    var selectedCardIndex = 0
    var dataAgreement: DataAgreementContext?
    var isFromSDK:Bool = false
    
    var EBSI_credentials: [[SearchItems_CustomWalletRecordCertModel]]?
    var EBSI_credentialsForSession: [[SearchItems_CustomWalletRecordCertModel]]?
    var sessionList: [SessionItem] = []
    var sessionIndex: Int = 0
    var EBSI_credentialsData: [[SearchItems_CustomWalletRecordCertModel]]?
//    let trace_withSign = Performance.sharedInstance().trace(name: "Data  Exchange with Signature -- exchange process")
//    let trace_withoutSignature = Performance.sharedInstance().trace(name: "Data Exchange without Signature -- exchange process")
    var EBSI_conformance: String?
    private var new_dataAgreement: DataAgreementContext?
    private var updateReq: SearchPresentationExchangeValueModel?
    private var processedPresentation: PRPresentation?

    init(walletHandle: IndyHandle?,reqDetail: SearchPresentationExchangeValueModel?,QRData: ExchangeDataQRCodeModel? = nil,isFromQR: Bool? = false, inboxId: String?,connectionModel: CloudAgentConnectionWalletModel?, QR_ID:String? = "", dataAgreementContext: DataAgreementContext? = nil) {

        self.walletHandle = walletHandle
        self.reqDetail = reqDetail
        self.QRData = QRData
        self.isFromQR = isFromQR ?? false
        self.inboxId = inboxId
        self.connectionModel = connectionModel
        self.QR_ID = QR_ID
        self.dataAgreement = dataAgreementContext
    }

    init(walletHandle: IndyHandle?, connectionModel: CloudAgentConnectionWalletModel?, conformance: String?){
        self.walletHandle = walletHandle
        self.connectionModel = connectionModel
        self.EBSI_conformance = conformance
    }

    //Fetching data agreement to show in UI - This will be saving in history too
    func fetchDataAgreement() {
        if dataAgreement != nil { return}
        if isFromQR{
            let walletHandler = walletHandle ?? IndyHandle()
            let value = "\(self.QRData?.invitationURL?.split(separator: "=").last ?? "")".decodeBase64() ?? ""
            let dataDID = UIApplicationUtils.shared.convertToDictionary(text: value)
            let recipientKey = (dataDID?["recipientKeys"] as? [String])?.first ?? ""
            let label = dataDID?["label"] as? String ?? ""
            let serviceEndPoint = dataDID?["serviceEndpoint"] as? String ?? ""
            let routingKey = (dataDID?["routingKeys"] as? [String]) ?? []
            let imageURL = dataDID?["imageUrl"] as? String ?? (dataDID?["image_url"] as? String ?? "")
            let type = dataDID?["@type"] as? String ?? ""
            let didcom = type.split(separator: ";").first ?? ""

            AriesAgentFunctions.shared.createAndStoreId(walletHandler: walletHandler) {[weak self] (createDidSuccess, myDid, verKey,error) in
                //            let myDid = myDid
                guard let strongSelf = self else { return}
                AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: recipientKey, didCom: String(didcom), myVerKey: verKey ?? "", type: .fetchDataAgreement, isRoutingKeyEnabled: routingKey.count > 0, externalRoutingKey: routingKey, QR_ID: strongSelf.QR_ID) {[weak self] (success, data, error) in
                    guard let strongSelf = self else { return}
                    NetworkManager.shared.sendMsg(isMediator: false, msgData: data ?? Data(),url: serviceEndPoint) { [weak self](statuscode,responseData) in
                        guard let strongSelf = self else { return}
                        AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responseData ?? Data()) { [weak self](unpackSuccess, unpackedData, error) in
                            guard let strongSelf = self else { return}
                            if let messageModel = try? JSONSerialization.jsonObject(with: unpackedData ?? Data(), options: []) as? [String : Any] {
                                print("unpackmsg -- \(messageModel)")
                                let msgString = (messageModel)["message"] as? String
                                let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                let dataAgreement = DataAgreementModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? DataAgreementModel

                                let agreement = DataAgreementContext(message: DataAgreementMessage(body: Body(purpose: nil,
                                                                                                              dataControllerURL: nil,
                                                                                                              dataSubjectDid: nil,
                                                                                                              id: nil,
                                                                                                              templateVersion: nil,
                                                                                                              dataControllerName: nil,
                                                                                                              personalData: nil,
                                                                                                              templateID: nil,
                                                                                                              purposeDescription: nil,
                                                                                                              lawfulBasis: nil,
                                                                                                              methodOfUse: nil,
                                                                                                              dataPolicy: DataPolicy(
                                                                                                                industrySector: dataAgreement?.purposeDetails?.purpose?.industryScope ?? "",
                                                                                                                jurisdiction: dataAgreement?.purposeDetails?.purpose?.jurisdiction ?? "", policyURL: dataAgreement?.purposeDetails?.purpose?.policyURL ?? "",
                                                                                                                storageLocation: dataAgreement?.purposeDetails?.purpose?.restriction ?? "",
                                                                                                                dataRetentionPeriod: nil,
                                                                                                                geographicRestriction: dataAgreement?.purposeDetails?.purpose?.dataRetention?.retentionPeriod?.toString, thirdPartyDataSharing: nil),
                                                                                                              version: nil,
                                                                                                              context: nil,
                                                                                                              dpia: nil,
                                                                                                              language: nil,
                                                                                                              type: nil),
                                                                                                   id: "", from: "", to: "", createdTime: "",
                                                                                                   type: ""), messageType: "")

                                strongSelf.dataAgreement = agreement
                                strongSelf.delegate?.refresh()
                                debugPrint("Data Agreement fetched")
                            }
                        }
                    }
                }
            }
        } else {
            let walletHandler = walletHandle ?? IndyHandle()

            AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid: self.connectionModel?.value?.myDid ?? "") { [weak self](getMetaSuccessfully, metadata, error) in
                guard let strongSelf = self else { return}
                let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata ?? "")
                let didcom = strongSelf.reqDetail?.type?.split(separator: ";").first ?? ""
                print("Thread id --- \(strongSelf.reqDetail?.value?.threadID ?? "")" )
                if let my_verKey = metadataDict?["verkey"] as? String{
                    AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: strongSelf.connectionModel?.value?.reciepientKey ?? "", didCom: String(didcom), myVerKey: my_verKey, type: .fetchDataAgreement, isRoutingKeyEnabled: strongSelf.connectionModel?.value?.routingKey?.count ?? 0 > 0, externalRoutingKey: strongSelf.connectionModel?.value?.routingKey, QR_ID: strongSelf.QR_ID) {[weak self] (success, data, error) in
                        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnectionInvitation, searchType: .searchWithId,searchValue: strongSelf.connectionModel?.value?.requestID ?? "") { [weak self](success, searchHandler, error) in
                            guard let strongSelf = self else { return}
                            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) {[weak self] (searchSuccess, records, error) in
                                guard let strongSelf = self else { return}
                                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: records)
                                let invitationRecord = (resultsDict?["records"] as? [[String: Any]])?.first
                                let serviceEndPoint = (invitationRecord?["value"] as? [String: Any])?["serviceEndpoint"] as? String ?? ""
                                _ = (invitationRecord?["value"] as? [String: Any])?["routing_key"] as? String ?? ""
                                NetworkManager.shared.sendMsg(isMediator: false, msgData: data ?? Data(),url: serviceEndPoint) { [weak self](statuscode,responseData) in
                                    guard let strongSelf = self else { return}
                                    AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responseData ?? Data()) { [weak self](unpackSuccess, unpackedData, error) in
                                        guard let strongSelf = self else { return}
                                        if let messageModel = try? JSONSerialization.jsonObject(with: unpackedData ?? Data(), options: []) as? [String : Any] {

                                            print("unpackmsg -- \(messageModel)")
                                            let msgString = (messageModel)["message"] as? String
                                            let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                                            let dataAgreement = DataAgreementModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? DataAgreementModel

                                            strongSelf.dataAgreement = DataAgreementContext(message: DataAgreementMessage(body:
                                                                                                                            Body(purpose: nil,
                                                                                                                                 dataControllerURL: nil,
                                                                                                                                 dataSubjectDid: nil,
                                                                                                                                 id: nil,
                                                                                                                                 templateVersion: nil,
                                                                                                                                 dataControllerName: nil,
                                                                                                                                 personalData: nil,
                                                                                                                                 templateID: nil,
                                                                                                                                 purposeDescription: nil,
                                                                                                                                 lawfulBasis: nil,
                                                                                                                                 methodOfUse: nil,
                                                                                                                                 dataPolicy: DataPolicy(
                                                                                                                                    industrySector: dataAgreement?.purposeDetails?.purpose?.industryScope ?? "",
                                                                                                                                    jurisdiction: dataAgreement?.purposeDetails?.purpose?.jurisdiction ?? "", policyURL: dataAgreement?.purposeDetails?.purpose?.policyURL ?? "",
                                                                                                                                    storageLocation: dataAgreement?.purposeDetails?.purpose?.restriction ?? "",
                                                                                                                                    dataRetentionPeriod: nil,
                                                                                                                                    geographicRestriction: dataAgreement?.purposeDetails?.purpose?.dataRetention?.retentionPeriod?.toString, thirdPartyDataSharing: nil),
                                                                                                                                 version: nil,
                                                                                                                                 context: nil,
                                                                                                                                 dpia: nil,
                                                                                                                                 language: nil,
                                                                                                                                 type: nil),
                                                                                                                          id: "",
                                                                                                                          from: "", to: "", createdTime: "",
                                                                                                                          type: ""), messageType: "")




                                            strongSelf.delegate?.refresh()
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

    // Get the values for each attributes requested. Used Indy function to get values from credential and our own logic to get value from self attested certificates.
    func getCredsForProof(forceReqDetail: Bool? = false, completion: @escaping(Bool) -> Void) {
        let walletHandler = walletHandle ?? IndyHandle()
        UIApplicationUtils.showLoader()
        var attrs = isFromQR ? self.QRData?.proofRequest?.requestedAttributes ?? [:] : self.reqDetail?.value?.presentationRequest?.requestedAttributes ?? [:]
        var presentntReq = isFromQR ? self.QRData?.proofRequest : self.reqDetail?.value?.presentationRequest

        if forceReqDetail ?? false {
            presentntReq = self.reqDetail?.value?.presentationRequest
            attrs = self.reqDetail?.value?.presentationRequest?.requestedAttributes ?? [:]
        } else {
            presentntReq = getPresentationRequest()
            attrs = presentntReq?.requestedAttributes ?? [:]
        }

        attributelist = []
        certAttributes = []
        allItemsIncludedGroups.removeAll()
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithId, searchValue: self.reqDetail?.value?.connectionID ?? "") { [weak self] (success, connSearchHandler, error) in

            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: connSearchHandler) { [weak self] (fetched, records, error) in
                guard let strongSelf = self else { return}
                let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: records)
                let cloudAgentSearchConnectionModel = CloudAgentSearchConnectionModel.decode(withDictionary: recordResponse as NSDictionary? ?? NSDictionary()) as? CloudAgentSearchConnectionModel
                strongSelf.orgName = cloudAgentSearchConnectionModel?.records?.first?.value?.theirLabel ?? ""
                strongSelf.orgImage = cloudAgentSearchConnectionModel?.records?.first?.value?.imageURL ?? ""
                strongSelf.orgLocation = cloudAgentSearchConnectionModel?.records?.first?.value?.orgDetails?.location ?? ""
                if strongSelf.isFromQR {
                    let value = "\(strongSelf.QRData?.invitationURL?.split(separator: "=").last ?? "")".decodeBase64() ?? ""
                    let dataDID = UIApplicationUtils.shared.convertToDictionary(text: value)
                    let label = dataDID?["label"] as? String ?? ""
                    strongSelf.orgName = label
                    strongSelf.orgImage = dataDID?["imageUrl"] as? String ?? (dataDID?["image_url"] as? String ?? "")
                }

                //Search value for each key in both indy saved and self atteched certificates
                var count = 0
                for item in attrs.keys {
                    AriesPoolHelper.shared.pool_prover_search_credentials(forProofRequest: UIApplicationUtils.shared.getJsonString(for: presentntReq.dictionary ?? [String:Any]()), extraQueryJSON: UIApplicationUtils.shared.getJsonString(for: [String:Any]()), walletHandle: walletHandler) {[weak self] (success, searchHandle, error) in
                        guard let strongSelf = self else { return}
                        AriesPoolHelper.shared.proverfetchcredentialsforproof_req(forProofReqItemReferent: item, searchHandle: searchHandle ?? IndyHandle(), count: 100) { [weak self] (success, response, error) in
                            guard let strongSelf = self else { return}
                            let addKeyRecord = "{\"records\":" + (response ?? "") + "}"
                            let proofReqDict = UIApplicationUtils.shared.convertToDictionary(text: addKeyRecord)
                            let searchProofRequestItemResponse = SearchProofRequestItemResponse.decode(withDictionary: proofReqDict as NSDictionary? ?? NSDictionary()) as? SearchProofRequestItemResponse

                            if searchProofRequestItemResponse?.records?.count ?? 0 == 0 && ((attrs[item]?.restrictions?.count ?? 0) == 0) {
                                //Search in self attested documents
                                WalletRecord.shared.fetchAllCert { idCardSearchModel in
                                    if idCardSearchModel?.records?.count ?? 0 == 0 {
                                        strongSelf.isInsufficientData = true
                                    }
                                    let sortedRecords = idCardSearchModel?.records?.sorted(by: { (first, second) -> Bool in
                                        (first.value?.addedDate ?? "0") > (second.value?.addedDate ?? "0")
                                    })
                                    innerloop : for doc in sortedRecords ?? [] {
                                        //MARK: Credential issued
                                        if (doc.value?.certInfo) != nil{
                                            //Do nothing
                                        }
                                        //MARK: PASSPORT
                                        else if let dict = doc.value?.passport?.dictionary{
                                            //                                                    if let value = (dict[attrs[item]?.name ?? ""]{
                                            if var idCardValue =  IDCardAttributes.decode(withDictionary: (dict[attrs[item]?.name ?? ""] ?? NSDictionary()) as? NSDictionary ?? NSDictionary()) as? IDCardAttributes, let _ = idCardValue.value{

                                                strongSelf.selfAttestedAttributes[item] = idCardValue.value ?? ""
                                                var attributes = ProofExchangeAttributes()
                                                attributes.name = attrs[item]?.name
                                                attributes.value = idCardValue.value ?? ""
                                                attributes.credDefId = nil
                                                attributes.referent = nil
                                                strongSelf.attributelist.append(attributes)
                                                idCardValue.name = attrs[item]?.name ?? ""
                                                if idCardValue.value == nil {
                                                    strongSelf.isInsufficientData = true
                                                }
                                                var searchedAttr = SearchedAttribute()
                                                searchedAttr.value = idCardValue
                                                searchedAttr.exchangeAttributes = attributes
                                                searchedAttr.id = doc.id ?? ""
                                                searchedAttr.certselfAttestedSubType = .passport
                                                searchedAttr.selfAttestedCertModel = doc.value
                                                searchedAttr.attrName = attrs[item]?.name
                                                searchedAttr.presentationRequestParamName = item
                                                strongSelf.certAttributes.append(searchedAttr)
                                            }
                                        }
                                        //MARK: AADHAR
                                        else if let dict = doc.value?.aadhar?.dictionary{
                                            if var idCardValue =  IDCardAttributes.decode(withDictionary: (dict[attrs[item]?.name ?? ""] ?? NSDictionary()) as? NSDictionary ?? NSDictionary()) as? IDCardAttributes, let _ = idCardValue.value{

                                                strongSelf.selfAttestedAttributes[item] = idCardValue.value ?? ""
                                                var attributes = ProofExchangeAttributes()
                                                attributes.name = attrs[item]?.name
                                                attributes.value = idCardValue.value ?? ""
                                                attributes.credDefId = nil
                                                attributes.referent = nil
                                                strongSelf.attributelist.append(attributes)
                                                idCardValue.name = attrs[item]?.name ?? ""
                                                if idCardValue.value == nil {
                                                    strongSelf.isInsufficientData = true
                                                }
                                                var searchedAttr = SearchedAttribute()
                                                searchedAttr.value = idCardValue
                                                searchedAttr.exchangeAttributes = attributes
                                                searchedAttr.id = doc.id ?? ""
                                                searchedAttr.certselfAttestedSubType = .aadhar
                                                searchedAttr.selfAttestedCertModel = doc.value
                                                searchedAttr.attrName = attrs[item]?.name
                                                searchedAttr.presentationRequestParamName = item
                                                strongSelf.certAttributes.append(searchedAttr)

                                            }
                                        }
                                        //MARK: PKPASS
                                        else if doc.value?.pkPass?.attributes != nil {
                                            //old pkpass model

                                        }
                                        else if let dict = doc.value?.pkPass?.attributeModel.dictionary{
                                            if var idCardValue =  IDCardAttributes.decode(withDictionary: (dict[attrs[item]?.name ?? ""] ?? NSDictionary()) as? NSDictionary ?? NSDictionary()) as? IDCardAttributes, let _ = idCardValue.value{

                                                strongSelf.selfAttestedAttributes[item] = idCardValue.value ?? ""
                                                var attributes = ProofExchangeAttributes()
                                                attributes.name = attrs[item]?.name
                                                attributes.value = idCardValue.value ?? ""
                                                attributes.credDefId = nil
                                                attributes.referent = nil
                                                strongSelf.attributelist.append(attributes)
                                                idCardValue.name = attrs[item]?.name ?? ""
                                                if idCardValue.value == nil {
                                                    strongSelf.isInsufficientData = true
                                                }
                                                var searchedAttr = SearchedAttribute()
                                                searchedAttr.value = idCardValue
                                                searchedAttr.exchangeAttributes = attributes
                                                searchedAttr.id = doc.id ?? ""
                                                searchedAttr.certselfAttestedSubType = .pkPass
                                                searchedAttr.selfAttestedCertModel = doc.value
                                                searchedAttr.attrName = attrs[item]?.name
                                                searchedAttr.presentationRequestParamName = item
                                                strongSelf.certAttributes.append(searchedAttr)

                                            }
                                        } else if let dw_attr = doc.value?.attributes?[attrs[item]?.name ?? ""]{
                                            var idCardValue = IDCardAttributes(name: dw_attr.label , value:dw_attr.value)
                                            strongSelf.selfAttestedAttributes[item] = idCardValue.value ?? ""
                                            var attributes = ProofExchangeAttributes()
                                            attributes.name = attrs[item]?.name
                                            attributes.value = idCardValue.value ?? ""
                                            attributes.credDefId = nil
                                            attributes.referent = nil
                                            strongSelf.attributelist.append(attributes)
//                                            idCardValue.name = attrs[item]?.name ?? ""
                                            if idCardValue.value == nil {
                                                strongSelf.isInsufficientData = true
                                            }
                                            var searchedAttr = SearchedAttribute()
                                            searchedAttr.value = idCardValue
                                            searchedAttr.exchangeAttributes = attributes
                                            searchedAttr.id = doc.id ?? ""
                                            searchedAttr.certselfAttestedSubType = .profile
                                            searchedAttr.selfAttestedCertModel = doc.value
                                            searchedAttr.attrName = attrs[item]?.name
                                            searchedAttr.presentationRequestParamName = item
                                            strongSelf.certAttributes.append(searchedAttr)
                                        }
                                    }
                                    strongSelf.checkAndAddBlankModel(attr:attrs[item]?.name ?? "")

                                    // processed last attr
                                    if count == attrs.keys.count - 1  {
                                        var tempArray: [ProofExchangeAttributes] = []
                                        for attr in attrs.keys {
                                            if let value = strongSelf.attributelist.filter({$0.name == attrs[attr]?.name}).first {
                                                tempArray.append(value)
                                            }
                                        }
                                        strongSelf.attributelist = tempArray
                                        AriesPoolHelper.shared.proverclosecredentialssearchforproofreq(withHandle: searchHandle ?? IndyHandle()) { (success, error) in
                                            strongSelf.createGroupedAttributes(refreshDisabled: forceReqDetail)
                                            completion(true)
                                        }
                                    } else {
                                        count = count + 1
                                        print("count ---- \(count)")
                                    }
                                }
                            }
                            else {
                                //Search value in non self certificates
                                count = count + 1
                                if (searchProofRequestItemResponse?.records?.count ?? 0) == 0 {
                                    strongSelf.checkAndAddBlankModel(attr:attrs[item]?.name ?? "")
                                    if count == attrs.keys.count {
                                        var tempArray: [ProofExchangeAttributes] = []
                                        for attr in attrs.keys {
                                            if let value = strongSelf.attributelist.filter({$0.name == attrs[attr]?.name}).first {
                                                tempArray.append(value)
                                            }
                                        }
                                        strongSelf.attributelist = tempArray
                                        AriesPoolHelper.shared.proverclosecredentialssearchforproofreq(withHandle: searchHandle ?? IndyHandle()) {(success, error) in
                                            strongSelf.createGroupedAttributes(refreshDisabled: forceReqDetail)
                                            completion(true)
                                        }
                                    }
                                } else {
                                    for searchResult in searchProofRequestItemResponse?.records ?? [] {
                                        var credValue = ProofCredentialValue()
                                        credValue.credId = searchResult.credInfo?.referent
                                        credValue.revealed = true
                                        strongSelf.requestedAttributes[item] = credValue
                                        var attributes = ProofExchangeAttributes()
                                        attributes.name = attrs[item]?.name
                                        attributes.value = searchResult.credInfo?.attrs?[attributes.name ?? ""] ?? ""
                                        if let names = attrs[item]?.names {
                                            for name in names{
                                                if let value = searchResult.credInfo?.attrs?[name] {
                                                    attributes.name = name
                                                    attributes.value = value
                                                }
                                            }
                                        }
                                        attributes.credDefId = searchResult.credInfo?.credDefID
                                        attributes.referent = searchResult.credInfo?.referent
                                        strongSelf.attributelist.append(attributes)
                                        let idCardModel = IDCardAttributes.init(name: attributes.name, value: attributes.value)
                                        var searchedAttr = SearchedAttribute()
                                        searchedAttr.value = idCardModel
                                        searchedAttr.exchangeAttributes = attributes
                                        searchedAttr.id = searchResult.credInfo?.referent
                                        searchedAttr.isSelfAttestedCert = true
                                        searchedAttr.attrName = item
                                        searchedAttr.certType = .credentials
                                        strongSelf.certAttributes.append(searchedAttr)

                                        if searchResult.credInfo?.referent == searchProofRequestItemResponse?.records?.last?.credInfo?.referent && count == attrs.keys.count {
                                            var tempArray: [ProofExchangeAttributes] = []
                                            for attr in attrs.keys {
                                                if let value = strongSelf.attributelist.filter({$0.name == attrs[attr]?.name}).first {
                                                    tempArray.append(value)
                                                }
                                            }
                                            strongSelf.attributelist = tempArray
                                            AriesPoolHelper.shared.proverclosecredentialssearchforproofreq(withHandle: searchHandle ?? IndyHandle()) {(success, error) in
                                                strongSelf.createGroupedAttributes(refreshDisabled: forceReqDetail)
                                                completion(true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                if attrs.isEmpty {
                    strongSelf.isInsufficientData = true
                    strongSelf.createGroupedAttributes(refreshDisabled: forceReqDetail)
                    completion(true)
                }
            }
        }
    }

    private func trimCertNameFromSchemeID(name: String) -> String{
        return name.stringByRemovingAll(subStrings: SupportingCertificateNameInSchema.allCases.map({ e in
            e.rawValue
        }))
    }
    //If the value for the attribute is not in the wallet, We need to create blank model in order to display the preview.
    private func checkAndAddBlankModel(attr: String) {
        let attrArray = certAttributes.first { e in
            e.attrName == attr
        }
        if attrArray == nil {
            var searchedAttr = SearchedAttribute()
            var attributes = ProofExchangeAttributes()
            attributes.name = attr
            attributes.value = ""
            attributes.credDefId = nil
            attributes.referent = nil
            self.attributelist.append(attributes)
            //                                                strongSelf.isInsufficientData = true
            searchedAttr.exchangeAttributes = attributes
            searchedAttr.attrName = attr
            self.certAttributes.append(searchedAttr)
        }
    }

    // Grouping the attribute according to certificate
    func createGroupedAttributes(refreshDisabled: Bool?){
        var attributeGroups = Array(Dictionary(grouping:certAttributes){$0.id}.values)
        allItemsIncludedGroups.removeAll()

        var presentntReq = getPresentationRequest()
        let attrs = presentntReq?.requestedAttributes ?? [:]

        for groups in attributeGroups {
            if groups.count == attrs.count {
                allItemsIncludedGroups.append(GroupedAttributes(id: groups.first?.id, attr: groups, isSeleceted: false))
            }
        }
        if(allItemsIncludedGroups.count == 0){
            attributeGroups = Array(Dictionary(grouping:certAttributes){$0.attrName}.values)
            var attrs: [SearchedAttribute] = []
            for groups in attributeGroups {
                if let attr = groups.first{
                    attrs.append(attr)
                }
            }
            if attrs.isEmpty {
                let attributes = presentntReq?.requestedAttributes ?? [:]
                for item in attributes {
                    attrs.append(SearchedAttribute.init(value: IDCardAttributes.init(name: item.value.name ?? item.value.names?.first ?? "", value: nil), exchangeAttributes: nil, requestCred: nil, id: nil, attrName: nil, isSelfAttestedCert: false, certType: nil, certselfAttestedSubType: nil, selfAttestedCertModel: nil))
                }
                isInsufficientData = true
                allItemsIncludedGroups.append(GroupedAttributes(id: nil, attr: attrs, isSeleceted: true))
            } else {
                allItemsIncludedGroups.append(GroupedAttributes(id: nil, attr: attrs, isSeleceted: true))
            }

        }
        if !(refreshDisabled ?? false){
            delegate?.refresh()
        }
    }

    //Check connection is already established if not establish a new connection
    func checkConnection() {
        let blankData = allItemsIncludedGroups.filter { e in
            e.attr?.filter({ i in
                (i.value?.value == "" ||  i.value?.value == nil)
            }).isNotEmpty ?? false
        }

        if isInsufficientData || blankData.count != 0 {
            UIApplicationUtils.showErrorSnackbar(withTitle:"Error",message: "Insufficient Data")
            return
        }
//        trace_withSign?.start()
        sharedAttributes = allItemsIncludedGroups[selectedCardIndex]
        if requestedAttributes.isNotEmpty {
            self.requestedAttributes.removeAll()
            for attr in sharedAttributes?.attr ?? [] {
                var credValue = ProofCredentialValue()
                credValue.credId = attr.id
                credValue.revealed = true
                self.requestedAttributes[attr.attrName ?? ""] = credValue
            }
        }

        if selfAttestedAttributes.isNotEmpty {
            for item in sharedAttributes?.attr ?? []{
                selfAttestedAttributes[item.presentationRequestParamName ?? ""] = item.value?.value
            }
        }

        var value = "\(self.QRData?.invitationURL?.split(separator: "=").last ?? "")".decodeBase64() ?? ""
        var dataDID = UIApplicationUtils.shared.convertToDictionary(text: value)
//        trace_withSign?.start()
        if value == "" {
            let invitationDict = UIApplicationUtils.shared.convertToDictionary(text: self.QRData?.invitationURL ?? "") as? [String: Any]
            dataDID = invitationDict?["invitation"] as? [String: AnyObject]
        }
        let recipientKey = (dataDID?["recipientKeys"] as? [String])?.first ?? ""
        let label = dataDID?["label"] as? String ?? ""
        let serviceEndPoint = dataDID?["serviceEndpoint"] as? String ?? ""
        let routingKey = (dataDID?["routingKeys"] as? [String]) ?? []
        let imageURL = dataDID?["imageUrl"] as? String ?? (dataDID?["image_url"] as? String ?? "")
        let type = dataDID?["@type"] as? String ?? ""
        let didcom = type.split(separator: ";").first ?? ""
        self.orgName = label
        self.orgImage = imageURL
        if self.isFromQR && self.QRData?.threadId == nil {
            UIApplicationUtils.showLoader()
            self.getConnectionModel { model in
                let walletHandler = self.walletHandle ?? IndyHandle()
                if let connectionModel = model {
                    AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid: connectionModel.value?.myDid ?? "") { [weak self] (getMetaSuccessfully, metadata, error) in
                        guard let strongSelf = self else { return}
                        let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata ?? "")
                        if let my_verKey = metadataDict?["verkey"] as? String{
                            strongSelf.getPresentationRequest(walletHandler: walletHandler, connectionModel: connectionModel, recipientKey: connectionModel.value?.reciepientKey ?? "", myKey: my_verKey, serviceEndPoint: serviceEndPoint, didCom: String(didcom))
                        }
                    }
                }else{
                    let connectionVC = ConnectionPopupViewController()
                    connectionVC.showConnectionPopup(orgName: label, orgImageURL: imageURL, walletHandler: walletHandler, recipientKey: recipientKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey,isFromDataExchange: true, didCom: String(didcom)) { [weak self] (connectionModel,recipientKey,myVerKey,message) in
                        guard let strongSelf = self else { return}
                        DispatchQueue.main.async {
                            UIApplicationUtils.showLoader()
                            guard let connectionModel = connectionModel, let recipientKey = recipientKey, let myVerKey = myVerKey else{
                                UIApplicationUtils.hideLoader()
                                UIApplicationUtils.showErrorSnackbar(message: "Something went wrong".localizedForSDK())
                                return
                            }
                            strongSelf.connectionModel = connectionModel
                            strongSelf.getPresentationRequest(walletHandler: walletHandler, connectionModel: connectionModel, recipientKey: recipientKey, myKey: myVerKey,serviceEndPoint:serviceEndPoint, didCom: String(didcom))
                        }
                    }
                }
            }
        } else {
            self.acceptCertificate()
        }
    }

    //Get connection from the wallet
    func getConnectionModel(completion: @escaping(CloudAgentConnectionWalletModel?) -> Void){
        if self.connectionModel != nil {
            completion(self.connectionModel)
            return
        }
        let walletHandler = self.walletHandle ?? IndyHandle()
        let value = "\(self.QRData?.invitationURL?.split(separator: "=").last ?? "")".decodeBase64() ?? ""
        let dataDID = UIApplicationUtils.shared.convertToDictionary(text: value)
        let recipientKey = (dataDID?["recipientKeys"] as? [String])?.first ?? ""
        let label = dataDID?["label"] as? String ?? ""
        let serviceEndPoint = dataDID?["serviceEndpoint"] as? String ?? ""
        let routingKey = (dataDID?["routingKeys"] as? [String]) ?? []
        let imageURL = dataDID?["imageUrl"] as? String ?? (dataDID?["image_url"] as? String ?? "")

        self.orgName = label
        self.orgImage = imageURL
        AriesCloudAgentHelper.shared.checkConnectionWithSameOrgExist(walletHandler: walletHandler, label: label, theirVerKey: recipientKey, serviceEndPoint: serviceEndPoint, routingKey: routingKey, imageURL: imageURL, isFromDataExchange: true) { [weak self] success, orgInfoModel, connectionModel, message  in
            guard let strongSelf = self else { return}
            if connectionModel?.value == nil {
                completion(nil)
            } else{
                strongSelf.connectionModel = connectionModel
                completion(connectionModel)
            }
        }
        //        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection,searchType: .checkExistingConnection,invitationKey: recipientKey, completion: { [weak self](success, searchWalletHandler, error) in
        //            if (success){
        //                AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchWalletHandler, completion: {[weak self] (fetchedSuccessfully,results,error) in
        //                    if (fetchedSuccessfully){
        //                        let resultDict = UIApplicationUtils.shared.convertToDictionary(text: results,boolKeys: ["delete"])
        //                        if ((resultDict?["records"] as? [[String:Any]])?.first?["id"] as? String) != nil {
        //                            let records = resultDict?["records"] as? [[String:Any]]
        //                            let firstRecord = records?.first
        //                            let connectionModel = CloudAgentConnectionWalletModel.decode(withDictionary: firstRecord as NSDictionary? ?? NSDictionary()) as? CloudAgentConnectionWalletModel ?? CloudAgentConnectionWalletModel()
        //                            strongSelf.connectionModel = connectionModel
        //                            completion(connectionModel)
        //                        } else {
        //                            completion(nil)
        //                        }
        //                    }
        //                })
        //                }
        //        })
    }

    //get presentation Request - case: isfromQR == true
    func getPresentationRequest(walletHandler: IndyHandle,connectionModel:CloudAgentConnectionWalletModel, recipientKey: String, myKey: String,serviceEndPoint:String,didCom:String ){
        UIApplicationUtils.showLoader()
        var attr = ProofExchangeAttributesArray()
        attr.items = (allItemsIncludedGroups[selectedCardIndex].attr ?? []).map({ e in
            e.exchangeAttributes ?? ProofExchangeAttributes()
        }) //attributelist
        let didcom = isFromQR ? didCom : String(reqDetail?.type?.split(separator: ";").first ?? "")
        AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: recipientKey, didCom: didcom, myVerKey: myKey, attributes: attr, type: .proposePresentation,isRoutingKeyEnabled: connectionModel.value?.routingKey?.count ?? 0 > 0,externalRoutingKey: connectionModel.value?.routingKey ?? [],QR_ID: self.QR_ID) {[weak self] (success, data, error) in
            guard let strongSelf = self else { return}
            NetworkManager.shared.sendMsg(isMediator: false, msgData: data ?? Data(),url: serviceEndPoint) { [weak self](statuscode,responseData) in
                guard let strongSelf = self else { return}
                AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responseData ?? Data()) { [weak self](unpackSuccess, unpackedData, error) in
                    guard let strongSelf = self else { return}
                    if let receivedData = unpackedData {
                        if let messageModel = try? JSONSerialization.jsonObject(with: receivedData , options: []) as? [String : Any] {
                            print("unpackmsg -- \(messageModel)")
                            let msgString = (messageModel)["message"] as? String
                            let msgDict = UIApplicationUtils.shared.convertToDictionary(text: msgString ?? "")
                            let recipient_verkey = (messageModel)["recipient_verkey"] as? String ?? ""
                            let sender_verkey = (messageModel)["sender_verkey"] as? String ?? ""
                            print("Presentation request received")
                            let requestPresentationMessageModel = RequestPresentationMessageModel.decode(withDictionary: msgDict as NSDictionary? ?? NSDictionary()) as? RequestPresentationMessageModel
                            strongSelf.requestPresentationReceived(requestPresentationMessageModel:requestPresentationMessageModel,myVerKey: recipient_verkey,recipientKey: sender_verkey, type: String(didcom))
                        }

                    } else {
                        UIApplicationUtils.showErrorSnackbar(message: "Something went wrong".localizedForSDK())
                        UIApplicationUtils.hideLoader()
                    }
                }
            }
        }
    }

    //Accept and share the data -- when user click on confirm
    fileprivate func getSchemaAndCredParsedList(credentialDefinitionID: String) async throws -> ([String], [String], Error?) {
        let walletHandler = self.walletHandle ?? IndyHandle()
        var schemaParsedList: [String] = []
        var credParsedList: [String] = []

        //Set protocol --- let setProtocol_success
        _ = try await AriesPoolHelper.shared.pool_setProtocol(version: 2)

        //get credentials --- let (getCredential_success,credentialJSON)
        let (_,credentialJSON) = try await AriesPoolHelper.shared.pool_prover_get_credential(id: credentialDefinitionID, walletHandle: walletHandler)
        let credentialDict = UIApplicationUtils.shared.convertToDictionary(text: credentialJSON)
        let credentialInfo = SearchProofReqCredInfo.decode(withDictionary: credentialDict as NSDictionary? ?? NSDictionary()) as? SearchProofReqCredInfo

        //get scheme request --- let (getSchemaReq_success, getSchemaReqResponse)
        let (_, getSchemaReqResponse) =  try await AriesPoolHelper.shared.buildGetSchemaRequest(id: credentialInfo?.schemaID ?? "")

        //submit request --- let (submitReq_success, submitResponse)
        let (_, submitResponse) =  try await AriesPoolHelper.shared.submitRequest(poolHandle: AriesPoolHelper.poolHandler, requestJSON: getSchemaReqResponse)

        //get scheme response ---  let (submitResponse_success, defId, defJson)
        let (_, _, defJson) =  try await AriesPoolHelper.shared.buildGetSchemaResponse(getSchemaResponse: submitResponse)
        if (!schemaParsedList.contains(defJson)){
            schemaParsedList.append(defJson)
        }

        //get credential definition request --- let (getCredDef_success, credReqResponse)
        let (_, credReqResponse) =  try await AriesPoolHelper.shared.buildGetCredDefRequest(id: credentialInfo?.credDefID ?? "")

        //submit request --- let (credDefRes_success, credDefResponse)
        let (_, credDefResponse) =  try await AriesPoolHelper.shared.submitRequest(poolHandle: AriesPoolHelper.poolHandler, requestJSON: credReqResponse)

        //parseGetCredDef --- let (parseCredDefRes_success, credId, credresJson)
        let (_, _, credresJson,error) = await AriesPoolHelper.shared.parseGetCredDefResponseWithLedgerSwitching(credentialDefinitionID: credentialInfo?.credDefID ?? "")
        if error?.localizedDescription.contains("309") ?? false {
            UIApplicationUtils.hideLoader()
            UIApplicationUtils.showErrorSnackbar(message: "Invalid Ledger. You can choose proper ledger from settings".localizedForSDK())
            return([],[],error)
        }
        credParsedList.append(credresJson)
        debugPrint("credResJSON added")
        return (schemaParsedList,credParsedList, nil)
    }

    func acceptCertificate() {
        Task {
            let (schemaParsedList,credParsedList) = await withTaskGroup(of: ([String],[String]).self) { group -> ([String],[String]) in

                let walletHandler = self.walletHandle ?? IndyHandle()
                UIApplicationUtils.showLoader()

                if self.requestedAttributes.count == 0 {
                    return ([],[])
                }

                //for initial check and switch ledger
                _ = await AriesPoolHelper.shared.getSchemaAndCredParsedListWithLedgerSwitching(credentialDefinitionID: self.requestedAttributes.first?.value.credId ?? "")

                for item in self.requestedAttributes {
                    group.addTask{
                        do {
                            let (schemaParsedList,credParsedList,error) = try await self.getSchemaAndCredParsedList(credentialDefinitionID: item.value.credId ?? "")
                            if error?.localizedDescription.contains("309") ?? false {
                                UIApplicationUtils.hideLoader()
                                UIApplicationUtils.showErrorSnackbar(message: "Invalid Ledger. You can choose proper ledger from settings".localizedForSDK())
                                return([],[])
                            }
                            return (schemaParsedList,credParsedList)
                        }catch{
                            if error.localizedDescription.contains("309") {
                                UIApplicationUtils.hideLoader()
                                UIApplicationUtils.showErrorSnackbar(message: "Invalid Ledger. You can choose proper ledger from settings".localizedForSDK())
                                return([],[])
                            }
                            return([],[])
                        }
                    }
                }
                var schemaParsedList: [String] = []
                var credParsedList: [String] = []
                for await (schema,credList) in group {
                    schemaParsedList.append(contentsOf: schema)
                    credParsedList.append(contentsOf: credList)
                }
                return (schemaParsedList,credParsedList)
            }
            if schemaParsedList.isNotEmpty && credParsedList.isNotEmpty{
                self.createPool(schemaList: schemaParsedList, credList: credParsedList)
                debugPrint("create pool")
            } else if selfAttestedAttributes.isNotEmpty {
                self.createPool(schemaList: schemaParsedList, credList: credParsedList)
            } else {
                UIApplicationUtils.hideLoader()
            }
        }
    }

    func createPool(schemaList:[String], credList: [String]) {
        let walletHandler = walletHandle ?? IndyHandle()

        let deviceID = UIDevice.current.identifierForVendor!.uuidString
        let masterSecretID = "iGrantMobileAgent-\(deviceID)"

        var schemasJson = [String:Any]()
        for item in schemaList{
            let tempDict =  UIApplicationUtils.shared.convertToDictionary(text: item)
            let schemaID = tempDict?["id"] as? String ?? ""

            schemasJson[schemaID] = UIApplicationUtils.shared.convertToDictionary(text: item)
        }

        var credJson = [String:Any]()
        for item in credList {
            let tempDict =  UIApplicationUtils.shared.convertToDictionary(text: item)
            let credID = tempDict?["id"] as? String ?? ""
            credJson[credID] = UIApplicationUtils.shared.convertToDictionary(text: item)
        }

        let RequestedCredentialsJSON = ["self_attested_attributes": self.selfAttestedAttributes,
                                        "requested_attributes":  requestedAttributes.dictionary ?? [String:Any](),
                                        "requested_predicates": [String : Any]()] as [String : Any]


        var presentntReq = getPresentationRequest()
        AriesPoolHelper.shared.createProof(
            forRequest: UIApplicationUtils.shared.getJsonString(for: presentntReq.dictionary ?? [String:Any]()) ,
            requestedCredentialsJSON: UIApplicationUtils.shared.getJsonString(for: RequestedCredentialsJSON),
            masterSecretID: masterSecretID,
            schemasJSON: UIApplicationUtils.shared.getJsonString(for: schemasJson),
            credentialDefsJSON: UIApplicationUtils.shared.getJsonString(for: credJson),
            revocStatesJSON: UIApplicationUtils.shared.getJsonString(for:[String:Any]()),
            walletHandle: walletHandler) {[weak self] (success,proofJson, error) in
                guard let strongSelf = self else { return}
                strongSelf.updateReq = strongSelf.reqDetail
                let proofDict = UIApplicationUtils.shared.convertToDictionary(text: proofJson)
                let presentation = PRPresentation.decode(withDictionary: proofDict as NSDictionary? ?? NSDictionary()) as? PRPresentation
                print("Presentation --- \(presentation)")
                strongSelf.updateReq?.value?.presentation = presentation
                strongSelf.updateReq?.value?.state = "presentation_sent"
                strongSelf.processedPresentation = presentation
                AriesAgentFunctions.shared.updateWalletRecord(walletHandler: walletHandler, type: .credentialExchange, id: strongSelf.reqDetail?.id ?? "",presentationReqModel:strongSelf.updateReq?.value) {[weak self] (success, id, error) in
                    guard let strongSelf = self else { return}
                    AriesAgentFunctions.shared.updateWalletTags(walletHandler: walletHandler, id: strongSelf.reqDetail?.id ?? "", type: .credentialExchange,threadId: strongSelf.updateReq?.value?.threadID ?? "" ,state:strongSelf.updateReq?.value?.state ?? "") {[weak self] (success, error) in
                        guard let strongSelf = self else { return}
                        AriesAgentFunctions.shared.getMyDidWithMeta(walletHandler: walletHandler, myDid: strongSelf.connectionModel?.value?.myDid ?? "") { [weak self](getMetaSuccessfully, metadata, error) in
                            guard let strongSelf = self else { return}
                            let metadataDict = UIApplicationUtils.shared.convertToDictionary(text: metadata ?? "")
                            let didcom = strongSelf.reqDetail?.type?.split(separator: ";").first ?? ""
                            print("Thread id --- \(strongSelf.reqDetail?.value?.threadID ?? "")" )
                            Task {
                                if let my_verKey = metadataDict?["verkey"] as? String{
                                    var presentationDataAgreementTemplate: [String: Any]?
                                    if let dataAgreementContext = strongSelf.dataAgreement, dataAgreementContext.message?.body?.proof != nil{
                                        (presentationDataAgreementTemplate,strongSelf.new_dataAgreement) = await SignCredential.shared.signCredential(dataAgreement: dataAgreementContext, recordId: strongSelf.connectionModel?.id ?? "")
                                    }

                                    let packTemplate =  presentationDataAgreementTemplate != nil ? AriesPackMessageTemplates.presentationDataExchangeWithDataAgreement(presentation: strongSelf.updateReq?.value?.presentation ?? strongSelf.processedPresentation, didCom: strongSelf.QRData?.didCom ?? String(didcom), threadId: strongSelf.QRData?.threadId ?? strongSelf.reqDetail?.value?.threadID ?? "",dataAgreementContext: presentationDataAgreementTemplate ?? [String: Any]()) : AriesPackMessageTemplates.presentationDataExchange(presentation: strongSelf.updateReq?.value?.presentation ?? strongSelf.processedPresentation, didCom: String(didcom), threadId: strongSelf.reqDetail?.value?.threadID ?? "")

                                    AriesAgentFunctions.shared.packMessage(walletHandler: walletHandler, recipientKey: strongSelf.connectionModel?.value?.reciepientKey ?? "", didCom: String(didcom), myVerKey: my_verKey, threadId: strongSelf.reqDetail?.value?.threadID ?? "", type: .rawDataBody, isRoutingKeyEnabled: strongSelf.connectionModel?.value?.routingKey?.count ?? 0 > 0, externalRoutingKey : strongSelf.connectionModel?.value?.routingKey ?? [], rawDict: packTemplate) { (success, packedData, error) in
                                        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnectionInvitation, searchType: .searchWithId,searchValue: strongSelf.connectionModel?.value?.requestID ?? "") { (success, searchHandler, error) in
                                            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (searchSuccess, records, error) in
                                                let resultsDict = UIApplicationUtils.shared.convertToDictionary(text: records)
                                                let invitationRecord = (resultsDict?["records"] as? [[String: Any]])?.first
                                                let serviceEndPoint = (invitationRecord?["value"] as? [String: Any])?["serviceEndpoint"] as? String ?? ""
                                                _ = (invitationRecord?["value"] as? [String: Any])?["routing_key"] as? String ?? ""
//                                                let trace = Performance.sharedInstance().trace(name: "Data Exchange -- presentation ")
//                                                trace?.start()
                                                NetworkManager.shared.sendMsg(isMediator: false, msgData: packedData ?? Data(),url: serviceEndPoint) {(statuscode,responseData) in
//                                                    trace?.stop()
                                                    //                                                                    AriesAgentFunctions.shared.unpackMessage(walletHandler: walletHandler, messageData: responseData ?? Data()) { (unpackSuccess, unpackedData, error) in
                                                    //                                                                        if unpackSuccess {
//                                                    strongSelf.trace_withSign?.stop()
                                                    strongSelf.deleteWalletRecord()
                                                    strongSelf.addHistory()
                              //                                                                        }
                                                    //                                                                    }
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

    func deleteWalletRecord(isFromDelete: Bool = false) {
        let walletHandler = walletHandle ?? IndyHandle()
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.presentationExchange, id: reqDetail?.id ?? "") { [weak self](success, error) in
            guard let strongSelf = self else { return}
            AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.inbox, id: strongSelf.inboxId ?? "") {[weak self] (deletedSuccessfully, error) in
                guard let strongSelf = self else { return}
                UIApplicationUtils.hideLoader()
                UIApplicationUtils.showSuccessSnackbar(message: isFromDelete ? "Removed successfully".localizedForSDK() : "Data has been shared successfully".localizedForSDK())
                if deletedSuccessfully {
                    strongSelf.delegate?.goBack()
                } else {
                    if strongSelf.isFromQR ?? false{
                        strongSelf.delegate?.goBack()
                        return
                    }
                    strongSelf.delegate?.showError(message: "Failed to delete request from wallet record.".localizedForSDK())
                }
            }
        }
    }

    func rejectCertificate() {
        self.deleteWalletRecord(isFromDelete: true)
    }

}

//MARK: request-presentation
extension ExchangeDataPreviewViewModel {

    func requestPresentationReceived(requestPresentationMessageModel: RequestPresentationMessageModel?,myVerKey: String,recipientKey: String,type: String) {
        let walletHandler = self.walletHandle ?? 0
        let base64String = requestPresentationMessageModel?.requestPresentationsAttach?.first?.data?.base64?.decodeBase64() ?? ""
        let base64DataDict = UIApplicationUtils.shared.convertToDictionary(text: base64String)
        let presentationRequestModel = PresentationRequestModel.decode(withDictionary: base64DataDict as NSDictionary? ?? NSDictionary()) as? PresentationRequestModel
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.cloudAgentConnection, searchType: .searchWithReciepientKey,searchValue: recipientKey) {[weak self] (success, searchHandler, error) in
            guard let strongSelf = self else { return}
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) {[weak self] (success, record, error) in
                guard let strongSelf = self else { return}
                let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: record)
                let cloudAgentSearchConnectionModel = CloudAgentSearchConnectionModel.decode(withDictionary: recordResponse as NSDictionary? ?? NSDictionary()) as? CloudAgentSearchConnectionModel
                if cloudAgentSearchConnectionModel?.totalCount ?? 0 > 0 {
                    //                    AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.presentationExchange,searchType:.searchWithThreadId, threadId: requestPresentationMessageModel?.id ?? "") { (success, prsntnExchngSearchWallet, error) in
                    //                        AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: prsntnExchngSearchWallet) { (success, response, error) in
                    //                            let recordResponse = UIApplicationUtils.shared.convertToDictionary(text: response)
                    //                            if (recordResponse?["totalCount"] as? Int ?? 0) > 0 {
                    //                                return
                    //                            }
                    //                            let searchPresentationExchangeModel = SearchPresentationExchangeModel.decode(withDictionary: recordResponse as NSDictionary? ?? NSDictionary()) as? SearchPresentationExchangeModel
                    print("Req Thread id --- \(requestPresentationMessageModel?.thread?.thid ?? "")" )
                    let connectionModel = cloudAgentSearchConnectionModel?.records?.first
                    var  presentationExchangeWalletModel = PresentationRequestWalletRecordModel.init()
                    presentationExchangeWalletModel.threadID = requestPresentationMessageModel?.thread?.thid ?? ""
                    presentationExchangeWalletModel.connectionID = connectionModel?.value?.requestID
                    presentationExchangeWalletModel.createdAt = AgentWrapper.shared.getCurrentDateTime()
                    presentationExchangeWalletModel.updatedAt = AgentWrapper.shared.getCurrentDateTime()
                    presentationExchangeWalletModel.initiator = "external"
                    presentationExchangeWalletModel.presentationRequest = presentationRequestModel
                    presentationExchangeWalletModel.role = "prover"
                    presentationExchangeWalletModel.state = "request_received"
                    presentationExchangeWalletModel.autoPresent = true
                    presentationExchangeWalletModel.trace = false
                    strongSelf.reqDetail = SearchPresentationExchangeValueModel()
                    strongSelf.reqDetail?.id = requestPresentationMessageModel?.id
                    strongSelf.reqDetail?.type = requestPresentationMessageModel?.type
                    strongSelf.reqDetail?.value = presentationExchangeWalletModel
                    strongSelf.attributelist.removeAll()
                    strongSelf.requestedAttributes.removeAll()
                    strongSelf.selfAttestedAttributes.removeAll()
                    strongSelf.getCredsForProof(forceReqDetail: true) {[weak self] (success) in
                        guard let strongSelf = self else { return}
                        UIApplicationUtils.showLoader()
                        strongSelf.acceptCertificate()
                    }
                }
            }
        }
    }
    //        }
    //    }

    func getCertDetail(recordId: String,completion: @escaping(SearchItems_CustomWalletRecordCertModel?) -> Void) {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates,searchType: .searchWithId, searchValue: recordId) {[weak self] (success, searchHandler, error) in
            guard let strongSelf = self else { return}
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { [weak self](fetched, response, error) in
                guard let strongSelf = self else { return}
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let certSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                // To support old model -- have made new changes in new app -- v 2.2.3 onwards
                if certSearchModel?.totalCount == 0 {
                    WalletRecord.shared.fetchAllCert { recordsModel in
                        let selectedCert = recordsModel?.records?.first(where: { cert in
                            cert.id == recordId
                        })
                        completion(selectedCert)
                    }
                } else {
                    completion(certSearchModel?.records?.first)
                }
            }
        }
    }

    //Saving copy to wallet in order to show in history screen.
    func addHistory() {
        let walletHandler = walletHandle ?? IndyHandle()
        var history = History()
        let attrArray = sharedAttributes?.attr?.map({ e in
            e.value ?? IDCardAttributes.init(name: e.attrName, value: "")
        }) ?? []
        history.attributes = attrArray
        history.dataAgreementModel = new_dataAgreement ?? dataAgreement
        history.dataAgreementModel?.validated = .not_validate
        let dateFormat = DateFormatter.init()
        dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
        history.date = dateFormat.string(from: Date())
        history.connectionModel = connectionModel
        history.type = HistoryType.exchange.rawValue
        history.name = isFromQR ? "\(QRData?.proofRequest?.name ?? "")" : "\(reqDetail?.value?.presentationRequest?.name ?? "")"
        history.threadID = QRData?.threadId ?? reqDetail?.value?.threadID ?? ""
        WalletRecord.shared.add(connectionRecordId: "", walletHandler: walletHandler, type: .dataHistory, historyModel: history) { success, id, error in
            debugPrint("historySaved -- \(success)")
        }
    }

    func modifyPresentationRequestForAttributeGroups(presentntReq: PresentationRequestModel?) -> PresentationRequestModel? {
        var newReqAttributeModel :[String: AdditionalProp] = [:]
        for attr in presentntReq?.requestedAttributes ?? [:] {
            if let names = attr.value.names,names.isNotEmpty {
                for name in names{
                    let newValue = AdditionalProp.init(name: name, names: nil, restrictions: attr.value.restrictions)
                    newReqAttributeModel[name] = newValue
                }
            } else if attr.value.name != nil {
                newReqAttributeModel[attr.key] = attr.value
            }
        }
        var newPresentntReq = presentntReq
        newPresentntReq?.requestedAttributes = newReqAttributeModel
        return newPresentntReq
    }

    func getPresentationRequest() -> PresentationRequestModel? {
        var presentntReq = isFromQR ? self.QRData?.proofRequest : self.reqDetail?.value?.presentationRequest
        ////////// Lissi - to handle attributes group
        presentntReq = self.modifyPresentationRequestForAttributeGroups(presentntReq: presentntReq)
        /////////////////
        return presentntReq
    }
}


//MARK: Models

struct ProofCredentialValue:Codable {
    var credId: String?
    var revealed: Bool?

    enum CodingKeys: String, CodingKey {
        case credId = "cred_id"
        case revealed
    }

    init(){}
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        credId = try? container.decode(String.self, forKey: .credId)

        do{
            revealed = try? container.decode(Bool.self, forKey: .revealed)
        } catch {
            revealed = false
        }
    }
}

struct ProofExchangeAttributes: Codable {
    var name: String?
    var names: [String]?
    var value: String?
    var credDefId: String?
    var referent: String?

    enum CodingKeys: String, CodingKey {
        case credDefId = "cred_def_id"
        case value
        case referent
        case name
    }
}

struct ProofExchangeAttributesArray: Codable {
    var items: [ProofExchangeAttributes]?
}

struct GroupedAttributes {
    var id: String?
    var attr: [SearchedAttribute]?
    var isSeleceted = false
}

struct SearchedAttribute {
    var value: IDCardAttributes?
    var exchangeAttributes: ProofExchangeAttributes?
    var requestCred: [String: ProofCredentialValue]?
    var id: String?
    var attrName: String?
    var presentationRequestParamName: String?
    var isSelfAttestedCert = false
    var certType: CertType?
    var certselfAttestedSubType: SelfAttestedCertTypes?
    var selfAttestedCertModel: CustomWalletRecordCertModel?
}
