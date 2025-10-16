//
//  GenesisRepository.swift
//  dataWallet
//
//  Created by sreelekh N on 01/03/22.
//

import Foundation
import CoreData

protocol GenesisProtocol: UpdatesProtocol {}

struct GenesisRepository: GenesisProtocol {
    
    typealias T = GenesisModel
    let defaults = UserDefaults.standard
    let defaultKey = "Genesis"
    func createMethod(record: GenesisModel) {
        var records = getAllData()
        records?.append(record)
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(records) else {
            return
        }
        defaults.set(jsonData, forKey: defaultKey)
    }
    
    func getAllData() -> [GenesisModel]? {
        if let data = defaults.data(forKey: defaultKey) {
            // Decode the Data object back to an array of Person objects.
            let decoder = JSONDecoder()
            if let results = try? decoder.decode([GenesisModel].self, from: data) {
                return results // prints "[Person(name: "John", age: 25), Person(name: "Mary", age: 30)]"
            }
        }
        return []
    }
    
    func getById(id: String) -> GenesisModel? {
        let data = getGenesisCoreDataModel(byId: id.toInt)
        guard data != nil else {
            return nil
        }
        return data
    }
    
    func update(record: GenesisModel) -> Bool {
//        let model = getGenesisCoreDataModel(byId: record.id)
//        guard model != nil else {
//            return false
//        }
//        model?.id = record.id.toString
//        model?.str = record.str
//        model?.genesisURL = record.genesisURL
//        model?.registerDIDHTMLText = record.registerDIDHTMLText
//        model?.genesisString = record.genesisString
//        PersistentStorage.shared.saveContext()
        return true
    }
    
    func deleteByIdentifier(id: String) -> Bool {
        var results = getAllData()
        results?.removeAll(where: { e in
            e.id == id.toInt
        })
        return true
    }
    
    private func getGenesisCoreDataModel(byId id: Int) -> GenesisModel? {
        let results = getAllData()?.first(where: { e in
            e.id == id
        })
        return results
    }
    
    func deleteAllMetadata() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GenesisCoreData")
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
