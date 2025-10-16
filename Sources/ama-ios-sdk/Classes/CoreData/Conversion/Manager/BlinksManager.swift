//
//  BlinksManager.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 14/10/22.
//

import Foundation
struct BlinksManager {
    
    private let repo: BlinksRepository
    
    init() {
        repo = BlinksRepository()
    }
    
    func createNewMetaModel(model: BlinksModel) {
        repo.createMethod(record: model)
    }
    
    func getMetaModel() -> [BlinksModel]? {
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
