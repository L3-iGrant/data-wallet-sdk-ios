//
//  AadharStateViewModel.swift
//  dataWallet
//
//  Created by sreelekh N on 07/01/22.
//

import Foundation
import UIKit
import IndyCWrapper

final class AadharStateViewModel {
    
    weak var pageDelegate: CirtificateDelegate?
    var aadharDetails: [IDCardAttributes]?
    var aadharModel: AadharModel?
    
    var recordId: String?
    var QRCodeImage: UIImage?
    var userImage: UIImage?
    
    init(model: AadharModel){
        aadharModel = model
        QRCodeImage = UIApplicationUtils.shared.convertBase64StringToImage(imageBase64String: model.QRCode?.value ?? "")
        userImage = UIApplicationUtils.shared.convertBase64StringToImage(imageBase64String: model.userImage?.value ?? "")
        let uID = model.uid?.value?.formatedFor(stride: .aadhar)
        let pin = model.pincode?.value?.formatedFor(stride: .pincode)
        aadharDetails = [
            IDCardAttributes.init(type: .string, name: "Unique ID", value: uID),
            IDCardAttributes.init(type: .string, name: "Name", value: model.name?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "Gender", value: model.gender?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "Year Of Birth", value: model.yearOfBirth?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "Care Of ", value: model.careOf?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "House", value: model.house?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "Landmark", value: model.landmark?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "Village/Town/City", value: model.vtc?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "Post Office", value: model.postOffice?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "Sub District", value: model.subDistrict?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "District", value: model.district?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "State", value: model.state?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "Location", value: model.location?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "Pincode", value: pin)
        ]
    }
    
    fileprivate func saveToWallet() {
        let customWalletModel = CustomWalletRecordCertModel.init()
        customWalletModel.referent = nil
        customWalletModel.schemaID = nil
        customWalletModel.certInfo = nil
        customWalletModel.connectionInfo = nil
        customWalletModel.type = CertType.idCards.rawValue
        customWalletModel.subType = SelfAttestedCertTypes.aadhar.rawValue
        customWalletModel.searchableText = SelfAttestedCertTypes.aadhar.rawValue

        if let model = self.aadharModel {
            customWalletModel.aadhar = model
        }
        WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .walletCert ) { [weak self] success, id, error in
            if (!success) {
                UIApplicationUtils.showErrorSnackbar(message: "Not able to save ID card".localizedForSDK())
            } else {
                self?.pageDelegate?.idCardSaved()
                UIApplicationUtils.showSuccessSnackbar(message: "Aadhar is now added to the Data Wallet".localizedForSDK())
                NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
            }
        }
    }
    
    func saveAadharCertToWallet() {
        if let uid = aadharModel?.uid?.value,uid.isNotEmpty {
            self.checkDuplicate(docNumber: uid) { duplicateExist in
                if(!duplicateExist){
                    self.saveToWallet()
                }else {
                    UIApplicationUtils.showSuccessSnackbar(message: "Aadhar of this user already exist in Data Wallet".localizedForSDK())
                }
            }
            } else {
                saveToWallet()
            }
    }
    
    func checkDuplicate(docNumber: String, completion: @escaping((Bool) -> Void)){
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, searchType: .aadhar) { (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (fetched, response, error) in
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let idCardSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                var duplicateExist = false
                for doc in idCardSearchModel?.records ?? []{
                    if (doc.value?.aadhar?.uid?.value == docNumber){
                        duplicateExist = true
                    }
                }
                completion(duplicateExist)
            }
        }
    }
    
    func deleteIDCardFromWallet(walletRecordId: String?){
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, id: walletRecordId ?? "") { [weak self](success, error) in
            NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
            self?.pageDelegate?.idCardSaved()
        }
    }
}
