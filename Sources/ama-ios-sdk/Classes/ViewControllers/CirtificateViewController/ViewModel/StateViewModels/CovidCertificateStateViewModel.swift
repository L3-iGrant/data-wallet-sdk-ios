//
//  CovidCertificateStateViewModel.swift
//  dataWallet
//
//  Created by sreelekh N on 08/01/22.
//

import Foundation
import covid19_global_sdk_iOS
import IndyCWrapper
import UIKit

enum CovidCertType {
    case India
    case Europe
    case UK
    case Malaysia
    case Philippine
}

enum CertificateType {
    case EuropianCovid
    case digitalTestCertificate
}

final class CovidCertificateStateViewModel {
    weak var pageDelegate: CirtificateDelegate?
    
    var EU_Model: ValidationResult?
    var IN_Model: CovidIndiaCertificateModel?
    var recordId: String?
    var beneficiaryName: String?
    var ageValue: String?
    var genderValue: String?
    var idVerifiedValue: String?
    var idNumberValue: String?
    var uniqueHealthIDValue: String?
    var beneficiaryReferenceIDValue: String?
    var certificateId: String?
    var vaccinationManufacturer: String?
    var batchNumber: String?
    
    var vaccinationNameValue: String?
    var dateOfDoseValue: String?
    var validUntill: String?
    var vaccinatedByValue: String?
    var vaccinationAtValue: String?
    var vaccinatedDosageValue: String?
    var vaccineManufacturerValue: String?
    var vaccinatedCountry: String?
    var certificateIssuer: String?
    var type: CovidCertType?
    var QRCodeImage: UIImage?
    
    var beneficiaryDetails: [IDCardAttributes]?
    var vaccinationDetails: [IDCardAttributes]?
    
    var certificateType: CertificateType? = .EuropianCovid
    
    init(model: ValidationResult, certificateType: CertificateType? = .EuropianCovid) {
        self.certificateType = certificateType
        EU_Model = model
        beneficiaryName = (model.greenpass?.person.givenName?.uppercased() ?? "") + " " + (model.greenpass?.person.familyName?.uppercased() ?? "")
        ageValue = model.greenpass?.dateOfBirth ?? ""
        switch certificateType {
        case .digitalTestCertificate:
            let vaccination = model.greenpass?.tests?.last
            certificateIssuer = vaccination?.certificateIssuer ?? ""
            uniqueHealthIDValue = vaccination?.certificateIdentifier
            var stateLabel = "Member State".localizedForSDK()
            switch (model.metaInformation?.issuer){
            case "UK","GB":
                type = CovidCertType.UK
                stateLabel = "Country".localizedForSDK()
            case "MY":
                type = CovidCertType.Malaysia
                stateLabel = "Country".localizedForSDK()
            default:
                type = CovidCertType.Europe
            }
            
            let beneficiaryDetails = [
                IDCardAttributes.init(type: .string, name: "Full Name".localizedForSDK(), value: beneficiaryName),
                IDCardAttributes.init(type: .string, name: "Date Of Birth".localizedForSDK(), value: ageValue),
                IDCardAttributes.init(type: .string, name: stateLabel.localizedForSDK(), value: vaccination?.country),
            ]
            self.beneficiaryDetails = beneficiaryDetails.createAndFindNumberOfLines()
        default:
            let vaccination = model.greenpass?.vaccinations?.last
            dateOfDoseValue = vaccination?.vaccinationDate
            validUntill = String(model.metaInformation?.expirationTime?.split(separator: "T").first ?? "NA")
            vaccineManufacturerValue = VaccineManufacturer(rawValue: vaccination?.marketingAuthorizationHolder ?? "")?.humanReadable() ?? vaccination?.marketingAuthorizationHolder
            vaccinatedDosageValue = "\(vaccination?.doseNumber ?? 0) of \(vaccination?.totalDoses ?? 0)"
            uniqueHealthIDValue = vaccination?.certificateIdentifier
            var stateLabel = "Member State".localizedForSDK()
            switch (model.metaInformation?.issuer){
            case "UK","GB":
                type = CovidCertType.UK
                stateLabel = "Country".localizedForSDK()
            case "MY":
                type = CovidCertType.Malaysia
                stateLabel = "Country".localizedForSDK()
            default:
                type = CovidCertType.Europe
            }
            
            certificateIssuer = vaccination?.certificateIssuer ?? ""
            let beneficiaryDetails = [
                IDCardAttributes.init(type: .string, name: "Full Name".localizedForSDK(), value: beneficiaryName),
                IDCardAttributes.init(type: .string, name: "Date Of Birth".localizedForSDK(), value: ageValue),
                IDCardAttributes.init(type: .string, name: stateLabel.localizedForSDK(), value: vaccination?.country),
            ]
            self.beneficiaryDetails = beneficiaryDetails.createAndFindNumberOfLines()
        }
        vaccinationDetails = getDetailsSection()
        if(model.error == ValidationError.CWT_EXPIRED) {
            UIApplicationUtils.showErrorSnackbar(message: "Certificate is expired".localizedForSDK())
        }
        self.pageDelegate?.updateUI()
    }
    
    //INDIA
    init(model: CovidIndiaCertificateModel) {
        IN_Model = model
        beneficiaryName = model.credentialSubject?.name
        ageValue = model.credentialSubject?.age ??  model.credentialSubject?.dob ?? ""
        genderValue = model.credentialSubject?.gender ?? model.credentialSubject?.sex
        let id = model.credentialSubject?.id?.split(separator: ":")
        if (id?.count ?? 0) > 2 {
            idVerifiedValue = "\(id?[1] ?? "")"
            idNumberValue = "\(id?[2] ?? "")"
        } else {
            idVerifiedValue = "NA"
            idNumberValue = "NA"
        }
        
        uniqueHealthIDValue = model.credentialSubject?.uhid ?? "NA"
        beneficiaryReferenceIDValue = model.credentialSubject?.refID ?? "NA"
        let vaccine = model.evidence?.last
        vaccinationNameValue = vaccine?.vaccine ?? "NA"
        dateOfDoseValue = vaccine?.date
        vaccinatedByValue = vaccine?.verifier?.name ?? "NA"
        vaccinationAtValue = vaccine?.facility?.name ?? "NA"
        vaccinatedDosageValue = "\(vaccine?.dose ?? 0) of \(vaccine?.totalDoses ?? 0)"
        certificateId = vaccine?.certificateID ?? ""
        vaccinationManufacturer = vaccine?.manufacturer ?? ""
        batchNumber = vaccine?.batch ?? ""
        //switch model.
        type = CovidCertType.India
        if model.issuer == "PHL DOH" {
            type = CovidCertType.Philippine
            populateDetailsForPHLCert()
        } else {
            populateDetailsForINDCert()
        }
    }
    
    //IND
    init(model: CovidIndiaCertificateWalletModel) {
        beneficiaryName = model.fullName?.value ?? ""
        ageValue = model.age?.value ?? ""
        genderValue = model.gender?.value ?? ""
        idVerifiedValue = model.idVerified?.value ?? ""
        idNumberValue = model.idNumber?.value ?? ""
        
        uniqueHealthIDValue = model.uniqueHealthId?.value ?? ""
        beneficiaryReferenceIDValue = model.beneficiaryRefId?.value ?? ""
        vaccinationNameValue = model.vaccineName?.value ?? ""
        dateOfDoseValue = model.dateOfDose?.value ?? ""
        vaccinatedByValue = model.vaccinatedBy?.value ?? ""
        vaccinationAtValue = model.vaccinatedAt?.value ?? ""
        vaccinatedDosageValue = model.vaccinationDosage?.value ?? ""
        QRCodeImage = convertBase64StringToImage(imageBase64String: model.QRCodeImage?.value ?? "")
        type = .India
        populateDetailsForINDCert()
    }
    
    //PHL
    init(model: CovidPHLCertificateWalletModel) {
        certificateId = model.certificateId?.value ?? ""
        vaccinationManufacturer = model.vaccinationManufacturer?.value ?? ""
        batchNumber = model.batchNumber?.value ?? ""
        beneficiaryName = model.fullName?.value ?? ""
        ageValue = model.dob?.value ?? ""
        genderValue = model.gender?.value ?? ""
        beneficiaryReferenceIDValue = model.beneficiaryRefId?.value ?? ""
        vaccinationNameValue = model.vaccineName?.value ?? ""
        dateOfDoseValue = model.dateOfDose?.value ?? ""
        vaccinationAtValue = model.vaccinatedAt?.value ?? ""
        vaccinatedDosageValue = model.vaccinationDosage?.value ?? ""
        QRCodeImage = convertBase64StringToImage(imageBase64String: model.QRCodeImage?.value ?? "")
        type = .Philippine
        populateDetailsForPHLCert()
    }
    
    func getDetailsSection() -> [IDCardAttributes] {
        switch self.certificateType {
        case .digitalTestCertificate:
            let model = EU_Model?.greenpass?.tests?.last
            let split = model?.timestampSample.split(separator: "T")
            let manufactur = TestManufacturer(rawValue: model?.manufacturer ?? "")?.humanReadable()
            let result = TestResult(rawValue: model?.result ?? "")?.humanReadable()
            let testType = TestType(rawValue: model?.type ?? "")?.humanReadable()
            let disease = DiseaseAgentTargeted(rawValue: model?.disease ?? "")?.humanReadable()
            validUntill = String(EU_Model?.metaInformation?.expirationTime?.split(separator: "T").first ?? "NA")
            
            let details = [
                IDCardAttributes.init(type: .string, name: "Unique Certificate Identifier".localizedForSDK(), value: model?.certificateIdentifier),
                IDCardAttributes.init(type: .string, name: "disease_targetted".localizedForSDK(), value: disease ?? "NA"),
                IDCardAttributes.init(type: .string, name: "type_of_test".localizedForSDK(), value: testType ?? "NA"),
                IDCardAttributes.init(type: .string, name: "test_name".localizedForSDK(), value: model?.testName ?? "NA"),
                IDCardAttributes.init(type: .string, name: "device_identifier".localizedForSDK(), value: manufactur ?? "NA"),
                IDCardAttributes.init(type: .string, name: "sample_collection_date".localizedForSDK(), value: String(split?.first ?? "NA")),
                IDCardAttributes.init(type: .string, name: "Certificate Valid Until".localizedForSDK(), value: validUntill),
                IDCardAttributes.init(type: .string, name: "test_result".localizedForSDK(), value: result ?? "NA"),
                IDCardAttributes.init(type: .string, name: "test_center".localizedForSDK(), value: model?.testCenter ?? "NA"),
            ]
            let calculated = details.createAndFindNumberOfLines()
            return calculated
        default:
            let details = [
                IDCardAttributes.init(type: .string, name: "Vaccination Manufacturer".localizedForSDK(), value: vaccineManufacturerValue),
                IDCardAttributes.init(type: .string, name: "Vaccination Date".localizedForSDK(), value: dateOfDoseValue),
                IDCardAttributes.init(type: .string, name: "Certificate Valid Until".localizedForSDK(), value: validUntill),
                IDCardAttributes.init(type: .string, name: "Unique Certificate Identifier".localizedForSDK(), value: uniqueHealthIDValue),
                IDCardAttributes.init(type: .string, name: "Vaccinated Dosage".localizedForSDK(), value: vaccinatedDosageValue)
            ]
            let calculated = details.createAndFindNumberOfLines()
            return calculated
        }
    }
    
    init(model: CovidEUCertificateWalletModel, certificateType: CertificateType? = .EuropianCovid) {
        self.certificateType = certificateType
        switch certificateType {
        case .EuropianCovid:
            beneficiaryName = model.fullName?.value ?? ""
            ageValue = model.DateOfBirth?.value ?? ""
            dateOfDoseValue = model.vaccineDate?.value ?? ""
            validUntill = model.validUntil?.value ?? ""
            vaccineManufacturerValue = model.vaccineManufacturer?.value ?? ""
            vaccinatedDosageValue = model.vaccinatedDosage?.value ?? ""
            uniqueHealthIDValue = model.uniqueCertificateIdentifier?.value ?? ""
            var stateLabel = "Member State".localizedForSDK()
            switch (model.country?.value){
            case "UK","GB":
                type = CovidCertType.UK
                stateLabel = "Country".localizedForSDK()
            case "MY":
                type = CovidCertType.Malaysia
                stateLabel = "Country".localizedForSDK()
            default:
                type = CovidCertType.Europe
            }
            
            certificateIssuer = model.certificateIssuer?.value ?? ""
            QRCodeImage = convertBase64StringToImage(imageBase64String: model.QRCodeImage?.value ?? "")
            
            let beneficiaryDetails = [
                IDCardAttributes(type: .string, name: "Full Name".localizedForSDK(), value: beneficiaryName),
                IDCardAttributes(type: .string, name: "Date Of Birth".localizedForSDK(), value: ageValue),
                IDCardAttributes(type: .string, name: stateLabel.localizedForSDK(), value: model.memberState?.value ?? ""),
            ]
            self.beneficiaryDetails = beneficiaryDetails.createAndFindNumberOfLines()
            
            let vaccinationDetails = [
                IDCardAttributes(type: .string, name: "Vaccination Manufacturer".localizedForSDK(), value: vaccineManufacturerValue),
                IDCardAttributes(type: .string, name: "Vaccination Date".localizedForSDK(), value: dateOfDoseValue),
                IDCardAttributes(type: .string, name: "Certificate Valid Until".localizedForSDK(), value: validUntill),
                IDCardAttributes(type: .string, name: "Unique Certificate Identifier".localizedForSDK(), value: uniqueHealthIDValue),
                IDCardAttributes(type: .string, name: "Vaccinated Dosage".localizedForSDK(), value: vaccinatedDosageValue)
            ]
            self.vaccinationDetails = vaccinationDetails.createAndFindNumberOfLines()
        default:
            loadSavedEUTestCertificate(model)
        }
        self.pageDelegate?.updateUI()
    }
    
    func loadSavedEUTestCertificate(_ model: CovidEUCertificateWalletModel) {
        certificateIssuer = model.certificateIssuer?.value ?? ""
        QRCodeImage = convertBase64StringToImage(imageBase64String: model.QRCodeImage?.value ?? "")
        uniqueHealthIDValue = model.certificateIdentifier?.value ?? ""
        
        let beneficiaryDetails = [
            IDCardAttributes.init(type: .string, name: "Full Name".localizedForSDK(), value: model.name?.value),
            IDCardAttributes.init(type: .string, name: "Date Of Birth".localizedForSDK(), value: model.DOB?.value),
            IDCardAttributes.init(type: .string, name: "Member State".localizedForSDK(), value: model.state?.value),
        ]
        self.beneficiaryDetails = beneficiaryDetails.createAndFindNumberOfLines()
        
        let vaccinationDetails = [
            IDCardAttributes.init(type: .string, name: "Unique Certificate Identifier".localizedForSDK(), value: model.certificateIdentifier?.value ?? "NA"),
            IDCardAttributes.init(type: .string, name: "disease_targetted".localizedForSDK(), value: model.disease?.value ?? "NA"),
            IDCardAttributes.init(type: .string, name: "type_of_test".localizedForSDK(), value: model.testType?.value ?? ""),
            IDCardAttributes.init(type: .string, name: "test_name".localizedForSDK(), value: model.testName?.value ?? "NA"),
            IDCardAttributes.init(type: .string, name: "device_identifier".localizedForSDK(), value: model.manufactur?.value ?? "NA"),
            IDCardAttributes.init(type: .string, name: "sample_collection_date".localizedForSDK(), value: model.sampleCollectionDate?.value ?? "NS"),
            IDCardAttributes.init(type: .string, name: "test_result".localizedForSDK(), value: model.result?.value ?? "NA"),
            IDCardAttributes.init(type: .string, name: "test_center".localizedForSDK(), value: model.center?.value ?? "NA"),
        ]
        self.vaccinationDetails = vaccinationDetails.createAndFindNumberOfLines()
    }
    
    //Philippines
    func populateDetailsForPHLCert() {
        let beneficiaryDetails = [
            IDCardAttributes.init(type: .string, name: "Full Name", value: beneficiaryName),
            IDCardAttributes.init(type: .string, name: "Date Of Birth", value: ageValue),
            IDCardAttributes.init(type: .string, name: "Gender", value: genderValue),
            IDCardAttributes.init(type: .string, name: "Beneficiary Reference Id", value: beneficiaryReferenceIDValue),
        ]
        
        self.beneficiaryDetails = beneficiaryDetails.createAndFindNumberOfLines()
        
        let vaccinationDetails = [
            IDCardAttributes.init(type: .string, name: "Certificate Id", value: certificateId),
            IDCardAttributes.init(type: .string, name: "Vaccine Name", value: vaccinationNameValue),
            IDCardAttributes.init(type: .string, name: "Vaccination Manufacturer", value: vaccinationManufacturer),
            IDCardAttributes.init(type: .string, name: "Batch Number", value: batchNumber),
            IDCardAttributes.init(type: .string, name: "Date Of Dose", value: dateOfDoseValue),
            IDCardAttributes.init(type: .string, name: "Vaccinated At", value: vaccinationAtValue),
            IDCardAttributes.init(type: .string, name: "Vaccinated Dosage", value: vaccinatedDosageValue)        ]
        
        self.vaccinationDetails = vaccinationDetails.createAndFindNumberOfLines()
        self.pageDelegate?.updateUI()
    }
    
    func saveCovidCertificate() {
        switch type {
        case .India,.Philippine:
            saveINCovideCertToWallet()
        default:
            if(EU_Model?.error == ValidationError.CWT_EXPIRED) {
                UIApplicationUtils.showErrorSnackbar(message: "Certificate is expired".localizedForSDK())
                return
            }
            
            switch certificateType {
            case .digitalTestCertificate:
                saveEUDigitalCertificate()
            default:
                saveEUCovideCertToWallet()
            }
        }
    }
    
    func saveEUDigitalCertificate() {
        self.checkDuplicateEUTestCertificate(docNumber: uniqueHealthIDValue ?? "") { duplicateExist in
            if duplicateExist {
                UIApplicationUtils.showSuccessSnackbar(message: "digital_cerificate_exists".localizedForSDK())
            } else {
                let customWalletModel = CustomWalletRecordCertModel.init()
                customWalletModel.referent = nil
                customWalletModel.schemaID = nil
                customWalletModel.certInfo = nil
                customWalletModel.connectionInfo = nil
                customWalletModel.type = CertType.selfAttestedRecords.rawValue
                customWalletModel.subType = SelfAttestedCertTypes.digitalTestCertificateEU.rawValue
                customWalletModel.searchableText = SelfAttestedCertTypes.digitalTestCertificateEU.rawValue
                customWalletModel.passport = nil
                if let user = self.beneficiaryDetails, let userDetails = self.vaccinationDetails {
                    var allFields = [IDCardAttributes]()
                    allFields.append(contentsOf: user)
                    allFields.append(contentsOf: userDetails)
                    if let image = self.QRCodeImage {
                        let converted = self.convertImageToBase64String(img: image)
                        let qrCode = IDCardAttributes.init(type: .image, name: "qrCode", value: converted)
                        allFields.append(qrCode)
                    }
                    let issuer = IDCardAttributes.init(name: "issuer", value: self.certificateIssuer)
                    allFields.append(issuer)
                    let saverModel = CovidEUCertificateWalletModel.getEUTestSaverModel(savedModel: allFields)
                    customWalletModel.covidCert_EU = saverModel
                }
                
                WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .walletCert ) { [weak self] success, id, error in
                    if (!success) {
                        UIApplicationUtils.showErrorSnackbar(message: "cant_save_EU_digital".localizedForSDK())
                    } else {
                        self?.pageDelegate?.idCardSaved()
                        UIApplicationUtils.showSuccessSnackbar(message: "digital_EU_is_added".localizedForSDK())
                        NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                    }
                }
            }
        }
    }
    
    func saveEUCovideCertToWallet() {
        self.checkDuplicate(docNumber: uniqueHealthIDValue ?? "") { duplicateExist in
            if (!duplicateExist) {
                let customWalletModel = CustomWalletRecordCertModel.init()
                customWalletModel.referent = nil
                customWalletModel.schemaID = nil
                customWalletModel.certInfo = nil
                customWalletModel.connectionInfo = nil
                customWalletModel.type = CertType.selfAttestedRecords.rawValue
                customWalletModel.subType = SelfAttestedCertTypes.covidCert_EU.rawValue
                customWalletModel.searchableText = SelfAttestedCertTypes.covidCert_EU.rawValue
                customWalletModel.passport = nil
                if let model = self.EU_Model {
                    customWalletModel.covidCert_EU = CovidEUCertificateWalletModel.initFromCovidCertModel(model: model, QRCode: self.convertImageToBase64String(img: self.QRCodeImage ?? UIImage()))
                }
                WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .walletCert ) { [weak self] success, id, error in
                    if (!success) {
                        UIApplicationUtils.showErrorSnackbar(message: "Not able to save ID card".localizedForSDK())
                    } else {
                        
                        self?.pageDelegate?.idCardSaved()
                        UIApplicationUtils.showSuccessSnackbar(message: "Vaccination Certificate is now added to the Data Wallet".localizedForSDK())
                        NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                    }
                }
            } else {
                UIApplicationUtils.showSuccessSnackbar(message: "Vaccination Certificate of this user already existing".localizedForSDK())
            }
        }
    }
    
    func convertImageToBase64String (img: UIImage) -> String {
        return img.jpegData(compressionQuality: 1)?.base64EncodedString() ?? ""
    }
    
    func convertBase64StringToImage (imageBase64String:String) -> UIImage {
        let imageData = Data.init(base64Encoded: imageBase64String, options: .init(rawValue: 0))
        let image = UIImage(data: imageData ?? Data())
        return image ?? UIImage()
    }
    
    func checkDuplicate(docNumber: String, completion: @escaping((Bool) -> Void)){
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        var cert_type: WalletSearch = .covidCert_IN
        switch type {
        case .India:
            cert_type = .covidCert_IN
        case .Philippine:
            cert_type = .covidCert_PHL
        case .Europe:
            cert_type = .covidCert_EU
        default:
            break
        }
        
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, searchType: cert_type) { (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (fetched, response, error) in
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let idCardSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                var duplicateExist = false
                switch self.type {
                case .India :
                    for doc in idCardSearchModel?.records ?? []{
                        if (doc.value?.covidCert_IND?.idNumber?.value == docNumber){
                            duplicateExist = true
                        }
                    }
                case .Philippine:
                    for doc in idCardSearchModel?.records ?? []{
                        if (doc.value?.covidCert_PHL?.certificateId?.value == docNumber){
                            duplicateExist = true
                        }
                    }
                default:
                    for doc in idCardSearchModel?.records ?? []{
                        if (doc.value?.covidCert_EU?.uniqueCertificateIdentifier?.value == docNumber){
                            duplicateExist = true
                        }
                    }
                    
                }
                completion(duplicateExist)
            }
        }
    }
    
    func checkDuplicateEUTestCertificate(docNumber: String, completion: @escaping((Bool) -> Void)){
        let walletHandler = WalletViewModel.openedWalletHandler ?? IndyHandle()
        
        AriesAgentFunctions.shared.openWalletSearch_type(walletHandler: walletHandler, type: AriesAgentFunctions.walletCertificates, searchType: .testCert_EU) { (success, searchHandler, error) in
            AriesAgentFunctions.shared.fetchWalletSearchNextRecords(walletHandler: walletHandler, searchWalletHandler: searchHandler) { (fetched, response, error) in
                let responseDict = UIApplicationUtils.shared.convertToDictionary(text: response)
                let idCardSearchModel = Search_CustomWalletRecordCertModel.decode(withDictionary: responseDict as NSDictionary? ?? NSDictionary()) as? Search_CustomWalletRecordCertModel
                var duplicateExist = false
                
                //Check for certificate in wallet with similar unique id
                for doc in idCardSearchModel?.records ?? []{
                    if (doc.value?.covidCert_EU?.certificateIdentifier?.value == docNumber){
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

extension CovidCertificateStateViewModel {
    func populateDetailsForINDCert(){
        let beneficiaryDetails = [
            IDCardAttributes.init(type: .string, name: "Beneficiary Name", value: beneficiaryName),
            IDCardAttributes.init(type: .string, name: "Age", value: ageValue),
            IDCardAttributes.init(type: .string, name: "Gender", value: genderValue),
            IDCardAttributes.init(type: .string, name: "ID Verified", value: idVerifiedValue),
            IDCardAttributes.init(type: .string, name: "ID Number ", value: idNumberValue),
            IDCardAttributes.init(type: .string, name: "Unique Health ID ", value: uniqueHealthIDValue),
            IDCardAttributes.init(type: .string, name: "Beneficiary Reference ID", value: beneficiaryReferenceIDValue),
        ]
        
        self.beneficiaryDetails = beneficiaryDetails.createAndFindNumberOfLines()
        
        let vaccinationDetails = [
            IDCardAttributes.init(type: .string, name: "Vaccine Name", value: vaccinationNameValue),
            IDCardAttributes.init(type: .string, name: "Date Of Dose", value: dateOfDoseValue),
            IDCardAttributes.init(type: .string, name: "Vaccinated By", value: vaccinatedByValue),
            IDCardAttributes.init(type: .string, name: "Vaccinated At", value: vaccinationAtValue),
            IDCardAttributes.init(type: .string, name: "Vaccinated Dosage", value: vaccinatedDosageValue)
        ]
        
        self.vaccinationDetails = vaccinationDetails.createAndFindNumberOfLines()
        self.pageDelegate?.updateUI()
    }
    
    func saveINCovideCertToWallet() {
        var uniqueId = idNumberValue
        switch type {
        case .Philippine: uniqueId = certificateId
        default: break
        }
        self.checkDuplicate(docNumber: uniqueId ?? "") { duplicateExist in
            if (!duplicateExist) {
                let customWalletModel = CustomWalletRecordCertModel.init()
                customWalletModel.referent = nil
                customWalletModel.schemaID = nil
                customWalletModel.certInfo = nil
                customWalletModel.connectionInfo = nil
                customWalletModel.type = CertType.selfAttestedRecords.rawValue
                customWalletModel.subType = self.type == .India ? SelfAttestedCertTypes.covidCert_IN.rawValue : SelfAttestedCertTypes.covidCert_PHL.rawValue
                customWalletModel.searchableText = self.type == .India ? SelfAttestedCertTypes.covidCert_IN.rawValue : SelfAttestedCertTypes.covidCert_PHL.rawValue
                if let model = self.IN_Model {
                    if self.type == .India {
                        customWalletModel.covidCert_IND = CovidIndiaCertificateWalletModel.initFromCovidCertModel(model: model, QRCode: self.convertImageToBase64String(img: self.QRCodeImage ?? UIImage()))
                    } else if self.type == .Philippine {
                        customWalletModel.covidCert_PHL = CovidPHLCertificateWalletModel.initFromCovidCertModel(model: model, QRCode: self.convertImageToBase64String(img: self.QRCodeImage ?? UIImage()))
                    }
                }
                WalletRecord.shared.add(connectionRecordId: "", walletCert: customWalletModel, walletHandler: WalletViewModel.openedWalletHandler ?? IndyHandle(), type: .walletCert ) { [weak self] success, id, error in
                    if (!success) {
                        UIApplicationUtils.showErrorSnackbar(message: "Not able to save ID card".localizedForSDK())
                    } else {
                        self?.pageDelegate?.idCardSaved()
                        UIApplicationUtils.showSuccessSnackbar(message: "Vaccination Certificate is now added to the Data Wallet".localizedForSDK())
                        NotificationCenter.default.post(name: Constants.reloadWallet, object: nil)
                    }
                }
            } else {
                UIApplicationUtils.showSuccessSnackbar(message: "Vaccination Certificate of this user already existing".localizedForSDK())
            }
        }
    }
}
