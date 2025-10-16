//
//  PaymentAdditionalDataRequestBottomSheetViewModel.swift
//  dataWallet
//
//  Created by iGrant on 07/05/25.
//

import Foundation
import eudiWalletOidcIos

class PaymentAdditionalDataRequestBottomSheetViewModel {
    
    var EBSI_credentials: [[SearchItems_CustomWalletRecordCertModel]]?
    
    func populateModelForEBSI(forPassportExchange: Bool = false, presentationDefinition: String?, dcql: DCQLQuery?, isLimitedDisclosure: Bool? = false, credentialsDict: [String: Any]? = nil, completionBlock: ((Bool) -> ())? = nil) {
        Task {
                
            var queryItem: Any?
            if let dcql = dcql {
                queryItem = dcql
            } else if presentationDefinition != "" {
                let jsonData = presentationDefinition?.replacingOccurrences(of: "+", with: " ").data(using: .utf8)
                let presentationDefinitionModel = try? JSONDecoder().decode(eudiWalletOidcIos.PresentationDefinitionModel.self, from: jsonData ?? Data())
                queryItem = presentationDefinitionModel
            }
            EBSI_credentials = getUpdatedDataWithPresentationDefinition(model: EBSIWallet.shared.exchangeDataRecordsdModel, queryItem: queryItem)
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
            let newItem = SearchItems_CustomWalletRecordCertModel(type: model?.type, id: model?.id, value:MDOCParser.shared.getMDOCCredentialWalletRecord(connectionModel: EBSIWallet.shared.connectionModel, credential_cbor: base64StringWithoutPadding, format: "mso_mdoc", credentialType: model?.value?.searchableText))
            return newItem
    }
    
    func getUpdatedDataWithPresentationDefinition(model: [[SearchItems_CustomWalletRecordCertModel]]?, queryItem: Any?) -> [[SearchItems_CustomWalletRecordCertModel]]? {
        var updatedRecords = [[SearchItems_CustomWalletRecordCertModel]]()
        guard let recordsData = model else { return nil}
        for (index,data) in recordsData.enumerated() {
            var records = [SearchItems_CustomWalletRecordCertModel]()
            
            for item in data {
                var credentialFormat: String = ""
                if let pd = queryItem as? PresentationDefinitionModel {
                    if let format = pd.inputDescriptors?[index].format ?? pd.format {
                        for (key, _) in format {
                            credentialFormat = key
                        }
                    }
                } else if let dcql = queryItem as? DCQLQuery {
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
            
            let newItem = SearchItems_CustomWalletRecordCertModel(type: model?.type, id: model?.id, value:EBSIWallet.shared.updateCredentialWithJWT(jwt:updatedJwt ?? "", searchableText: displayText ?? ""))
            newItem.value?.cover = model?.value?.cover
            newItem.value?.backgroundColor = model?.value?.backgroundColor
            return newItem
    }
    
}
