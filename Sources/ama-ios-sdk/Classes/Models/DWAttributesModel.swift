//
//  DWAttributesModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 04/01/23.
//

import Foundation

struct DWAttributesModel: Codable {
    let value, type, imageType, parent, label: String?
    let pwaType: CertAttributesTypes?

    enum CodingKeys: String, CodingKey {
        case value, type, imageType, parent, label, pwaType
    }
    
    init(value: String?, type: String?, imageType: String?, parent: String?, label: String?, pwaType: CertAttributesTypes? = CertAttributesTypes.string) {
        self.value = value
        self.type = type
        self.imageType = imageType
        self.parent = parent
        self.label = label
        self.pwaType = pwaType
    }
    
    init(fromAttributes: IDCardAttributes, parent: String) {
        self.value = fromAttributes.value
        self.type = fromAttributes.type?.rawValue ?? CertAttributesTypes.string.rawValue
        self.parent = parent
        self.label = fromAttributes.name
        self.imageType = ""
        self.pwaType = fromAttributes.type
    }
    
    static func generateAttributeMap(fromAttributes: IDCardAttributes, parent: String) -> (String, DWAttributesModel) {
        return (fromAttributes.schemeID ?? "", DWAttributesModel.init(fromAttributes: fromAttributes, parent: parent))
    }
}

struct DWSection: Codable {
    var title,key, type: String?
    
    enum CodingKeys: String, CodingKey {
        case title,key, type
    }
}

struct DWHeaderFields: Codable {
    let title,subTitle,desc: String?
    
    enum CodingKeys: String, CodingKey {
        case title,subTitle,desc
    }
}

struct DWQRCodeData: Codable {
    let rawData,imageBase64: String?
    
    enum CodingKeys: String, CodingKey {
        case rawData,imageBase64
    }
}

