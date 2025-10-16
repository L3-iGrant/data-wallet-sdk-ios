//
//  BoardingManager.swift
//  dataWallet
//
//  Created by sreelekh N on 01/03/22.
//

import Foundation
struct BoardingManager {
    
    private let repo: BoardingRepository
    
    init() {
        repo = BoardingRepository()
    }
    
    func createNewMetaModel(model: BoardingMetaDataModel) {
        repo.deleteAllMetadata()
        repo.createMethod(record: model)
    }
    
    func getMetaModel() -> BoardingMetaDataModel? {
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
