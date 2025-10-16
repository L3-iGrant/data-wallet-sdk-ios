//
//  GenesisManager.swift
//  dataWallet
//
//  Created by sreelekh N on 01/03/22.
//

import Foundation
struct GenesisManager {
    
    private let repo: GenesisRepository
    
    init() {
        repo = GenesisRepository()
    }
    
    func createNewMetaModel(model: GenesisModel) {
        repo.createMethod(record: model)
    }
    
    func getMetaModel() -> [GenesisModel]? {
        let all = repo.getAllData()
        guard all?.isNotEmpty ?? true else {
            return nil
        }
        return all
    }
    
    func deleteAll() {
        repo.deleteAllMetadata()
    }
}
