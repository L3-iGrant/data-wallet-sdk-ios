//
//  AddCardFilterModel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 16/08/21.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let addCardFilterModel = try? newJSONDecoder().decode(AddCardFilterModel.self, from: jsonData)

import Foundation

// MARK: - AddCardFilterModel
class AddCardFilterModel: Codable {
    let regions: [Region]?
    let regionMapping: [String: [Region]]?

    enum CodingKeys: String, CodingKey {
        case regions = "regions"
        case regionMapping = "region_mapping"
    }

    init(regions: [Region]?, regionMapping: [String: [Region]]?) {
        self.regions = regions
        self.regionMapping = regionMapping
    }
}

// MARK: - RegionMapping
class RegionMapping: Codable {
    let europe: [Region]?
    let oceania: [Region]?
    let southAmerica: [Region]?
    let africa: [Region]?
    let asia: [Region]?
    let antarctica: [Region]?
    let northAmerica: [Region]?

    enum CodingKeys: String, CodingKey {
        case europe = "europe"
        case oceania = "oceania"
        case southAmerica = "south_america"
        case africa = "africa"
        case asia = "asia"
        case antarctica = "antarctica"
        case northAmerica = "north_america"
    }

    init(europe: [Region]?, oceania: [Region]?, southAmerica: [Region]?, africa: [Region]?, asia: [Region]?, antarctica: [Region]?, northAmerica: [Region]?) {
        self.europe = europe
        self.oceania = oceania
        self.southAmerica = southAmerica
        self.africa = africa
        self.asia = asia
        self.antarctica = antarctica
        self.northAmerica = northAmerica
    }
}

// MARK: - Region
class Region: Codable {
    let disabled: Bool?
    let regionID: String?
    let regionLabel: String?

    enum CodingKeys: String, CodingKey {
        case disabled = "disabled"
        case regionID = "regionId"
        case regionLabel = "regionLabel"
    }

    init(disabled: Bool?, regionID: String?, regionLabel: String?) {
        self.disabled = disabled
        self.regionID = regionID
        self.regionLabel = regionLabel
    }
}
