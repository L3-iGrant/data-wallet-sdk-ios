//
//  PKPassWalletModel.swift
//  dataWallet
//
//  Created by Mohamed Rebin on 28/11/21.
//

import Foundation

class PKPassWalletModel: Codable{
    var pkPass: Data?
    var id: String?
    var attributes: [IDCardAttributes]?
    var attributeModel: PKPassAttributeModel?
    var type: String?
    var imageData: Data?
    var orgName: String?
    var bgColor: String?
    var transitType: TransitType?
    var walletTitle: String?
    var walletSubTitle: String?

    enum CodingKeys: String, CodingKey {
        case pkPass
        case id
        case attributes
        case type
        case imageData
        case orgName
        case bgColor
        case transitType
        case walletTitle
        case walletSubTitle
        case attributeModel
        
        ///Attributes
        
    }
}

class PKPassAttributeModel: Codable {
    var orgName: IDCardAttributes?
    var gate: IDCardAttributes?
    var departure: IDCardAttributes?
    var arrival: IDCardAttributes?
    var passengerName: IDCardAttributes?
    var boardingTime: IDCardAttributes?
    var flightNumber: IDCardAttributes?
    var boardingDate: IDCardAttributes?
    var ticketClass: IDCardAttributes?
    var barcodeMsg: IDCardAttributes?
    
    enum CodingKeys: String, CodingKey {
        case orgName = "PKPASS BoardingPass Organisation Name"
        case gate = "PKPASS BoardingPass Gate"
        case departure = "PKPASS BoardingPass Depart"
        case arrival = "PKPASS BoardingPass Arrive"
        case passengerName = "PKPASS BoardingPass Passenger"
        case boardingTime = "PKPASS BoardingPass Boarding Time"
        case flightNumber = "PKPASS BoardingPass Flight Number"
        case boardingDate = "PKPASS BoardingPass Boarding Date"
        case ticketClass = "PKPASS BoardingPass Class"
        case barcodeMsg = "PKPASS BoardingPass Barcode Message"
    }
}
