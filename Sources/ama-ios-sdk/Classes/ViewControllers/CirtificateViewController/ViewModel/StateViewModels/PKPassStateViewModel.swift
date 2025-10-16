//
//  PKPassStateViewModel.swift
//  dataWallet
//
//  Created by sreelekh N on 08/01/22.
//

import Foundation
import IndyCWrapper
import UIKit

enum TransitType: String, Codable {
    case PKTransitTypeAir = "PKTransitTypeAir"
    case PKTransitTypeTrain = "PKTransitTypeTrain"
}

final class PKPassStateViewModel {
    
    weak var pageDelegate: CirtificateDelegate?
    
    var PKPassDict: [String: Any]?
    var PKPassData: Data?
    var attrArray: [IDCardAttributes] = []
    var backFieldArray: [IDCardAttributes] = []
    var headerFieldArray: [IDCardAttributes] = []
    var logoImageData: Data?
    var recordId: String?
    var orgName: String?
    var mainTitle: String?
    var subTitle: String?
    var transitType: TransitType?
    
    //Boarding pass - travel mode - airline,train
    var origin: String?
    var origin_short: String?
    var destination: String?
    var destination_short: String?
    var bgColor: UIColor?
    var fgColor: UIColor?
    var labelColor: UIColor?
    var barCodeImage: UIImage?
    var subTitleKeys: [String] = []
    var PKPassAttr = PKPassAttributeModel()
    var PKPassMeta : [String: [String]]?

    
    init(pkPassDict:[String: Any]?, pkPassData: Data?, recordId: String?, imageData: Data?,orgName: String?){      
        self.PKPassDict = pkPassDict
        self.PKPassData = pkPassData
        self.recordId = recordId
        self.logoImageData = imageData
        self.orgName = orgName
        if let bgColorString = pkPassDict?["backgroundColor"] as? String {
            self.bgColor = UIColor.getColorFromRGBString(rgbString: bgColorString)
        }
        if let bgColorString = pkPassDict?["foregroundColor"] as? String {
            self.fgColor = UIColor.getColorFromRGBString(rgbString: bgColorString)
        }
        if let bgColorString = pkPassDict?["foregroundColor"] as? String {
            self.labelColor = UIColor.getColorFromRGBString(rgbString: bgColorString)
        }
        if let barcodeDict = pkPassDict?["barcode"] as? [String: Any] ?? (pkPassDict?["barcodes"] as? [[String: Any]])?.first {
            if let barcodeType = barcodeDict["format"] as? String{
                switch barcodeType{
                case "PKBarcodeFormatQR":
                    if let barcodeMsg = barcodeDict["message"] as? String{
                        barCodeImage = generateQRCode(from: barcodeMsg)
                    }
                case "PKBarcodeFormatAztec":
                    if let barcodeMsg = barcodeDict["message"] as? String{
                        if let data = barcodeMsg.data(using: .utf8) {
                            if let CIBarCodeImage = CIFilter(name: "CIAztecCodeGenerator",
                                                             parameters: [ "inputMessage" : data ])?
                                .outputImage?.transformed(by: CGAffineTransform(scaleX: 4, y: 4)) {
                                barCodeImage = self.convert(cmage: CIBarCodeImage)
                            }
                        }
                    }
                default:
                    if let barcodeMsg = barcodeDict["message"] as? String{
                        if let data = barcodeMsg.data(using: .utf8) {
                            if let CIBarCodeImage = CIFilter(name: "CIAztecCodeGenerator",
                                                             parameters: [ "inputMessage" : data ])?
                                .outputImage?.transformed(by: CGAffineTransform(scaleX: 4, y: 4)) {
                                barCodeImage = self.convert(cmage: CIBarCodeImage)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func savePKPassToWallet(){
        let id  = PKPassDict?["authenticationToken"] as? String ?? PKPassDict?["serialNumber"] as? String ?? ""
        self.checkDuplicate(docNumber: id) { duplicateExist in
            if(!duplicateExist){
                let customWalletModel = CustomWalletRecordCertModel.init()
                customWalletModel.referent = nil
                customWalletModel.schemaID = nil
                customWalletModel.certInfo = nil
                customWalletModel.connectionInfo = nil
                customWalletModel.type = CertType.selfAttestedRecords.rawValue
                customWalletModel.subType = SelfAttestedCertTypes.pkPass.rawValue
                customWalletModel.searchableText = self.getPKPassSearchableString()
                let model = PKPassWalletModel.init()
                model.pkPass = self.PKPassData
                model.id = id
                model.attributeModel = self.generateAttributes()
                model.imageData = self.logoImageData
                model.orgName = self.orgName
                model.bgColor = self.PKPassDict?["backgroundColor"] as? String ?? ""
                model.transitType = self.transitType
                model.type = self.getPKPassType()
                model.walletTitle = (self.origin_short ?? "") + " - " + (self.destination_short ?? "")
                let flightNo = self.subTitle != nil ? "(\( self.subTitle ?? ""))" : ""
                model.walletSubTitle = (self.orgName ?? "") + flightNo
                customWalletModel.pkPass = model
                WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .walletCert ) { [weak self] success, id, error in
                    if (!success) {
                        UIApplicationUtils.showErrorSnackbar(message: "Not able to save ID card".localizedForSDK())
                    } else {
                        self?.pageDelegate?.popVC()
                        UIApplicationUtils.showSuccessSnackbar(message: "PKPass is now added to the Data Wallet".localizedForSDK())
                        NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                    }
                }
            } else {
                UIApplicationUtils.showSuccessSnackbar(message: "PKPass already exist in Data Wallet".localizedForSDK())
            }
        }
    }
    
    private func generateAttributes() -> PKPassAttributeModel{
            PKPassAttr.orgName = IDCardAttributes.init(name: "PKPASS BoardingPass Organisation Name", value: orgName)
            PKPassAttr.departure = IDCardAttributes.init(name: "PKPASS BoardingPass Depart", value: origin)
            PKPassAttr.arrival = IDCardAttributes.init(name: "PKPASS BoardingPass Arrive", value: destination)
            PKPassAttr.gate = generateIDCardAttribute(schemeID: "PKPASS BoardingPass Gate")
            PKPassAttr.passengerName = generateIDCardAttribute(schemeID: "PKPASS BoardingPass Passenger")
            PKPassAttr.boardingTime = generateIDCardAttribute(schemeID: "PKPASS BoardingPass Boarding Time")
            PKPassAttr.flightNumber = generateIDCardAttribute(schemeID: "PKPASS BoardingPass Flight Number")
            PKPassAttr.boardingDate = generateIDCardAttribute(schemeID: "PKPASS BoardingPass Boarding Date")
            PKPassAttr.ticketClass = generateIDCardAttribute(schemeID: "PKPASS BoardingPass Class")
            PKPassAttr.barcodeMsg = generateIDCardAttribute(schemeID: "PKPASS BoardingPass Barcode Message")
        return PKPassAttr
    }
    
    private func generateIDCardAttribute(schemeID:String) -> IDCardAttributes{
        let keys = PKPassMeta?[schemeID] ?? []
        if let boardingPass = PKPassDict?["boardingPass"] as? [String: Any] {
            if let headerFields = boardingPass["headerFields"] as? [[String: String]] {
                for field in headerFields {
                    if keys.map({ e in
                        e.lowercased()
                    }).contains(field["key"]?.lowercased() ?? ""){
                        return IDCardAttributes.init(name: field["label"] ?? "", value: field["value"] ?? "")
                    }
                }
            }
            
            if let headerFields = boardingPass["secondaryFields"] as? [[String: String]] {
                for field in headerFields {
                    if keys.map({ e in
                        e.lowercased()
                    }).contains(field["key"]?.lowercased() ?? ""){
                        return IDCardAttributes.init(name: field["label"] ?? "", value: field["value"] ?? "")
                    }
                }
            }
            
            if let headerFields = boardingPass["auxiliaryFields"] as? [[String: String]] {
                for field in headerFields {
                    if keys.map({ e in
                        e.lowercased()
                    }).contains(field["key"]?.lowercased() ?? ""){
                        return IDCardAttributes.init(name: field["label"] ?? "", value: field["value"] ?? "")
                    }
                }
            }
        }
        return IDCardAttributes.init(name: "", value: "")
    }
    
    func checkDuplicate(docNumber: String, completion: @escaping((Bool) -> Void)){
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, searchType: .PKPass) { (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (fetched, response, error) in
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let idCardSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                var duplicateExist = false
                for doc in idCardSearchModel?.records ?? []{
                    if (doc.value?.pkPass?.id == docNumber){
                        duplicateExist = true
                    }
                }
                completion(duplicateExist)
            }
        }
    }
    
    func getPKPassType() -> String{
        if PKPassDict?.keys.contains("boardingPass") ?? false{
            return "Boarding Pass".localizedForSDK()
        }else if PKPassDict?.keys.contains("coupon") ?? false{
            return "Coupon".localizedForSDK()
        }else if PKPassDict?.keys.contains("event") ?? false{
            return "Event".localizedForSDK()
        }else if PKPassDict?.keys.contains("genericpass") ?? false{
            return "Generic Pass".localizedForSDK()
        }else if PKPassDict?.keys.contains("storecard") ?? false{
            return "Store Card".localizedForSDK()
        }else{
            return "PK Pass"
        }
    }
    
    func getPKPassSearchableString() -> String {
        if PKPassDict?.keys.contains("boardingPass") ?? false{
            return "Boarding Pass"
        }else if PKPassDict?.keys.contains("coupon") ?? false{
            return "Coupon"
        }else if PKPassDict?.keys.contains("event") ?? false{
            return "Event"
        }else if PKPassDict?.keys.contains("genericpass") ?? false{
            return "Generic Pass"
        }else if PKPassDict?.keys.contains("storecard") ?? false{
            return "Store Card"
        }else{
            return "PK Pass"
        }
    }
    
    func getIDCardAttributesArray() {
        orgName = PKPassDict?["organizationName"] as? String ?? ""
        if let boardingPass = PKPassDict?["boardingPass"] as? [String: Any] {
            attrArray.append(contentsOf: generateIDCardAttributesFromDictionary(dict: boardingPass))
            pageDelegate?.updateUI()
        } else {
            pageDelegate?.notSupportedPKPass()
        }
        //        else if let coupon = PKPassDict?["coupon"] as? [String: Any] {
        //            attrArray.append(contentsOf: generateIDCardAttributesFromDictionary(dict: coupon))
        //        }else if let event = PKPassDict?["event"] as? [String: Any] {
        //            attrArray.append(contentsOf: generateIDCardAttributesFromDictionary(dict: event))
        //        }else if let genericpass = PKPassDict?["genericpass"] as? [String: Any] {
        //            attrArray.append(contentsOf: generateIDCardAttributesFromDictionary(dict: genericpass))
        //        }else if let storecard = PKPassDict?["storecard"] as? [String: Any] {
        //            attrArray.append(contentsOf: generateIDCardAttributesFromDictionary(dict: storecard))
        //        }
    }
    
    func generateIDCardAttributesFromDictionary(dict: [String: Any]) -> [IDCardAttributes]{
        var tempAttrArray: [IDCardAttributes] = []
        PKPassAttr.orgName = IDCardAttributes.init(name: "PKPASS BoardingPass Organisation Name", value: orgName)
        if let transitTypeString = dict["transitType"] as? String {
            switch transitTypeString {
            case TransitType.PKTransitTypeAir.rawValue:
                transitType = TransitType.PKTransitTypeAir
            case TransitType.PKTransitTypeTrain.rawValue:
                transitType = TransitType.PKTransitTypeTrain
            default:
                transitType = TransitType.PKTransitTypeAir
            }
        }
        if let headerFields = dict["headerFields"] as? [[String: String]] {
            for field in headerFields {
                if subTitleKeys.contains(field["key"]?.lowercased() ?? ""){
                    self.subTitle = "\(field["label"] ?? ""): \(field["value"] ?? "")"
                } else {
                    headerFieldArray.append(IDCardAttributes.init(name: field["label"], value: field["value"] ?? ""))
                }
            }
        }
        if let primaryFields = dict["primaryFields"] as? [[String: String]] {
            //            let originKeys = ["origin","depart","offPoint" ]
            //            let destinationKeys = ["destination","arrive", "dest", "boardPoint"]
            //            for field in primaryFields {
            //                if originKeys.contains(field["key"] ?? ""){
            //                    self.origin = field["label"]
            //                    self.origin_short = field["value"]
            //                }else if destinationKeys.contains(field["key"] ?? ""){
            //                    self.destination = field["label"]
            //                    self.destination_short = field["value"]
            //                } else {
            //                    tempAttrArray.append(IDCardAttributes.init(name: field["key"], value: field["label"] ?? ""))
            //                }
            //            }
            if let originField = primaryFields.first {
                self.origin = originField["label"]
                self.origin_short = originField["value"]
            }
            if primaryFields.count >= 2 {
                let destField = primaryFields[1]
                self.destination = destField["label"]
                self.destination_short = destField["value"]
            }
        }
        if let secondaryFields = dict["secondaryFields"] as? [[String: String]] {
            for field in secondaryFields {
                if subTitleKeys.contains(field["key"]?.lowercased() ?? ""){
                    self.subTitle = "\(field["label"] ?? ""): \(field["value"] ?? "")"
                } else {
                    tempAttrArray.append(IDCardAttributes.init(name: field["label"], value: field["value"] ?? ""))
                }
            }
        }
        if let auxiliaryFields = dict["auxiliaryFields"] as? [[String: String]] {
            for field in auxiliaryFields {
                if subTitleKeys.contains(field["key"]?.lowercased() ?? ""){
                    self.subTitle = "\(field["label"] ?? ""): \(field["value"] ?? "")"
                } else {
                    tempAttrArray.append(IDCardAttributes.init(name: field["label"], value: field["value"] ?? ""))
                }
            }
        }
        if let backFields = dict["backFields"] as? [[String: String]] {
            for field in backFields {
                backFieldArray.append(IDCardAttributes.init(name: field["label"], value: field["value"] ?? ""))
            }
        }
        return tempAttrArray
    }
    
    func deleteIDCardFromWallet(walletRecordId: String?){
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, id: walletRecordId ?? "") { [weak self](success, error) in
            NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
            self?.pageDelegate?.popVC()
        }
    }
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    func generateQRCode(from string: String) -> UIImage?
    {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator")
        {
            filter.setValue(data, forKey: "inputMessage")
            guard let _ = filter.outputImage else { return nil }
            let transform = CGAffineTransform(scaleX: 4, y: 4)
            if let output = filter.outputImage?.transformed(by: transform)
            {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
}
