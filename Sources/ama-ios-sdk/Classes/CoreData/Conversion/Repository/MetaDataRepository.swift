//
//  MetaDataRepository.swift
//  dataWallet
//
//  Created by sreelekh N on 01/03/22.
//

import Foundation
import CoreData

protocol MetaDataProtocol: UpdatesProtocol {}

struct MetaDataRepository: MetaDataProtocol {
    
    typealias T = MetaDataModel
    let defaults = UserDefaults.standard
    let defaultKey = "Metadata"
    func createMethod(record: MetaDataModel) {
        var records = getAllData()
        records?.append(record)
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(records) else {
            return
        }
        defaults.set(jsonData, forKey: defaultKey)
    }
    
    func getAllData() -> [MetaDataModel]? {
        if let data = defaults.data(forKey: defaultKey) {
            // Decode the Data object back to an array of Person objects.
            let decoder = JSONDecoder()
            if let results = try? decoder.decode([MetaDataModel].self, from: data) {
                return results // prints "[Person(name: "John", age: 25), Person(name: "Mary", age: 30)]"
            }
        }
        return []
    }
    
    func getById(id: String) -> MetaDataModel? {
        return nil
    }
    
    func update(record: MetaDataModel) -> Bool {
        return true
    }
    
    func deleteByIdentifier(id: String) -> Bool {
        return true
    }
    
    func deleteAllMetadata() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "DataWalletMetaData")
        fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try PersistentStorage.shared.context.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else {continue}
                PersistentStorage.shared.context.delete(objectData)
            }
        } catch let error {
            print("Detele all data error :", error)
        }
    }
}
