//
//  MetaDataManager.swift
//  dataWallet
//
//  Created by sreelekh N on 01/03/22.
//

import Foundation
struct MetaDataManager {
    
    private let repo: MetaDataRepository
    
    init() {
        repo = MetaDataRepository()
    }
    
    func createNewMetaModel(model: MetaDataModel) {
        repo.deleteAllMetadata()
        repo.createMethod(record: model)
    }
    
    func getMetaModel() -> MetaDataModel? {
        let all = repo.getAllData()
        guard all?.isNotEmpty ?? true else {
            return nil
        }
        return all?.first
    }
    
    func deleteAll() {
        repo.deleteAllMetadata()
    }
}
