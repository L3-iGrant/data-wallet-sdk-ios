//
//  protocol.swift
//  dataWallet
//
//  Created by sreelekh N on 01/03/22.
//

import Foundation
protocol UpdatesProtocol {
   
    func createMethod(record: T)
    func getAllData() -> [T]?
    func getById(id: String) -> T?
    func update(record: T) -> Bool
    func deleteByIdentifier(id: String) -> Bool
    func deleteAllMetadata()
    
    associatedtype T
}
