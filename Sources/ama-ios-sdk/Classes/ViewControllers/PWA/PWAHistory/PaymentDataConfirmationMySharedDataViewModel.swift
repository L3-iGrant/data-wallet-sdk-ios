//
//  PaymentDataConfirmationMySharedDataViewModel.swift
//  dataWallet
//
//  Created by iGrant on 11/12/24.
//

import Foundation

class PaymentDataConfirmationMySharedDataViewModel {
    
    var history: HistoryRecordValue?
    
    init(history: HistoryRecordValue? = nil) {
        self.history = history
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
    
}
