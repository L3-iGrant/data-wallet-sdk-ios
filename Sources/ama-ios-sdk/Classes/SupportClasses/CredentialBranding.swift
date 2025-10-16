//
//  File.swift
//  ama-ios-sdk
//
//  Created by iGrant on 10/10/25.
//

import Foundation

class CredentialBranding {
    
    func getVerificationOrIssuanceTitleNameForMySharedData(history: History?) -> String? {
        var titleName: String? = nil
        guard let history = history else { return nil}
        if history.type == HistoryType.exchange.rawValue {
            var name: String = history.name?.uppercased() ?? ""
            if isMultipleInputDescriptors(history: history) ?? false {
                if let text = getNameFromPresentationDefinition(history: history), !text.isEmpty {
                    name = text.uppercased()
                } else {
                    name = "Requested Credential".localize
                }
            } else {
                if let text = getNameFromPresentationDefinition(history: history), !text.isEmpty {
                    name = text.uppercased()
                } else if let text = getNameAndIdFromInputDescriptor(index: 0, history: history).0,  !text.isEmpty {
                    name = text.uppercased()
                } else if let text = history.display?.name, !text.isEmpty {
                    name = text
                } else if let text = history.certSubType, !text.isEmpty {
                    name = text
                }
            }
            titleName = name
        } else {
            titleName =  history.name ?? ""
            if history.name == CertType.EBSI.rawValue {
                var subType = history.certSubType
                switch history.certSubType ?? "" {
                case EBSI_CredentialType.Diploma.rawValue:
                    subType = EBSI_CredentialSearchText.Diploma.rawValue
                case EBSI_CredentialType.StudentID.rawValue:
                    subType = EBSI_CredentialSearchText.StudentID.rawValue
                case EBSI_CredentialType.VerifiableID.rawValue:
                    subType = EBSI_CredentialSearchText.VerifiableID.rawValue
                case EBSI_CredentialType.PDA1.rawValue:
                    subType = EBSI_CredentialSearchText.PDA1.rawValue
                default: break
                }
                titleName = (subType?.replacingOccurrences(of: "-", with: " "))?.uppercased() ?? history.certSubType ?? ""
            } else {
                titleName = history.name ?? history.certSubType ?? ""
            }
        }
        return titleName
    }
    
    func isMultipleInputDescriptors(history: History?) -> Bool? {
        guard let data = history else { return false }
        switch data.presentationDefinition {
        case .presentationDefinition(let pd):
            return pd.inputDescriptors?.count ?? 0 > 1
        case .dcqlQuery(let dcql):
            return dcql.credentials.count > 1
        case .none:
            return false
        }
        
    }
    
    func getNameFromPresentationDefinition(history: History?) -> String? {
        var title: String?
        guard let data = history?.presentationDefinition else { return nil }
        switch data {
        case .presentationDefinition(let model):
            title = model.name
        case .dcqlQuery(let dcqlModel):
            title = nil
        }
        return title
    }
    
    func getNameAndIdFromInputDescriptor(index: Int, history: History?) -> (String?, String?) {
        var title: String?
        var id: String?
        guard let data = history?.presentationDefinition else { return (nil, nil) }
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
}
