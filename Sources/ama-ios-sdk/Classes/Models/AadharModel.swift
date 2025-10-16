//
//  AadharModel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 06/08/21.
//

import Foundation

class AadharModel: Codable {
    let uid: IDCardAttributes?
    let name: IDCardAttributes?
    let gender: IDCardAttributes?
    let yearOfBirth: IDCardAttributes?
    let careOf: IDCardAttributes?
    let house: IDCardAttributes?
    let landmark: IDCardAttributes?
    let vtc: IDCardAttributes?
    let postOffice: IDCardAttributes?
    let district: IDCardAttributes?
    let subDistrict: IDCardAttributes?
    let state: IDCardAttributes?
    let pincode: IDCardAttributes?
    let location: IDCardAttributes?
    let QRCode: IDCardAttributes?
    let userImage: IDCardAttributes?

    init(model: PrintLetterBarcodeData,qrCode: String,userImageBase64: String?){
        uid = IDCardAttributes.init(name: "Aadhar Uid", value: model.uid)
        name = IDCardAttributes.init(name: "Aadhar Name", value:model.name)
        gender = IDCardAttributes.init(name: "Aadhar Gender", value:model.gender)
        yearOfBirth = IDCardAttributes.init(name: "Aadhar YearOfBirth", value:model.yob)
        careOf = IDCardAttributes.init(name: "Aadhar CareOf", value:model.co)
        house = IDCardAttributes.init(name: "Aadhar House", value:model.house)
        landmark = IDCardAttributes.init(name: "Aadhar Landmark", value:model.lm)
        vtc = IDCardAttributes.init(name: "Aadhar Vtc", value:model.vtc)
        postOffice = IDCardAttributes.init(name: "Aadhar PostOffice", value:model.po)
        district = IDCardAttributes.init(name: "Aadhar District", value:model.dist)
        subDistrict = IDCardAttributes.init(name: "Aadhar SubDistrict", value:model.subdist)
        pincode = IDCardAttributes.init(name: "Aadhar Pincode", value:model.pc)
        state = IDCardAttributes.init(name: "Aadhar State", value:model.state)
        location = IDCardAttributes.init(name: "Aadhar Location", value:model.location)
        QRCode = IDCardAttributes.init(type: .image, name: "QRCode", value: qrCode)
        userImage = IDCardAttributes.init(type: .image, name: "Aadhar Image",value: userImageBase64 ?? "")
        
        //TO DO:
//        uid = IDCardAttributes.init(name: "Unique ID", value: model.uid, schemeID: "Aadhar Uid")
//        name = IDCardAttributes.init(name: "Name", value:model.name, schemeID: "Aadhar Name")
//        gender = IDCardAttributes.init(name: "Gender", value:model.gender, schemeID: "Aadhar Gender")
//        yearOfBirth = IDCardAttributes.init(name: "Year Of Birth", value:model.yob, schemeID: "Aadhar YearOfBirth")
//        careOf = IDCardAttributes.init(name: "Care Of", value:model.co, schemeID: "Aadhar CareOf")
//        house = IDCardAttributes.init(name: "House", value:model.house, schemeID: "Aadhar House")
//        landmark = IDCardAttributes.init(name: "Landmark", value:model.lm, schemeID: "Aadhar Landmark")
//        vtc = IDCardAttributes.init(name: "Village/Town/City", value:model.vtc, schemeID: "Aadhar Vtc")
//        postOffice = IDCardAttributes.init(name: "Post Office", value:model.po, schemeID: "Aadhar PostOffice")
//        district = IDCardAttributes.init(name: "District", value:model.dist, schemeID: "Aadhar District")
//        subDistrict = IDCardAttributes.init(name: "Sub District", value:model.subdist, schemeID: "Aadhar SubDistrict")
//        pincode = IDCardAttributes.init(name: "Pincode", value:model.pc, schemeID: "Aadhar Pincode")
//        state = IDCardAttributes.init(name: "State", value:model.state, schemeID: "Aadhar State")
//        location = IDCardAttributes.init(name: "Location", value:model.location, schemeID: "Aadhar Location")
//        QRCode = IDCardAttributes.init(type: .image, name: "QRCode", value: qrCode, schemeID: "QRCode")
//        userImage = IDCardAttributes.init(type: .image, name: "Aadhar Image",value: userImageBase64 ?? "", schemeID: "Aadhar Image")
    }

    enum CodingKeys: String, CodingKey {
        case uid = "Aadhar Uid"
        case name = "Aadhar Name"
        case gender = "Aadhar Gender"
        case yearOfBirth = "Aadhar YearOfBirth"
        case careOf = "Aadhar CareOf"
        case house = "Aadhar House"
        case landmark = "Aadhar Landmark"
        case vtc = "Aadhar Vtc"
        case postOffice = "Aadhar PostOffice"
        case district = "Aadhar District"
        case subDistrict = "Aadhar SubDistrict"
        case pincode = "Aadhar Pincode"
        case state = "Aadhar State"
        case location = "Aadhar Location"
        case QRCode = "QRCode"
        case userImage = "Aadhar Image"

    }
}

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let aadharScannedModel = try? newJSONDecoder().decode(AadharScannedModel.self, from: jsonData)

import Foundation

// MARK: - AadharScannedModel
class AadharScannedModel: Codable {
    let printLetterBarcodeData: PrintLetterBarcodeData?

    enum CodingKeys: String, CodingKey {
        case printLetterBarcodeData = "PrintLetterBarcodeData"
    }

    init(printLetterBarcodeData: PrintLetterBarcodeData?) {
        self.printLetterBarcodeData = printLetterBarcodeData
    }
}

// MARK: - PrintLetterBarcodeData
class PrintLetterBarcodeData: Codable {
    let pc: String?
    let name: String?
    let dist: String?
    let subdist: String?
    let state: String?
    let po: String?
    let gender: String?
    let house: String?
    let co: String?
    let yob: String?
    let lm: String?
    let uid: String?
    let vtc: String?
    let location: String?

    enum CodingKeys: String, CodingKey {
        case pc = "_pc"
        case name = "_name"
        case dist = "_dist"
        case subdist = "_subdist"
        case state = "_state"
        case po = "_po"
        case gender = "_gender"
        case house = "_house"
        case co = "_co"
        case yob = "_yob"
        case lm = "_lm"
        case uid = "_uid"
        case vtc = "_vtc"
        case location = "_loc"
    }

    init(pc: String?, name: String?, dist: String?, subdist: String?, state: String?, po: String?, gender: String?, house: String?, co: String?, yob: String?, lm: String?, uid: String?, vtc: String?, location: String?) {
        self.pc = pc
        self.name = name
        self.dist = dist
        self.subdist = subdist
        self.state = state
        self.po = po
        self.gender = gender
        self.house = house
        self.co = co
        self.yob = yob
        self.lm = lm
        self.uid = uid
        self.vtc = vtc
        self.location = location
    }
}
