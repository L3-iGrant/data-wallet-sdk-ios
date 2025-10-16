//
//  BlinksRepository.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 14/10/22.
//

import Foundation
import CoreData

protocol BlinksProtocol: UpdatesProtocol {}

struct BlinksRepository: BlinksProtocol {
    
    typealias T = BlinksModel
    let defaults = UserDefaults.standard
    let defaultKey = "Blinks"
    func createMethod(record: BlinksModel) {
//        let genesis = BlinksMetaData(context: PersistentStorage.shared.context)
//        genesis.prefix = record.prefix
//        genesis.url = record.url
//        genesis.infraProviders = record.infraProviders
//        PersistentStorage.shared.saveContext()
        var records = getAllData()
        records?.append(record)
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(records) else {
            return
        }
        defaults.set(jsonData, forKey: defaultKey)

    }
    
    func getAllData() -> [BlinksModel]? {
        if let results = defaults.data(forKey: defaultKey) {
            // Decode the Data object back to an array of Person objects.
            let decoder = JSONDecoder()
            if let results = try? decoder.decode([BlinksModel].self, from: results) {
                return results // prints "[Person(name: "John", age: 25), Person(name: "Mary", age: 30)]"
            }
        }
        return []
    }
    
    func getById(id: String) -> BlinksModel? {
        let person = getBlinksMetaDataModel(byPrefix: id)
        guard person != nil else {
            return nil
        }
        return person
    }
    
    func update(record: BlinksModel) -> Bool {
        var model = getBlinksMetaDataModel(byPrefix: record.prefix)
        guard model != nil else {
            return false
        }
        model?.prefix = record.prefix
        model?.url = record.url
        model?.infraProviders = record.infraProviders
        PersistentStorage.shared.saveContext()
        return true
    }
    
    func deleteByIdentifier(id: String) -> Bool {
        var results = getAllData()
        results?.removeAll(where: { e in
            e.prefix == id
        })
        return true
    }
    
    private func getBlinksMetaDataModel(byPrefix prefix: String) -> BlinksModel? {
//        let fetchRequest = NSFetchRequest<BlinksMetaData>(entityName: "BlinksMetaData")
//        let fetchById = NSPredicate(format: "prefix==%@", prefix as CVarArg)
//        fetchRequest.predicate = fetchById
//        let result = try! PersistentStorage.shared.context.fetch(fetchRequest)
//        guard result.isNotEmpty else {
//            return nil
//        }
//        return result.first
        
        let results = getAllData()?.first(where: { e in
            e.prefix == prefix
        })
        return results
    }
    
    func deleteAllMetadata() {
        
    }
}
