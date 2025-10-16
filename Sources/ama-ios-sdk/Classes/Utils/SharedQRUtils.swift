//
//  SharedQRUtils.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 10/10/21.
//

import Foundation

class SharedQRUtils: Codable {
    
    public static func addToSharedQRQueue(imageData: Data){
        var placeArray = getSharedQRQueue()
        placeArray?.append(imageData)
        let placesData = try! JSONEncoder().encode(placeArray)
        UserDefaults.standard.set(placesData, forKey: "shared_QR")
    }
    
    public static func getSharedQRQueue() -> [Data]?{
        if let placeData = UserDefaults.standard.data(forKey: "shared_QR") {
            if let placeArray = try? JSONDecoder().decode([Data].self, from: placeData){
                return placeArray
            }
            return []
        }
        return []
    }
}
