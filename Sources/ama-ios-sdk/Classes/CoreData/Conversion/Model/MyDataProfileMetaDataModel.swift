//
//  MyDataProfileDataModel.swift
//  dataWallet
//
//  Created by MOHAMED REBIN K on 22/12/22.
//

import Foundation

//   let myDataProfileDataModel = try? newJSONDecoder().decode(MyDataProfileDataModel.self, from: jsonData)

// MARK: - MyDataProfileDataModelElement
class MyDataProfileModel: Codable {
    let key: String?
    let type: String?
    let label: String?
    let isMandatory: Bool?
    var value: String? = ""

    init(key: String?, type: String?, label: String?, isMandatory: Bool?, value: String? = "") {
        self.key = key
        self.type = type
        self.label = label
        self.isMandatory = isMandatory
        self.value = value
    }
}

extension MyDataProfileModel {
    func convertToDWAttributeMap() -> [String: DWAttributesModel] {
        return [(key ?? "") : DWAttributesModel(value: value, type: type, imageType: "", parent: "", label: label)]
    }
    
    func convertToDWAttributeMap(parent: String) -> [String: DWAttributesModel] {
        return [(key ?? "") : DWAttributesModel(value: value, type: type, imageType: "", parent: parent, label: label)]
    }
    
    func convertToDWAttributeModel(parent: String) ->  DWAttributesModel{
        return DWAttributesModel(value: value, type: type, imageType: "", parent: parent, label: label)
    }
}

extension MyDataProfileMetaDataModel {
    func convertToMyDataProfileMetaDataModel() -> [[MyDataProfileModel]] {
        do{
            let model = try JSONDecoder().decode([[MyDataProfileModel]].self, from: self.data)
            return model
        } catch{
            debugPrint(error.localizedDescription)
            return []
        }
    }
    
    func convertToDWAttributeModel() -> [[String: DWAttributesModel]] {
        do{
            let model = try JSONDecoder().decode([[MyDataProfileModel]].self, from: self.data)
            var attrModelArray: [[String: DWAttributesModel]] = []
            model.forEach { arrayModel in
                attrModelArray.append(contentsOf: arrayModel.map { e in
                   return [(e.key ?? "") : DWAttributesModel(value: e.value, type: e.type, imageType: "", parent: "", label: e.label)]
                })
            }
            return attrModelArray
        } catch{
            debugPrint(error.localizedDescription)
            return []
        }
    }
}




class MyDataProfileMetaDataModel: Codable {
    let data: Data
    
    internal init(data: Data) {
        self.data = data
    }
}

