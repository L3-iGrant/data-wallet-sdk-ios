//
//  IDCardModel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 20/05/21.
//

import Foundation
//import NFCPassportReader
import UIKit

enum IDCardType: String {
    case Passport = "passport"
    case DrivingLicense = "Driving License"
    case VotersID = "Voters ID"
    case CovidCert_IND = "IND Covid Certificate"
    case CovidCert_EU = "EU Covid Certificate"
    case CovidCert_PHL = "PHL Covid Certificate"
    case digitalTestCertificateEU
}

struct IDCardModel: Codable {
    let type: IDCardAttributes?
    let firstName: IDCardAttributes?
    let surName: IDCardAttributes?
    let gender: IDCardAttributes?
    let nationality: IDCardAttributes?
    let dateOfBirth: IDCardAttributes?
    let personalNumber: IDCardAttributes?
    let documentNumber: IDCardAttributes?
    let issuingCountry: IDCardAttributes?
    let dateOfExpiry: IDCardAttributes?
    let profileImage: IDCardAttributes?
    let signature: IDCardAttributes?
    
//    static func initFromPassportModel(model: NFCPassportModel) -> IDCardModel {
//        let type = IDCardAttributes.init(name: "type", value:IDCardType.Passport.rawValue, schemeID: "")
//        let firstName = IDCardAttributes.init(name: "First Name", value:model.firstName, schemeID: "Passport First Name")
//        let surName = IDCardAttributes.init(name: "Sur Name", value:model.lastName, schemeID: "Passport Sur Name")
//        let gender = IDCardAttributes.init(name: "Passport Gender", value:model.gender)
//        let nationality = IDCardAttributes.init(name: "Passport Nationality", value:model.nationality)
//        let dateOfBirth = IDCardAttributes.init(name: "Passport Birth Date", value:model.dateOfBirth)
//        let personalNumber = IDCardAttributes.init(name: "Passport Personal Number", value:model.personalNumber)
//        let documentNumber = IDCardAttributes.init(name: "Passport Serial Number", value:model.documentNumber)
//        let issuingCountry = IDCardAttributes.init(name: "Passport Issuer Authority", value:model.issuingAuthority)
//        let dateOfExpiry = IDCardAttributes.init(name: "Passport Expiry Date", value:model.documentExpiryDate)
//        var profileImage: IDCardAttributes?
//        var signature: IDCardAttributes?
//        
//        if let passportImage = model.passportImage{
//            profileImage = IDCardAttributes.init(type: .image, name: "Passport Image",value:UIApplicationUtils.shared.convertImageToBase64String(img: passportImage))
//        }
//        
//        if let signatureImage = model.signatureImage{
//            signature = IDCardAttributes.init(type: .image, name: "Passport Signature",value:UIApplicationUtils.shared.convertImageToBase64String(img: signatureImage))
//        }
//        
//        return IDCardModel.init(type: type, firstName: firstName, surName: surName, gender: gender, nationality: nationality, dateOfBirth: dateOfBirth, personalNumber: personalNumber, documentNumber: documentNumber, issuingCountry: issuingCountry, dateOfExpiry: dateOfExpiry, profileImage: profileImage, signature: signature)
//    }
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case firstName = "Passport First Name"
        case surName = "Passport Sur Name"
        case gender = "Passport Gender"
        case nationality = "Passport Nationality"
        case dateOfBirth = "Passport Birth Date"
        case personalNumber = "Passport Personal Number"
        case documentNumber = "Passport Serial Number"
        case issuingCountry = "Passport Issuer Authority"
        case dateOfExpiry = "Passport Expiry Date"
        case profileImage = "Passport Image"
        case signature = "Passport Signature"
    }
}

struct IDCardSearchRecordModel: Codable {
    var totalCount: Int?
    var records: [CustomWalletRecordCertModel]?
}

struct IDCardItems_CustomWalletRecordCertModel: Codable {
    var type: String?
    var id: String?
    var value: CustomWalletRecordCertModel?
}

struct IDCardAttributes: Codable {
    var type: CertAttributesTypes?
    var value: String?
    var name: String?
    var schemeID: String?
    
    // custom
    var alignmentCalculated: Bool?
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case value = "value"
        case name = "name"
        case schemeID = "schemeID"
        case alignmentCalculated
    }
    
    init(type: CertAttributesTypes? = CertAttributesTypes.string, name:String?, value: String?, schemeID: String? = nil) {
        self.type = type
        self.value = value
        self.name = name
        self.schemeID = schemeID
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try? container.decode(CertAttributesTypes.self, forKey: .type)
        name = try? container.decode(String.self, forKey: .name)
//        value = CodableUtils.decodeAsString(container: container, codingKey: .value)
        value = try? container.decode(String.self, forKey: .value)

        schemeID = try? container.decode(String.self, forKey: .schemeID)
        
        do{
            alignmentCalculated = try container.decode(Bool.self, forKey: .alignmentCalculated)
        } catch {
            alignmentCalculated = false
        }
    }
}

enum CertAttributesTypes: String,Codable {
    case string = "String"
    case image = "Image"
    case account = "Account"
    case card = "Card"
}

extension Array where Element == IDCardAttributes {
    
    func createAndFindNumberOfLines() -> [IDCardAttributes] {
        var calculatedArray = self
        let font = UIFont.systemFont(ofSize: 15)
        let font_2 = UIFont.systemFont(ofSize: 14)
        let width = (ScreenMain.init().width ?? 0) - 70
        //Consider min space between name and value as 15
        let space: CGFloat = 15
        let labelWidth = width - space
        for (index, data) in calculatedArray.enumerated() {
            let nameWidth : CGFloat = data.name?.widthOfString(usingFont: font) ?? 0.0
            let valueWidth : CGFloat = data.value?.widthOfString(usingFont: font_2) ?? 0.0
            let totWidth = nameWidth + valueWidth
            if totWidth > labelWidth {
                calculatedArray[index].alignmentCalculated = true
            } else {
                calculatedArray[index].alignmentCalculated = false
            }
        }
        return calculatedArray
    }
}

extension UILabel {
    
    static func getLabel(font: UIFont) -> UILabel {
        let lbl = UILabel()
        lbl.font = font
        lbl.numberOfLines = 0
        lbl.sizeToFit()
        return lbl
    }
    
    func numberOfLine(width: CGFloat) -> Int {
        let textSize = CGSize(width: width, height: CGFloat(Float.infinity))
        let rHeight = lroundf(Float(self.sizeThatFits(textSize).height))
        let charSize = lroundf(Float(self.font.lineHeight))
        let lineCount = rHeight/charSize
        return lineCount
    }
}

extension String {
    func widthOfString(usingFont font: UIFont) -> CGFloat {
        let fontAttributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: fontAttributes)
        return size.width
    }
}

struct ScreenMain {
    
    var area: CGRect!
    
    init () {
        area = UIScreen.main.bounds
    }
    
    var width: CGFloat? {
        return area.width
    }
    
    var height: CGFloat? {
        return area.height
    }
}
