//
//  Country.swift
//  CountryCode
//
//  Created by Created by WeblineIndia  on 01/07/20.
//  Copyright © 2020 WeblineIndia . All rights reserved.
//

import Foundation
open class Country: NSObject,Codable {

    open var parent: [String]?
    open var regionID: String?
    open var disabled: Bool?
    open var regionLabel : String?
    
    public static var emptyCountry: Country { return Country(regionID: "", regionLabel: "", disabled: true,parent: []) }
    
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
 //init method for country code phone extension and flag
    public init(regionID: String, regionLabel: String, disabled: Bool, parent: [String]) {
        self.regionID = regionID
        self.regionLabel = regionLabel
        self.disabled = disabled
        self.parent = parent
    }

//Method used to find current country of the user
    public static var currentCountry: Country {

        let localIdentifier = Locale.current.identifier //returns identifier of your telephones country/region settings

        let locale = NSLocale(localeIdentifier: localIdentifier)
        if let countryCode = locale.object(forKey: .countryCode) as? String {
            return Countries.countryFromCountryCode(countryCode.uppercased())
        }

        return Country.emptyCountry
    }

    /// Constructor to initialize a country
    ///
    /// - Parameters:
    ///   - countryCode: the country code
    ///   - phoneExtension: phone extension
    ///   - isMain: Bool
    /// Obatin the country name based on current locale
    @objc open var name: String {
        return self.regionLabel ?? ""
//        let localIdentifier = Locale.current.identifier //returns identifier of your telephones country/region settings
//        let locale = NSLocale(localeIdentifier: localIdentifier)
//
//        if let country: String = locale.displayName(forKey: .countryCode, value: regionLabel?.uppercased() ?? "") {
//            return country
//
//        } else {
//            return "Invalid country code"
//        }
    }
}

/// compare to country
///
/// - Parameters:
///   - lhs: Country
///   - rhs: Country
/// - Returns: Bool
public func ==(lhs: Country, rhs: Country) -> Bool {
    return lhs.regionLabel == rhs.regionLabel
}
