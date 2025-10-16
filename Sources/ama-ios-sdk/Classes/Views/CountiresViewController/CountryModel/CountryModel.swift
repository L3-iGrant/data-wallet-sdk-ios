//
//  CountryModel.swift
//  CountryCode
//
//  Created by Created by WeblineIndia  on 01/07/20.
//  Copyright © 2020 WeblineIndia . All rights reserved.
//

import Foundation
//
//class CountryModel{
//    var disabled: bool?
//    var regionId: String?
//    var regionLabel: String?
//    var parent : [Parent]?
//}
//
//class CountryListModel{
//    var country: [CountryModel]?
//
//    init(_ data: [JSON]) {
//        country = [CountryModel]()
//        for dt in data {
//            let ctyInfo = CountryModel()
//            ctyInfo.disabled = dt["disabled"].boolValue
//            ctyInfo.regionId = dt["regionId"].stringValue
//            ctyInfo.regionLabel = dt["regionLabel"].stringValue
//            ctyInfo.parent = dt["parent"] as? [String] ?? []
//            country?.append(ctyInfo)
//        }
//    }
//}

//"disabled": true, "regionId": "afghanistan", "regionLabel": "Afghanistan", "parent": ["asia"]
//   let countryModel = try? newJSONDecoder().decode(CountryModel.self, from: jsonData)

// MARK: - CountryModelElement
public class CountryModel: Codable {
    let disabled: Bool?
    let regionID: String?
    let regionLabel: String?
    let parent: [String]?

    enum CodingKeys: String, CodingKey {
        case disabled = "disabled"
        case regionID = "regionId"
        case regionLabel = "regionLabel"
        case parent = "parent"
    }
    
    init(disabled: Bool?, regionID: String?, regionLabel: String?, parent: [String]?) {
        self.disabled = disabled
        self.regionID = regionID
        self.regionLabel = regionLabel
        self.parent = parent
    }
}

enum Parent: String, Codable {
    case africa = "africa"
    case antarctica = "antarctica"
    case asia = "asia"
    case europe = "europe"
    case northAmerica = "north_america"
    case oceania = "oceania"
    case southAmerica = "south_america"
}

public typealias CountryListModel = [Country]
