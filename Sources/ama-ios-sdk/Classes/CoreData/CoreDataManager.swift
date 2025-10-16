//
//  CoreDataUtils.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 21/01/22.
//

import Foundation
final class CoreDataManager {
    
    let metadataManager: MetaDataManager
    let boardingManager: BoardingManager
    let genesisManager: GenesisManager
    let blinkManager: BlinksManager
    let myDataProfileManager: MyDataProfileDataManager
    
    init() {
        metadataManager = MetaDataManager()
        boardingManager = BoardingManager()
        genesisManager = GenesisManager()
        blinkManager = BlinksManager()
        myDataProfileManager = MyDataProfileDataManager()
    }
    
    func addGenesis(model: [GenesisModel], completion: @escaping (() -> Void)) {
        genesisManager.deleteAll()
        for model in model {
            genesisManager.createNewMetaModel(model: model)
        }
        completion()
    }
    
    private func deleteAllGenesis(completion: @escaping (() -> Void)){
        genesisManager.deleteAll()
        completion()
    }
    
    func getAllGenesis() -> [GenesisModel]? {
        genesisManager.getMetaModel()
    }
    
    func getCurrentGenesis() -> GenesisModel? {
        let ledgerIndex = UserDefaults.standard.value(forKey: Constants.userDefault_ledger) as? Int ?? 0
        let genesisList = getAllGenesis()
        return genesisList?.first(where: { model in
            model.id == ledgerIndex
        })
    }
}

extension CoreDataManager {
    
    func addPKPassBoardingPassMetadata(data: Data, completion: @escaping (() -> Void)) {
        let model = BoardingMetaDataModel(data: data)
        boardingManager.createNewMetaModel(model: model)
        completion()
    }
    
    private func deleteAllPKPassBoardingPassMetadata( completion: @escaping (()->Void)){
        boardingManager.deleteAll()
        completion()
    }
    
    func getPKPassMetaData() -> [String: [String]]? {
        guard let data = boardingManager.getMetaModel() else {
            return nil
        }
        let dict = try? JSONDecoder().decode([String: [String]].self, from: data.data)
        return dict
    }
}

extension CoreDataManager {
    
    func addDataWalletLastUpdate(data: MetaDataModel, completion: @escaping (() -> Void)) {
        metadataManager.createNewMetaModel(model: data)
        completion()
    }
    
    func deletelastUpdatedMetadata(completion: @escaping (() -> Void)){
        metadataManager.deleteAll()
        completion()
    }
    
    func getlastUpdatedMetaData() -> MetaDataModel? {
        let meta = metadataManager.getMetaModel()
        return meta
    }
}

extension CoreDataManager {
    
    func addBlinks(model: [BlinksModel], completion: @escaping (() -> Void)) {
        blinkManager.deleteAll()
        for model in model {
            blinkManager.createNewMetaModel(model: model)
        }
        completion()
    }
    
    private func deleteAllBlinks(completion: @escaping (() -> Void)){
        blinkManager.deleteAll()
        completion()
    }
    
    func getAllBlinks() -> [BlinksModel]? {
        blinkManager.getMetaModel()
    }
    
    func getBlinksFromPrefix(prefix:String) -> BlinksModel? {
        let blinksList = getAllBlinks()
        return blinksList?.first(where: { model in
            model.prefix == prefix
        })
    }
}

extension CoreDataManager {
    
    func addMyDataProfile(model: MyDataProfileMetaDataModel, completion: @escaping (() -> Void)) {
        myDataProfileManager.deleteAll()
        myDataProfileManager.createNewMetaModel(model: model)
        completion()
    }
    
    private func deleteMyDataProfile(completion: @escaping (() -> Void)){
        myDataProfileManager.deleteAll()
        completion()
    }
    
    func getMyDataProfile() -> [MyDataProfileMetaDataModel]? {
        myDataProfileManager.getMetaModel()
    }
    
}
