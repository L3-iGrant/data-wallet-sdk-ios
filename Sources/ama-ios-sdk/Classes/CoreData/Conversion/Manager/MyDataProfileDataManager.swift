//
//  MyDataProfileDataManager.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 22/12/22.
//

import Foundation
struct MyDataProfileDataManager {
    
    private let repo: MyDataProfileMetadataRepository
    
    init() {
        repo = MyDataProfileMetadataRepository()
    }
    
    func createNewMetaModel(model: MyDataProfileMetaDataModel) {
        repo.createMethod(record: model)
    }
    
    func getMetaModel() -> [MyDataProfileMetaDataModel]? {
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
