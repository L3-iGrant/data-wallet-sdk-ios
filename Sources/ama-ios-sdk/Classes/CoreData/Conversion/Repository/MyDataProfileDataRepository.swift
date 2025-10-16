//
//  MyDataProfileDataRepository.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 22/12/22.
//

import Foundation
import CoreData

protocol MyDataProfileMetadataProtocol: UpdatesProtocol {}

struct MyDataProfileMetadataRepository: MyDataProfileMetadataProtocol {
    
    typealias T = MyDataProfileMetaDataModel
    let defaults = UserDefaults.standard
    let defaultKey = "MyDataProfile"
    func createMethod(record: MyDataProfileMetaDataModel) {
        var records = getAllData()
        records?.append(record)
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(records) else {
            return
        }
        defaults.set(jsonData, forKey: defaultKey)
    }
    
    func getAllData() -> [MyDataProfileMetaDataModel]? {
        if let data = defaults.data(forKey: defaultKey) {
            // Decode the Data object back to an array of Person objects.
            let decoder = JSONDecoder()
            if let results = try? decoder.decode([MyDataProfileMetaDataModel].self, from: data) {
                return results // prints "[Person(name: "John", age: 25), Person(name: "Mary", age: 30)]"
            }
        }
        return []
    }
    
    func getById(id: String) -> MyDataProfileMetaDataModel? {
        return nil
    }
    
    func update(record: MyDataProfileMetaDataModel) -> Bool {
        return true
    }
    
    func deleteByIdentifier(id: String) -> Bool {
        return true
    }
    
    func deleteAllMetadata() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PKPassBoardingPassMetadata")
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
