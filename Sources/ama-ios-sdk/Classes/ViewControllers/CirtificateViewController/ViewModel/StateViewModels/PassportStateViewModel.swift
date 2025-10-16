//
//  PassportStateController.swift
//  dataWallet
//
//  Created by sreelekh N on 07/01/22.
//

import Foundation
import IndyCWrapper

final class PassportStateViewModel: NSObject {
   
    var passportModel: IDCardModel?
    weak var pageDelegate: CirtificateDelegate?
    var passportSections = [[IDCardAttributes]]()
    var recordId: String?
    
    func saveIDCardToWallet(model: IDCardModel) {
        self.checkDuplicate(docNumber: model.documentNumber?.value ?? "") { duplicateExist in
            if(!duplicateExist){
                let customWalletModel = CustomWalletRecordCertModel.init()
                customWalletModel.referent = nil
                customWalletModel.schemaID = nil
                customWalletModel.certInfo = nil
                customWalletModel.connectionInfo = nil
                customWalletModel.type = CertType.idCards.rawValue
                customWalletModel.subType = SelfAttestedCertTypes.passport.rawValue
                customWalletModel.searchableText = SelfAttestedCertTypes.passport.rawValue
                customWalletModel.passport = model
                WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .walletCert ) { [weak self] success, id, error in
                    if (!success) {
                        UIApplicationUtils.showErrorSnackbar(message: "Not able to save ID card".localizedForSDK())
                    } else {
                        self?.pageDelegate?.idCardSaved()
                        UIApplicationUtils.showSuccessSnackbar(message: "Card successfully added to your Data Wallet".localizedForSDK())
                        NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                    }
                }
            } else {
                UIApplicationUtils.showSuccessSnackbar(message: "Passport of this user already existing.".localizedForSDK())
            }
        }
    }
    
    func checkDuplicate(docNumber: String, completion: @escaping((Bool) -> Void)){
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, searchType: .idCards) { (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (fetched, response, error) in
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let idCardSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                var duplicateExist = false
                for doc in idCardSearchModel?.records ?? []{
                    if (doc.value?.passport?.documentNumber?.value == docNumber){
                        duplicateExist = true
                    }
                }
                completion(duplicateExist)
            }
        }
    }
    
    func deleteIDCardFromWallet(walletRecordId: String?) {
        let walletHandler = WalletViewModel.openedWalletHandler ?? 0
        AriesAgentFunctions.shared.deleteWalletRecord(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, id: walletRecordId ?? "") { [weak self](success, error) in
            NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
            self?.pageDelegate?.idCardSaved()
        }
    }
    
    func loadData(model: IDCardModel) {
        passportSections.append(firstSection(model: model))
        passportSections.append(secondSection(model: model))
    }
    
    func firstSection(model: IDCardModel) -> [IDCardAttributes] {
        let firstName = model.firstName?.value ?? ""
        let lastName = model.surName?.value ?? ""
        let gender = model.gender?.value
        let naionality = model.nationality?.value
        let dob = model.dateOfBirth?.value
        let personalNumber = model.personalNumber?.value
        
        let array = [
            IDCardAttributes(name: "First name".localizedForSDK(), value: firstName),
            IDCardAttributes(name: "Last name".localizedForSDK(), value: lastName),
            IDCardAttributes(name: "Gender".localizedForSDK(), value: gender),
            IDCardAttributes(name: "Nationality".localizedForSDK(), value: naionality),
            IDCardAttributes(name: "Date of birth".localizedForSDK(), value: dob),
            IDCardAttributes(name: "Personal Number".localizedForSDK(), value: personalNumber)
        ]
        return array.createAndFindNumberOfLines()
    }
    
    func secondSection(model: IDCardModel) -> [IDCardAttributes] {
        let docNum = model.documentNumber?.value
        let issueCou = model.issuingCountry?.value
        let doe = model.dateOfExpiry?.value
        
        let array = [
            IDCardAttributes(name: "Passport number".localizedForSDK(), value: docNum),
            IDCardAttributes(name: "Issuing Country".localizedForSDK(), value: issueCou),
            IDCardAttributes(name: "Expiration date".localizedForSDK(), value: doe)
        ]
        return array.createAndFindNumberOfLines()
    }
}
