//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 20/08/25.
//

import Foundation
import eudiWalletOidcIos
import SwiftCBOR
import OrderedCollections
import IndyCWrapper

//extension ExchangeDataPreviewViewModel {
//        
//    func populateModelForEBSI(forPassportExchange: Bool = false, presentationDefinition: PresentationDefinitionModel?, isLimitedDisclosure: Bool? = false, credentialsDict: [String: Any]? = nil,dcql: DCQLQuery? = nil, completionBlock: ((Bool) -> ())? = nil) {
//        Task {
//            
//                
//                //let model = Search_CustomWalletRecordCertModel.init(totalCount: EBSIWallet.shared.exchangeDataRecordsdModel.count, records: EBSIWallet.shared.exchangeDataRecordsdModel)
//            EBSI_credentialsData = getUpdatedDataWithPresentationDefinition(model: EBSIWallet.shared.exchangeDataRecordsdModel, presentationDefinition: presentationDefinition, dcql: dcql)
//                delegate?.refresh()
//                delegate?.showAllViews()
//                completionBlock?(true)
//        }
//    }
//   
//    
//    func getUpdatedDataWithPresentationDefinition(model: [[SearchItems_CustomWalletRecordCertModel]]?, presentationDefinition: PresentationDefinitionModel?, dcql: DCQLQuery?) -> [[SearchItems_CustomWalletRecordCertModel]]? {
//        var updatedRecords = [[SearchItems_CustomWalletRecordCertModel]]()
//        guard let recordsData = model else { return nil}
//        for (index,data) in recordsData.enumerated() {
//            var records = [SearchItems_CustomWalletRecordCertModel]()
//            for item in data {
//                var queryItem: Any?
//                var credentialFormat: String = ""
//                if let presentationDefinition = presentationDefinition {
//                    queryItem = presentationDefinition
//                    //Need to check for the format
//                    if presentationDefinition.inputDescriptors?.count ?? 0 > 1 {
//                        if let format = presentationDefinition.inputDescriptors?[index].format ?? presentationDefinition.format {
//                            for (key, _) in format {
//                                credentialFormat = key
//                            }
//                        }
//                    } else {
//                        if let format = presentationDefinition.inputDescriptors?.first?.format ?? presentationDefinition.format {
//                            for (key, _) in format {
//                                credentialFormat = key
//                            }
//                        }
//                    }
//                } else if let dcql = dcql {
//                    queryItem = dcql
//                    let format = dcql.credentials[index].format
//                    credentialFormat = format
//                }
//               
//                
//                if item.value?.vct == nil &&  item.value?.subType != "passport" {
//                    records.append(item)
//                } else {
//                    guard let recordValue = updateJwtWithPresentationDefinition2(model: item, queryItem: queryItem, index: index) else { return nil}
//                    records.append(recordValue)
//                }
//            }
//            updatedRecords.append(records)
//        }
//        return updatedRecords
//    }
//    
//    func updateJwtWithPresentationDefinition2(model: SearchItems_CustomWalletRecordCertModel?, queryItem: Any?, index: Int) -> SearchItems_CustomWalletRecordCertModel? {
//        var queryData: Any?
//        var credentialFormat: String = ""
//        var displayText: String? = ""
//        if let presentationDefinition = queryItem as? PresentationDefinitionModel {
//            if presentationDefinition.inputDescriptors?.count ?? 0 > 1 {
//                queryData = presentationDefinition.inputDescriptors?[index]
//            } else {
//                queryData = presentationDefinition.inputDescriptors?.first
//            }
//            var queryFormat: [String: Any]? = [:]
//            let data = queryData as? InputDescriptor
//            queryFormat = (data?.format ?? [:]) as [String : Any]
//            if let format = presentationDefinition.format ?? queryFormat {
//                for (key, _) in format {
//                    credentialFormat = key
//                }
//            }
//            
//            if let text = data?.name, !text.isEmpty {
//                displayText = text
//            } else if let text = model?.value?.searchableText, !text.isEmpty {
//                displayText = text
//            }
//        } else if let dcql = queryItem as? DCQLQuery {
//            queryData = dcql.credentials[index]
//            if let credentialData = queryData as? CredentialItems {
//                credentialFormat = credentialData.format
//                if let text = model?.value?.searchableText, !text.isEmpty {
//                    displayText = text
//                }
//            }
//        }
//        
//        let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyHandlerKeyID)
//        let updatedJwt = eudiWalletOidcIos.SDJWTService.shared.processDisclosures(credential: model?.value?.EBSI_v2?.credentialJWT, query: queryData, format: credentialFormat, keyHandler: keyHandler)
//        
//        
//       // eudiWalletOidcIos.SDJWTService.shared.processDisclosuresWithPresentationDefinition(credential: model?.value?.EBSI_v2?.credentialJWT, inputDescriptor: inputDescriptor, format: credentialFormat, keyHandler: keyHandler)
//            
//            let newItem = SearchItems_CustomWalletRecordCertModel(type: model?.type, id: model?.id, value: EBSIWallet.shared.updateCredentialWithJWT(jwt:updatedJwt ?? "", searchableText: displayText ?? ""))
//            return newItem
//    }
//    
//    
//    //Saving copy to wallet in order to show in history screen.
//    func addHistoryToEBSI(jwtList: [String] = [], presentationDefinition: PresentationDefinitionModel? = nil, clientMetaData: String = "", isValidOrganization: Bool? = false, credentials: Search_CustomWalletRecordCertModel? = nil, queryItem: Any? = nil) {
//        //        if let search_cert_model = EBSI_credentials?.records?[safe: selectedCardIndex], let cert = search_cert_model.value {
//        let search_cert_model = EBSI_credentialsData?.first?[safe: selectedCardIndex]?.value
//        let jsonDecoder = JSONDecoder()
//        
////        let organisationDetails = EBSIWallet.shared.openIdIssuerResponseData
////        display = EBSIWallet.shared.getDisplayFromIssuerConfig(config: organisationDetails)
//        let clientMetadataJson = clientMetaData.data(using: .utf8)!
//        let clientMetaDataModel = try? JSONDecoder().decode(ClientMetaData.self, from: clientMetadataJson)
//        let display = EBSIWallet.shared.convertClientMetaDataToDisplay(clientMetaData: clientMetaDataModel)
//        connectionModel?.value?.orgDetails?.isValidOrganization = isValidOrganization
//        connectionModel?.value?.orgDetails?.x5c = EBSIWallet.shared.presentationRequestJwt
//        Task {
//            let walletHandler = walletHandle ?? IndyHandle()
//            var history = History()
//            history.JWT = ""
//            history.attributes = []
//            history.dataAgreementModel = dataAgreement == nil ? nil : dataAgreement
//            history.dataAgreementModel?.validated = .not_validate
//            let dateFormat = DateFormatter.init()
//            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
//            dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
//            history.date = dateFormat.string(from: Date())
//            history.connectionModel = connectionModel
//            history.type = HistoryType.exchange.rawValue
//            history.name = CertType.EBSI.rawValue
//            history.credentials = credentials
//            if isMultipleInputDescriptors(queryItem: queryItem) ?? false {
//                if search_cert_model?.subType == EBSI_CredentialType.PDA1.rawValue {
//                    history.certSubType = search_cert_model?.subType
//                } else {
//                    history.certSubType = presentationDefinition?.id
//                }
//            } else {
//                history.certSubType = search_cert_model?.subType == "" ? search_cert_model?.searchableText : search_cert_model?.subType
//            }
//            history.JWTList = jwtList
//            history.threadID = ""
//            if let pd = queryItem as? PresentationDefinitionModel {
//                history.presentationDefinition = .presentationDefinition(pd)
//            } else if let dcql = queryItem as? DCQLQuery {
//                history.presentationDefinition = .dcqlQuery(dcql)
//            }
//            
//            if history.display == nil {
//                history.display = CredentialDisplay(name: nil, location: nil, locale: nil, description: nil, cover: nil, logo: nil, backgroundColor: nil, textColor: nil)
//            }
//            history.display?.name = search_cert_model?.searchableText
//            do {
//                let jsonData = try JSONEncoder().encode(history)
//                let stringData = String(data: jsonData, encoding: .utf8)
//                print("historyJsonData: \(stringData ?? "")")
//            } catch {
//                print("error")
//            }
//            WalletRecord.shared.add(connectionRecordId: "", walletHandler: walletHandler, type: .dataHistory, historyModel: history) { [weak self] success, id, error in
//                debugPrint("historySaved -- \(success)")
//                guard let strongSelf = self else { return}
//                strongSelf.delegate?.goBack()
//                UIApplicationUtils.hideLoader()
//                if !EBSIWallet.shared.isDynamicCredentialRequest {
//                    UIApplicationUtils.showSuccessSnackbar(message: "data_data_has_been_shared_successfully".localizedForSDK())
//                }
//            }
//        }
////        connectionModel?.value?.orgDetails?.name = display.name ?? ""
////        connectionModel?.value?.orgDetails?.location = display.location ?? ""
////        connectionModel?.value?.orgDetails?.logoImageURL = display.logo?.url ?? ""
////        connectionModel?.value?.orgDetails?.coverImageURL = display.cover?.url ?? ""
////        connectionModel?.value?.orgDetails?.organisationInfoModelDescription = display.description ?? ""
////        connectionModel?.value?.orgDetails?.orgId = EBSIWallet.shared.exchangeClientID
//        
//        
//        
//    }
//    
//    func isMultipleInputDescriptors(queryItem: Any?) -> Bool? {
//        guard let data = queryItem else { return false }
//        if let pd = queryItem as? PresentationDefinitionModel {
//            return pd.inputDescriptors?.count ?? 0 > 1
//        } else if let dcql = queryItem as? DCQLQuery {
//            return dcql.credentials.count > 1
//        } else {
//            return false
//        }
//    }
////    }
//}


extension ExchangeDataPreviewViewModel {
        
    func prepareDataForCredentialSet(presentationDefinition: PresentationDefinitionModel?, dcql: DCQLQuery? = nil) {
        if let presentationDefinition = presentationDefinition {
            EBSI_credentialsForSession = EBSI_credentials
        } else if let dcql = dcql {
            //prepare session list
            if let credentialSets = dcql.credentialSets, !credentialSets.isEmpty {
                sessionList = transformCredentialSets(input: EBSI_credentials, dcql: dcql)
                EBSI_credentialsForSession = buildEbsiCredentialForSession(sessionItems: sessionList, targetIndex: 0, dcqlQuery: dcql, inputMatrix: EBSI_credentials)
                print(EBSI_credentialsForSession ?? [])
            } else {
                EBSI_credentialsForSession = EBSI_credentials
            }
        }
    }
    
    func transformCredentialSets(
        input: [[SearchItems_CustomWalletRecordCertModel]]?,
        dcql: DCQLQuery?
    ) -> [SessionItem] {
        var result: [SessionItem] = []
        var mandatorySingleOptionList: [String] = []
        var mandatorySingleIndexList: [Int] = []
        guard let dcql = dcql else { return [] }
        guard let input = input else { return [] }

        // Helper: check if all ids in group are valid and non-empty
        func filterGroup(_ ids: [String]) -> ([String]?, [Int] )? {
            var valid: [String] = []
            var indexList: [Int] = []
            for id in ids {
                if let index = dcql.credentials.firstIndex(where: { $0.id == id }),
                   input.indices.contains(index),
                   !input[index].isEmpty {
                    valid.append(id)
                    indexList.append(index)
                } else {
                    // one missing → whole group invalid
                    return nil
                }
            }
            return (valid, indexList)
        }

        // Rule 1: Collect all mandatory single-option credentials
        for set in dcql.credentialSets ?? [] {
            let required = set.required ?? true
            if required, set.options.count == 1 {
                if let filtered = filterGroup(set.options[0]) {
                    mandatorySingleOptionList.append(contentsOf: filtered.0 ?? [])
                    mandatorySingleIndexList.append(contentsOf: filtered.1)
                    
                }
            }
        }
        if !mandatorySingleOptionList.isEmpty {
            result.append(
                SessionItem(
                    credentialIdList: mandatorySingleOptionList,
                    type: "MandatoryWithSingleOption",
                    checkedItem: Array(mandatorySingleOptionList.indices)                )
            )
        }

        // Rules 2, 3, 4
        for set in dcql.credentialSets ?? [] {
            let required = set.required ?? true
            var aggregated: [String] = []   // collect valid groups for this set

            for option in set.options {
                if let filtered = filterGroup(option) {
                    aggregated.append(contentsOf: filtered.0 ?? [])
                }
            }

            if !aggregated.isEmpty {
                let type: String
                switch (required, set.options.count) {
                case (true, let count) where count > 1:
                    type = "MandatoryWithOROption"
                case (false, let count) where count > 1:
                    type = "OptionalWithOrOption"
                case (false, 1):
                    type = "OptionalWithSingleItem"
                default:
                    continue
                }

                let filteredOptions = set.options.filter { option in
                    // keep the option only if *all* ids in option are inside aggregated
                    option.allSatisfy { aggregated.contains($0) }
                }

                if !filteredOptions.isEmpty {
                    result.append(
                        SessionItem(
                            credentialIdList: aggregated,
                            type: type,
                            options: filteredOptions
                        )
                    )
                }
            }
        }

        return result
    }

    public func buildEbsiCredentialForSession(
        sessionItems: [SessionItem],
        targetIndex: Int,
        dcqlQuery: DCQLQuery,
        inputMatrix: [[SearchItems_CustomWalletRecordCertModel]]?
    ) -> [[SearchItems_CustomWalletRecordCertModel]]? {
        guard let inputMatrix = inputMatrix else {
                return nil
            }
        var output: [[SearchItems_CustomWalletRecordCertModel]] = []

        guard targetIndex < sessionItems.count else { return output }

        let sessionItem = sessionItems[targetIndex]

        for credId in sessionItem.credentialIdList {
            if let index = dcqlQuery.credentials.firstIndex(where: { $0.id == credId }),
               index < inputMatrix.count {
                output.append(inputMatrix[index])
            }
        }

        return output
    }
    
    func populateModelForEBSI(forPassportExchange: Bool = false, presentationDefinition: PresentationDefinitionModel?, isLimitedDisclosure: Bool? = false, credentialsDict: [String: Any]? = nil,dcql: DCQLQuery? = nil, completionBlock: ((Bool) -> ())? = nil) {
        Task {
            
                
                //let model = Search_CustomWalletRecordCertModel.init(totalCount: EBSIWallet.shared.exchangeDataRecordsdModel.count, records: EBSIWallet.shared.exchangeDataRecordsdModel)
            EBSI_credentials = getUpdatedDataWithPresentationDefinition(model: EBSIWallet.shared.exchangeDataRecordsdModel, presentationDefinition: presentationDefinition, dcql: dcql)
            prepareDataForCredentialSet(presentationDefinition: presentationDefinition, dcql: dcql)
            delegate?.refresh()
            delegate?.showAllViews()
            completionBlock?(true)
        }
    }
    
    // This function will update the cbor with selective disclosure and return the updated cbor
    
    func updateCborWithPresentationDefinition2(model: SearchItems_CustomWalletRecordCertModel?, queryItem: Any?, index: Int) -> SearchItems_CustomWalletRecordCertModel? {
        let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
        let verificationHandler = eudiWalletOidcIos.VerificationService(keyhandler: keyHandler)
        var newModel = Search_CustomWalletRecordCertModel()
        var records = [SearchItems_CustomWalletRecordCertModel]()
        var queryItem: Any?
        if let pd = queryItem as? PresentationDefinitionModel {
        if pd.inputDescriptors?.count ?? 0 > 1 {
            queryItem = pd.inputDescriptors?[index]
            } else {
                queryItem = pd.inputDescriptors?.first
            }
        } else if let dcql = queryItem as? DCQLQuery {
            queryItem = dcql.credentials[index]
        }
                let updatedCBOR =
        verificationHandler.getFilteredCbor(credential: model?.value?.EBSI_v2?.credentialJWT ?? "", query: queryItem)
                let cborString = Data(updatedCBOR.encode()).base64EncodedString()

            var base64StringWithoutPadding = cborString.replacingOccurrences(of: "=", with: "")
            base64StringWithoutPadding = base64StringWithoutPadding.replacingOccurrences(of: "+", with: "-")
            base64StringWithoutPadding = base64StringWithoutPadding.replacingOccurrences(of: "/", with: "_")
        let newItem = SearchItems_CustomWalletRecordCertModel(type: model?.type, id: model?.id, value:MDOCParser.shared.getMDOCCredentialWalletRecord(connectionModel: EBSIWallet.shared.connectionModel, credential_cbor: base64StringWithoutPadding, format: "mso_mdoc", credentialType: model?.value?.searchableText, addedDate: model?.value?.addedDate ?? ""))
            return newItem
    }
    
    func getUpdatedDataWithPresentationDefinition(model: [[SearchItems_CustomWalletRecordCertModel]]?, presentationDefinition: PresentationDefinitionModel?, dcql: DCQLQuery?) -> [[SearchItems_CustomWalletRecordCertModel]]? {
        var updatedRecords = [[SearchItems_CustomWalletRecordCertModel]]()
        guard let recordsData = model else { return nil}
        for (index,data) in recordsData.enumerated() {
            var records = [SearchItems_CustomWalletRecordCertModel]()
            for item in data {
                var queryItem: Any?
                var credentialFormat: String = ""
                if let presentationDefinition = presentationDefinition {
                    queryItem = presentationDefinition
                    //Need to check for the format
                    if presentationDefinition.inputDescriptors?.count ?? 0 > 1 {
                        if let format = presentationDefinition.inputDescriptors?[index].format ?? presentationDefinition.format {
                            for (key, _) in format {
                                credentialFormat = key
                            }
                        }
                    } else {
                        if let format = presentationDefinition.inputDescriptors?.first?.format ?? presentationDefinition.format {
                            for (key, _) in format {
                                credentialFormat = key
                            }
                        }
                    }
                } else if let dcql = dcql {
                    queryItem = dcql
                    let format = dcql.credentials[index].format
                    credentialFormat = format
                }
               
                
                if credentialFormat == "mso_mdoc" {
                    guard let recordValue = updateCborWithPresentationDefinition2(model: item, queryItem: queryItem, index: index) else { return nil}
                    records.append(recordValue)
                } else if item.value?.vct == nil &&  item.value?.subType != "passport" {
                    records.append(item)
                } else {
                    guard let recordValue = updateJwtWithPresentationDefinition2(model: item, queryItem: queryItem, index: index) else { return nil}
                    records.append(recordValue)
                }
            }
            updatedRecords.append(records)
        }
        return updatedRecords
    }
    
    func updateJwtWithPresentationDefinition2(model: SearchItems_CustomWalletRecordCertModel?, queryItem: Any?, index: Int) -> SearchItems_CustomWalletRecordCertModel? {
        var queryData: Any?
        var credentialFormat: String = ""
        var displayText: String? = ""
        if let presentationDefinition = queryItem as? PresentationDefinitionModel {
            if presentationDefinition.inputDescriptors?.count ?? 0 > 1 {
                queryData = presentationDefinition.inputDescriptors?[index]
            } else {
                queryData = presentationDefinition.inputDescriptors?.first
            }
            var queryFormat: [String: Any]? = [:]
            let data = queryData as? InputDescriptor
            queryFormat = (data?.format ?? [:]) as [String : Any]
            if let format = presentationDefinition.format ?? queryFormat {
                for (key, _) in format {
                    credentialFormat = key
                }
            }
            
            if let text = data?.name, !text.isEmpty {
                displayText = text
            } else if let text = model?.value?.searchableText, !text.isEmpty {
                displayText = text
            }
        } else if let dcql = queryItem as? DCQLQuery {
            queryData = dcql.credentials[index]
            if let credentialData = queryData as? CredentialItems {
                credentialFormat = credentialData.format
                if let text = model?.value?.searchableText, !text.isEmpty {
                    displayText = text
                }
            }
        }
        
        let keyHandler = SecureEnclaveHandler(keyID: EBSIWallet.shared.keyIDforWUA)
        let updatedJwt = eudiWalletOidcIos.SDJWTService.shared.processDisclosures(credential: model?.value?.EBSI_v2?.credentialJWT, query: queryData, format: credentialFormat, keyHandler: keyHandler)
            let newItem = SearchItems_CustomWalletRecordCertModel(type: model?.type, id: model?.id, value:EBSIWallet.shared.updateCredentialWithJWT(jwt:updatedJwt ?? "", searchableText: displayText ?? "", addedDate: model?.value?.addedDate ?? ""))
            return newItem
    }
    
    //Saving copy to wallet in order to show in history screen.
    func addHistoryToEBSI(jwtList: [String] = [], presentationDefinition: PresentationDefinitionModel? = nil, clientMetaData: String = "", isValidOrganization: Bool? = false, credentials: Search_CustomWalletRecordCertModel? = nil, queryItem: Any? = nil) {
        //        if let search_cert_model = EBSI_credentials?.records?[safe: selectedCardIndex], let cert = search_cert_model.value {
        let search_cert_model = EBSI_credentials?.first?[safe: selectedCardIndex]?.value
        let jsonDecoder = JSONDecoder()
        
//        let organisationDetails = EBSIWallet.shared.openIdIssuerResponseData
//        display = EBSIWallet.shared.getDisplayFromIssuerConfig(config: organisationDetails)
        let clientMetadataJson = clientMetaData.data(using: .utf8)!
        let clientMetaDataModel = try? JSONDecoder().decode(ClientMetaData.self, from: clientMetadataJson)
        let display = EBSIWallet.shared.convertClientMetaDataToDisplay(clientMetaData: clientMetaDataModel)
        connectionModel?.value?.orgDetails?.isValidOrganization = isValidOrganization
        connectionModel?.value?.orgDetails?.x5c = EBSIWallet.shared.presentationRequestJwt
        Task {
            let walletHandler = walletHandle ?? IndyHandle()
            var history = History()
            history.JWT = ""
            history.attributes = []
            history.dataAgreementModel = dataAgreement == nil ? nil : dataAgreement
            history.dataAgreementModel?.validated = .not_validate
            let dateFormat = DateFormatter.init()
            dateFormat.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSS'Z'"
            dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
            history.date = dateFormat.string(from: Date())
            history.connectionModel = connectionModel
            history.type = HistoryType.exchange.rawValue
            history.name = CertType.EBSI.rawValue
            history.credentials = credentials
            if isMultipleInputDescriptors(queryItem: queryItem) ?? false {
                if search_cert_model?.subType == EBSI_CredentialType.PDA1.rawValue || search_cert_model?.subType == EBSI_CredentialType.PWA.rawValue{
                    history.certSubType = search_cert_model?.subType
                } else {
                    history.certSubType = presentationDefinition?.id
                }
            } else {
                history.certSubType = search_cert_model?.subType == "" ? search_cert_model?.searchableText : search_cert_model?.subType
            }
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
                strongSelf.delegate?.goBack()
                UIApplicationUtils.hideLoader()
                if !EBSIWallet.shared.isDynamicCredentialRequest {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                UIApplicationUtils.showSuccessSnackbar(message: "Data has been shared successfully".localizedForSDK())
                            }
                }
            }
        }
//        connectionModel?.value?.orgDetails?.name = display.name ?? ""
//        connectionModel?.value?.orgDetails?.location = display.location ?? ""
//        connectionModel?.value?.orgDetails?.logoImageURL = display.logo?.url ?? ""
//        connectionModel?.value?.orgDetails?.coverImageURL = display.cover?.url ?? ""
//        connectionModel?.value?.orgDetails?.organisationInfoModelDescription = display.description ?? ""
//        connectionModel?.value?.orgDetails?.orgId = EBSIWallet.shared.exchangeClientID
        
        
        
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
//    }
}
